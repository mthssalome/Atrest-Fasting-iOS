import Foundation

public enum FastingStatus: Equatable {
    case idle
    case active(FastingPeriod)
    case completed(FastingSession)
    case abandoned(FastingPeriod)
}

public struct FastingPeriod: Equatable {
    public let start: Date
    public let lastEvent: Date

    public init(start: Date, lastEvent: Date) {
        self.start = start
        self.lastEvent = max(lastEvent, start)
    }

    public func durationHours(reference: Date? = nil) -> Double {
        let end = reference ?? lastEvent
        let interval = max(end.timeIntervalSince(start), 0)
        return interval / 3600.0
    }
}

public struct FastingSessionMachine: Equatable {
    public private(set) var status: FastingStatus

    public init(status: FastingStatus = .idle) {
        self.status = status
    }

    @discardableResult
    public mutating func start(at start: Date) -> FastingStatus {
        status = .active(FastingPeriod(start: start, lastEvent: start))
        return status
    }

    @discardableResult
    public mutating func update(now: Date) -> FastingStatus {
        guard case let .active(period) = status else { return status }
        status = .active(FastingPeriod(start: period.start, lastEvent: now))
        return status
    }

    @discardableResult
    public mutating func complete(at end: Date, targetDurationHours: Double = 16.0) -> FastingStatus {
        guard case let .active(period) = status else { return status }
        let endTime = max(end, period.start)
        let session = FastingSession(start: period.start, end: endTime, targetDurationHours: targetDurationHours)
        status = .completed(session)
        return status
    }

    @discardableResult
    public mutating func abandon(at time: Date) -> FastingStatus {
        guard case let .active(period) = status else { return status }
        let endTime = max(time, period.start)
        status = .abandoned(FastingPeriod(start: period.start, lastEvent: endTime))
        return status
    }

    public var durationHours: Double {
        switch status {
        case .idle:
            return 0
        case let .active(period):
            return period.durationHours()
        case let .completed(session):
            return session.durationHours
        case let .abandoned(period):
            return period.durationHours()
        }
    }
}
