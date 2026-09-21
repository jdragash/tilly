import Foundation
import TillyCore

/// Where the months ahead stop. See "The future runs five years ahead, or to your last payment" in
/// `docs/DESIGN.md`.
enum TimelineCeiling {
    /// The month of the last payment when every expense has an end, never before
    /// `current + 1`; `current + monthsAhead` when any expense runs on. `nil` with no
    /// expenses. Archived expenses are left out, as they are from the floor: the engine
    /// never generates an occurrence for one.
    static func month(for expenses: [Expense], current: MonthKey, calendar: Calendar) -> MonthKey? {
        let live = expenses.filter { !$0.isArchived }
        guard !live.isEmpty else { return nil }
        let nextMonth = current.advanced(by: 1)
        guard live.allSatisfy({ $0.endDate != nil }) else {
            return current.advanced(by: TimelineWindow.monthsAhead)
        }
        let last = live.compactMap { lastPayment(of: $0, calendar: calendar) }.max()
        guard let last else { return nextMonth }
        return max(MonthKey(containing: last, calendar: calendar), nextMonth)
    }

    /// True when the ceiling is a real last payment, so the list says so.
    static func isLastPayment(_ ceiling: MonthKey, for expenses: [Expense], current: MonthKey, calendar: Calendar) -> Bool {
        let live = expenses.filter { !$0.isArchived }
        return !live.isEmpty
            && live.allSatisfy { $0.endDate != nil }
            && month(for: expenses, current: current, calendar: calendar) == ceiling
    }

    /// The last date an ended expense is charged: the last date its rule generates on or
    /// before its end, or later if an override moved one of those payments later. `nil` when
    /// it runs on, or ends before it starts.
    private static func lastPayment(of expense: Expense, calendar: Calendar) -> Date? {
        guard let endDate = expense.endDate else { return nil }
        let start = calendar.startOfDay(for: expense.anchorDate)
        let end = calendar.startOfDay(for: endDate)
        guard end >= start else { return nil }
        let scheduled = RecurrenceEngine.dates(for: expense.rule, in: DateInterval(start: start, end: end), calendar: calendar)
        let moved = (expense.overrides ?? []).compactMap { override -> Date? in
            guard let movedDate = override.movedDate,
                  calendar.startOfDay(for: override.scheduledDate) <= end else { return nil }
            return calendar.startOfDay(for: movedDate)
        }
        return (scheduled + moved).max()
    }
}
