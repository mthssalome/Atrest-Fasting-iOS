import Foundation

public enum TreeState: Equatable {
    case established
    case incomplete
    case materializing(progress: Double)
}

public struct TreeMemory: Equatable {
    public let session: FastingSession
    public let state: TreeState

    public init(session: FastingSession, state: TreeState) {
        self.session = session
        self.state = state
    }
}

public enum TreeMapper {
    public static func trees(for sessions: [FastingSession]) -> [TreeMemory] {
        sessions.compactMap { session in
            guard session.durationHours >= 4.0 else { return nil }
            let target = session.targetDurationHours
            if session.durationHours >= target {
                return TreeMemory(session: session, state: .established)
            } else if session.durationHours >= target * 0.70 {
                return TreeMemory(session: session, state: .incomplete)
            } else {
                return nil
            }
        }
    }
}
