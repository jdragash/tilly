import Foundation

/// One day of a month's grid: the charges that land on it, skipped ones left out.
struct CalendarDay: Identifiable, Equatable, Sendable {
    let day: Int // 1...31
    let date: Date // start of day
    /// Amount descending, ties by name ascending, a `nil` amount last.
    let entries: [TimelineEntry]
    let total: Decimal // the entries' amounts; a `nil` amount adds nothing
    let isUpcoming: Bool // date is after today

    var id: Int { day }
}

/// A month as a grid: every day of it, and the empty cells that square off the first and last
/// weeks.
struct CalendarMonth: Equatable, Sendable {
    let section: MonthSection
    let leadingDays: Int // grid cells before the 1st, counted from `calendar.firstWeekday`
    let trailingDays: Int // cells after the last day, completing the final week
    let days: [CalendarDay] // every day of the month, empty ones included
}
