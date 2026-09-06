import Testing
import Foundation
@testable import TillyCore

@Suite struct OccurrenceTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func expense(
        amount: Decimal? = 10,
        isEstimate: Bool = false,
        rule: RecurrenceRule,
        isArchived: Bool = false
    ) -> ExpenseSnapshot {
        ExpenseSnapshot(id: UUID(), amount: amount, isEstimate: isEstimate, rule: rule, isArchived: isArchived)
    }

    @Test func noOverridesProducesOneOccurrencePerDateCarryingExpenseFields() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let expense = Self.expense(amount: 42, isEstimate: true, rule: rule)
        let range = DateInterval(start: anchor, end: Self.date(2027, 1, 3))

        let result = RecurrenceEngine.occurrences(for: expense, overrides: [], in: range, calendar: Self.calendar)

        #expect(result.count == 3)
        #expect(result.allSatisfy { $0.amount == 42 && $0.isEstimate == true && $0.expenseID == expense.id })
        #expect(result.map(\.scheduledDate) == [1, 2, 3].map { Self.date(2027, 1, $0) })
        #expect(result.map(\.effectiveDate) == result.map(\.scheduledDate))
    }

    @Test func actualAmountOverrideReplacesAmountAndClearsEstimate() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let expense = Self.expense(amount: 10, isEstimate: true, rule: rule)
        let range = DateInterval(start: anchor, end: Self.date(2027, 1, 2))
        let override = OccurrenceOverride(scheduledDate: Self.date(2027, 1, 2), actualAmount: 99, movedDate: nil, isSkipped: false)

        let result = RecurrenceEngine.occurrences(for: expense, overrides: [override], in: range, calendar: Self.calendar)

        let day1 = result.first { $0.scheduledDate == Self.date(2027, 1, 1) }!
        let day2 = result.first { $0.scheduledDate == Self.date(2027, 1, 2) }!
        #expect(day1.amount == 10 && day1.isEstimate == true)
        #expect(day2.amount == 99 && day2.isEstimate == false)
    }

    @Test func skippedOverrideStillAppearsFlagged() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let expense = Self.expense(rule: rule)
        let range = DateInterval(start: anchor, end: Self.date(2027, 1, 2))
        let override = OccurrenceOverride(scheduledDate: Self.date(2027, 1, 1), actualAmount: nil, movedDate: nil, isSkipped: true)

        let result = RecurrenceEngine.occurrences(for: expense, overrides: [override], in: range, calendar: Self.calendar)

        #expect(result.count == 2)
        #expect(result.first { $0.scheduledDate == Self.date(2027, 1, 1) }?.isSkipped == true)
        #expect(result.first { $0.scheduledDate == Self.date(2027, 1, 2) }?.isSkipped == false)
    }

    @Test func movedDateChangesEffectiveDateButNotScheduledDate() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let expense = Self.expense(rule: rule)
        let range = DateInterval(start: anchor, end: Self.date(2027, 1, 2))
        let moved = Self.date(2027, 1, 15)
        let override = OccurrenceOverride(scheduledDate: Self.date(2027, 1, 1), actualAmount: nil, movedDate: moved, isSkipped: false)

        let result = RecurrenceEngine.occurrences(for: expense, overrides: [override], in: range, calendar: Self.calendar)
        let movedOccurrence = result.first { $0.scheduledDate == Self.date(2027, 1, 1) }!

        #expect(movedOccurrence.scheduledDate == Self.date(2027, 1, 1))
        #expect(movedOccurrence.effectiveDate == moved)
    }

    @Test func movedOccurrenceSortsByEffectiveDate() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let expense = Self.expense(rule: rule)
        let range = DateInterval(start: anchor, end: Self.date(2027, 1, 3))
        // Move day 1's occurrence to after day 3, so effective order becomes 2, 3, 1.
        let override = OccurrenceOverride(scheduledDate: Self.date(2027, 1, 1), actualAmount: nil, movedDate: Self.date(2027, 1, 10), isSkipped: false)

        let result = RecurrenceEngine.occurrences(for: expense, overrides: [override], in: range, calendar: Self.calendar)

        #expect(result.map(\.scheduledDate) == [Self.date(2027, 1, 2), Self.date(2027, 1, 3), Self.date(2027, 1, 1)])
        #expect(result.map(\.effectiveDate) == [Self.date(2027, 1, 2), Self.date(2027, 1, 3), Self.date(2027, 1, 10)])
    }

    @Test func overrideMatchingNothingIsIgnored() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let expense = Self.expense(rule: rule)
        let range = DateInterval(start: anchor, end: Self.date(2027, 1, 2))
        let strayOverride = OccurrenceOverride(scheduledDate: Self.date(2027, 6, 1), actualAmount: 1, movedDate: nil, isSkipped: true)

        let result = RecurrenceEngine.occurrences(for: expense, overrides: [strayOverride], in: range, calendar: Self.calendar)

        #expect(result.count == 2)
        #expect(result.allSatisfy { !$0.isSkipped })
    }

    @Test func archivedExpenseReturnsEmptyRegardlessOfRule() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let expense = Self.expense(rule: rule, isArchived: true)
        let range = DateInterval(start: anchor, end: Self.date(2027, 1, 10))

        let result = RecurrenceEngine.occurrences(for: expense, overrides: [], in: range, calendar: Self.calendar)

        #expect(result.isEmpty)
    }

    @Test func nilAmountExpenseYieldsNilAmountOccurrences() {
        let anchor = Self.date(2027, 1, 1)
        let rule = RecurrenceRule(interval: 1, unit: .day, anchorDate: anchor)
        let expense = Self.expense(amount: nil, rule: rule)
        let range = DateInterval(start: anchor, end: Self.date(2027, 1, 2))

        let result = RecurrenceEngine.occurrences(for: expense, overrides: [], in: range, calendar: Self.calendar)

        #expect(result.allSatisfy { $0.amount == nil })
    }
}
