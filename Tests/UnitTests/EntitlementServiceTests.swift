import XCTest
@testable import Data
@testable import Domain

final class EntitlementServiceTests: XCTestCase {
    private var store: EntitlementStore!
    private var clockDate: Date!

    override func setUp() {
        super.setUp()
        let serviceID = "entitlement-tests-\(UUID().uuidString)"
        store = EntitlementStore(service: serviceID)
        clockDate = Date(timeIntervalSince1970: 1_000)
    }

    override func tearDown() {
        store.clear()
        super.tearDown()
    }

    func testInitialDefaultsToFree() async {
        let service = EntitlementService(store: store, purchaseClient: MockPurchaseClient(), clock: { self.clockDate })
        let snapshot = await service.current()
        XCTAssertEqual(snapshot.entitlement, .free)
    }

    func testPurchaseUpgradesToPremiumAndPersists() async {
        let client = MockPurchaseClient(purchaseOutcome: .purchased(productID: PurchaseProduct.annual.rawValue))
        let service = EntitlementService(store: store, purchaseClient: client, clock: { self.clockDate })
        let snapshot = await service.purchase(product: .annual)
        XCTAssertEqual(snapshot.entitlement, .premium)
        XCTAssertEqual(snapshot.source, .purchase)

        let service2 = EntitlementService(store: store, purchaseClient: client, clock: { self.clockDate })
        let stored = await service2.current()
        XCTAssertEqual(stored.entitlement, .premium)
    }

    func testRestoreDoesNotDowngradeWhenNotFound() async {
        let client = MockPurchaseClient(restoreOutcome: .notFound)
        let service = EntitlementService(store: store, purchaseClient: client, clock: { self.clockDate })
        let snapshot = await service.restore()
        XCTAssertEqual(snapshot.entitlement, .free)
    }

    func testRestoreUpgradesWhenFound() async {
        let client = MockPurchaseClient(restoreOutcome: .purchased(productID: PurchaseProduct.lifetime.rawValue))
        let service = EntitlementService(store: store, purchaseClient: client, clock: { self.clockDate })
        let snapshot = await service.restore()
        XCTAssertEqual(snapshot.entitlement, .premium)
        XCTAssertEqual(snapshot.source, .restore)
    }

    func testReconcileUpgradesWhenEntitlementFound() async {
        let client = MockPurchaseClient(currentOutcome: .purchased(productID: PurchaseProduct.annual.rawValue))
        let service = EntitlementService(store: store, purchaseClient: client, clock: { self.clockDate })
        let snapshot = await service.reconcile()
        XCTAssertEqual(snapshot.entitlement, .premium)
        XCTAssertEqual(snapshot.source, .reconcile)
    }

    func testReconcileDowngradesWhenExpired() async {
        let client = MockPurchaseClient(currentOutcome: .notFound)
        store.save(.premium)
        let service = EntitlementService(store: store, purchaseClient: client, clock: { self.clockDate })
        let snapshot = await service.reconcile()
        XCTAssertEqual(snapshot.entitlement, .free)
    }

    func testPurchaseCancelledKeepsStoredEntitlement() async {
        let client = MockPurchaseClient(purchaseOutcome: .userCancelled)
        let service = EntitlementService(store: store, purchaseClient: client, clock: { self.clockDate })
        let snapshot = await service.purchase(product: .annual)
        XCTAssertEqual(snapshot.entitlement, .free)
    }

    func testTrialEntitlementAppliesThroughTenthCompletionOnly() async {
        let client = MockPurchaseClient()
        let service = EntitlementService(store: store, purchaseClient: client, clock: { self.clockDate }, completedCount: { 10 })
        let snapshot = await service.current()
        XCTAssertEqual(snapshot.entitlement, .trial)
        XCTAssertEqual(snapshot.source, .trial)
    }

    func testTrialExpiresAfterTenthCompletion() async {
        let client = MockPurchaseClient(currentOutcome: .notFound)
        let service = EntitlementService(store: store, purchaseClient: client, clock: { self.clockDate }, completedCount: { 11 })
        let snapshot = await service.current()
        XCTAssertEqual(snapshot.entitlement, .free)
    }
}

struct MockPurchaseClient: PurchaseClient {
    var productsResult: [StoreProductInfo]
    var purchaseOutcome: PurchaseOutcome
    var restoreOutcome: PurchaseOutcome
    var currentOutcome: PurchaseOutcome

    init(productsResult: [StoreProductInfo] = [],
         purchaseOutcome: PurchaseOutcome = .notFound,
         restoreOutcome: PurchaseOutcome = .notFound,
         currentOutcome: PurchaseOutcome = .notFound) {
        self.productsResult = productsResult
        self.purchaseOutcome = purchaseOutcome
        self.restoreOutcome = restoreOutcome
        self.currentOutcome = currentOutcome
    }

    func products(ids: [String]) async throws -> [StoreProductInfo] { productsResult }
    func purchase(productID: String) async throws -> PurchaseOutcome { purchaseOutcome }
    func restoreEntitlements(productIDs: [String]) async throws -> PurchaseOutcome { restoreOutcome }
    func currentEntitlement(productIDs: [String]) async throws -> PurchaseOutcome { currentOutcome }
}
