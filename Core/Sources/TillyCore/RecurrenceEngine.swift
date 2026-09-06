import Foundation

public enum RecurrenceEngine {
    /// The dates `rule` *schedules* within `range`, ascending. Bounds are compared at day
    /// granularity in `calendar` and both ends are inclusive, so a bound's time-of-day is
    /// ignored rather than silently excluding that day. All returned dates are start-of-day.
    ///
    /// This windows on scheduled dates because a rule on its own has no other date to offer.
    /// `occurrences(for:overrides:in:calendar:)` windows on *effective* dates — see "The
    /// occurrence window means effective dates" in `docs/DECISIONS.md`.
    public static func dates(
        for rule: RecurrenceRule,
        in range: DateInterval,
        calendar: Calendar
    ) -> [Date] {
        let rangeStart = calendar.startOfDay(for: range.start)
        var rangeEnd = calendar.startOfDay(for: range.end)
        if let endDate = rule.endDate {
            rangeEnd = min(rangeEnd, calendar.startOfDay(for: endDate))
        }
        guard rangeEnd >= rangeStart else { return [] }

        switch rule.unit {
        case .day, .week:
            return dayBasedDates(for: rule, from: rangeStart, through: rangeEnd, calendar: calendar)
        case .month, .year:
            return monthBasedDates(for: rule, from: rangeStart, through: rangeEnd, calendar: calendar)
        }
    }

    private static func dayBasedDates(
        for rule: RecurrenceRule,
        from rangeStart: Date,
        through rangeEnd: Date,
        calendar: Calendar
    ) -> [Date] {
        // `max(1,)` belts the clamp in `RecurrenceRule.init`: a zero step would make every
        // index yield the anchor and loop forever.
        let stepDays = (rule.unit == .week ? 7 : 1) * max(1, rule.interval)
        let anchor = calendar.startOfDay(for: rule.anchorDate)
        guard anchor <= rangeEnd else { return [] }

        let daysToRangeStart = calendar.dateComponents([.day], from: anchor, to: rangeStart).day ?? 0
        // Integer ceiling division — the `Double` form traps on a zero step.
        let startIndex = daysToRangeStart <= 0 ? 0 : (daysToRangeStart + stepDays - 1) / stepDays

        var results: [Date] = []
        var index = startIndex
        while let candidate = calendar.date(byAdding: .day, value: index * stepDays, to: anchor),
              candidate <= rangeEnd {
            if candidate >= rangeStart {
                results.append(candidate)
            }
            index += 1
        }
        return results
    }

    /// Every occurrence is the anchor's day-of-month, in the target month reached by
    /// `index * monthStep` months from the anchor, clamped to that month's last valid
    /// day. The clamp is recomputed from the anchor every time — never carried forward
    /// from the previous occurrence, which is the Dime drift bug this engine exists to
    /// avoid (see docs/DECISIONS.md).
    private static func monthBasedDates(
        for rule: RecurrenceRule,
        from rangeStart: Date,
        through rangeEnd: Date,
        calendar: Calendar
    ) -> [Date] {
        let anchor = calendar.startOfDay(for: rule.anchorDate)
        guard anchor <= rangeEnd else { return [] }

        let anchorComponents = calendar.dateComponents([.year, .month, .day], from: anchor)
        guard let anchorYear = anchorComponents.year,
              let anchorMonth = anchorComponents.month,
              let anchorDay = anchorComponents.day else { return [] }

        let anchorMonthIndex = anchorYear * 12 + (anchorMonth - 1)
        let monthStep = (rule.unit == .year ? 12 : 1) * max(1, rule.interval)

        func occurrenceDate(at index: Int) -> Date? {
            let totalMonthIndex = anchorMonthIndex + index * monthStep
            let year = totalMonthIndex.quotientAndRemainder(dividingBy: 12).quotient
            let month = totalMonthIndex.quotientAndRemainder(dividingBy: 12).remainder + 1
            guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                  let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count else {
                return nil
            }
            let day = min(anchorDay, daysInMonth)
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
                return nil
            }
            return calendar.startOfDay(for: date)
        }

        var results: [Date] = []
        var index = 0
        while let candidate = occurrenceDate(at: index), candidate <= rangeEnd {
            if candidate >= rangeStart {
                results.append(candidate)
            }
            index += 1
        }
        return results
    }
}

extension RecurrenceEngine {
    /// Rule-generated occurrences for `expense` with `overrides` applied, windowed on
    /// **effective** dates: an occurrence scheduled outside `range` but moved into it is
    /// included, and one scheduled inside but moved out is not. Bounds are compared at day
    /// granularity, both ends inclusive. Results sort by `effectiveDate`, then
    /// `scheduledDate`. See "The occurrence window means effective dates" in
    /// `docs/DECISIONS.md`.
    ///
    /// Callers must pass every override that could bear on the window, *including ones whose
    /// `scheduledDate` falls outside it* — fetching overrides with the same date predicate as
    /// the query would silently drop exactly the ones that move in.
    ///
    /// Skipped occurrences are returned, flagged; excluding them is the caller's call.
    public static func occurrences(
        for expense: ExpenseSnapshot,
        overrides: [OccurrenceOverride],
        in range: DateInterval,
        calendar: Calendar
    ) -> [Occurrence] {
        guard !expense.isArchived else { return [] }

        let windowStart = calendar.startOfDay(for: range.start)
        let windowEnd = calendar.startOfDay(for: range.end)

        let overridesByDate = Dictionary(
            overrides.map { (calendar.startOfDay(for: $0.scheduledDate), $0) },
            uniquingKeysWith: { _, latest in latest }
        )

        var scheduledDates = Set(dates(for: expense.rule, in: range, calendar: calendar))

        // Pull in occurrences scheduled outside the window but moved into it. An override
        // names the occurrence it moves, so the candidates are known exactly and no padding
        // constant is needed — but the named date has to be one the rule actually generates,
        // or a stray override would conjure an occurrence out of nothing.
        for override in overrides {
            guard let movedDate = override.movedDate else { continue }
            let moved = calendar.startOfDay(for: movedDate)
            guard moved >= windowStart, moved <= windowEnd else { continue }

            let scheduled = calendar.startOfDay(for: override.scheduledDate)
            guard !scheduledDates.contains(scheduled) else { continue }
            let oneDay = DateInterval(start: scheduled, end: scheduled)
            guard !dates(for: expense.rule, in: oneDay, calendar: calendar).isEmpty else { continue }

            scheduledDates.insert(scheduled)
        }

        return scheduledDates.map { scheduledDate -> Occurrence in
            let override = overridesByDate[scheduledDate]
            let movedTo = override?.movedDate.map { calendar.startOfDay(for: $0) }
            return Occurrence(
                expenseID: expense.id,
                scheduledDate: scheduledDate,
                effectiveDate: movedTo ?? scheduledDate,
                amount: override?.actualAmount ?? expense.amount,
                isEstimate: override?.actualAmount != nil ? false : expense.isEstimate,
                isSkipped: override?.isSkipped ?? false
            )
        }
        .filter { $0.effectiveDate >= windowStart && $0.effectiveDate <= windowEnd }
        .sorted {
            $0.effectiveDate == $1.effectiveDate
                ? $0.scheduledDate < $1.scheduledDate
                : $0.effectiveDate < $1.effectiveDate
        }
    }
}
