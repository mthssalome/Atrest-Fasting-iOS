import Foundation

public enum TreeState: Equatable {
    case established
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
        sessions
            .filter { $0.durationHours >= 4.0 }
            .map { TreeMemory(session: $0, state: .established) }
    }
}
