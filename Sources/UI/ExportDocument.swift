import Foundation
import UniformTypeIdentifiers
import SwiftUI

public struct ExportDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.json] }

    public let data: Data

    public init(data: Data) {
        self.data = data
    }

    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.data = data
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }

    public static var empty: ExportDocument { ExportDocument(data: Data()) }
}
