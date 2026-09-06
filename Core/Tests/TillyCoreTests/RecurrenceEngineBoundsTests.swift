import Testing
import Foundation
@testable import TillyCore

@Suite struct RecurrenceEngineBoundsTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test func dailyRespectsEndDate() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor, endDate: Self.date(2027, 1, 5))
        let range = DateInterval(start: anchor, end: Self.date(2027, 1, 10))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result == [1, 2, 3, 4, 5].map { Self.date(2027, 1, $0) })
    }

    @Test func weeklyRespectsEndDate() {
        let anchor = Self.date(2027, 1, 6)
        let rule = RecurrenceRule(interval: 1, unit: .week, anchorDate: anchor, endDate: Self.date(2027, 1, 20))
        let range = DateInterval(start: anchor, end: Self.date(2027, 2, 10))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result == [Self.date(2027, 1, 6), Self.date(2027, 1, 13), Self.date(2027, 1, 20)])
    }

    @Test func monthlyRespectsEndDate() {
        let anchor = Self.date(2027, 1, 31)
        let rule = RecurrenceRule(interval: 1, unit: .month, anchorDate: anchor, endDate: Self.date(2027, 3, 31))
        let range = DateInterval(start: anchor, end: Self.date(2027, 6, 30))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result == [Self.date(2027, 1, 31), Self.date(2027, 2, 28), Self.date(2027, 3, 31)])
    }

    @Test func yearlyRespectsEndDate() {
        let anchor = Self.date(2027, 3, 3)
        let rule = RecurrenceRule(interval: 1, unit: .year, anchorDate: anchor, endDate: Self.date(2029, 3, 3))
        let range = DateInterval(start: anchor, end: Self.date(2032, 3, 3))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result == [Self.date(2027, 3, 3), Self.date(2028, 3, 3), Self.date(2029, 3, 3)])
    }

    @Test func occurrenceExactlyOnEndDateIsIncluded() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 5, unit: .day, anchorDate: anchor, endDate: Self.date(2027, 1, 11))
        let range = DateInterval(start: anchor, end: Self.date(2027, 1, 20))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result.last == Self.date(2027, 1, 11))
    }

    @Test func endDateEarlierThanAnchorReturnsEmpty() {
        let anchor = Self.date(2027, 6, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor, endDate: Self.date(2027, 1, 1))
        let range = DateInterval(start: Self.date(2027, 1, 1), end: Self.date(2027, 12, 31))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result.isEmpty)
    }

    @Test func nilEndDateIsUnboundedByRange() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2027, 1, 3))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result.count == 3)
    }
}
