import Foundation
import Domain

public struct SessionStoreState: Equatable {
    public let sessions: [FastingSession]
    public let active: FastingPeriod?
    public let activeTargetHours: Double?
    public let completedCount: Int
}

public enum SessionMergeStrategy {
    case mergeDedup
    case replace
}

public actor SessionStore {
    private struct PersistedState: Codable, Equatable {
        var sessions: [FastingSessionDTO]
        var active: ActiveStateDTO?
        var completedCount: Int
    }

    private struct ActiveStateDTO: Codable, Equatable {
        var start: Date
        var lastEvent: Date
        var targetDurationHours: Double

        var period: FastingPeriod {
            FastingPeriod(start: start, lastEvent: lastEvent)
        }

        init(period: FastingPeriod, targetDurationHours: Double = 16.0) {
            self.start = period.start
            self.lastEvent = period.lastEvent
            self.targetDurationHours = targetDurationHours
        }
    }

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let stateURL: URL

    public init(fileManager: FileManager = .default, directory: URL? = nil) {
        self.fileManager = fileManager
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let baseDirectory: URL
        if let directory {
            baseDirectory = directory
        } else {
            let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            baseDirectory = support.appendingPathComponent("AtrestFasting", isDirectory: true)
        }

        self.stateURL = baseDirectory.appendingPathComponent("session-state.json", isDirectory: false)
    }

    public func load() async -> SessionStoreState {
        do {
            let data = try Data(contentsOf: stateURL)
            let persisted = try decoder.decode(PersistedState.self, from: data)
            return SessionStoreState(
                sessions: persisted.sessions.map { $0.domainModel() },
                active: persisted.active?.period,
                activeTargetHours: persisted.active?.targetDurationHours,
                completedCount: persisted.completedCount
            )
        } catch {
            return SessionStoreState(sessions: [], active: nil, activeTargetHours: nil, completedCount: 0)
        }
    }

    public func setActive(_ period: FastingPeriod?, targetDurationHours: Double? = nil) async throws -> SessionStoreState {
        var state = await load()
        state = SessionStoreState(sessions: state.sessions, active: period, activeTargetHours: targetDurationHours, completedCount: state.completedCount)
        try persist(state)
        return state
    }

    public func saveSessions(_ sessions: [FastingSession], active: FastingPeriod?, activeTargetHours: Double?, completedCount: Int) async throws -> SessionStoreState {
        let sanitized = Self.sortedDedup(sessions)
        let state = SessionStoreState(sessions: sanitized, active: active, activeTargetHours: activeTargetHours, completedCount: completedCount)
        try persist(state)
        return state
    }

    public func append(_ session: FastingSession, incrementCompleted: Bool = true) async throws -> SessionStoreState {
        var state = await load()
        var map = Dictionary(uniqueKeysWithValues: state.sessions.map { ($0.id, $0) })
        let isNew = map[session.id] == nil
        map[session.id] = session
        let merged = map.values.sorted { $0.end > $1.end }
        let updatedCount = incrementCompleted && isNew ? state.completedCount + 1 : state.completedCount
        let newState = SessionStoreState(sessions: merged, active: nil, activeTargetHours: nil, completedCount: updatedCount)
        try persist(newState)
        return newState
    }

    public func merge(imported: [FastingSession], strategy: SessionMergeStrategy) async throws -> SessionStoreState {
        let current = await load()
        let mergedSessions: [FastingSession]
        let completedCount: Int

        switch strategy {
        case .replace:
            mergedSessions = Self.sortedDedup(imported)
            completedCount = max(current.completedCount, mergedSessions.count)
        case .mergeDedup:
            var map = Dictionary(uniqueKeysWithValues: current.sessions.map { ($0.id, $0) })
            for session in imported {
                if let existing = map[session.id] {
                    map[session.id] = Self.preferMoreRecent(existing: existing, incoming: session)
                } else {
                    map[session.id] = session
                }
            }
            mergedSessions = map.values.sorted { $0.end > $1.end }
            let existingIDs = Set(current.sessions.map { $0.id })
            let added = mergedSessions.filter { !existingIDs.contains($0.id) }.count
            completedCount = current.completedCount + added
        }

        let state = SessionStoreState(sessions: mergedSessions, active: current.active, activeTargetHours: current.activeTargetHours, completedCount: completedCount)
        try persist(state)
        return state
    }

    // MARK: - Helpers

    private func persist(_ state: SessionStoreState) throws {
        let dto = PersistedState(
            sessions: state.sessions.map(FastingSessionDTO.init),
            active: state.active.map { ActiveStateDTO(period: $0, targetDurationHours: state.activeTargetHours ?? 16.0) },
            completedCount: state.completedCount
        )
        let data = try encoder.encode(dto)
        try ensureDirectoryExists()
        try data.write(to: stateURL, options: [.atomic])
    }

    private func ensureDirectoryExists() throws {
        let directory = stateURL.deletingLastPathComponent()
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: directory.path, isDirectory: &isDir) {
            if isDir.boolValue { return }
        }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private static func sortedDedup(_ sessions: [FastingSession]) -> [FastingSession] {
        var map: [UUID: FastingSession] = [:]
        for session in sessions {
            if let existing = map[session.id] {
                map[session.id] = preferMoreRecent(existing: existing, incoming: session)
            } else {
                map[session.id] = session
            }
        }
        return map.values.sorted { $0.end > $1.end }
    }

    private static func preferMoreRecent(existing: FastingSession, incoming: FastingSession) -> FastingSession {
        if incoming.end >= existing.end { return incoming }
        return existing
    }
}
