import Foundation

public enum RecurrenceEngine {
    /// Occurrence dates for `rule` falling within `range`, ascending.
    /// Both bounds of `range` are inclusive. All dates are start-of-day in `calendar`.
    public static func dates(
        for rule: RecurrenceRule,
        in range: DateInterval,
        calendar: Calendar
    ) -> [Date] {
        var effectiveRange = range
        if let endDate = rule.endDate {
            let clampedEnd = min(range.end, endDate)
            guard clampedEnd >= range.start else { return [] }
            effectiveRange = DateInterval(start: range.start, end: clampedEnd)
        }

        switch rule.unit {
        case .day, .week:
            return dayBasedDates(for: rule, in: effectiveRange, calendar: calendar)
        case .month, .year:
            return monthBasedDates(for: rule, in: effectiveRange, calendar: calendar)
        }
    }

    private static func dayBasedDates(
        for rule: RecurrenceRule,
        in range: DateInterval,
        calendar: Calendar
    ) -> [Date] {
        let stepDays = rule.unit == .week ? rule.interval * 7 : rule.interval
        let anchor = calendar.startOfDay(for: rule.anchorDate)

        guard anchor <= range.end else { return [] }

        let daysFromAnchorToRangeStart = calendar.dateComponents([.day], from: anchor, to: range.start).day ?? 0
        let startIndex: Int
        if daysFromAnchorToRangeStart <= 0 {
            startIndex = 0
        } else {
            startIndex = Int(ceil(Double(daysFromAnchorToRangeStart) / Double(stepDays)))
        }

        var results: [Date] = []
        var index = startIndex
        while let candidate = calendar.date(byAdding: .day, value: index * stepDays, to: anchor),
              candidate <= range.end {
            if candidate >= range.start {
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
        in range: DateInterval,
        calendar: Calendar
    ) -> [Date] {
        let anchor = calendar.startOfDay(for: rule.anchorDate)
        guard anchor <= range.end else { return [] }

        let anchorComponents = calendar.dateComponents([.year, .month, .day], from: anchor)
        guard let anchorYear = anchorComponents.year,
              let anchorMonth = anchorComponents.month,
              let anchorDay = anchorComponents.day else { return [] }

        let anchorMonthIndex = anchorYear * 12 + (anchorMonth - 1)
        let monthStep = rule.unit == .year ? rule.interval * 12 : rule.interval

        func occurrenceDate(at index: Int) -> Date? {
            let totalMonthIndex = anchorMonthIndex + index * monthStep
            let year = totalMonthIndex.quotientAndRemainder(dividingBy: 12).quotient
            let month = totalMonthIndex.quotientAndRemainder(dividingBy: 12).remainder + 1
            guard let firstOfMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                  let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count else {
                return nil
            }
            let day = min(anchorDay, daysInMonth)
            return calendar.date(from: DateComponents(year: year, month: month, day: day))
        }

        var results: [Date] = []
        var index = 0
        while let candidate = occurrenceDate(at: index), candidate <= range.end {
            if candidate >= range.start {
                results.append(candidate)
            }
            index += 1
        }
        return results
    }
}

extension RecurrenceEngine {
    /// Rule-generated occurrences for `expense`, with `overrides` applied. Overrides
    /// match on `scheduledDate` (start-of-day in `calendar`); one matching nothing is
    /// ignored, not an error. Results sort by `effectiveDate`.
    public static func occurrences(
        for expense: ExpenseSnapshot,
        overrides: [OccurrenceOverride],
        in range: DateInterval,
        calendar: Calendar
    ) -> [Occurrence] {
        guard !expense.isArchived else { return [] }

        let overridesByDate = Dictionary(
            overrides.map { (calendar.startOfDay(for: $0.scheduledDate), $0) },
            uniquingKeysWith: { _, latest in latest }
        )

        let scheduledDates = dates(for: expense.rule, in: range, calendar: calendar)
        let unsorted = scheduledDates.map { scheduledDate -> Occurrence in
            let override = overridesByDate[scheduledDate]
            return Occurrence(
                expenseID: expense.id,
                scheduledDate: scheduledDate,
                effectiveDate: override?.movedDate ?? scheduledDate,
                amount: override?.actualAmount ?? expense.amount,
                isEstimate: override?.actualAmount != nil ? false : expense.isEstimate,
                isSkipped: override?.isSkipped ?? false
            )
        }
        return unsorted.sorted { $0.effectiveDate < $1.effectiveDate }
    }
}
