import SwiftUI
import DesignSystem
import UniformTypeIdentifiers
import Domain

public struct SettingsScreen: View {
    @ObservedObject private var viewModel: SettingsViewModel
    private let entitlement: Entitlement
    private let onShowPaywall: (() -> Void)?

    @State private var exportDocument: ExportDocument = .empty
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var importError: String?

    public init(viewModel: SettingsViewModel, entitlement: Entitlement, onShowPaywall: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.entitlement = entitlement
        self.onShowPaywall = onShowPaywall
    }

    private var quickAddLabel: String {
        switch viewModel.hydrationUnit {
        case .milliliters:
            return "\(viewModel.quickAddAmount) ml"
        case .fluidOunces:
            let ounces = Double(viewModel.quickAddAmount) / 29.5735
            return String(format: "%.1f oz", ounces)
        }
    }

    public var body: some View {
        ZStack {
            DuskBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text(L10n.settingsTitle)
                        .font(Typography.title)
                        .foregroundStyle(Palette.highlight)

                    sectionCard(title: L10n.settingsSectionFasting) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Text(L10n.settingsFastingTarget)
                                    .font(Typography.heading)
                                    .foregroundStyle(Palette.highlight)
                                Spacer()
                                Text("\(Int(viewModel.targetHours))h")
                                    .font(Typography.body)
                                    .foregroundStyle(Palette.accent)
                            }
                            Slider(value: Binding(get: { viewModel.targetHours }, set: { viewModel.updateTargetHours($0) }), in: 12...24, step: 1)
                                .tint(Palette.accent)
                            Text(L10n.settingsFastingTargetNote)
                                .font(Typography.caption)
                                .foregroundStyle(Palette.muted)
                        }
                    }

                    sectionCard(title: L10n.settingsSectionHydration) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Picker(L10n.settingsHydrationUnit, selection: Binding(get: { viewModel.hydrationUnit }, set: { viewModel.hydrationUnit = $0 })) {
                                Text(L10n.settingsHydrationUnitMl).tag(HydrationUnit.milliliters)
                                Text(L10n.settingsHydrationUnitOz).tag(HydrationUnit.fluidOunces)
                            }
                            .pickerStyle(.segmented)

                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                HStack {
                                    Text(L10n.settingsHydrationQuickAdd)
                                        .font(Typography.body)
                                        .foregroundStyle(Palette.highlight)
                                    Spacer()
                                    Text(quickAddLabel)
                                        .font(Typography.body)
                                        .foregroundStyle(Palette.accent)
                                }
                                Stepper(value: Binding(get: { viewModel.quickAddAmount }, set: { viewModel.updateQuickAddAmount($0) }), in: 50...1000, step: 50) {
                                    EmptyView()
                                }
                            }
                        }
                    }

                    if entitlement != .premium {
                        sectionCard(title: L10n.settingsSectionPremium) {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text(L10n.paywallDescription)
                                    .font(Typography.body)
                                    .foregroundStyle(Palette.muted)
                                Button(L10n.settingsPremiumGo) {
                                    onShowPaywall?()
                                }
                                .font(Typography.body)
                                .foregroundStyle(Palette.highlight)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    sectionCard(title: L10n.settingsSectionData) {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Button(L10n.settingsExport) {
                                Task {
                                    do {
                                        exportDocument = try await viewModel.makeExportDocument()
                                        isExporting = true
                                    } catch {
                                        importError = error.localizedDescription
                                    }
                                }
                            }
                            .font(Typography.body)
                            .foregroundStyle(Palette.highlight)

                            Button(L10n.settingsImport) {
                                isImporting = true
                            }
                            .font(Typography.body)
                            .foregroundStyle(Palette.accent)

                            if let note = viewModel.importNote {
                                Text(note)
                                    .font(Typography.caption)
                                    .foregroundStyle(Palette.muted)
                            }

                            Text(L10n.settingsDataExplanation)
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

                    if entitlement == .premium {
                        sectionCard(title: L10n.settingsSectionAccount) {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                if let manageURL = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                                    Link(L10n.settingsManageSubscription, destination: manageURL)
                                        .font(Typography.body)
                                        .foregroundStyle(Palette.accent)
                                }

                                Button(L10n.settingsRestore) {
                                    onShowPaywall?()
                                }
                                .font(Typography.body)
                                .foregroundStyle(Palette.highlight)
                            }
                        }
                    }

                    sectionCard(title: L10n.settingsSectionLegal) {
                        HStack(spacing: Spacing.md) {
                            if let termsURL = URL(string: L10n.settingsTermsURL) {
                                Link(L10n.settingsTerms, destination: termsURL)
                                    .font(Typography.body)
                                    .foregroundStyle(Palette.accent)
                            }
                            if let privacyURL = URL(string: L10n.settingsPrivacyURL) {
                                Link(L10n.settingsPrivacy, destination: privacyURL)
                                    .font(Typography.body)
                                    .foregroundStyle(Palette.accent)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.xl)
            }
        }
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

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(Typography.heading)
                .foregroundStyle(Palette.highlight)
            content()
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radii.soft))
    }
}

#Preview {
    SettingsScreen(viewModel: SettingsViewModel(), entitlement: .free)
}
