import Foundation

/// A day on the calendar: a year, a month and a day, with no time and no time zone. Bills store
/// their days this way, so a bill made on the 15th stays on the 15th whichever time zone reads
/// it; a stored instant (the start of the day where it was made) read as the 14th in New York.
/// Turn one into a `Date` only with the calendar that is going to read it.
public struct CalendarDay: Hashable, Comparable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    /// The day `date` falls on in `calendar`.
    public init(_ date: Date, calendar: Calendar) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 1, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    /// The start of this day in `calendar`.
    public func date(in calendar: Calendar) -> Date {
        let made = calendar.date(from: DateComponents(year: year, month: month, day: day))
        return calendar.startOfDay(for: made ?? .distantPast)
    }

    /// "2026-03-15": a stable name for the day, the same in every time zone.
    public var id: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}
