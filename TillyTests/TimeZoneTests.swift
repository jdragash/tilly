import Foundation
import Testing
import TillyCore

@Suite struct TimeZoneTests {
    static func calendar(_ zone: String) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: zone)!
        return cal
    }

    /// A bill made in Paris and read in New York: the anchor is stored as an instant (start of
    /// the day in Paris), so the day numbers New York reads can differ.
    @Test func aBillMadeInParisReadInNewYorkKeepsItsDay() {
        let paris = Self.calendar("Europe/Paris")
        let newYork = Self.calendar("America/New_York")
        let anchor = paris.startOfDay(for: paris.date(from: DateComponents(year: 2026, month: 3, day: 15))!)
        let rule = RecurrenceRule(interval: 1, unit: .month, anchorDate: anchor)

        let range = DateInterval(
            start: newYork.date(from: DateComponents(year: 2026, month: 3, day: 1))!,
            end: newYork.date(from: DateComponents(year: 2026, month: 6, day: 30))!
        )
        let days = RecurrenceEngine.dates(for: rule, in: range, calendar: newYork)
            .prefix(3).map { newYork.component(.day, from: $0) }

        withKnownIssue("Dates are stored as instants, so a bill read in another time zone shifts a day; a decision for Jake", isIntermittent: false) {
            #expect(Array(days) == [15, 15, 15])
        }
    }
}
