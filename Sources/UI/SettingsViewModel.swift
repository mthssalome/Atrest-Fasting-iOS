import Foundation
import Data
import Domain
import SwiftUI

public enum SettingsError: Error, Equatable {
    case unavailable
}

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public private(set) var importNote: String?
    @Published public private(set) var statusMessage: String?
    @AppStorage("atrest.fasting.targetHours") public var targetHours: Double = 16.0
    @AppStorage("atrest.hydration.unit") public var hydrationUnitRaw: String = HydrationUnit.milliliters.rawValue
    @AppStorage("atrest.hydration.quickAdd") public var quickAddAmount: Int = 250

    private let sessionStore: SessionStore?
    private let exportService: DataExportService
    private let importService: DataImportService
    private let clock: () -> Date

    /// Called when persisted sessions change (e.g., import merge).
    public var onStoreUpdate: ((SessionStoreState) -> Void)?

    public var hydrationUnit: HydrationUnit {
        get { HydrationUnit(rawValue: hydrationUnitRaw) ?? .milliliters }
        set { hydrationUnitRaw = newValue.rawValue }
    }

    public init(sessionStore: SessionStore? = nil,
                importNote: String? = L10n.settingsImportNote,
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
        statusMessage = L10n.settingsImportSuccess
    }

    public func updateTargetHours(_ hours: Double) {
        targetHours = hours
    }

    public func updateQuickAddAmount(_ amount: Int) {
        quickAddAmount = amount
    }
}

public enum HydrationUnit: String, CaseIterable {
    case milliliters
    case fluidOunces
}
