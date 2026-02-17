import XCTest
import CryptoKit
@testable import Data
@testable import Domain

final class DataPortabilityTests: XCTestCase {
    private let exportService = DataExportService(version: 1)
    private let importService = DataImportService(currentVersion: 1)

    private let referenceDate = Date(timeIntervalSince1970: 0)

    func testRoundTripExportImport() throws {
        let sessions = makeSessions(count: 3, hours: 5)
        let bundle = try exportService.exportBundle(sessions: sessions, generatedAt: referenceDate)
        let data = try exportService.encode(bundle: bundle)

        let validated = try importService.validate(data: data)
        XCTAssertEqual(validated.preview.version, 1)
        XCTAssertEqual(validated.preview.sessionCount, 3)
        XCTAssertEqual(validated.preview.earliest, referenceDate - 5 * 3600)
        XCTAssertEqual(validated.preview.latest, referenceDate + 2 * 3600)

        let restored = importService.apply(validated)
        XCTAssertEqual(restored, sessions)
    }

    func testInvalidDataFails() {
        let data = Data("not json".utf8)
        XCTAssertThrowsError(try importService.validate(data: data)) { error in
            XCTAssertEqual(error as? DataPortabilityError, .invalidFormat)
        }
    }

    func testUnsupportedNewerVersionFails() throws {
        var bundle = try exportService.exportBundle(sessions: makeSessions(count: 1, hours: 4), generatedAt: referenceDate)
        bundle = DataExportBundle(version: 2, generatedAt: bundle.generatedAt, payload: bundle.payload, checksum: bundle.checksum)
        let data = try exportService.encode(bundle: bundle)

        XCTAssertThrowsError(try importService.validate(data: data)) { error in
            XCTAssertEqual(error as? DataPortabilityError, .unsupportedVersion(found: 2, current: 1))
        }
    }

    func testChecksumMismatchFails() throws {
        let bundle = try exportService.exportBundle(sessions: makeSessions(count: 1, hours: 4), generatedAt: referenceDate)
        var data = try exportService.encode(bundle: bundle)
        // Corrupt a byte
        data[0] = data[0] ^ 0xFF

        XCTAssertThrowsError(try importService.validate(data: data)) { error in
            XCTAssertEqual(error as? DataPortabilityError, .invalidFormat)
        }
    }

    func testUnsupportedOlderVersionFails() throws {
        let payload = DataExportBundle.Payload(sessions: makeSessions(count: 1, hours: 4).map(FastingSessionDTO.init))
        let encoder = makeEncoder()
        let checksum = try encoder.encode(payload).sha256Hex()
        let bundle = DataExportBundle(version: 0, generatedAt: referenceDate, payload: payload, checksum: checksum)
        let data = try encoder.encode(bundle)

        XCTAssertThrowsError(try importService.validate(data: data)) { error in
            XCTAssertEqual(error as? DataPortabilityError, .unsupportedVersion(found: 0, current: 1))
        }
    }

    // Helpers
    private func makeSessions(count: Int, hours: Double) -> [FastingSession] {
        (0..<count).map { index in
            let end = referenceDate.addingTimeInterval(Double(index) * 3600)
            let start = end.addingTimeInterval(-hours * 3600)
            return FastingSession(id: UUID(uuidString: "00000000-0000-0000-0000-0000000000\(String(format: "%02d", index))") ?? UUID(), start: start, end: end)
        }
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        return encoder
    }
}

private extension Data {
    func sha256Hex() -> String {
        let digest = SHA256.hash(data: self)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}
