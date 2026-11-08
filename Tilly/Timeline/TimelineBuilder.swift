import Foundation
import TillyCore

/// Reduces a set of expenses to one month's `MonthSection`, joining the engine's
/// occurrences back to their name and applying the timeline's own ordering, state and
/// totalling rules. Pure — no SwiftData, no view code — so it is tested without a
/// simulator. See `.claude/rules/core-engine.md`.
enum TimelineBuilder {
    /// With `extrasOnly`, charges that come every month are left out before anything is totalled,
    /// so `total` and `remaining` count extras alone.
    static func month(
        _ month: MonthKey,
        expenses: [TimelineExpense],
        today: Date,
        calendar: Calendar,
        extrasOnly: Bool
    ) -> MonthSection {
        let range = month.interval(in: calendar)
        let todayStart = calendar.startOfDay(for: today)

        var entries: [TimelineEntry] = []
        for expense in expenses {
            if extrasOnly && expense.snapshot.rule.chargesEveryMonth { continue }
            let occurrences = RecurrenceEngine.occurrences(
                for: expense.snapshot, overrides: expense.overrides, in: range, calendar: calendar
            )
            entries += makeEntries(occurrences, of: expense, todayStart: todayStart, calendar: calendar)
        }
        return section(month, entries: entries, extrasOnly: extrasOnly)
    }

    /// Several months in one engine pass per bill over the whole span, bucketed by month. Each
    /// section equals what `month` builds for that key; every requested month gets one, even empty.
    static func months(
        _ months: [MonthKey],
        expenses: [TimelineExpense],
        today: Date,
        calendar: Calendar,
        extrasOnly: Bool
    ) -> [MonthKey: MonthSection] {
        guard let first = months.min(), let last = months.max() else { return [:] }
        let span = DateInterval(
            start: first.interval(in: calendar).start, end: last.interval(in: calendar).end
        )
        let todayStart = calendar.startOfDay(for: today)
        let requested = Set(months)

        var buckets: [MonthKey: [TimelineEntry]] = [:]
        for expense in expenses {
            if extrasOnly && expense.snapshot.rule.chargesEveryMonth { continue }
            let occurrences = RecurrenceEngine.occurrences(
                for: expense.snapshot, overrides: expense.overrides, in: span, calendar: calendar
            )
            for entry in makeEntries(occurrences, of: expense, todayStart: todayStart, calendar: calendar) {
                let key = MonthKey(containing: entry.date, calendar: calendar)
                if requested.contains(key) { buckets[key, default: []].append(entry) }
            }
        }

        var result: [MonthKey: MonthSection] = [:]
        for key in requested {
            result[key] = section(key, entries: buckets[key] ?? [], extrasOnly: extrasOnly)
        }
        return result
    }

    private static func makeEntries(
        _ occurrences: [Occurrence], of expense: TimelineExpense, todayStart: Date, calendar: Calendar
    ) -> [TimelineEntry] {
        let isExtra = !expense.snapshot.rule.chargesEveryMonth
        let isYearly = expense.snapshot.rule.unit == .year
        let anchorDay = calendar.startOfDay(for: expense.snapshot.rule.anchorDate)
        let endDate = expense.seriesEndDate.map { calendar.startOfDay(for: $0) }
        let endHasPassed = endDate.map { $0 <= todayStart } ?? false
        return occurrences.map { occurrence in
            let day = calendar.startOfDay(for: occurrence.effectiveDate)
            let state: OccurrenceState = occurrence.isSkipped
                ? .skipped
                : (day <= todayStart ? .charged : .upcoming)
            let scheduledDay = calendar.startOfDay(for: occurrence.scheduledDate)
            return TimelineEntry(
                id: occurrence.id,
                expenseID: occurrence.expenseID,
                scheduledDate: scheduledDay,
                name: expense.name,
                picture: expense.picture,
                colour: expense.colour,
                date: day,
                amount: occurrence.amount.map(roundedToWholeUnits),
                state: state,
                endDate: endDate,
                endHasPassed: endHasPassed,
                isExtra: isExtra,
                startsRecord: scheduledDay == anchorDay,
                isYearly: isYearly
            )
        }
    }

    private static func section(_ month: MonthKey, entries unsorted: [TimelineEntry], extrasOnly: Bool) -> MonthSection {
        let entries = unsorted.sorted(by: entryOrder)
        let total = entries
            .filter { $0.state != .skipped }
            .reduce(Decimal(0)) { $0 + ($1.amount ?? 0) }
        let remaining = entries
            .filter { $0.state == .upcoming }
            .reduce(Decimal(0)) { $0 + ($1.amount ?? 0) }

        // isCurrent is never this builder's call — see the note on MonthSection.isCurrent.
        return MonthSection(
            month: month, entries: entries, total: total, remaining: remaining, isCurrent: false,
            showsExtrasOnly: extrasOnly
        )
    }

    /// Date descending so the future sits above; within a day, amount descending, ties on
    /// name ascending, a `nil` amount last.
    private static func entryOrder(_ lhs: TimelineEntry, _ rhs: TimelineEntry) -> Bool {
        if lhs.date != rhs.date { return lhs.date > rhs.date }
        return amountOrder(lhs, rhs)
    }

    static func amountOrder(_ lhs: TimelineEntry, _ rhs: TimelineEntry) -> Bool {
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

    static func roundedToWholeUnits(_ value: Decimal) -> Decimal {
        var result = Decimal()
        var input = value
        NSDecimalRound(&result, &input, 0, .plain)
        return result
    }
}
