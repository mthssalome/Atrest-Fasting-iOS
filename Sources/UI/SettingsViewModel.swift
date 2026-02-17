import Foundation
import Data
import Domain

public enum SettingsError: Error, Equatable {
    case unavailable
}

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public private(set) var importNote: String?
    @Published public private(set) var statusMessage: String?

    private let sessionStore: SessionStore?
    private let exportService: DataExportService
    private let importService: DataImportService
    private let clock: () -> Date

    /// Called when persisted sessions change (e.g., import merge).
    public var onStoreUpdate: ((SessionStoreState) -> Void)?

    public init(sessionStore: SessionStore? = nil,
                importNote: String? = L10n.importRequiresConfirmation,
                exportService: DataExportService = DataExportService(),
                importService: DataImportService = DataImportService(),
                clock: @escaping () -> Date = Date.init) {
        self.sessionStore = sessionStore
        self.importNote = importNote
        self.exportService = exportService
        self.importService = importService
        self.clock = clock
    }

    public func makeExportDocument() async throws -> ExportDocument {
        guard let sessionStore else { throw SettingsError.unavailable }
        let state = await sessionStore.load()
        let bundle = try exportService.exportBundle(sessions: state.sessions, generatedAt: clock())
        let data = try exportService.encode(bundle: bundle)
        return ExportDocument(data: data)
    }

    public func importFile(at url: URL, strategy: SessionMergeStrategy = .mergeDedup) async throws {
        guard let sessionStore else { throw SettingsError.unavailable }
        guard url.startAccessingSecurityScopedResource() else {
            throw SettingsError.unavailable
        }
        defer { url.stopAccessingSecurityScopedResource() }
        let data = try Data(contentsOf: url)
        let validated = try importService.validate(data: data)
        let sessions = importService.apply(validated)
        let state = try await sessionStore.merge(imported: sessions, strategy: strategy)
        onStoreUpdate?(state)
        statusMessage = L10n.importSuccess
    }
}
