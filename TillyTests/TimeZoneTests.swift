import Foundation
import SwiftData
import Testing
import TillyCore
@testable import Tilly

/// A bill keeps its days whichever time zone reads it: they are stored as calendar days, not as
/// the instant each began where the bill was made.
@MainActor
@Suite struct TimeZoneTests {
    static func calendar(_ zone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    static let paris = calendar("Europe/Paris")
    static let newYork = calendar("America/New_York")

    static func day(_ year: Int, _ month: Int, _ day: Int, in calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    /// Made in Paris on the 15th, monthly, ending on 15 June, with April's charge moved to the
    /// 20th: read in New York, every day is the one it was made on.
    @Test func aBillMadeInParisReadInNewYorkKeepsItsDays() throws {
        let context = ModelContext(try TillyStore.container(inMemory: true))
        let bill = Expense(
            name: "Rent", amount: 950, anchorDate: Self.day(2026, 3, 15, in: Self.paris),
            endDate: Self.day(2026, 6, 15, in: Self.paris), calendar: Self.paris
        )
        context.insert(bill)
        context.insert(OverrideRecord(
            scheduledDate: Self.day(2026, 4, 15, in: Self.paris), actualAmount: 990,
            movedDate: Self.day(2026, 4, 20, in: Self.paris), expense: bill, calendar: Self.paris
        ))
        try context.save()

        let newYork = Self.newYork
        #expect(newYork.component(.day, from: bill.anchorDate(in: newYork)) == 15)
        #expect(newYork.component(.day, from: try #require(bill.endDate(in: newYork))) == 15)

        let charges = RecurrenceEngine.occurrences(
            for: bill.snapshot(calendar: newYork), overrides: bill.overrideSnapshots(calendar: newYork),
            in: DateInterval(start: Self.day(2026, 3, 1, in: newYork), end: Self.day(2026, 6, 30, in: newYork)),
            calendar: newYork
        )
        let days = charges.map { CalendarDay($0.effectiveDate, calendar: newYork).id }
        #expect(days == ["2026-03-15", "2026-04-20", "2026-05-15", "2026-06-15"])
        #expect(charges.map(\.amount) == [950, 990, 950, 950])
    }
}
