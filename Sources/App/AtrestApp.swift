import SwiftUI
import UI
import Data
import Domain
import Policy
import DesignSystem

@main
struct AtrestApp: App {
    private let sessionStore = SessionStore()
    private let waterStore = WaterStore()
    private let entitlementService: EntitlementServicing
    private let purchaseClient: PurchaseClient

    @StateObject private var timerViewModel: TimerViewModel
    @StateObject private var forestViewModel: ForestViewModel
    @StateObject private var calendarViewModel: CalendarViewModel
    @StateObject private var waterViewModel: WaterViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var paywallViewModel: PaywallViewModel

    init() {
        self.purchaseClient = StoreKitPurchaseClient()
        self.entitlementService = EntitlementService(
            store: EntitlementStore(),
            purchaseClient: purchaseClient,
            completedCount: { [sessionStore] in
                let state = await sessionStore.load()
                return state.completedCount
            }
        )

        let timerVM = TimerViewModel(sessionStore: sessionStore)
        let waterStoreCopy = waterStore
        let sessionStoreCopy = sessionStore
        let entitlementServiceCopy = entitlementService
        let purchaseClientCopy = purchaseClient
        _timerViewModel = StateObject(wrappedValue: timerVM)
        _forestViewModel = StateObject(wrappedValue: ForestViewModel(historyItems: []))
        _calendarViewModel = StateObject(wrappedValue: CalendarViewModel(entries: []))
        _waterViewModel = StateObject(wrappedValue: WaterViewModel(store: waterStoreCopy))
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(sessionStore: sessionStoreCopy))
        _paywallViewModel = StateObject(wrappedValue: PaywallViewModel(entitlementService: entitlementServiceCopy, purchaseClient: purchaseClientCopy))
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                timerViewModel: timerViewModel,
                forestViewModel: forestViewModel,
                calendarViewModel: calendarViewModel,
                waterViewModel: waterViewModel,
                settingsViewModel: settingsViewModel,
                paywallViewModel: paywallViewModel,
                sessionStore: sessionStore,
                entitlementService: entitlementService
            )
        }
    }
}
