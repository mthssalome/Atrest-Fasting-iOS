import Foundation
import Data
import Domain
import Policy

@MainActor
public final class TimerViewModel: ObservableObject {
    @Published public private(set) var status: FastingStatus
    @Published public var isJustCompleted: Bool = false
    @Published public var trialNotice: String?

    public var completedFastCount: Int?

    private var machine: FastingSessionMachine
    private let clock: () -> Date
    private let sessionStore: SessionStore?
    private var isRestoring = false
    private var lastPersistedActiveUpdate: Date?
    private let activePersistInterval: TimeInterval = 60
    private var activeTargetHours: Double = 16.0

    /// Notifies listeners when persisted state changes (sessions or active period).
    public var onPersistedStateChange: ((SessionStoreState) -> Void)?

    public init(status: FastingStatus = .idle,
                sessionStore: SessionStore? = nil,
                clock: @escaping () -> Date = Date.init) {
        self.machine = FastingSessionMachine(status: status)
        self.status = status
        self.clock = clock
        self.sessionStore = sessionStore
    }

    @discardableResult
    public func primaryAction() -> FastingStatus {
        switch status {
        case .idle, .completed, .abandoned:
            isJustCompleted = false
            activeTargetHours = FastingDefaults.targetHours
            if activeTargetHours == 0 { activeTargetHours = 16.0 }
            status = machine.start(at: clock())
            persistActiveIfNeeded()
        case .active:
            status = machine.complete(at: clock(), targetDurationHours: activeTargetHours)
            isJustCompleted = true
            persistCompletionIfNeeded()
        }
        return status
    }

    @discardableResult
    public func abandon() -> FastingStatus {
        status = machine.abandon(at: clock())
        persistActiveIfNeeded()
        return status
    }

    @discardableResult
    public func refresh() -> FastingStatus {
        let now = clock()
        status = machine.update(now: now)
        if shouldPersistActiveSnapshot(now: now) {
            persistActiveIfNeeded()
        }
        return status
    }

    public var durationHours: Double {
        machine.durationHours
    }

    public var formattedElapsed: String {
        let totalSeconds = Int(durationHours * 3600)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    public var materializationProgress: Double {
        switch status {
        case .active:
            let targetSeconds = activeTargetHours * 3600
            guard targetSeconds > 0 else { return 0.05 }
            let elapsed = durationHours * 3600
            return max(0.05, min(1.0, elapsed / targetSeconds))
        case .completed:
            return 1.0
        default:
            return 0.0
        }
    }

    public var activeTreeVariantIndex: Int {
        guard case let .active(period) = status else { return 0 }
        return abs(period.start.hashValue) % 8
    }

    public var activeTreeToneIndex: Int {
        guard case let .active(period) = status else { return 0 }
        return abs(period.start.hashValue / 8) % 5
    }

    public var milestone: FastingMilestone? {
        FastingMilestone.milestone(forElapsedHours: durationHours)
    }

    public var statusLabel: String {
        switch status {
        case .idle:
            return L10n.timerIdlePrompt
        case .active:
            return L10n.timerActiveLabel
        case .completed:
            return L10n.timerCompletedLabel
        case .abandoned:
            return L10n.timerAbandonedLabel
        }
    }

    public func restorePersistedState() async {
        guard !isRestoring, let sessionStore else { return }
        isRestoring = true
        let state = await sessionStore.load()
        if let active = state.active {
            machine = FastingSessionMachine(status: .active(active))
            status = machine.status
            activeTargetHours = state.activeTargetHours ?? 16.0
        }
        onPersistedStateChange?(state)
        isRestoring = false
    }

    public var milestoneLabel: String {
        guard let milestone else { return L10n.milestoneNone }
        return TimerViewModel.label(for: milestone)
    }

    public var primaryActionLabel: String {
        switch status {
        case .idle, .completed, .abandoned:
            return L10n.timerActionBegin
        case .active:
            return L10n.timerActionEnd
        }
    }

    private static func label(for milestone: FastingMilestone) -> String {
        switch milestone {
        case .digestionCompleting:
            return L10n.milestoneDigestionCompleting
        case .beginningToShift:
            return L10n.milestoneBeginningToShift
        case .metabolicTransition:
            return L10n.milestoneMetabolicTransition
        case .deeperRhythm:
            return L10n.milestoneDeeperRhythm
        case .extendedFast:
            return L10n.milestoneExtendedFast
        case .prolongedFast:
            return L10n.milestoneProlongedFast
        }
    }

    private func persistActiveIfNeeded() {
        guard let sessionStore else { return }
        Task { @MainActor in
            let activePeriod: FastingPeriod?
            if case let .active(period) = status {
                activePeriod = period
                lastPersistedActiveUpdate = clock()
            } else {
                activePeriod = nil
                lastPersistedActiveUpdate = nil
            }
            if let state = try? await sessionStore.setActive(activePeriod, targetDurationHours: activeTargetHours) {
                onPersistedStateChange?(state)
            }
        }
    }

    private func persistCompletionIfNeeded() {
        guard let sessionStore else { return }
        Task { @MainActor in
            if case let .completed(session) = status {
                lastPersistedActiveUpdate = nil
                if SessionPersistencePolicy.shouldPersist(session) {
                    if let state = try? await sessionStore.append(session) {
                        onPersistedStateChange?(state)
                    }
                } else if let state = try? await sessionStore.setActive(nil) {
                    onPersistedStateChange?(state)
                }
            }
        }
    }

    private func shouldPersistActiveSnapshot(now: Date) -> Bool {
        guard case .active = status else { return false }
        guard let last = lastPersistedActiveUpdate else {
            lastPersistedActiveUpdate = now
            return true
        }
        if now.timeIntervalSince(last) >= activePersistInterval {
            lastPersistedActiveUpdate = now
            return true
        }
        return false
    }
}
