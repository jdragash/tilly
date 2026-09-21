import Testing
import Foundation
@testable import TillyCore

@Suite struct RecurrenceEngineNthDateTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test func indexZeroIsTheAnchorAtStartOfDay() {
        let anchor = Self.calendar.date(from: DateComponents(year: 2026, month: 6, day: 18, hour: 15, minute: 30))!
        let rule = RecurrenceRule(interval: 1, unit: .month, anchorDate: anchor)
        #expect(RecurrenceEngine.date(ofPayment: 0, for: rule, calendar: Self.calendar) == Self.date(2026, 6, 18))
    }

    @Test func twelveMonthlyPaymentsEndElevenMonthsOn() {
        let rule = RecurrenceRule(interval: 1, unit: .month, anchorDate: Self.date(2026, 6, 18))
        #expect(RecurrenceEngine.date(ofPayment: 11, for: rule, calendar: Self.calendar) == Self.date(2027, 5, 18))
    }

    @Test func monthEndClampsWithoutSticking() {
        let rule = RecurrenceRule(interval: 1, unit: .month, anchorDate: Self.date(2027, 1, 31))
        #expect(RecurrenceEngine.date(ofPayment: 1, for: rule, calendar: Self.calendar) == Self.date(2027, 2, 28))
        #expect(RecurrenceEngine.date(ofPayment: 2, for: rule, calendar: Self.calendar) == Self.date(2027, 3, 31))
    }

    @Test func aLeapDayYearlyRuleClampsInOrdinaryYears() {
        let rule = RecurrenceRule(interval: 1, unit: .year, anchorDate: Self.date(2024, 2, 29))
        #expect(RecurrenceEngine.date(ofPayment: 1, for: rule, calendar: Self.calendar) == Self.date(2025, 2, 28))
        #expect(RecurrenceEngine.date(ofPayment: 4, for: rule, calendar: Self.calendar) == Self.date(2028, 2, 29))
    }

    @Test func everyThreeMonthsStepsByTheInterval() {
        let rule = RecurrenceRule(interval: 3, unit: .month, anchorDate: Self.date(2026, 7, 22))
        #expect(RecurrenceEngine.date(ofPayment: 2, for: rule, calendar: Self.calendar) == Self.date(2027, 1, 22))
    }

    @Test func weeklyAndDailyStepByDays() {
        let anchor = Self.date(2026, 6, 18)
        let weekly = RecurrenceRule(interval: 1, unit: .week, anchorDate: anchor)
        let everyTwoDays = RecurrenceRule(interval: 2, unit: .day, anchorDate: anchor)
        #expect(
            RecurrenceEngine.date(ofPayment: 3, for: weekly, calendar: Self.calendar)
                == Self.calendar.date(byAdding: .day, value: 21, to: anchor)
        )
        #expect(
            RecurrenceEngine.date(ofPayment: 5, for: everyTwoDays, calendar: Self.calendar)
                == Self.calendar.date(byAdding: .day, value: 10, to: anchor)
        )
    }

    @Test func itAgreesWithTheDatesTheRuleGenerates() {
        let anchor = Self.date(2026, 1, 31)
        let rule = RecurrenceRule(interval: 1, unit: .month, anchorDate: anchor)
        let range = DateInterval(start: anchor, end: Self.date(2028, 1, 31))
        let generated = RecurrenceEngine.dates(for: rule, in: range, calendar: Self.calendar)
        for k in 0..<24 {
            #expect(RecurrenceEngine.date(ofPayment: k, for: rule, calendar: Self.calendar) == generated[k])
        }
    }
}
