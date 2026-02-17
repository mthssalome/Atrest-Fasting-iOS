import SwiftUI
import Data
import Policy

public struct RootView: View {
    @StateObject private var timerViewModel: TimerViewModel
    @StateObject private var forestViewModel: ForestViewModel
    @StateObject private var calendarViewModel: CalendarViewModel
    @StateObject private var waterViewModel: WaterViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var paywallViewModel: PaywallViewModel
    private let sessionStore: SessionStore?
    private let entitlementService: EntitlementServicing
    @State private var trialNoticeShown = false
    @Environment(\.scenePhase) private var scenePhase

    public init(timerViewModel: TimerViewModel,
                forestViewModel: ForestViewModel,
                calendarViewModel: CalendarViewModel,
                waterViewModel: WaterViewModel,
                settingsViewModel: SettingsViewModel,
                paywallViewModel: PaywallViewModel,
                sessionStore: SessionStore? = nil,
                entitlementService: EntitlementServicing) {
        _timerViewModel = StateObject(wrappedValue: timerViewModel)
        _forestViewModel = StateObject(wrappedValue: forestViewModel)
        _calendarViewModel = StateObject(wrappedValue: calendarViewModel)
        _waterViewModel = StateObject(wrappedValue: waterViewModel)
        _settingsViewModel = StateObject(wrappedValue: settingsViewModel)
        _paywallViewModel = StateObject(wrappedValue: paywallViewModel)
        self.sessionStore = sessionStore
        self.entitlementService = entitlementService
    }

    public var body: some View {
        TabView {
            NavigationStack {
                TimerScreen(viewModel: timerViewModel)
            }
            .tabItem { Label(L10n.tabTimer, systemImage: "timer") }

            NavigationStack {
                ForestScreen(viewModel: forestViewModel)
            }
            .tabItem { Label(L10n.tabForest, systemImage: "leaf") }

            NavigationStack {
                CalendarScreen(viewModel: calendarViewModel)
            }
            .tabItem { Label(L10n.tabCalendar, systemImage: "calendar") }

            NavigationStack {
                WaterScreen(viewModel: waterViewModel)
            }
            .tabItem { Label(L10n.tabWater, systemImage: "drop") }

            NavigationStack {
                SettingsScreen(viewModel: settingsViewModel, paywallViewModel: paywallViewModel)
            }
            .tabItem { Label(L10n.tabSettings, systemImage: "gearshape") }
        }
        .task { await loadPersistedState() }
        .onAppear { reconcileEntitlements() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                reconcileEntitlements()
            }
        }
    }

    private func reconcileEntitlements() {
        Task {
            let snapshot = await entitlementService.reconcile()
            await MainActor.run {
                paywallViewModel.updateEntitlement(snapshot)
            }
            if let sessionStore {
                let state = await sessionStore.load()
                await MainActor.run {
                    updateDerivedData(from: state, entitlement: snapshot.entitlement)
                }
            }
        }
    }

    private func loadPersistedState() async {
        guard let sessionStore else { return }
        timerViewModel.onPersistedStateChange = { state in
            updateDerivedData(from: state)
        }
        settingsViewModel.onStoreUpdate = { state in
            updateDerivedData(from: state)
        }
        await timerViewModel.restorePersistedState()
        let state = await sessionStore.load()
        updateDerivedData(from: state)
    }

    private func updateDerivedData(from state: SessionStoreState, entitlement: Entitlement? = nil) {
        let effectiveEntitlement = entitlement ?? paywallViewModel.entitlement.entitlement
        let history = HistoryVisibilityPolicy.history(for: state.sessions, entitlement: effectiveEntitlement)
        forestViewModel.update(historyItems: history)
        let entries = CalendarPolicy.entries(for: state.sessions, entitlement: effectiveEntitlement)
        calendarViewModel.update(entries: entries)
        if TrialPolicy.isNoticeDue(completed: state.completedCount) && effectiveEntitlement != .premium && !trialNoticeShown {
            paywallViewModel.setStatusMessage(L10n.paywallTrialNotice)
            timerViewModel.trialNotice = L10n.paywallTrialNotice
            trialNoticeShown = true
        }
    }
}
