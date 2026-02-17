import Foundation

public enum Entitlement: Equatable {
    case free
    case premium
    case trial
}

public struct FastingSession: Equatable {
    public let id: UUID
    public let start: Date
    public let end: Date

    public init(id: UUID = UUID(), start: Date, end: Date) {
        self.id = id
        self.start = start
        self.end = end
    }

    public var durationHours: Double {
        let interval = end.timeIntervalSince(start)
        return interval / 3600.0
    }
}

public struct HistoryItem: Equatable {
    public let session: FastingSession
    public let isInspectable: Bool
    public let isSilhouette: Bool

    public init(session: FastingSession, isInspectable: Bool, isSilhouette: Bool) {
        self.session = session
        self.isInspectable = isInspectable
        self.isSilhouette = isSilhouette
    }
}

public struct CalendarEntry: Equatable {
    public let sessionID: UUID
    public let date: Date
    public let isInspectable: Bool

    public init(sessionID: UUID, date: Date, isInspectable: Bool) {
        self.sessionID = sessionID
        self.date = date
        self.isInspectable = isInspectable
    }
}

public enum CoreUtility: CaseIterable, Equatable {
    case timer
    case phases
    case waterTracking
}

public struct WaterIntakeEntry: Equatable, Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let amountMilliliters: Int

    public init(id: UUID = UUID(), date: Date, amountMilliliters: Int) {
        self.id = id
        self.date = date
        self.amountMilliliters = amountMilliliters
    }
}
