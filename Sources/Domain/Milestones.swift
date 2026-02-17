import Foundation

public enum FastingMilestone: Equatable {
    case digestiveCompletion
    case earlyMetabolicShift
    case increasingMetabolicFlexibility
    case deeperFastingState
    case extendedFasting

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
        case .digestiveCompletion:
            return Window(lowerBoundHours: 0, upperBoundHours: 4)
        case .earlyMetabolicShift:
            return Window(lowerBoundHours: 4, upperBoundHours: 8)
        case .increasingMetabolicFlexibility:
            return Window(lowerBoundHours: 8, upperBoundHours: 12)
        case .deeperFastingState:
            return Window(lowerBoundHours: 12, upperBoundHours: 16)
        case .extendedFasting:
            return Window(lowerBoundHours: 16, upperBoundHours: nil)
        }
    }

    public static func milestone(forElapsedHours hours: Double) -> FastingMilestone? {
        guard hours >= 0 else { return nil }
        let milestones: [FastingMilestone] = [
            .digestiveCompletion,
            .earlyMetabolicShift,
            .increasingMetabolicFlexibility,
            .deeperFastingState,
            .extendedFasting
        ]
        return milestones.first { $0.window.contains(hours) }
    }
}
