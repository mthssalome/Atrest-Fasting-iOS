import Foundation
import Data

#if DEBUG
/// Debug-only static entitlement adapter used for previews and tests.
public actor StaticEntitlementService: EntitlementServicing {
    private let snapshot: EntitlementSnapshot

    public init(entitlement: Entitlement = .free) {
        self.snapshot = EntitlementSnapshot(entitlement: entitlement, source: .stored, updatedAt: Date())
    }

    public func current() async -> EntitlementSnapshot { snapshot }
    public func reconcile() async -> EntitlementSnapshot { snapshot }
    public func purchase(product: PurchaseProduct) async -> EntitlementSnapshot { snapshot }
    public func restore() async -> EntitlementSnapshot { snapshot }
}
#endif
