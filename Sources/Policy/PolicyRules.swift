import Foundation
import Domain

public struct PolicyStringScanner {
    public init() {}

    public func scan(for phrases: [String], in directory: URL, allowedExtensions: Set<String>) -> [String] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey]
        ) else { return [] }

        var hits: Set<String> = []
        for case let fileURL as URL in enumerator {
            guard allowedExtensions.contains(fileURL.pathExtension.lowercased()) else { continue }
            guard let contents = try? String(contentsOf: fileURL) else { continue }
            let normalizedContent = normalize(contents)
            for phrase in phrases {
                if normalizedContent.contains(normalize(phrase)) {
                    hits.insert(fileURL.path)
                    break
                }
            }
        }
        return hits.sorted()
    }

    public func scanSubstring(_ substring: String, in directory: URL, allowedExtensions: Set<String>) -> [String] {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey]
        ) else { return [] }

        var hits: Set<String> = []
        let needle = normalize(substring)
        for case let fileURL as URL in enumerator {
            guard allowedExtensions.contains(fileURL.pathExtension.lowercased()) else { continue }
            guard let contents = try? String(contentsOf: fileURL) else { continue }
            let normalizedContent = normalize(contents)
            if normalizedContent.contains(needle) {
                hits.insert(fileURL.path)
            }
        }
        return hits.sorted()
    }

    private func normalize(_ text: String) -> String {
        let lowered = text.lowercased()
        let components = lowered.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        let collapsedWhitespace = components.filter { !$0.isEmpty }
        return collapsedWhitespace.joined(separator: " ")
    }
}

public enum SessionPersistencePolicy {
    public static func shouldPersist(_ session: FastingSession) -> Bool {
        session.durationHours >= 4.0
    }
}

public enum CalendarPolicy {
    public static func entries(for sessions: [FastingSession], entitlement: Entitlement) -> [CalendarEntry] {
        let persisted = sessions
            .filter { SessionPersistencePolicy.shouldPersist($0) }
            .sorted { $0.end > $1.end }

        switch entitlement {
        case .premium, .trial:
            return persisted.map { session in
                CalendarEntry(sessionID: session.id, date: session.end, isInspectable: true)
            }
        case .free:
            let visible = persisted.prefix(10).map { session in
                CalendarEntry(sessionID: session.id, date: session.end, isInspectable: true)
            }
            let locked = persisted.dropFirst(10).map { session in
                CalendarEntry(sessionID: session.id, date: session.end, isInspectable: false)
            }
            return visible + locked
        }
    }
}

public enum HistoryVisibilityPolicy {
    public static func history(for sessions: [FastingSession], entitlement: Entitlement) -> [HistoryItem] {
        let persisted = sessions.filter { SessionPersistencePolicy.shouldPersist($0) }
        let sorted = persisted.sorted { $0.end > $1.end }
        switch entitlement {
        case .premium, .trial:
            return sorted.map { session in
                HistoryItem(session: session, isInspectable: true, isSilhouette: false)
            }
        case .free:
            let inspectable = sorted.prefix(10)
            let locked = sorted.dropFirst(10)
            let visibleInspectable = inspectable.map { session in
                HistoryItem(session: session, isInspectable: true, isSilhouette: false)
            }
            let silhouettes = locked.map { session in
                HistoryItem(session: sanitize(session), isInspectable: false, isSilhouette: true)
            }
            return visibleInspectable + silhouettes
        }
    }

    private static func sanitize(_ session: FastingSession) -> FastingSession {
        FastingSession(id: session.id, start: Date(timeIntervalSince1970: 0), end: Date(timeIntervalSince1970: 0))
    }
}

public enum CoreUtilityPolicy {
    public static func availableUtilities(for entitlement: Entitlement) -> [CoreUtility] {
        CoreUtility.allCases
    }
}

public enum TrialPolicy {
    /// Returns the entitlement granted by the completed-fast trial window.
    /// - Contract: first 10 completions are premium, 11th shows notice, 12th reverts to free.
    public static func entitlement(forCompleted count: Int) -> Entitlement? {
        switch count {
        case ...10:
            return .trial
        case 11:
            return .trial
        default:
            return nil
        }
    }

    public static func isNoticeDue(completed count: Int) -> Bool {
        count == 11
    }
}
