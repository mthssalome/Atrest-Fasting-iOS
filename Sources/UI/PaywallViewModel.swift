import Foundation
import Data
import Domain

@MainActor
public final class PaywallViewModel: ObservableObject {
    @Published public private(set) var products: [PurchaseProduct: StoreProductInfo] = [:]
    @Published public private(set) var statusText: String = L10n.paywallStatusIdle
    @Published public private(set) var entitlement: EntitlementSnapshot

    private let entitlementService: EntitlementServicing
    private let purchaseClient: PurchaseClient
    private let productIDs: [PurchaseProduct] = PurchaseProduct.allCases

    public init(entitlementService: EntitlementServicing, purchaseClient: PurchaseClient, initialEntitlement: EntitlementSnapshot = EntitlementSnapshot(entitlement: .free, source: .stored, updatedAt: Date())) {
        self.entitlementService = entitlementService
        self.purchaseClient = purchaseClient
        self.entitlement = initialEntitlement
    }

    public func loadProducts() async {
        do {
            let infos = try await purchaseClient.products(ids: productIDs.map { $0.rawValue })
            var mapped: [PurchaseProduct: StoreProductInfo] = [:]
            for info in infos {
                if let product = PurchaseProduct(rawValue: info.id) {
                    mapped[product] = info
                }
            }
            products = mapped
        } catch {
            statusText = L10n.paywallStatusError
        }
    }

    public func setProductsForTesting(_ products: [PurchaseProduct: StoreProductInfo]) {
        self.products = products
    }

    public func updateEntitlement(_ snapshot: EntitlementSnapshot) {
        entitlement = snapshot
    }

    public func setStatusMessage(_ message: String) {
        statusText = message
    }

    public func purchase(_ product: PurchaseProduct) async {
        statusText = L10n.paywallStatusPurchasing
        let snapshot = await entitlementService.purchase(product: product)
        entitlement = snapshot
        statusText = snapshot.entitlement == .premium ? L10n.paywallStatusSuccess : L10n.paywallStatusError
    }

    public func restore() async {
        statusText = L10n.paywallStatusRestoring
        let snapshot = await entitlementService.restore()
        entitlement = snapshot
        statusText = snapshot.entitlement == .premium ? L10n.paywallStatusSuccess : L10n.paywallStatusError
    }

    public func price(for product: PurchaseProduct) -> String {
        products[product]?.displayPrice ?? "—"
    }
}
