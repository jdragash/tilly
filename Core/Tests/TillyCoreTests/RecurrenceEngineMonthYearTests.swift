import Testing
import Foundation
@testable import TillyCore

@Suite struct RecurrenceEngineMonthYearTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test func monthlyAnchoredJan31ClampsAndRestoresPerMonth() {
        let anchor = Self.date(2027, 1, 31)
        let rule = RecurrenceRule(interval: 1, unit: .month, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2027, 5, 31))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result == [
            Self.date(2027, 1, 31),
            Self.date(2027, 2, 28),
            Self.date(2027, 3, 31),
            Self.date(2027, 4, 30),
            Self.date(2027, 5, 31)
        ])
    }

    @Test func monthlyAnchoredJan31LeapYearClampsToFeb29() {
        let anchor = Self.date(2028, 1, 31)
        let rule = RecurrenceRule(interval: 1, unit: .month, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2028, 3, 31))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result == [
            Self.date(2028, 1, 31),
            Self.date(2028, 2, 29),
            Self.date(2028, 3, 31)
        ])
    }

    @Test func monthlyOnThe15thIsUnaffectedByClampingAcrossAYear() {
        let anchor = Self.date(2027, 1, 15)
        let rule = RecurrenceRule(interval: 1, unit: .month, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2028, 1, 15))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result.count == 13)
        #expect(result.allSatisfy { Self.calendar.component(.day, from: $0) == 15 })
    }

    /// Plan originally read "31 May" for this case, which can't follow from a 30 Nov
    /// anchor (November has no 31st). Corrected to 30 May — anchor day restored since
    /// May has 31 days. See docs/plans/recurrence-engine.md build note, 2026-09-06.
    @Test func everyThreeMonthsAnchoredNov30RestoresAnchorDayWhenMonthAllows() {
        let anchor = Self.date(2027, 11, 30)
        let rule = RecurrenceRule(interval: 3, unit: .month, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2028, 5, 30))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result == [
            Self.date(2027, 11, 30),
            Self.date(2028, 2, 29),
            Self.date(2028, 5, 30)
        ])
    }

    @Test func yearlyAnchoredFeb29Leap2028ClampsInNonLeapYears() {
        let anchor = Self.date(2028, 2, 29)
        let rule = RecurrenceRule(interval: 1, unit: .year, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2032, 2, 29))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result == [
            Self.date(2028, 2, 29),
            Self.date(2029, 2, 28),
            Self.date(2030, 2, 28),
            Self.date(2031, 2, 28),
            Self.date(2032, 2, 29)
        ])
    }

    @Test func yearlyAnchoredMar3ReturnsMar3EveryYear() {
        let anchor = Self.date(2027, 3, 3)
        let rule = RecurrenceRule(interval: 1, unit: .year, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2030, 3, 3))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result == [
            Self.date(2027, 3, 3),
            Self.date(2028, 3, 3),
            Self.date(2029, 3, 3),
            Self.date(2030, 3, 3)
        ])
    }

    @Test func monthRangeWindowingExcludesEarlierAndIncludesBoundaries() {
        let anchor = Self.date(2027, 1, 15)
        let rule = RecurrenceRule(interval: 1, unit: .month, anchorDate: anchor)
        let range = DateInterval(start: Self.date(2027, 3, 15), end: Self.date(2027, 5, 15))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result == [
            Self.date(2027, 3, 15),
            Self.date(2027, 4, 15),
            Self.date(2027, 5, 15)
        ])
    }

    @Test func yearRangeWindowingExcludesEarlierAndIncludesBoundaries() {
        let anchor = Self.date(2020, 6, 1)
        let rule = RecurrenceRule(interval: 1, unit: .year, anchorDate: anchor)
        let range = DateInterval(start: Self.date(2025, 6, 1), end: Self.date(2027, 6, 1))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result == [
            Self.date(2025, 6, 1),
            Self.date(2026, 6, 1),
            Self.date(2027, 6, 1)
        ])
    }

    @Test func monthRangeEntirelyBeforeAnchorReturnsEmpty() {
        let anchor = Self.date(2027, 6, 1)
        let rule = RecurrenceRule(interval: 1, unit: .month, anchorDate: anchor)
        let range = DateInterval(start: Self.date(2027, 1, 1), end: Self.date(2027, 5, 1))
        let result = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        #expect(result.isEmpty)
    }
}
