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

    @Test func roundTripsThroughCodable() throws {
        let original = RecurrenceRule(interval: 3, unit: .month, anchorDate: Self.anchor, endDate: Self.anchor)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RecurrenceRule.self, from: data)
        #expect(decoded == original)
    }
}
