import Foundation
import TillyCore

extension Expense {
    /// Carries `overrideSnapshots` whole — unfiltered by date, deliberately. A bill can be
    /// moved into the timeline's query window from outside it, and a date-filtered fetch
    /// would drop exactly the override that says so.
    ///
    /// Only this record's own end: a caller with the whole series available should use
    /// `timelineExpenses(_:)` instead, which carries the series' end.
    var timelineExpense: TimelineExpense {
        TimelineExpense(
            name: name, emoji: category?.emoji, snapshot: snapshot, overrides: overrideSnapshots,
            seriesEndDate: endDate
        )
    }

    /// One `TimelineExpense` per record, each carrying its series' end: the end of the
    /// latest-anchored record sharing its `seriesKey`, nil when that record runs on. A bill
    /// split into a later record by "future charges" reads its whole series' end this way,
    /// not the open record's own.
    static func timelineExpenses(_ expenses: [Expense]) -> [TimelineExpense] {
        let series = Dictionary(grouping: expenses, by: \.seriesKey)
        let seriesEnds: [UUID: Date?] = series.mapValues { records in
            records.max(by: { $0.anchorDate < $1.anchorDate })?.endDate ?? nil
        }
        return expenses.map { expense in
            TimelineExpense(
                name: expense.name, emoji: expense.category?.emoji, snapshot: expense.snapshot,
                overrides: expense.overrideSnapshots, seriesEndDate: seriesEnds[expense.seriesKey] ?? nil
            )
        }
    }

    /// Each expense's snapshot id to its category's id, for `CategoryMonthBuilder`. An expense
    /// with no category is left out.
    static func categoryMap(_ expenses: [Expense]) -> [UUID: UUID] {
        var map: [UUID: UUID] = [:]
        for expense in expenses {
            if let category = expense.category { map[expense.snapshot.id] = category.id }
        }
        return map
    }
}
