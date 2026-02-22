import SwiftUI
import Data
import Policy
import Domain
import DesignSystem

public struct RootView: View {
    @StateObject private var timerViewModel: TimerViewModel
    @StateObject private var forestViewModel: ForestViewModel
    @StateObject private var calendarViewModel: CalendarViewModel
    @StateObject private var waterViewModel: WaterViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var paywallViewModel: PaywallViewModel
    private let sessionStore: SessionStore?
    private let entitlementService: EntitlementServicing

    @State private var destination: AppDestination = .timer
    @State private var currentEntitlement: Entitlement = .free
    @State private var showCalendarSheet = false
    @State private var showSettingsSheet = false
    @State private var showPaywallSheet = false
    @State private var showTransitionMoment = false
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
        ZStack {
            switch destination {
            case .timer:
                timerContent
                    .transition(.opacity)
            case .forest:
                ForestScreen(viewModel: forestViewModel) {
                    destination = .timer
                }
                .transition(.opacity)
            }

            if showTransitionMoment {
                TransitionMomentView(
                    onContinue: {
                        showTransitionMoment = false
                        showPaywallSheet = true
                    },
                    onDismiss: {
                        TrialPolicy.markTransitionDismissed()
                        showTransitionMoment = false
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(Motion.slow, value: destination)
        .sheet(isPresented: $showCalendarSheet) {
            CalendarScreen(viewModel: calendarViewModel)
                .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showSettingsSheet) {
            SettingsScreen(
                viewModel: settingsViewModel,
                entitlement: currentEntitlement,
                onShowPaywall: {
                    showSettingsSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showPaywallSheet = true
                    }
                }
            )
            .presentationBackground(.ultraThinMaterial)
        }
        .sheet(isPresented: $showPaywallSheet) {
            PaywallScreen(viewModel: paywallViewModel)
                .presentationBackground(.ultraThinMaterial)
        }
        .task { await loadPersistedState() }
        .onAppear { reconcileEntitlements() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                reconcileEntitlements()
            }
        }
        .onChange(of: paywallViewModel.entitlement) { _, snapshot in
            Task {
                if let sessionStore {
                    let state = await sessionStore.load()
                    await MainActor.run {
                        updateDerivedData(from: state, entitlement: snapshot.entitlement)
                    }
                } else {
                    await MainActor.run {
                        currentEntitlement = snapshot.entitlement
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var timerContent: some View {
        ZStack {
            TimerScreen(
                viewModel: timerViewModel,
                waterViewModel: waterViewModel,
                entitlement: currentEntitlement
            )

            if case .active = timerViewModel.status {
                EscapeHatchOverlay(
                    entitlement: currentEntitlement,
                    onForest: { destination = .forest },
                    onCalendar: { showCalendarSheet = true },
                    onSettings: { showSettingsSheet = true }
                )
            }

            if case .idle = timerViewModel.status {
                FloatingNavIcons(
                    entitlement: currentEntitlement,
                    onForest: { destination = .forest },
                    onCalendar: { showCalendarSheet = true },
                    onSettings: { showSettingsSheet = true }
                )
            }
            if case .completed = timerViewModel.status {
                FloatingNavIcons(
                    entitlement: currentEntitlement,
                    onForest: { destination = .forest },
                    onCalendar: { showCalendarSheet = true },
                    onSettings: { showSettingsSheet = true }
                )
            }
            if case .abandoned = timerViewModel.status {
                FloatingNavIcons(
                    entitlement: currentEntitlement,
                    onForest: { destination = .forest },
                    onCalendar: { showCalendarSheet = true },
                    onSettings: { showSettingsSheet = true }
                )
            }
        }
    }

    private func reconcileEntitlements() {
        Task {
            let snapshot = await entitlementService.reconcile()
            await MainActor.run {
                paywallViewModel.updateEntitlement(snapshot)
                currentEntitlement = snapshot.entitlement
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

        if TrialPolicy.shouldShowTransitionMoment(completedCount: state.completedCount) && effectiveEntitlement != .premium {
            showTransitionMoment = true
        }
        currentEntitlement = effectiveEntitlement
    }
}

public enum AppDestination: Equatable {
    case timer
    case forest
}
