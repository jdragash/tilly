import Testing
import Foundation
@testable import TillyCore

@Suite struct RecurrenceRuleTests {
    static let anchor = Date(timeIntervalSince1970: 0)

    @Test func zeroIntervalClampsToOne() {
        let rule = RecurrenceRule(interval: 0, unit: .day, anchorDate: Self.anchor)
        #expect(rule.interval == 1)
    }

    @Test func negativeIntervalClampsToOne() {
        let rule = RecurrenceRule(interval: -3, unit: .day, anchorDate: Self.anchor)
        #expect(rule.interval == 1)
    }

    @Test func positiveIntervalsStoreUnchanged() {
        #expect(RecurrenceRule(interval: 1, unit: .day, anchorDate: Self.anchor).interval == 1)
        #expect(RecurrenceRule(interval: 5, unit: .day, anchorDate: Self.anchor).interval == 5)
    }

    @Test func identicalRulesAreEqual() {
        let a = RecurrenceRule(interval: 2, unit: .week, anchorDate: Self.anchor, endDate: Self.anchor)
        let b = RecurrenceRule(interval: 2, unit: .week, anchorDate: Self.anchor, endDate: Self.anchor)
        #expect(a == b)
    }

    /// Synthesized `Decodable` writes stored properties directly and would skip the clamp,
    /// letting a persisted rule arrive with an interval that hangs the engine.
    @Test func decodedIntervalOfZeroClampsToOne() throws {
        let json = #"{"interval":0,"unit":"day","anchorDate":0}"#
        let rule = try JSONDecoder().decode(RecurrenceRule.self, from: Data(json.utf8))
        #expect(rule.interval == 1)
    }

    @Test func decodedNegativeIntervalClampsToOne() throws {
        let json = #"{"interval":-3,"unit":"month","anchorDate":0}"#
        let rule = try JSONDecoder().decode(RecurrenceRule.self, from: Data(json.utf8))
        #expect(rule.interval == 1)
    }

    @Test func roundTripsThroughCodable() throws {
        let original = RecurrenceRule(interval: 3, unit: .month, anchorDate: Self.anchor, endDate: Self.anchor)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RecurrenceRule.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - Rhythm

    private func rule(_ interval: Int, _ unit: RecurrenceUnit) -> RecurrenceRule {
        RecurrenceRule(interval: interval, unit: unit, anchorDate: Self.anchor)
    }

    @Test func monthlyChargesEveryMonth() {
        #expect(rule(1, .month).chargesEveryMonth)
    }

    @Test func everyTwoMonthsIsExtra() {
        #expect(!rule(2, .month).chargesEveryMonth)
    }

    @Test func yearlyIsExtra() {
        #expect(!rule(1, .year).chargesEveryMonth)
    }

    @Test func everyFourWeeksChargesEveryMonth() {
        #expect(rule(1, .week).chargesEveryMonth)
        #expect(rule(4, .week).chargesEveryMonth)
    }

    @Test func everyFiveWeeksIsExtra() {
        #expect(!rule(5, .week).chargesEveryMonth)
    }

    @Test func every28DaysChargesEveryMonth() {
        #expect(rule(1, .day).chargesEveryMonth)
        #expect(rule(28, .day).chargesEveryMonth)
    }

    @Test func every29DaysIsExtra() {
        #expect(!rule(29, .day).chargesEveryMonth)
    }

    @Test func chargesEveryMonthIgnoresEndDate() {
        let ended = RecurrenceRule(interval: 1, unit: .month, anchorDate: Self.anchor, endDate: Self.anchor)
        #expect(ended.chargesEveryMonth)
    }

    @Test func paymentsPerYearByUnit() {
        #expect(rule(1, .month).paymentsPerYear == 12)
        #expect(rule(3, .month).paymentsPerYear == 4)
        #expect(rule(1, .year).paymentsPerYear == 1)
        #expect(rule(2, .year).paymentsPerYear == Decimal(string: "0.5"))
        #expect(rule(2, .week).paymentsPerYear == 26)
        #expect(rule(1, .day).paymentsPerYear == 365)
    }

    @Test func paymentsPerYearKeepsFractions() {
        #expect(rule(5, .month).paymentsPerYear == Decimal(string: "2.4"))
    }
}
