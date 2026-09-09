import Foundation

/// Where history stops. See "History begins at the oldest charge you have entered" in
/// `docs/DECISIONS.md`.
enum TimelineFloor {
    /// The oldest month any occurrence can land in: the earliest anchor across all
    /// non-archived expenses, and any override whose `movedDate` is earlier still. `nil`
    /// when there are no expenses that could ever generate one — the caller shows the
    /// empty state instead. Archived expenses are excluded because the engine never
    /// generates an occurrence for one; counting their anchors would push the floor below
    /// anything the list could actually show.
    static func month(for expenses: [Expense], calendar: Calendar) -> MonthKey? {
        var earliest: Date?
        for expense in expenses where !expense.isArchived {
            if earliest == nil || expense.anchorDate < earliest! {
                earliest = expense.anchorDate
            }
            for override in expense.overrides ?? [] {
                guard let moved = override.movedDate else { continue }
                if earliest == nil || moved < earliest! {
                    earliest = moved
                }
            }
        }
        guard let earliest else { return nil }
        return MonthKey(containing: earliest, calendar: calendar)
    }
}
