import XCTest
@testable import Data
@testable import Domain

final class SessionStoreTests: XCTestCase {
    private var directory: URL!
    private var store: SessionStore!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        store = SessionStore(fileManager: .default, directory: directory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        super.tearDown()
    }

    func testDefaultLoadIsEmpty() async {
        let state = await store.load()
        XCTAssertTrue(state.sessions.isEmpty)
        XCTAssertNil(state.active)
        XCTAssertEqual(state.completedCount, 0)
    }

    func testAppendPersistsSessionAndClearsActive() async throws {
        let session = FastingSession(start: Date(timeIntervalSince1970: 0), end: Date(timeIntervalSince1970: 5 * 3600))
        let state = try await store.append(session)

        XCTAssertEqual(state.sessions.count, 1)
        XCTAssertNil(state.active)
        XCTAssertEqual(state.completedCount, 1)

        let reloaded = await store.load()
        XCTAssertEqual(reloaded.sessions, [session])
        XCTAssertNil(reloaded.active)
        XCTAssertEqual(reloaded.completedCount, 1)
    }

    func testActivePersistsAndRestores() async throws {
        let period = FastingPeriod(start: Date(timeIntervalSince1970: 10), lastEvent: Date(timeIntervalSince1970: 20))
        _ = try await store.setActive(period)

        let reloaded = await store.load()
        XCTAssertEqual(reloaded.active, period)
    }

    func testMergeDedupAddsNewSessionsOnly() async throws {
        let existing = FastingSession(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, start: Date(), end: Date())
        _ = try await store.append(existing)

        let duplicate = FastingSession(id: existing.id, start: existing.start, end: existing.end.addingTimeInterval(3600))
        let newSession = FastingSession(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, start: Date(), end: Date())

        let merged = try await store.merge(imported: [duplicate, newSession], strategy: .mergeDedup)

        XCTAssertEqual(merged.sessions.count, 2)
        XCTAssertEqual(merged.completedCount, 2)
        XCTAssertEqual(merged.sessions.first?.id, duplicate.id)
    }
}
