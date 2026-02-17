import XCTest
@testable import Domain

final class FastingSessionMachineTests: XCTestCase {
    func testStartTransitionsToActive() {
        var machine = FastingSessionMachine()
        let start = Date(timeIntervalSince1970: 100)
        let status = machine.start(at: start)

        XCTAssertEqual(status, .active(FastingPeriod(start: start, lastEvent: start)))
        XCTAssertEqual(machine.durationHours, 0)
    }

    func testUpdateAdvancesDuration() {
        var machine = FastingSessionMachine()
        let start = Date(timeIntervalSince1970: 0)
        machine.start(at: start)
        let later = Date(timeIntervalSince1970: 2 * 3600)
        _ = machine.update(now: later)

        XCTAssertEqual(machine.durationHours, 2, accuracy: 0.0001)
    }

    func testCompleteFromActiveProducesCompletedSession() {
        var machine = FastingSessionMachine()
        let start = Date(timeIntervalSince1970: 0)
        machine.start(at: start)
        let end = Date(timeIntervalSince1970: 5 * 3600)
        let status = machine.complete(at: end)

        if case let .completed(session) = status {
            XCTAssertEqual(session.start, start)
            XCTAssertEqual(session.end, end)
            XCTAssertEqual(session.durationHours, 5, accuracy: 0.0001)
        } else {
            XCTFail("Expected completed state")
        }
    }

    func testAbandonStopsAtLastEvent() {
        var machine = FastingSessionMachine()
        let start = Date(timeIntervalSince1970: 0)
        machine.start(at: start)
        let abandonTime = Date(timeIntervalSince1970: 3 * 3600)
        let status = machine.abandon(at: abandonTime)

        XCTAssertEqual(status, .abandoned(FastingPeriod(start: start, lastEvent: abandonTime)))
        XCTAssertEqual(machine.durationHours, 3, accuracy: 0.0001)
    }

    func testCompleteClampsEndBeforeStart() {
        var machine = FastingSessionMachine()
        let start = Date(timeIntervalSince1970: 10)
        machine.start(at: start)
        let earlier = Date(timeIntervalSince1970: 5)
        let status = machine.complete(at: earlier)

        if case let .completed(session) = status {
            XCTAssertEqual(session.durationHours, 0)
        } else {
            XCTFail("Expected completed state")
        }
    }

    func testRestartAfterCompletionBeginsNewSession() {
        var machine = FastingSessionMachine()
        let firstStart = Date(timeIntervalSince1970: 0)
        machine.start(at: firstStart)
        _ = machine.complete(at: Date(timeIntervalSince1970: 5 * 3600))

        let secondStart = Date(timeIntervalSince1970: 10 * 3600)
        let status = machine.start(at: secondStart)

        XCTAssertEqual(status, .active(FastingPeriod(start: secondStart, lastEvent: secondStart)))
        XCTAssertEqual(machine.durationHours, 0)
    }
}
