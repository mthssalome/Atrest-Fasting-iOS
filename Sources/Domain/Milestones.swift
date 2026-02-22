import Foundation

public enum FastingMilestone: Equatable {
    case digestionCompleting          // 0–4h
    case beginningToShift             // 4–8h
    case metabolicTransition          // 8–12h
    case deeperRhythm                 // 12–16h
    case extendedFast                 // 16–24h
    case prolongedFast                // 24h+

    public struct Window: Equatable {
        public let lowerBoundHours: Double
        public let upperBoundHours: Double?

        public init(lowerBoundHours: Double, upperBoundHours: Double?) {
            self.lowerBoundHours = lowerBoundHours
            self.upperBoundHours = upperBoundHours
        }

        public func contains(_ hours: Double) -> Bool {
            guard hours >= lowerBoundHours else { return false }
            if let upper = upperBoundHours {
                return hours < upper
            }
            return true
        }
    }

    public var window: Window {
        switch self {
        case .digestionCompleting:
            return Window(lowerBoundHours: 0, upperBoundHours: 4)
        case .beginningToShift:
            return Window(lowerBoundHours: 4, upperBoundHours: 8)
        case .metabolicTransition:
            return Window(lowerBoundHours: 8, upperBoundHours: 12)
        case .deeperRhythm:
            return Window(lowerBoundHours: 12, upperBoundHours: 16)
        case .extendedFast:
            return Window(lowerBoundHours: 16, upperBoundHours: 24)
        case .prolongedFast:
            return Window(lowerBoundHours: 24, upperBoundHours: nil)
        }
    }

    public static func milestone(forElapsedHours hours: Double) -> FastingMilestone? {
        guard hours >= 0 else { return nil }
        let milestones: [FastingMilestone] = [
            .digestionCompleting,
            .beginningToShift,
            .metabolicTransition,
            .deeperRhythm,
            .extendedFast,
            .prolongedFast
        ]
        return milestones.first { $0.window.contains(hours) }
    }
}
