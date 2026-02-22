import XCTest
@testable import Domain
@testable import Policy

final class PolicyRulesTests: XCTestCase {
    private let scanner = PolicyStringScanner()

    private func projectRoot(file: StaticString = #filePath) -> URL {
        var url = URL(fileURLWithPath: String(describing: file))
        for _ in 0..<3 {
            url.deleteLastPathComponent()
        }
        return url
    }

    func testBannedPhrasesAbsentFromSources() {
        let banned = [
            "autophagy maximized",
            "fat-burning zone",
            "peak fasting",
            "optimal window",
            "maximum benefits",
            "best results occur here",
            "don't break now",
            "this is where the magic happens",
            "you're doing great"
        ]
        let sources = projectRoot().appendingPathComponent("Sources")
        let hits = scanner.scan(for: banned, in: sources, allowedExtensions: ["swift", "strings"])
        XCTAssertTrue(hits.isEmpty, "Banned phrases present in sources: \(hits)")
    }

    func testNoStreakReferencesInSources() {
        let sources = projectRoot().appendingPathComponent("Sources")
        let hits = scanner.scanSubstring("streak", in: sources, allowedExtensions: ["swift", "strings"])
        XCTAssertTrue(hits.isEmpty, "Streak-like references found: \(hits)")
    }

    func testPersistenceThresholdEnforced() {
        let now = Date()
        let short = FastingSession(start: now, end: now.addingTimeInterval(3.9 * 3600))
        let long = FastingSession(start: now, end: now.addingTimeInterval(4.0 * 3600))

        XCTAssertFalse(SessionPersistencePolicy.shouldPersist(short))
        XCTAssertTrue(SessionPersistencePolicy.shouldPersist(long))

        let history = HistoryVisibilityPolicy.history(for: [short, long], entitlement: .premium)
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.session.id, long.id)
    }

    func testCalendarMirrorsPersistence() {
        let now = Date()
        let short = FastingSession(start: now, end: now.addingTimeInterval(3.5 * 3600))
        let long = FastingSession(start: now, end: now.addingTimeInterval(6.0 * 3600))

        let entries = CalendarPolicy.entries(for: [short, long], entitlement: .premium)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.sessionID, long.id)
    }

    func testHistoryVisibilityLimitFreeTier() {
        let sessions = makeSequentialSessions(count: 12, hours: 5.0)
        let freeHistory = HistoryVisibilityPolicy.history(for: sessions, entitlement: .free)

        XCTAssertTrue(freeHistory.isEmpty)
    }

    func testSilhouettesRedactMetadata() {
        let sessions = makeSequentialSessions(count: 12, hours: 5.0)
        let freeHistory = HistoryVisibilityPolicy.history(for: sessions, entitlement: .free)
        XCTAssertTrue(freeHistory.isEmpty)
    }

    func testNoDataDeletionOnDowngrade() {
        let sessions = makeSequentialSessions(count: 8, hours: 5.0)
        let premiumHistory = HistoryVisibilityPolicy.history(for: sessions, entitlement: .premium)
        let freeHistory = HistoryVisibilityPolicy.history(for: sessions, entitlement: .free)

        XCTAssertEqual(premiumHistory.count, sessions.count)
        XCTAssertTrue(freeHistory.isEmpty)
    }

    func testCalendarFreeTierLimitedToTen() {
        let sessions = makeSequentialSessions(count: 15, hours: 5.0)
        let freeEntries = CalendarPolicy.entries(for: sessions, entitlement: .free)
        XCTAssertEqual(freeEntries.count, 10)
        XCTAssertTrue(freeEntries.allSatisfy { $0.isInspectable })
    }

    func testNoUrgencyMonetizationLanguage() {
        let urgencyPhrases = [
            "limited time",
            "last chance",
            "act now",
            "only today",
            "ending soon",
            "don't miss",
            "while supplies last",
            "fear of missing out",
            "fomo",
            "hurry"
        ]
        let sources = projectRoot().appendingPathComponent("Sources")
        let hits = scanner.scan(for: urgencyPhrases, in: sources, allowedExtensions: ["swift", "strings"])
        XCTAssertTrue(hits.isEmpty, "Urgency monetization language present: \(hits)")
    }

    func testTrialPolicyWindow() {
        XCTAssertEqual(TrialPolicy.entitlement(forCompleted: 0), .trial)
        XCTAssertEqual(TrialPolicy.entitlement(forCompleted: 10), .trial)
        XCTAssertNil(TrialPolicy.entitlement(forCompleted: 11))
        XCTAssertNil(TrialPolicy.entitlement(forCompleted: 12))
    }

    // Helpers
    private func makeSequentialSessions(count: Int, hours: Double) -> [FastingSession] {
        let now = Date()
        return (0..<count).map { index in
            let end = now.addingTimeInterval(TimeInterval(index) * 3600)
            let start = end.addingTimeInterval(-hours * 3600)
            return FastingSession(start: start, end: end)
        }
    }
}
