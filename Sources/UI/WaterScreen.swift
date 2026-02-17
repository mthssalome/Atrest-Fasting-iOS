import SwiftUI
import DesignSystem
import Domain

public struct WaterScreen: View {
    @ObservedObject private var viewModel: WaterViewModel

    public init(viewModel: WaterViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(L10n.waterTitle)
                        .font(Typography.title)
                        .foregroundStyle(Palette.highlight)
                    Text(L10n.waterSubtitle)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.muted)
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text(L10n.waterToday)
                            .font(Typography.label)
                            .foregroundStyle(Palette.muted)
                        Text("\(viewModel.todayTotal) ml")
                            .font(Typography.heading)
                            .foregroundStyle(Palette.highlight)
                    }
                    Spacer()
                    Button(L10n.waterAdd250) {
                        Task { await viewModel.add(amountMilliliters: 250) }
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Palette.surface)
                    .cornerRadius(Radii.pill)
                    .foregroundStyle(Palette.highlight)
                }

                List {
                    ForEach(viewModel.entries) { entry in
                        HStack {
                            Text(Self.timeLabel(for: entry.date))
                                .font(Typography.body)
                                .foregroundStyle(Palette.highlight)
                            Spacer()
                            Text("\(entry.amountMilliliters) ml")
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
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                Spacer()
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xl)
        }
        .task { await viewModel.load() }
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

#Preview {
    WaterScreen(viewModel: WaterViewModel(store: WaterStore()))
}
