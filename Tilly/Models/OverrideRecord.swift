import Foundation
import SwiftData
import TillyCore

typealias OverrideRecord = SchemaV3.OverrideRecord

extension SchemaV3 {
    /// The stored form of `TillyCore.OccurrenceOverride`. Named differently on purpose, so the
    /// persisted type and the engine's value type never collide in a file or in a reader's head.
    /// Its days are stored as parts, as `Expense`'s are.
    @Model
    final class OverrideRecord {
        var scheduledYear: Int = 2000
        var scheduledMonth: Int = 1
        var scheduledDay: Int = 1
        var actualAmount: Decimal?
        var movedYear: Int?
        var movedMonth: Int?
        var movedDay: Int?
        var isSkipped: Bool = false
        var expense: Expense?

        /// `scheduledDate` and `movedDate` are read as days in `calendar`.
        init(
            scheduledDate: Date,
            actualAmount: Decimal? = nil,
            movedDate: Date? = nil,
            isSkipped: Bool = false,
            expense: Expense? = nil,
            calendar: Calendar
        ) {
            self.actualAmount = actualAmount
            self.isSkipped = isSkipped
            self.expense = expense
            self.scheduled = CalendarDay(scheduledDate, calendar: calendar)
            self.moved = movedDate.map { CalendarDay($0, calendar: calendar) }
        }
    }
}

extension OverrideRecord {
    /// The day the rule schedules the charge this record changes: its key.
    var scheduled: CalendarDay {
        get { CalendarDay(year: scheduledYear, month: scheduledMonth, day: scheduledDay) }
        set {
            scheduledYear = newValue.year
            scheduledMonth = newValue.month
            scheduledDay = newValue.day
        }
    }

    /// The day the charge moved to; nil when it stays.
    var moved: CalendarDay? {
        get {
            guard let movedYear, let movedMonth, let movedDay else { return nil }
            return CalendarDay(year: movedYear, month: movedMonth, day: movedDay)
        }
        set {
            movedYear = newValue?.year
            movedMonth = newValue?.month
            movedDay = newValue?.day
        }
    }

    func scheduledDate(in calendar: Calendar) -> Date { scheduled.date(in: calendar) }

    func movedDate(in calendar: Calendar) -> Date? { moved?.date(in: calendar) }

    func setMovedDate(_ date: Date?, in calendar: Calendar) { moved = date.map { CalendarDay($0, calendar: calendar) } }

    func snapshot(calendar: Calendar) -> OccurrenceOverride {
        OccurrenceOverride(
            scheduledDate: scheduledDate(in: calendar),
            actualAmount: actualAmount,
            movedDate: movedDate(in: calendar),
            isSkipped: isSkipped
        )
    }
}
