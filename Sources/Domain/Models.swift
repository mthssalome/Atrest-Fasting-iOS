import Foundation
import SwiftUI

public enum Entitlement: Equatable {
    case free
    case premium
    case trial
}

public struct FastingSession: Equatable {
    public let id: UUID
    public let start: Date
    public let end: Date
    public let targetDurationHours: Double

    public init(id: UUID = UUID(), start: Date, end: Date, targetDurationHours: Double = 16.0) {
        self.id = id
        self.start = start
        self.end = end
        self.targetDurationHours = targetDurationHours
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

public struct CalendarEntry: Equatable, Identifiable {
    public var id: UUID { sessionID }
    public let sessionID: UUID
    public let date: Date
    public let isInspectable: Bool
    public let isIncomplete: Bool
    public let durationHours: Double

    public init(sessionID: UUID, date: Date, isInspectable: Bool, isIncomplete: Bool = false, durationHours: Double = 0) {
        self.sessionID = sessionID
        self.date = date
        self.isInspectable = isInspectable
        self.isIncomplete = isIncomplete
        self.durationHours = durationHours
    }
}

public enum FastingDefaults {
    @AppStorage("atrest.fasting.targetHours") public static var targetHours: Double = 16.0
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
