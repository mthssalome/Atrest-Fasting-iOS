import CryptoKit
import Foundation
import Domain

public enum DataPortabilityError: Error, Equatable {
    case unsupportedVersion(found: Int, current: Int)
    case checksumMismatch
    case invalidFormat
}

public struct DataExportBundle: Codable, Equatable {
    public struct Payload: Codable, Equatable {
        public let sessions: [FastingSessionDTO]
    }

    public let version: Int
    public let generatedAt: Date
    public let payload: Payload
    public let checksum: String
}

public struct FastingSessionDTO: Codable, Equatable {
    public let id: UUID
    public let start: Date
    public let end: Date
    public let targetDurationHours: Double?

    public init(session: FastingSession) {
        self.id = session.id
        self.start = session.start
        self.end = session.end
        self.targetDurationHours = session.targetDurationHours
    }

    public func domainModel() -> FastingSession {
        FastingSession(id: id, start: start, end: end, targetDurationHours: targetDurationHours ?? 16.0)
    }
}

public struct ImportPreview: Equatable {
    public let version: Int
    public let sessionCount: Int
    public let earliest: Date?
    public let latest: Date?
}

public struct ValidatedImport: Equatable {
    public let preview: ImportPreview
    fileprivate let sessions: [FastingSession]
}

public final class DataExportService {
    private let version: Int
    private let encoder: JSONEncoder

    public init(version: Int = 1) {
        self.version = version
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        self.encoder = encoder
    }

    public func exportBundle(sessions: [FastingSession], generatedAt: Date = Date()) throws -> DataExportBundle {
        let persistedSessions = sessions.filter { $0.durationHours >= 4.0 }
        let payload = DataExportBundle.Payload(sessions: persistedSessions.map(FastingSessionDTO.init))
        let payloadData = try encoder.encode(payload)
        let checksum = Self.checksum(for: payloadData)
        return DataExportBundle(version: version, generatedAt: generatedAt, payload: payload, checksum: checksum)
    }

    public func encode(bundle: DataExportBundle) throws -> Data {
        try encoder.encode(bundle)
    }

    static func checksum(for data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

public final class DataImportService {
    private let currentVersion: Int
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    public init(currentVersion: Int = 1) {
        self.currentVersion = currentVersion
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.withoutEscapingSlashes, .sortedKeys]
        self.encoder = encoder
    }

    public func preview(data: Data) throws -> ImportPreview {
        try validate(data: data).preview
    }

    public func validate(data: Data) throws -> ValidatedImport {
        let bundle = try decodeBundle(data: data)
        let sessions = bundle.payload.sessions.map { $0.domainModel() }
        let dates = bundle.payload.sessions.flatMap { [$0.start, $0.end] }
        let preview = ImportPreview(
            version: bundle.version,
            sessionCount: sessions.count,
            earliest: dates.min(),
            latest: dates.max()
        )
        return ValidatedImport(preview: preview, sessions: sessions)
    }

    public func apply(_ validated: ValidatedImport) -> [FastingSession] {
        validated.sessions
    }

    private func decodeBundle(data: Data) throws -> DataExportBundle {
        let bundle: DataExportBundle
        do {
            bundle = try decoder.decode(DataExportBundle.self, from: data)
        } catch {
            throw DataPortabilityError.invalidFormat
        }

        guard bundle.version == currentVersion else {
            throw DataPortabilityError.unsupportedVersion(found: bundle.version, current: currentVersion)
        }

        let payloadData = try encoder.encode(bundle.payload)
        let expectedChecksum = DataExportService.checksum(for: payloadData)
        guard expectedChecksum == bundle.checksum else {
            throw DataPortabilityError.checksumMismatch
        }

        return bundle
    }
}
