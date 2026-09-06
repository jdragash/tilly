import Testing
import Foundation
@testable import TillyCore

@Suite struct RecurrenceEngineDayWeekTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar = RecurrenceEngineDayWeekTests.calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test func dailyOverTenDayRangeReturnsTenDates() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2027, 1, 10))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result.count == 10)
        #expect(result == (0..<10).map { Self.calendar.date(byAdding: .day, value: $0, to: anchor)! })
    }

    @Test func everyThreeDaysReturnsOnlyMultiples() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 3, unit: .day, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2027, 1, 10))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        let expected = [1, 4, 7, 10].map { Self.date(2027, 1, $0) }
        #expect(result == expected)
    }

    @Test func weeklyLandsOnSameWeekday() {
        let anchor = Self.date(2027, 1, 6)
        let rule = RecurrenceRule(interval: 1, unit: .week, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2027, 2, 3))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        let weekday = Self.calendar.component(.weekday, from: anchor)
        #expect(result.allSatisfy { Self.calendar.component(.weekday, from: $0) == weekday })
        #expect(result.count == 5)
    }

    @Test func everyTwoWeeksLandsOnSameWeekday() {
        let anchor = Self.date(2027, 1, 6)
        let rule = RecurrenceRule(interval: 2, unit: .week, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2027, 2, 3))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        let weekday = Self.calendar.component(.weekday, from: anchor)
        #expect(result.allSatisfy { Self.calendar.component(.weekday, from: $0) == weekday })
        #expect(result == [Self.date(2027, 1, 6), Self.date(2027, 1, 20), Self.date(2027, 2, 3)])
    }

    @Test func rangeStartingMidSeriesExcludesEarlierOccurrences() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let range = DateInterval(start: Self.date(2027, 1, 5), end: Self.date(2027, 1, 8))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result == [5, 6, 7, 8].map { Self.date(2027, 1, $0) })
    }

    @Test func occurrenceOnRangeStartIsIncluded() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 5, unit: .day, anchorDate: anchor)
        let range = DateInterval(start: Self.date(2027, 1, 6), end: Self.date(2027, 1, 20))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result.first == Self.date(2027, 1, 6))
    }

    @Test func occurrenceOnRangeEndIsIncluded() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 5, unit: .day, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2027, 1, 6))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result.last == Self.date(2027, 1, 6))
    }

    @Test func rangeEntirelyBeforeAnchorReturnsEmpty() {
        let anchor = Self.date(2027, 6, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let range = DateInterval(start: Self.date(2027, 1, 1), end: Self.date(2027, 5, 1))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result.isEmpty)
    }

    @Test func dailyAcrossSpringForwardInLondon() {
        var london = Calendar(identifier: .gregorian)
        london.timeZone = TimeZone(identifier: "Europe/London")!
        let anchor = Self.date(2027, 3, 25, calendar: london)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2027, 4, 1, calendar: london))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: london)
        #expect(result.count == 8)
        for d in result {
            #expect(london.component(.hour, from: d) == 0)
        }
        for i in 1..<result.count {
            let diff = london.dateComponents([.day], from: result[i - 1], to: result[i]).day
            #expect(diff == 1)
        }
    }

    @Test func dailyAcrossAutumnBackInLondon() {
        var london = Calendar(identifier: .gregorian)
        london.timeZone = TimeZone(identifier: "Europe/London")!
        let anchor = Self.date(2027, 10, 28, calendar: london)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2027, 11, 4, calendar: london))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: london)
        #expect(result.count == 8)
        for d in result {
            #expect(london.component(.hour, from: d) == 0)
        }
        for i in 1..<result.count {
            let diff = london.dateComponents([.day], from: result[i - 1], to: result[i]).day
            #expect(diff == 1)
        }
    }

    /// Range bounds are compared at day granularity, so a caller passing "now" as the start
    /// keeps today's occurrence instead of losing it to the clock.
    @Test func nonMidnightRangeStartStillIncludesThatDay() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let afternoon = Self.calendar.date(from: DateComponents(year: 2027, month: 1, day: 5, hour: 14))!
        let range = DateInterval(start: afternoon, end: Self.date(2027, 1, 8))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result == [5, 6, 7, 8].map { Self.date(2027, 1, $0) })
    }

    /// A rule decoded with a zero interval used to trap converting an infinite `Double` to
    /// `Int`, or loop forever appending the anchor. The clamp now survives decoding.
    @Test func decodedZeroIntervalRuleGeneratesDailyThroughTheEngine() throws {
        let anchor = Self.date(2027, 1, 1)
        let json = #"{"interval":0,"unit":"day","anchorDate":\#(anchor.timeIntervalSinceReferenceDate)}"#
        let rule = try JSONDecoder().decode(RecurrenceRule.self, from: Data(json.utf8))
        let range = DateInterval(start: Self.date(2027, 1, 5), end: Self.date(2027, 1, 8))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result == [5, 6, 7, 8].map { Self.date(2027, 1, $0) })
    }

    @Test func dailyOverAYearCompletesQuickly() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2028, 1, 1))
        let start = Date()
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        let elapsed = Date().timeIntervalSince(start)
        #expect(result.count == 366)
        #expect(elapsed < 1.0)
    }
}
