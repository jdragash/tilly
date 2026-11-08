import Foundation
import Testing
@testable import TillyCore

@Suite struct CalendarDayTests {
    static func calendar(_ zone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    @Test func aDayRoundTripsThroughAnyCalendar() {
        let day = CalendarDay(year: 2026, month: 3, day: 15)
        for zone in ["UTC", "Europe/Paris", "America/New_York", "Pacific/Kiritimati", "Pacific/Pago_Pago"] {
            let calendar = Self.calendar(zone)
            let date = day.date(in: calendar)
            #expect(CalendarDay(date, calendar: calendar) == day, "\(zone)")
            #expect(date == calendar.startOfDay(for: date), "\(zone)")
        }
    }

    /// The bug this type exists for: the start of the 15th in Paris is the 14th in New York.
    /// The day itself, read in New York, is still the 15th.
    @Test func aDayMadeInParisIsTheSameDayInNewYork() {
        let paris = Self.calendar("Europe/Paris")
        let newYork = Self.calendar("America/New_York")
        let madeInParis = paris.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        #expect(CalendarDay(madeInParis, calendar: newYork).day == 14)
        let day = CalendarDay(madeInParis, calendar: paris)
        #expect(newYork.component(.day, from: day.date(in: newYork)) == 15)
    }

    @Test func daysOrderByYearThenMonthThenDay() {
        #expect(CalendarDay(year: 2025, month: 12, day: 31) < CalendarDay(year: 2026, month: 1, day: 1))
        #expect(CalendarDay(year: 2026, month: 1, day: 31) < CalendarDay(year: 2026, month: 2, day: 1))
        #expect(CalendarDay(year: 2026, month: 2, day: 1) < CalendarDay(year: 2026, month: 2, day: 2))
    }

    @Test func itsIdIsTheDayWrittenOut() {
        #expect(CalendarDay(year: 2026, month: 3, day: 5).id == "2026-03-05")
    }

    /// An occurrence's id names its day, so the same charge has the same id in every time zone.
    @Test func anOccurrenceIdNamesTheScheduledDay() {
        let calendar = Self.calendar("UTC")
        let expense = UUID()
        let scheduled = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let occurrence = Occurrence(
            expenseID: expense, scheduledDate: scheduled, effectiveDate: scheduled,
            amount: 1, isEstimate: false, isSkipped: false, calendar: calendar
        )
        #expect(occurrence.id == "\(expense.uuidString)-2026-03-15")
    }
}
