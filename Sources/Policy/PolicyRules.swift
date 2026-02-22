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
                CalendarEntry(sessionID: session.id, date: session.end, isInspectable: true, isIncomplete: Self.isIncomplete(session), durationHours: session.durationHours)
            }
        case .free:
            return persisted.prefix(10).map { session in
                CalendarEntry(sessionID: session.id, date: session.end, isInspectable: true, isIncomplete: Self.isIncomplete(session), durationHours: session.durationHours)
            }
        }
    }

    private static func isIncomplete(_ session: FastingSession) -> Bool {
        session.durationHours < session.targetDurationHours && session.durationHours >= session.targetDurationHours * 0.70
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
            return []
        }
    }
}

public enum TrialPolicy {
    /// First 10 completed fasts → trial entitlement.
    public static func entitlement(forCompleted count: Int) -> Entitlement? {
        count <= 10 ? .trial : nil
    }

    public static func shouldShowTransitionMoment(completedCount: Int) -> Bool {
        completedCount == 10 && !UserDefaults.standard.bool(forKey: "atrest.transition.dismissed")
    }

    public static func markTransitionDismissed() {
        UserDefaults.standard.set(true, forKey: "atrest.transition.dismissed")
    }
}
