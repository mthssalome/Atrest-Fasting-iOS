import XCTest
@testable import Domain

final class TreeMappingTests: XCTestCase {
    func testTreesCreatedForCompletedSessionsOnly() {
        let start = Date(timeIntervalSince1970: 0)
        let short = FastingSession(start: start, end: start.addingTimeInterval(3.5 * 3600))
        let long = FastingSession(start: start, end: start.addingTimeInterval(4.0 * 3600))
        let longer = FastingSession(start: start, end: start.addingTimeInterval(10.0 * 3600))

        let trees = TreeMapper.trees(for: [short, long, longer])
        XCTAssertEqual(trees.count, 2)
        XCTAssertEqual(trees.map { $0.session.id }.sorted(), [long.id, longer.id].sorted())
        XCTAssertTrue(trees.allSatisfy { $0.state == .established })
    }
}
