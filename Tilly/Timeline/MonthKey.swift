import Foundation

/// One calendar month, identified by year and month number — never by any particular date
/// within it. Comparable by chronological order so ranges of months sort naturally.
struct MonthKey: Hashable, Comparable, Identifiable, Sendable {
    let year: Int
    let month: Int // 1...12

    var id: Int { year * 12 + (month - 1) }

    init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    init(containing date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.year, .month], from: date)
        self.year = components.year ?? 1
        self.month = components.month ?? 1
    }

    /// Handles year boundaries via floor division, so a negative step from January lands
    /// in December of the previous year rather than truncating toward zero.
    func advanced(by months: Int) -> MonthKey {
        let totalMonthIndex = year * 12 + (month - 1) + months
        let advancedYear = Self.floorDiv(totalMonthIndex, 12)
        let advancedMonth = totalMonthIndex - advancedYear * 12
        return MonthKey(year: advancedYear, month: advancedMonth + 1)
    }

    /// First day of the month through its last, both start-of-day — the interval the
    /// engine windows an "effective dates" query against. See "How month paging maps onto
    /// the engine" in `docs/plans/timeline.md`.
    func interval(in calendar: Calendar) -> DateInterval {
        let first = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let daysInMonth = calendar.range(of: .day, in: .month, for: first)?.count ?? 1
        let last = calendar.date(byAdding: .day, value: daysInMonth - 1, to: first)!
        return DateInterval(start: calendar.startOfDay(for: first), end: calendar.startOfDay(for: last))
    }

    /// "September" when `year` is the year `today` falls in; "September 2025" otherwise —
    /// the year only earns its place once it resolves a genuine ambiguity.
    func name(in calendar: Calendar, relativeTo today: Date, locale: Locale) -> String {
        let currentYear = calendar.component(.year, from: today)
        let first = calendar.date(from: DateComponents(year: year, month: month, day: 1))!

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        formatter.dateFormat = year == currentYear ? "LLLL" : "LLLL yyyy"
        return formatter.string(from: first)
    }

    static func < (lhs: MonthKey, rhs: MonthKey) -> Bool {
        lhs.id < rhs.id
    }

    private static func floorDiv(_ a: Int, _ n: Int) -> Int {
        let q = a / n
        let r = a % n
        return r < 0 ? q - 1 : q
    }
}
