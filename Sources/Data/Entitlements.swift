import Foundation
import Domain
import Policy
#if canImport(StoreKit)
import StoreKit
import Security
#else
import Security
#endif

public enum PurchaseProduct: String, CaseIterable {
    case annual = "com.atrest.annual"
    case lifetime = "com.atrest.lifetime"
}

public struct StoreProductInfo: Equatable {
    public let id: String
    public let displayName: String
    public let displayPrice: String
}

public enum PurchaseOutcome: Equatable {
    case purchased(productID: String)
    case userCancelled
    case pending
    case notFound
}

public protocol PurchaseClient: Sendable {
    func products(ids: [String]) async throws -> [StoreProductInfo]
    func purchase(productID: String) async throws -> PurchaseOutcome
    func restoreEntitlements(productIDs: [String]) async throws -> PurchaseOutcome
    func currentEntitlement(productIDs: [String]) async throws -> PurchaseOutcome
}

#if canImport(StoreKit)
@available(iOS 16.0, *)
public struct StoreKitPurchaseClient: PurchaseClient, Sendable {
    public init() {}

    public func products(ids: [String]) async throws -> [StoreProductInfo] {
        let products = try await Product.products(for: ids)
        return products.map { StoreProductInfo(id: $0.id, displayName: $0.displayName, displayPrice: $0.displayPrice) }
    }

    public func purchase(productID: String) async throws -> PurchaseOutcome {
        guard let product = try await Product.products(for: [productID]).first else { return .notFound }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                return .purchased(productID: product.id)
            case .unverified:
                return .notFound
            }
        case .userCancelled:
            return .userCancelled
        case .pending:
            return .pending
        @unknown default:
            return .notFound
        }
    }

    public func restoreEntitlements(productIDs: [String]) async throws -> PurchaseOutcome {
        var restored = false
        for await result in Transaction.all {
            if case .verified(let transaction) = result, productIDs.contains(transaction.productID) {
                await transaction.finish()
                restored = true
            }
        }
        return restored ? .purchased(productID: productIDs.first ?? "") : .notFound
    }

    public func currentEntitlement(productIDs: [String]) async throws -> PurchaseOutcome {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, productIDs.contains(transaction.productID) {
                return .purchased(productID: transaction.productID)
            }
        }
        return .notFound
    }
}
#endif

public final class EntitlementStore {
    private let service: String
    private let account: String

    public init(service: String = "app.atrest.entitlement", account: String = "state") {
        self.service = service
        self.account = account
    }

    public func load() -> EntitlementSnapshot {
        guard let data = read(), let value = String(data: data, encoding: .utf8), let entitlement = Entitlement(rawValue: value) else {
            return EntitlementSnapshot(entitlement: .free, source: .stored, updatedAt: Date())
        }
        return EntitlementSnapshot(entitlement: entitlement, source: .stored, updatedAt: Date())
    }

    public func save(_ entitlement: Entitlement) {
        let data = entitlement.rawValue.data(using: .utf8) ?? Data()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            _ = SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    public func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func read() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        return item as? Data
    }
}

public struct EntitlementSnapshot: Equatable {
    public enum Source: Equatable {
        case stored
        case purchase
        case restore
        case reconcile
        case trial
    }

    public let entitlement: Entitlement
    public let source: Source
    public let updatedAt: Date

    public init(entitlement: Entitlement, source: Source, updatedAt: Date) {
        self.entitlement = entitlement
        self.source = source
        self.updatedAt = updatedAt
    }
}

public protocol EntitlementServicing {
    func current() async -> EntitlementSnapshot
    func reconcile() async -> EntitlementSnapshot
    func purchase(product: PurchaseProduct) async -> EntitlementSnapshot
    func restore() async -> EntitlementSnapshot
}

public final actor EntitlementService: EntitlementServicing {
    private let store: EntitlementStore
    private let purchaseClient: PurchaseClient
    private let productIDs = PurchaseProduct.allCases.map { $0.rawValue }
    private let clock: () -> Date
    private let completedCount: () async -> Int

    public init(store: EntitlementStore = EntitlementStore(),
                purchaseClient: PurchaseClient,
                clock: @escaping () -> Date = Date.init,
                completedCount: @escaping () async -> Int = { 0 }) {
        self.store = store
        self.purchaseClient = purchaseClient
        self.clock = clock
        self.completedCount = completedCount
    }

    public func current() async -> EntitlementSnapshot {
        let stored = store.load()
        let count = await completedCount()
        return effectiveSnapshot(purchaseEntitlement: stored.entitlement, source: stored.source, completedCount: count)
    }

    public func reconcile() async -> EntitlementSnapshot {
        let outcome = try? await purchaseClient.currentEntitlement(productIDs: productIDs)
        let isPurchased: Bool
        if case .purchased = outcome {
            isPurchased = true
        } else {
            isPurchased = false
        }
        let purchaseEntitlement: Entitlement = isPurchased ? .premium : .free
        if purchaseEntitlement == .premium {
            store.save(.premium)
        } else {
            store.save(.free)
        }
        let count = await completedCount()
        return effectiveSnapshot(purchaseEntitlement: purchaseEntitlement, source: .reconcile, completedCount: count)
    }

    public func purchase(product: PurchaseProduct) async -> EntitlementSnapshot {
        let outcome = try? await purchaseClient.purchase(productID: product.rawValue)
        switch outcome {
        case .purchased:
            store.save(.premium)
            let count = await completedCount()
            return effectiveSnapshot(purchaseEntitlement: .premium, source: .purchase, completedCount: count)
        default:
            return await current()
        }
    }

    public func restore() async -> EntitlementSnapshot {
        let outcome = try? await purchaseClient.restoreEntitlements(productIDs: productIDs)
        switch outcome {
        case .purchased:
            store.save(.premium)
            let count = await completedCount()
            return effectiveSnapshot(purchaseEntitlement: .premium, source: .restore, completedCount: count)
        default:
            return await current()
        }
    }

    private func effectiveSnapshot(purchaseEntitlement: Entitlement,
                                   source: EntitlementSnapshot.Source,
                                   completedCount: Int) -> EntitlementSnapshot {
        if purchaseEntitlement == .premium {
            return EntitlementSnapshot(entitlement: .premium, source: source, updatedAt: clock())
        }

        if let trialEntitlement = TrialPolicy.entitlement(forCompleted: completedCount) {
            return EntitlementSnapshot(entitlement: trialEntitlement, source: .trial, updatedAt: clock())
        }

        return EntitlementSnapshot(entitlement: .free, source: source, updatedAt: clock())
    }

}

private extension Entitlement {
    init?(rawValue: String?) {
        guard let rawValue else { return nil }
        switch rawValue {
        case "free": self = .free
        case "premium": self = .premium
        case "trial": self = .trial
        default: return nil
        }
    }

    var rawValue: String {
        switch self {
        case .free: return "free"
        case .premium: return "premium"
        case .trial: return "trial"
        }
    }
}
