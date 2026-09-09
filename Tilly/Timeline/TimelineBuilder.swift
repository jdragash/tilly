import Foundation
import TillyCore

/// Reduces a set of expenses to one month's `MonthSection`, joining the engine's
/// occurrences back to their name and applying the timeline's own ordering, state and
/// totalling rules. Pure — no SwiftData, no view code — so it is tested without a
/// simulator. See "How month paging maps onto the engine" in `docs/plans/timeline.md`.
enum TimelineBuilder {
    static func month(
        _ month: MonthKey,
        expenses: [TimelineExpense],
        today: Date,
        calendar: Calendar
    ) -> MonthSection {
        let range = month.interval(in: calendar)
        let todayStart = calendar.startOfDay(for: today)

        var entriesByDay: [Date: [TimelineEntry]] = [:]
        for expense in expenses {
            let occurrences = RecurrenceEngine.occurrences(
                for: expense.snapshot,
                overrides: expense.overrides,
                in: range,
                calendar: calendar
            )
            for occurrence in occurrences {
                let day = calendar.startOfDay(for: occurrence.effectiveDate)
                let state: OccurrenceState = occurrence.isSkipped
                    ? .skipped
                    : (day <= todayStart ? .charged : .upcoming)
                let entry = TimelineEntry(
                    id: occurrence.id,
                    name: expense.name,
                    date: day,
                    amount: occurrence.amount.map(roundedToWholeUnits),
                    state: state
                )
                entriesByDay[day, default: []].append(entry)
            }
        }

        let days = entriesByDay
            .map { day, entries in dayGroup(on: day, entries: entries, todayStart: todayStart) }
            .sorted { $0.date > $1.date }

        let total = days.reduce(Decimal(0)) { $0 + $1.total }
        let remaining = days
            .flatMap(\.entries)
            .filter { $0.state == .upcoming }
            .reduce(Decimal(0)) { $0 + ($1.amount ?? 0) }

        // isCurrent is never this builder's call — see the note on MonthSection.isCurrent.
        return MonthSection(month: month, days: days, total: total, remaining: remaining, isCurrent: false)
    }

    private static func dayGroup(on day: Date, entries: [TimelineEntry], todayStart: Date) -> DayGroup {
        let sortedEntries = entries.sorted(by: entryOrder)
        let total = sortedEntries
            .filter { $0.state != .skipped }
            .reduce(Decimal(0)) { $0 + ($1.amount ?? 0) }
        let state: OccurrenceState = day <= todayStart ? .charged : .upcoming
        return DayGroup(date: day, entries: sortedEntries, total: total, state: state)
    }

    /// Descending by amount; ties break on name, ascending; a `nil` amount sorts last.
    private static func entryOrder(_ lhs: TimelineEntry, _ rhs: TimelineEntry) -> Bool {
        switch (lhs.amount, rhs.amount) {
        case let (lhsAmount?, rhsAmount?):
            return lhsAmount == rhsAmount ? lhs.name < rhs.name : lhsAmount > rhsAmount
        case (nil, nil):
            return lhs.name < rhs.name
        case (nil, _):
            return false
        case (_, nil):
            return true
        }
    }

    private static func roundedToWholeUnits(_ value: Decimal) -> Decimal {
        var result = Decimal()
        var input = value
        NSDecimalRound(&result, &input, 0, .plain)
        return result
    }
}
