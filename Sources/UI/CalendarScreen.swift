import SwiftUI
import Domain
import DesignSystem

public struct CalendarScreen: View {
    @ObservedObject private var viewModel: CalendarViewModel

    public init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Palette.canvas.ignoresSafeArea()
            List {
                if !viewModel.visibleEntries.isEmpty {
                    Section(L10n.calendarEntries) {
                        ForEach(viewModel.visibleEntries, id: \.sessionID) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(Self.dateLabel(for: entry.date))
                                        .font(Typography.body)
                                        .foregroundStyle(Palette.highlight)
                                    Text(L10n.calendarInspectable)
                                        .font(Typography.caption)
                                        .foregroundStyle(Palette.muted)
                                }
                                Spacer()
                            }
                            .padding(.vertical, Spacing.xs)
                        }
                    }
                }
                if !viewModel.lockedEntries.isEmpty {
                    Section(L10n.calendarLocked) {
                        ForEach(viewModel.lockedEntries, id: \.sessionID) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(Self.dateLabel(for: entry.date))
                                        .font(Typography.body)
                                        .foregroundStyle(Palette.muted)
                                    Text(L10n.calendarLockedLabel)
                                        .font(Typography.caption)
                                        .foregroundStyle(Palette.muted)
                                }
                                Spacer()
                            }
                            .opacity(0.65)
                            .padding(.vertical, Spacing.xs)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(L10n.calendarTitle)
        }
    }

    private static func dateLabel(for date: Date) -> String {
        FormatterCache.shared.formatter.string(from: date)
    }
}

private final class FormatterCache {
    static let shared = FormatterCache()
    let formatter: DateFormatter

    private init() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        self.formatter = formatter
    }
}

#Preview {
    CalendarScreen(viewModel: CalendarViewModel(entries: []))
}
