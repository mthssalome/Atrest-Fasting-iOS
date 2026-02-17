import SnapshotTesting
import SwiftUI
import XCTest
@testable import Data
@testable import Domain
@testable import UI

@MainActor
final class UIScreenSnapshotTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 0)

    override func setUp() {
        super.setUp()
        isRecording = true // TODO: Set to false after baseline capture on Mac
    }

    override func tearDown() {
        super.tearDown()
    }

    func testTimerScreenHierarchy() {
        let period = FastingPeriod(start: referenceDate, lastEvent: referenceDate.addingTimeInterval(5 * 3600))
        let viewModel = TimerViewModel(status: .active(period), clock: { self.referenceDate.addingTimeInterval(5 * 3600) })
        let controller = UIHostingController(rootView: TimerScreen(viewModel: viewModel))
        assertSnapshot(matching: controller, as: .recursiveDescription)
    }

    func testForestScreenHierarchy() {
        let sessions = sampleSessions(count: 12, hours: 5)
        let items = sessions.prefix(10).map { HistoryItem(session: $0, isInspectable: true, isSilhouette: false) } +
            sessions.suffix(2).map { HistoryItem(session: $0, isInspectable: false, isSilhouette: true) }
        let viewModel = ForestViewModel(historyItems: items)
        let controller = UIHostingController(rootView: ForestScreen(viewModel: viewModel))
        assertSnapshot(matching: controller, as: .recursiveDescription)
    }

    func testCalendarScreenHierarchy() {
        let entries = [
            CalendarEntry(sessionID: UUID(), date: referenceDate, isInspectable: true),
            CalendarEntry(sessionID: UUID(), date: referenceDate.addingTimeInterval(24 * 3600), isInspectable: false)
        ]
        let viewModel = CalendarViewModel(entries: entries)
        let controller = UIHostingController(rootView: CalendarScreen(viewModel: viewModel))
        assertSnapshot(matching: controller, as: .recursiveDescription)
    }

    func testSettingsScreenHierarchy() {
        let viewModel = SettingsViewModel()
        let controller = UIHostingController(rootView: SettingsScreen(viewModel: viewModel))
        assertSnapshot(matching: controller, as: .recursiveDescription)
    }

    func testWaterScreenHierarchy() {
        let viewModel = WaterViewModel(store: WaterStore())
        let controller = UIHostingController(rootView: WaterScreen(viewModel: viewModel))
        assertSnapshot(matching: controller, as: .recursiveDescription)
    }

    func testPaywallScreenHierarchy() {
        let mockClient = SnapshotPurchaseClient()
        let service = StaticEntitlementService()
        let paywallVM = PaywallViewModel(entitlementService: service, purchaseClient: mockClient)
        paywallVM.setProductsForTesting(mockClient.sampleProducts)
        let controller = UIHostingController(rootView: PaywallScreen(viewModel: paywallVM))
        assertSnapshot(matching: controller, as: .recursiveDescription)
    }

    func testRootNavigationHierarchy() {
        let timerVM = TimerViewModel(status: .idle, clock: { self.referenceDate })
        let forestVM = ForestViewModel(historyItems: [])
        let calendarVM = CalendarViewModel(entries: [])
        let waterVM = WaterViewModel(store: WaterStore())
        let settingsVM = SettingsViewModel()
        let paywallVM = PaywallViewModel(entitlementService: StaticEntitlementService(), purchaseClient: SnapshotPurchaseClient())
        let controller = UIHostingController(
            rootView: RootView(
                timerViewModel: timerVM,
                forestViewModel: forestVM,
                calendarViewModel: calendarVM,
                waterViewModel: waterVM,
                settingsViewModel: settingsVM,
                paywallViewModel: paywallVM,
                entitlementService: StaticEntitlementService()
            )
        )
        assertSnapshot(matching: controller, as: .recursiveDescription)
    }

    // Helpers
    private func sampleSessions(count: Int, hours: Double) -> [FastingSession] {
        (0..<count).map { index in
            let end = referenceDate.addingTimeInterval(Double(index) * 3600)
            let start = end.addingTimeInterval(-hours * 3600)
            return FastingSession(start: start, end: end)
        }
    }
}

struct SnapshotPurchaseClient: PurchaseClient {
    let sampleProducts: [PurchaseProduct: StoreProductInfo] = [
        .annual: StoreProductInfo(id: PurchaseProduct.annual.rawValue, displayName: "Annual", displayPrice: "$29.99"),
        .lifetime: StoreProductInfo(id: PurchaseProduct.lifetime.rawValue, displayName: "Lifetime", displayPrice: "$69.99")
    ]

    func products(ids: [String]) async throws -> [StoreProductInfo] {
        ids.compactMap { id in
            guard let product = PurchaseProduct(rawValue: id) else { return nil }
            return sampleProducts[product]
        }
    }

    func purchase(productID: String) async throws -> PurchaseOutcome { .purchased(productID: productID) }
    func restoreEntitlements(productIDs: [String]) async throws -> PurchaseOutcome { .notFound }
    func currentEntitlement(productIDs: [String]) async throws -> PurchaseOutcome { .notFound }
}
