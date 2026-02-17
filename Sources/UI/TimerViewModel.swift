import Foundation
import Data
import Domain
import Policy

@MainActor
public final class TimerViewModel: ObservableObject {
    @Published public private(set) var status: FastingStatus
    @Published public var trialNotice: String?

    private var machine: FastingSessionMachine
    private let clock: () -> Date
    private let sessionStore: SessionStore?
    private var isRestoring = false
    private var lastPersistedActiveUpdate: Date?
    private let activePersistInterval: TimeInterval = 60

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
            status = machine.start(at: clock())
            persistActiveIfNeeded()
        case .active:
            status = machine.complete(at: clock())
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

    public var milestone: FastingMilestone? {
        FastingMilestone.milestone(forElapsedHours: durationHours)
    }

    public var statusLabel: String {
        switch status {
        case .idle:
            return L10n.statusIdle
        case .active:
            return L10n.statusActive
        case .completed:
            return L10n.statusCompleted
        case .abandoned:
            return L10n.statusAbandoned
        }
    }

    public func restorePersistedState() async {
        guard !isRestoring, let sessionStore else { return }
        isRestoring = true
        let state = await sessionStore.load()
        if let active = state.active {
            machine = FastingSessionMachine(status: .active(active))
            status = machine.status
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
            return L10n.primaryStart
        case .active:
            return L10n.primaryStop
        }
    }

    private static func label(for milestone: FastingMilestone) -> String {
        switch milestone {
        case .digestiveCompletion:
            return L10n.milestoneDigestiveCompletion
        case .earlyMetabolicShift:
            return L10n.milestoneEarlyMetabolicShift
        case .increasingMetabolicFlexibility:
            return L10n.milestoneIncreasingMetabolicFlexibility
        case .deeperFastingState:
            return L10n.milestoneDeeperFastingState
        case .extendedFasting:
            return L10n.milestoneExtendedFasting
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
            if let state = try? await sessionStore.setActive(activePeriod) {
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
