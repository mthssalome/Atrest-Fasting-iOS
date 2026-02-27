import XCTest
@testable import Policy

final class VigilDoctrineTests: XCTestCase {
    private let scanner = PolicyStringScanner()

    private func projectRoot(file: StaticString = #filePath) -> URL {
        var url = URL(fileURLWithPath: String(describing: file))
        for _ in 0..<3 {
            url.deleteLastPathComponent()
        }
        return url
    }

    private func sourcesDirectory(_ relativePath: String) -> URL {
        projectRoot().appendingPathComponent(relativePath)
    }

    private func localizableLines() -> [String] {
        let path = sourcesDirectory("Sources/UI/Resources/Localizable.strings")
        guard let contents = try? String(contentsOf: path) else { return [] }
        return contents.components(separatedBy: .newlines)
    }

    private func vigilStringLines() -> [String] {
        localizableLines().filter { $0.lowercased().contains("vigil.") }
    }

    private func vigilCitationLines() -> [String] {
        vigilStringLines().filter { $0.contains("citation") }
    }

    func testRule1_vigilToggleOptInExists() {
        let sources = sourcesDirectory("Sources")
        let hits = scanner.scanSubstring("atrest.vigil.enabled", in: sources, allowedExtensions: ["swift"])
        XCTAssertFalse(hits.isEmpty, "Rule 1: add opt-in Vigil toggle backed by atrest.vigil.enabled")
    }

    func testRule1_vigilToggleDiscoverableInSettingsStrings() {
        let vigilKeys = vigilStringLines().filter { $0.contains("vigil.section.") }
        XCTAssertFalse(vigilKeys.isEmpty, "Rule 1: add Vigil settings strings and discovery copy")
    }

    func testRule2_vigilOnlyAddsContentNotMechanics() {
        let uiHits = scanner.scanSubstring("vigil", in: sourcesDirectory("Sources/UI"), allowedExtensions: ["swift"])
        let domainHits = scanner.scanSubstring("vigil", in: sourcesDirectory("Sources/Domain"), allowedExtensions: ["swift"])
        let dataHits = scanner.scanSubstring("vigil", in: sourcesDirectory("Sources/Data"), allowedExtensions: ["swift"])
        let policyHits = scanner.scanSubstring("vigil", in: sourcesDirectory("Sources/Policy"), allowedExtensions: ["swift"])

        XCTAssertFalse(uiHits.isEmpty, "Rule 2: Vigil content must be wired into UI layer")
        XCTAssertTrue(domainHits.isEmpty, "Rule 2: Vigil must not alter Domain mechanics")
        XCTAssertTrue(dataHits.isEmpty, "Rule 2: Vigil must not alter Data layer")
        XCTAssertTrue(policyHits.isEmpty, "Rule 2: Vigil must not alter Policy layer")
    }

    func testRule3And5_citationsAreBookAndChapterOnly() {
        let citations = vigilCitationLines()
        XCTAssertFalse(citations.isEmpty, "Rules 3 & 5: add Vigil citation strings")

        let bannedTokens = [":", "esv", "niv", "kjv", "nrsv", "nasb", "csb"]
        for line in citations {
            let lower = line.lowercased()
            XCTAssertFalse(bannedTokens.contains(where: { lower.contains($0) }), "Rules 3 & 5: citation must exclude translation names and verse numbers: \(line)")
        }
    }

    func testRule4_noCommentaryOrExplanationAlongsideFragments() {
        let fragments = vigilStringLines().filter { !$0.contains("vigil.section.explanation") && !$0.contains("vigil.section.title") }
        XCTAssertFalse(fragments.isEmpty, "Rule 4: add Vigil fragments and companion lines")

        let commentaryWords = ["commentary", "explain", "interpret", "because", "therefore"]
        for line in fragments {
            let lower = line.lowercased()
            XCTAssertFalse(commentaryWords.contains(where: { lower.contains($0) }), "Rule 4: scripture fragments must not include commentary: \(line)")
        }
    }

    func testRule6_milestoneCompanionAdditionsPreserveDefaultCopy() {
        let companions = vigilStringLines().filter { $0.contains(".companion") }
        XCTAssertEqual(companions.count, 6, "Rule 6: provide six Vigil companion additions (one per milestone)")
    }

    func testRule7_incompleteFastsRemainSilent() {
        let vigilLines = vigilStringLines()
        XCTAssertFalse(vigilLines.isEmpty, "Rule 7: Vigil content must be added before enforcing silence on incomplete fasts")

        let incompleteMentions = vigilLines.filter { $0.lowercased().contains("incomplete") || $0.lowercased().contains("abandoned") }
        XCTAssertTrue(incompleteMentions.isEmpty, "Rule 7: do not add Vigil content for incomplete/abandoned fasts")
    }

    func testRule8_noMeritOrEvaluationLanguage() {
        let vigilLines = vigilStringLines()
        XCTAssertFalse(vigilLines.isEmpty, "Rule 8: Vigil content must be added")

        let meritWords = ["deserve", "earned", "reward", "merit", "congratulations", "proud", "discipline", "achievement"]
        for line in vigilLines {
            let lower = line.lowercased()
            XCTAssertFalse(meritWords.contains(where: { lower.contains($0) }), "Rule 8: Vigil content must not evaluate or praise discipline: \(line)")
        }
    }

    func testRule9_noDenominationalSignals() {
        let vigilLines = vigilStringLines()
        XCTAssertFalse(vigilLines.isEmpty, "Rule 9: Vigil content must be added")

        let denominationalWords = ["lent", "advent", "mass", "rosary", "eucharist", "orthodox", "catholic", "evangelical", "revival", "pentecost"]
        for line in vigilLines {
            let lower = line.lowercased()
            XCTAssertFalse(denominationalWords.contains(where: { lower.contains($0) }), "Rule 9: Vigil content must remain pre-denominational: \(line)")
        }
    }

    func testRule10_vigilContentIsNotPaywalled() {
        let vigilLines = vigilStringLines()
        XCTAssertFalse(vigilLines.isEmpty, "Rule 10: Vigil content must be added")

        let paywallFiles = ["Sources/UI/PaywallScreen.swift", "Sources/UI/PaywallViewModel.swift"]
        let paywallHits = paywallFiles.flatMap { path in
            scanner.scanSubstring("vigil", in: sourcesDirectory(path), allowedExtensions: ["swift"])
        }
        XCTAssertTrue(paywallHits.isEmpty, "Rule 10: Vigil must not be mentioned or gated in paywall surfaces: \(paywallHits)")
    }
}
