import Foundation
import SwiftData
import TillyCore

typealias Expense = SchemaV3.Expense

extension SchemaV3 {
    @Model
    final class Expense {
        var id: UUID = UUID()
        var name: String = ""
        var amount: Decimal?
        var isEstimate: Bool = false
        var isArchived: Bool = false
        var recurrenceInterval: Int = 1
        /// A plain `String` rather than the enum: CloudKit-safe, readable in the store, and
        /// usable in a `#Predicate`. A stored enum goes through `Codable` into an opaque blob.
        var recurrenceUnitRaw: String = RecurrenceUnit.month.rawValue
        /// The first charge's day as parts, never an instant, so it reads the same in every time
        /// zone. Through `anchor`, or `anchorDate(in:)` with the calendar that will use it.
        var anchorYear: Int = 2000
        var anchorMonth: Int = 1
        var anchorDay: Int = 1
        /// The last charge's day, all three nil when the bill runs on. Through `end`.
        var endYear: Int?
        var endMonth: Int?
        var endDay: Int?
        /// Optional because CloudKit requires it; the editor requires one, so `nil` only occurs in a
        /// store saved before categories existed.
        var category: ExpenseCategory?
        /// Optional so a migrated store gives existing bills no shared default: nil is "its own
        /// series". Set when "future charges" splits a bill into a new record sharing this one.
        var seriesID: UUID?

        @Relationship(deleteRule: .cascade, inverse: \OverrideRecord.expense)
        var overrides: [OverrideRecord]?

        /// `anchorDate` and `endDate` are read as days in `calendar`.
        init(
            id: UUID = UUID(),
            name: String = "",
            amount: Decimal? = nil,
            isEstimate: Bool = false,
            isArchived: Bool = false,
            recurrenceInterval: Int = 1,
            recurrenceUnit: RecurrenceUnit = .month,
            anchorDate: Date,
            endDate: Date? = nil,
            category: ExpenseCategory? = nil,
            seriesID: UUID? = nil,
            calendar: Calendar
        ) {
            self.id = id
            self.name = name
            self.amount = amount
            self.isEstimate = isEstimate
            self.isArchived = isArchived
            self.recurrenceInterval = recurrenceInterval
            self.recurrenceUnitRaw = recurrenceUnit.rawValue
            self.category = category
            self.seriesID = seriesID
            self.anchor = CalendarDay(anchorDate, calendar: calendar)
            self.end = endDate.map { CalendarDay($0, calendar: calendar) }
        }
    }
}

extension Expense {
    /// The first charge's day.
    var anchor: CalendarDay {
        get { CalendarDay(year: anchorYear, month: anchorMonth, day: anchorDay) }
        set {
            anchorYear = newValue.year
            anchorMonth = newValue.month
            anchorDay = newValue.day
        }
    }

    /// The last charge's day; nil when the bill runs on.
    var end: CalendarDay? {
        get {
            guard let endYear, let endMonth, let endDay else { return nil }
            return CalendarDay(year: endYear, month: endMonth, day: endDay)
        }
        set {
            endYear = newValue?.year
            endMonth = newValue?.month
            endDay = newValue?.day
        }
    }

    func anchorDate(in calendar: Calendar) -> Date { anchor.date(in: calendar) }

    func setAnchorDate(_ date: Date, in calendar: Calendar) { anchor = CalendarDay(date, calendar: calendar) }

    func endDate(in calendar: Calendar) -> Date? { end?.date(in: calendar) }

    func setEndDate(_ date: Date?, in calendar: Calendar) { end = date.map { CalendarDay($0, calendar: calendar) } }
}

extension Expense {
    /// Falls back to its own id: a migrated store gives every existing bill a nil `seriesID`,
    /// and nil must mean "its own series" rather than sharing one default with every other bill.
    var seriesKey: UUID { seriesID ?? id }
}

extension Expense {
    /// Falls back to `.month` rather than failing. Mapping to the engine is total: a bill shown
    /// with a defaulted unit is an obvious fault, and one that silently vanishes is not.
    var recurrenceUnit: RecurrenceUnit {
        RecurrenceUnit(rawValue: recurrenceUnitRaw) ?? .month
    }

    func rule(calendar: Calendar) -> RecurrenceRule {
        RecurrenceRule(
            interval: recurrenceInterval,
            unit: recurrenceUnit,
            anchorDate: anchorDate(in: calendar),
            endDate: endDate(in: calendar)
        )
    }

    func snapshot(calendar: Calendar) -> ExpenseSnapshot {
        ExpenseSnapshot(id: id, amount: amount, isEstimate: isEstimate, rule: rule(calendar: calendar), isArchived: isArchived)
    }

    func overrideSnapshots(calendar: Calendar) -> [OccurrenceOverride] {
        (overrides ?? []).map { $0.snapshot(calendar: calendar) }
    }
}
