import XCTest
@testable import Domain

final class MilestoneMappingTests: XCTestCase {
    func testMilestoneWindowsMapCorrectly() {
        XCTAssertEqual(FastingMilestone.milestone(forElapsedHours: 0), .digestiveCompletion)
        XCTAssertEqual(FastingMilestone.milestone(forElapsedHours: 3.99), .digestiveCompletion)
        XCTAssertEqual(FastingMilestone.milestone(forElapsedHours: 4.0), .earlyMetabolicShift)
        XCTAssertEqual(FastingMilestone.milestone(forElapsedHours: 7.99), .earlyMetabolicShift)
        XCTAssertEqual(FastingMilestone.milestone(forElapsedHours: 8.0), .increasingMetabolicFlexibility)
        XCTAssertEqual(FastingMilestone.milestone(forElapsedHours: 12.0), .deeperFastingState)
        XCTAssertEqual(FastingMilestone.milestone(forElapsedHours: 15.99), .deeperFastingState)
        XCTAssertEqual(FastingMilestone.milestone(forElapsedHours: 16.0), .extendedFasting)
        XCTAssertEqual(FastingMilestone.milestone(forElapsedHours: 48.0), .extendedFasting)
    }

    func testNegativeElapsedHasNoMilestone() {
        XCTAssertNil(FastingMilestone.milestone(forElapsedHours: -0.1))
    }
}
