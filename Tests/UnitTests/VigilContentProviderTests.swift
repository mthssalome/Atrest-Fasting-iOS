import XCTest
@testable import UI
import Domain

final class VigilContentProviderTests: XCTestCase {

    // MARK: - Idle Fragment Rotation

    func testIdleFragmentReturnsSameFragmentForSameDay() {
        let date = Date()
        let a = VigilContentProvider.idleFragment(for: date)
        let b = VigilContentProvider.idleFragment(for: date)
        XCTAssertEqual(a.text, b.text)
        XCTAssertEqual(a.citation, b.citation)
    }

    func testIdleFragmentChangesNextDay() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let a = VigilContentProvider.idleFragment(for: today)
        let b = VigilContentProvider.idleFragment(for: tomorrow)
        XCTAssertNotEqual(a.text, b.text)
    }

    // MARK: - Milestone Content

    func testAllMilestonesHaveContent() {
        let milestones: [FastingMilestone] = [
            .digestionCompleting, .beginningToShift, .metabolicTransition,
            .deeperRhythm, .extendedFast, .prolongedFast
        ]
        for milestone in milestones {
            let content = VigilContentProvider.milestoneContent(for: milestone)
            XCTAssertFalse(content.companionAddition.isEmpty, "\(milestone) missing companion addition")
            XCTAssertFalse(content.scripture.text.isEmpty, "\(milestone) missing scripture text")
            XCTAssertFalse(content.scripture.citation.isEmpty, "\(milestone) missing citation")
        }
    }

    func testMilestoneCitationsAreBookChapterOnly() {
        let milestones: [FastingMilestone] = [
            .digestionCompleting, .beginningToShift, .metabolicTransition,
            .deeperRhythm, .extendedFast, .prolongedFast
        ]
        for milestone in milestones {
            let citation = VigilContentProvider.milestoneContent(for: milestone).scripture.citation
            XCTAssertFalse(citation.contains(":"), "Citation '\(citation)' should not have verse numbers")
        }
    }

    // MARK: - Arrival Rotation

    func testArrivalFragmentCycles() {
        let a = VigilContentProvider.arrivalFragment(fastIndex: 0)
        let b = VigilContentProvider.arrivalFragment(fastIndex: 5)
        XCTAssertEqual(a.text, b.text)
    }

    func testArrivalFragmentDiffersByIndex() {
        let a = VigilContentProvider.arrivalFragment(fastIndex: 0)
        let b = VigilContentProvider.arrivalFragment(fastIndex: 1)
        XCTAssertNotEqual(a.text, b.text)
    }

    // MARK: - Forest Inscription

    func testForestInscriptionIsNotEmpty() {
        XCTAssertFalse(VigilContentProvider.forestInscription.text.isEmpty)
        XCTAssertFalse(VigilContentProvider.forestInscription.citation.isEmpty)
    }
}
