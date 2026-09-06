import Testing
import Foundation
@testable import TillyCore

/// The range given to `occurrences(for:overrides:in:calendar:)` selects on *effective*
/// dates — see "The occurrence window means effective dates" in `docs/DECISIONS.md`.
@Suite struct OccurrenceWindowTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    /// Monthly on the 31st: January's occurrence is the one that gets moved.
    static func expense(endDate: Date? = nil, anchor: Date = date(2027, 1, 31)) -> ExpenseSnapshot {
        ExpenseSnapshot(
            id: UUID(),
            amount: 50,
            isEstimate: false,
            rule: RecurrenceRule(interval: 1, unit: .month, anchorDate: anchor, endDate: endDate),
            isArchived: false
        )
    }

    static let january = DateInterval(start: date(2027, 1, 1), end: date(2027, 1, 31))
    static let february = DateInterval(start: date(2027, 2, 1), end: date(2027, 2, 28))

    static func movedToFeb2() -> OccurrenceOverride {
        OccurrenceOverride(
            scheduledDate: date(2027, 1, 31),
            actualAmount: nil,
            movedDate: date(2027, 2, 2),
            isSkipped: false
        )
    }

    @Test func movedIntoWindowAppears() {
        let result = RecurrenceEngine.occurrences(
            for: Self.expense(), overrides: [Self.movedToFeb2()],
            in: Self.february, calendar: Self.calendar)

        #expect(result.count == 2)
        #expect(result.first?.scheduledDate == Self.date(2027, 1, 31))
        #expect(result.first?.effectiveDate == Self.date(2027, 2, 2))
        #expect(result.last?.scheduledDate == Self.date(2027, 2, 28))
    }

    @Test func movedOutOfWindowDisappears() {
        let result = RecurrenceEngine.occurrences(
            for: Self.expense(), overrides: [Self.movedToFeb2()],
            in: Self.january, calendar: Self.calendar)

        #expect(result.isEmpty)
    }

    @Test func movedOccurrenceAppearsInExactlyOneOfTwoAdjacentWindows() {
        let expense = Self.expense()
        let overrides = [Self.movedToFeb2()]
        let engine = RecurrenceEngine.self

        let jan = engine.occurrences(for: expense, overrides: overrides, in: Self.january, calendar: Self.calendar)
        let feb = engine.occurrences(for: expense, overrides: overrides, in: Self.february, calendar: Self.calendar)
        let whole = engine.occurrences(
            for: expense, overrides: overrides,
            in: DateInterval(start: Self.date(2027, 1, 1), end: Self.date(2027, 2, 28)),
            calendar: Self.calendar)

        // Paging month by month must neither drop the payment nor show it twice.
        #expect(jan + feb == whole)
        #expect(whole.filter { $0.scheduledDate == Self.date(2027, 1, 31) }.count == 1)
    }

    @Test func strayOverrideWithMovedDateInWindowIsNotConjured() {
        // The 15th is not an occurrence of a rule anchored on the 31st.
        let stray = OccurrenceOverride(
            scheduledDate: Self.date(2027, 1, 15), actualAmount: 999,
            movedDate: Self.date(2027, 2, 10), isSkipped: false)

        let result = RecurrenceEngine.occurrences(
            for: Self.expense(), overrides: [stray], in: Self.february, calendar: Self.calendar)

        #expect(result.count == 1)
        #expect(result.first?.scheduledDate == Self.date(2027, 2, 28))
    }

    @Test func overrideBeforeAnchorIsNotPulledIn() {
        let expense = Self.expense(anchor: Self.date(2027, 3, 31))
        let tooEarly = OccurrenceOverride(
            scheduledDate: Self.date(2027, 2, 28), actualAmount: nil,
            movedDate: Self.date(2027, 4, 10), isSkipped: false)
        let april = DateInterval(start: Self.date(2027, 4, 1), end: Self.date(2027, 4, 30))

        let result = RecurrenceEngine.occurrences(
            for: expense, overrides: [tooEarly], in: april, calendar: Self.calendar)

        #expect(result.count == 1)
        #expect(result.first?.scheduledDate == Self.date(2027, 4, 30))
    }

    @Test func overrideAfterEndDateIsNotPulledIn() {
        // The rule would generate 30 Apr, but it ends in March.
        let expense = Self.expense(endDate: Self.date(2027, 3, 31))
        let tooLate = OccurrenceOverride(
            scheduledDate: Self.date(2027, 4, 30), actualAmount: nil,
            movedDate: Self.date(2027, 4, 15), isSkipped: false)
        let april = DateInterval(start: Self.date(2027, 4, 1), end: Self.date(2027, 4, 30))

        let result = RecurrenceEngine.occurrences(
            for: expense, overrides: [tooLate], in: april, calendar: Self.calendar)

        #expect(result.isEmpty)
    }

    @Test func moveWithinWindowChangesDateNotMembership() {
        let expense = Self.expense(anchor: Self.date(2027, 2, 2))
        let within = OccurrenceOverride(
            scheduledDate: Self.date(2027, 2, 2), actualAmount: nil,
            movedDate: Self.date(2027, 2, 20), isSkipped: false)

        let plain = RecurrenceEngine.occurrences(
            for: expense, overrides: [], in: Self.february, calendar: Self.calendar)
        let moved = RecurrenceEngine.occurrences(
            for: expense, overrides: [within], in: Self.february, calendar: Self.calendar)

        #expect(plain.count == moved.count)
        #expect(moved.first?.scheduledDate == Self.date(2027, 2, 2))
        #expect(moved.first?.effectiveDate == Self.date(2027, 2, 20))
    }
}
