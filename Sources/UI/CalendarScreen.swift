import SwiftUI
import Domain
import DesignSystem

public struct CalendarScreen: View {
    @ObservedObject private var viewModel: CalendarViewModel
    @State private var monthOffset: Int = 0
    @State private var selectedEntry: CalendarEntry?
    private let calendar = Calendar.autoupdatingCurrent

    public init(viewModel: CalendarViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            DuskBackground().ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                header
                monthGrid
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xl)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Radii.soft))
            .padding(.horizontal, Spacing.lg)
        }
        .sheet(item: $selectedEntry) { entry in
            detailSheet(entry)
                .presentationDetents([.medium])
        }
    }

    private var header: some View {
        HStack {
            Button {
                monthOffset -= 1
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Palette.muted)
            }
            Spacer()
            Text(monthTitle(for: currentMonthStart))
                .font(Typography.heading)
                .foregroundStyle(Palette.highlight)
            Spacer()
            Button {
                monthOffset += 1
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Palette.muted)
            }
        }
    }

    private var monthGrid: some View {
        let days = daysInMonth(starting: currentMonthStart)
        let entryMap = Dictionary(uniqueKeysWithValues: viewModel.entries.map { (calendar.startOfDay(for: $0.date), $0) })

        return VStack(spacing: Spacing.sm) {
            let symbols = calendar.shortWeekdaySymbols
            HStack {
                ForEach(symbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(Typography.caption)
                        .foregroundStyle(Palette.muted)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 7), spacing: Spacing.sm) {
                ForEach(days) { day in
                    let entry = entryMap[calendar.startOfDay(for: day.date)]
                    DayCell(date: day.date, isCurrentMonth: day.isCurrentMonth, entry: entry)
                        .onTapGesture {
                            if let entry { selectedEntry = entry }
                        }
                }
            }
        }
    }

    private var currentMonthStart: Date {
        let now = Date()
        guard let base = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else { return now }
        return calendar.date(byAdding: .month, value: monthOffset, to: base) ?? base
    }

    private func daysInMonth(starting monthStart: Date) -> [Day] {
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingEmpty = (firstWeekday + 6) % 7
        var days: [Day] = []

        // leading days
        if let previousMonth = calendar.date(byAdding: .month, value: -1, to: monthStart),
           let prevRange = calendar.range(of: .day, in: .month, for: previousMonth) {
            let startDay = prevRange.count - leadingEmpty + 1
            for day in startDay...prevRange.count {
                if let date = calendar.date(bySetting: .day, value: day, of: previousMonth) {
                    days.append(Day(date: date, isCurrentMonth: false))
                }
            }
        }

        // current month days
        for day in range {
            if let date = calendar.date(bySetting: .day, value: day, of: monthStart) {
                days.append(Day(date: date, isCurrentMonth: true))
            }
        }

        // trailing days to complete grid
        while days.count % 7 != 0 {
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: days.last?.date ?? monthStart) {
                days.append(Day(date: nextDate, isCurrentMonth: false))
            } else {
                break
            }
        }
        return days
    }

    private func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }

    private func detailSheet(_ entry: CalendarEntry) -> some View {
        VStack(spacing: Spacing.md) {
            Text(monthDayLabel(for: entry.date))
                .font(Typography.heading)
                .foregroundStyle(Palette.highlight)

            Text(String(format: L10n.calendarDetailDuration, durationLabel(for: entry)))
                .font(Typography.body)
                .foregroundStyle(Palette.accent)

            Text(entry.isIncomplete ? L10n.calendarDetailIncomplete : L10n.calendarDetailCompleted)
                .font(Typography.body)
                .foregroundStyle(Palette.muted)

            Spacer()
        }
        .padding()
        .background(DuskBackground().ignoresSafeArea())
    }

    private func monthDayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }

    private func durationLabel(for entry: CalendarEntry) -> String {
        let totalMinutes = Int(entry.durationHours * 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(hours)h \(minutes)m"
    }
}

private struct Day: Identifiable {
    let date: Date
    let isCurrentMonth: Bool
    var id: Date { date }
}

private struct DayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let entry: CalendarEntry?
    private let calendar = Calendar.autoupdatingCurrent

    var body: some View {
        VStack {
            Text("\(calendar.component(.day, from: date))")
                .font(Typography.body)
                .foregroundStyle(isCurrentMonth ? Palette.highlight : Palette.muted.opacity(0.4))
            if let entry {
                Circle()
                    .fill(entry.isIncomplete ? Palette.treeGrey : Palette.earthTones[toneIndex].light)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44)
    }

    private var toneIndex: Int {
        abs(entry?.sessionID.hashValue ?? 0) % Palette.earthTones.count
    }
}
