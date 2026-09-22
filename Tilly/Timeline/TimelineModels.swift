import Foundation
import TillyCore

/// A row's temporal state, carried by weight per `DESIGN.md`'s state grammar: upcoming
/// sits back, charged comes forward, skipped withdraws further still. The grammar's second
/// axis — certainty — is not rendered in v1; it returns with variable bills.
enum OccurrenceState: Equatable, Sendable {
    case upcoming, charged, skipped
}

struct TimelineEntry: Identifiable, Equatable, Sendable {
    let id: String // Occurrence.id — stable across launches
    let expenseID: UUID
    let scheduledDate: Date // the rule's date, start of day; `date` stays the effective one
    let name: String
    let emoji: String? // the category's; nil only for data saved before categories existed
    let date: Date // effectiveDate, start of day
    let amount: Decimal? // already rounded to whole units
    let state: OccurrenceState
    let endDate: Date? // the series' end, start of day; nil when it runs on
    let endHasPassed: Bool // endDate is today or earlier
}

struct MonthSection: Identifiable, Equatable, Sendable {
    let month: MonthKey
    /// Descending by date so the future sits above; a day's charges by amount descending,
    /// ties by name ascending, a `nil` amount last.
    let entries: [TimelineEntry]
    let total: Decimal // excludes skipped entries
    let remaining: Decimal // sum of .upcoming entries only; excludes skipped

    /// Whether this is the month `today` falls in. Not derived here from a `today` the
    /// builder happens to have — it's a question about the screen's anchor, so whoever
    /// assembles sections for display sets it explicitly. No default: a forgotten flag would
    /// silently render the current month as a plain total, the one figure this design is
    /// about, so every call site is made to state it.
    let isCurrent: Bool

    init(month: MonthKey, entries: [TimelineEntry], total: Decimal, remaining: Decimal, isCurrent: Bool) {
        self.month = month
        self.entries = entries
        self.total = total
        self.remaining = remaining
        self.isCurrent = isCurrent
    }

    var id: Int { month.id }
    var isEmpty: Bool { entries.isEmpty }
    var hasChargedEntry: Bool {
        entries.contains { $0.state == .charged }
    }
}

/// One expense reduced to what the timeline needs, so the builder is pure and testable
/// without SwiftData.
struct TimelineExpense: Equatable, Sendable {
    let name: String
    let emoji: String? // nil only for data saved before categories existed
    let snapshot: ExpenseSnapshot
    let overrides: [OccurrenceOverride]
    /// The end of the latest-anchored record sharing this expense's series; nil when that
    /// record runs on. A bill split by "future charges" reads its whole series' end, not its
    /// own record's.
    let seriesEndDate: Date?
}
