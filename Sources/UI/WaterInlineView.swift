import SwiftUI
import DesignSystem

public struct WaterInlineView: View {
    @ObservedObject private var viewModel: WaterViewModel
    @State private var isExpanded = false
    @AppStorage("atrest.hydration.quickAdd") private var quickAddAmount: Int = 250
    @AppStorage("atrest.hydration.unit") private var hydrationUnitRaw: String = HydrationUnit.milliliters.rawValue

    public init(viewModel: WaterViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                withAnimation(Motion.ease) { isExpanded.toggle() }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(Palette.highlight)
                        .accessibilityLabel(L10n.waterA11yDrop)
                    Text(String(format: L10n.waterTodayTotal, formattedTotal))
                        .font(Typography.label)
                        .foregroundStyle(Palette.highlight)
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Palette.surface.opacity(0.55))
                .cornerRadius(Radii.pill)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Button {
                        Task { await viewModel.add(amountMilliliters: quickAddAmount) }
                    } label: {
                        Text(String(format: L10n.waterAdd, quickAddAmountLabel))
                            .font(Typography.body)
                            .foregroundStyle(Palette.highlight)
                            .padding(.vertical, Spacing.xs)
                            .frame(maxWidth: .infinity)
                            .background(Palette.surface.opacity(0.6))
                            .cornerRadius(Radii.soft)
                    }

                    ForEach(viewModel.entries) { entry in
                        HStack {
                            Text(Self.timeLabel(for: entry.date))
                                .font(Typography.caption)
                                .foregroundStyle(Palette.muted)
                            Spacer()
                            Text(entryDisplay(entry))
                                .font(Typography.body)
                                .foregroundStyle(Palette.accent)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await viewModel.remove(id: entry.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(Spacing.md)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: Radii.soft))
                .transition(.opacity)
                .task { await viewModel.load() }
            }
        }
    }

    private var formattedTotal: String {
        entryDisplay(amount: viewModel.todayTotal)
    }

    private func entryDisplay(_ entry: WaterIntakeEntry) -> String {
        entryDisplay(amount: entry.amountMilliliters)
    }

    private func entryDisplay(amount: Int) -> String {
        switch HydrationUnit(rawValue: hydrationUnitRaw) ?? .milliliters {
        case .milliliters:
            return "\(amount) ml"
        case .fluidOunces:
            let ounces = Double(amount) / 29.5735
            return String(format: "%.1f oz", ounces)
        }
    }

    private var quickAddAmountLabel: String {
        entryDisplay(amount: quickAddAmount)
    }

    private static func timeLabel(for date: Date) -> String {
        timeFormatter.string(from: date)
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        return formatter
    }()
}
