import SwiftUI
import DesignSystem
import UniformTypeIdentifiers

public struct SettingsScreen: View {
    @ObservedObject private var viewModel: SettingsViewModel
    private let paywallViewModel: PaywallViewModel?
    @State private var exportDocument: ExportDocument = .empty
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var importError: String?

    public init(viewModel: SettingsViewModel, paywallViewModel: PaywallViewModel? = nil) {
        self.viewModel = viewModel
        self.paywallViewModel = paywallViewModel
    }

    public var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()
            List {
                if let paywallViewModel {
                    Section(L10n.paywallTitle) {
                        NavigationLink(L10n.paywallTitle) {
                            PaywallScreen(viewModel: paywallViewModel)
                        }
                    }
                }

                Section(L10n.settingsSectionSubscriptions) {
                    if let manageURL = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                        Link(L10n.manageSubscriptions, destination: manageURL)
                            .foregroundStyle(Palette.accent)
                    }
                }

                Section(L10n.settingsSectionData) {
                    Button(L10n.exportData) {
                        Task {
                            do {
                                exportDocument = try await viewModel.makeExportDocument()
                                isExporting = true
                            } catch {
                                importError = error.localizedDescription
                            }
                        }
                    }
                    .foregroundStyle(Palette.highlight)

                    Button(L10n.importData) {
                        isImporting = true
                    }
                    .foregroundStyle(Palette.accent)

                    if let note = viewModel.importNote {
                        Text(note)
                            .font(Typography.caption)
                            .foregroundStyle(Palette.muted)
                    }

                    Text(L10n.localDataExplanation)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.muted)

                    if let status = viewModel.statusMessage {
                        Text(status)
                            .font(Typography.caption)
                            .foregroundStyle(Palette.highlight)
                    }

                    if let error = importError {
                        Text(error)
                            .font(Typography.caption)
                            .foregroundStyle(Palette.accent)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(L10n.settingsTitle)
            .fileExporter(isPresented: $isExporting, document: exportDocument, contentType: .json, defaultFilename: "AtrestExport.json") { result in
                if case .failure(let error) = result {
                    importError = error.localizedDescription
                }
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    Task {
                        do {
                            try await viewModel.importFile(at: url)
                            importError = nil
                        } catch {
                            importError = error.localizedDescription
                        }
                    }
                case .failure(let error):
                    importError = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    SettingsScreen(viewModel: SettingsViewModel())
}
