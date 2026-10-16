import Foundation

/// Lays a built month out as a grid of days. Pure, like the builders it sits on, so it's tested
/// without a simulator.
enum CalendarMonthBuilder {
    static func month(_ section: MonthSection, today: Date, calendar: Calendar) -> CalendarMonth {
        let first = calendar.date(from: DateComponents(year: section.month.year, month: section.month.month, day: 1))!
        let dayCount = calendar.range(of: .day, in: .month, for: first)?.count ?? 1
        let todayStart = calendar.startOfDay(for: today)

        let charged = section.entries.filter { $0.state != .skipped }
        let byDay = Dictionary(grouping: charged) { calendar.component(.day, from: $0.date) }

        let days = (1...dayCount).map { day in
            let date = calendar.date(byAdding: .day, value: day - 1, to: first)!
            let entries = (byDay[day] ?? []).sorted(by: TimelineBuilder.amountOrder)
            let start = calendar.startOfDay(for: date)
            return CalendarDay(
                day: day,
                date: start,
                entries: entries,
                total: entries.reduce(Decimal(0)) { $0 + ($1.amount ?? 0) },
                isUpcoming: start > todayStart
            )
        }

        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let trailing = (7 - (leading + dayCount) % 7) % 7
        return CalendarMonth(section: section, leadingDays: leading, trailingDays: trailing, days: days)
    }
}
