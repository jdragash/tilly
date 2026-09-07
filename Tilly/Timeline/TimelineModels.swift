import Foundation
import TillyCore

/// A row's temporal state, carried by weight per `DESIGN.md`'s state grammar: upcoming
/// sits back, charged comes forward, skipped withdraws further still. The grammar's second
/// axis — certainty — is deferred with the `EST` mark; see the 2026-09-07 update in
/// `docs/plans/timeline.md`.
enum OccurrenceState: Equatable, Sendable {
    case upcoming, charged, skipped
}

struct TimelineEntry: Identifiable, Equatable, Sendable {
    let id: String // Occurrence.id — stable across launches
    let name: String
    let date: Date // effectiveDate, start of day
    let amount: Decimal? // already rounded to whole units
    let state: OccurrenceState
}

struct DayGroup: Identifiable, Equatable, Sendable {
    let date: Date // start of day
    let entries: [TimelineEntry]
    let total: Decimal // excludes skipped entries
    let state: OccurrenceState // .charged or .upcoming — the day's own temporal state

    var id: Date { date }
    var isGrouped: Bool { entries.count > 1 }
}

struct MonthSection: Identifiable, Equatable, Sendable {
    let month: MonthKey
    let days: [DayGroup] // descending by date: the future sits above
    let total: Decimal // excludes skipped entries

    var id: Int { month.id }
    var isEmpty: Bool { days.isEmpty }
    var hasChargedEntry: Bool {
        days.contains { day in day.entries.contains { $0.state == .charged } }
    }
}

/// One expense reduced to what the timeline needs, so the builder is pure and testable
/// without SwiftData.
struct TimelineExpense: Equatable, Sendable {
    let name: String
    let snapshot: ExpenseSnapshot
    let overrides: [OccurrenceOverride]
}
