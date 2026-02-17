import Foundation
import Domain

public struct WaterStoreState: Equatable {
    public let entries: [WaterIntakeEntry]
}

public actor WaterStore {
    private let url: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default, directory: URL? = nil) {
        self.fileManager = fileManager
        let baseDirectory: URL
        if let directory {
            baseDirectory = directory
        } else {
            let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            baseDirectory = support.appendingPathComponent("AtrestFasting", isDirectory: true)
        }
        self.url = baseDirectory.appendingPathComponent("water-log.json")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func load() async -> WaterStoreState {
        do {
            let data = try Data(contentsOf: url)
            let entries = try decoder.decode([WaterIntakeEntry].self, from: data)
            return WaterStoreState(entries: entries)
        } catch {
            return WaterStoreState(entries: [])
        }
    }

    public func add(amountMilliliters: Int, at date: Date = Date()) async throws -> WaterStoreState {
        var state = await load()
        let entry = WaterIntakeEntry(date: date, amountMilliliters: amountMilliliters)
        state = WaterStoreState(entries: (state.entries + [entry]).sorted { $0.date > $1.date })
        try persist(state.entries)
        return state
    }

    public func remove(id: UUID) async throws -> WaterStoreState {
        var state = await load()
        state = WaterStoreState(entries: state.entries.filter { $0.id != id })
        try persist(state.entries)
        return state
    }

    private func persist(_ entries: [WaterIntakeEntry]) throws {
        try ensureDirectory()
        let data = try encoder.encode(entries)
        try data.write(to: url, options: [.atomic])
    }

    private func ensureDirectory() throws {
        let directory = url.deletingLastPathComponent()
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: directory.path, isDirectory: &isDir) {
            if isDir.boolValue { return }
        }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
