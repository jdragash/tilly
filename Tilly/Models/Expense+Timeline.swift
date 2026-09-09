import Foundation
import TillyCore

extension Expense {
    /// Carries `overrideSnapshots` whole — unfiltered by date, deliberately. A bill can be
    /// moved into the timeline's query window from outside it, and a date-filtered fetch
    /// would drop exactly the override that says so.
    var timelineExpense: TimelineExpense {
        TimelineExpense(name: name, snapshot: snapshot, overrides: overrideSnapshots)
    }
}
