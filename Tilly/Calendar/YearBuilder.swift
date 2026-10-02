import Foundation

/// Reduces twelve built months to the year overview: a mark for every day, a label for every
/// month, and the usual month the labels and dots are measured against. Pure, like the builders
/// it sits on, so it's tested without a simulator.
enum YearBuilder {
    /// A fifth of the usual month: what makes a month's label bold and a day's dot large. Relative,
    /// so it holds in any currency and for any size of bills (tenet 4: measured against your own).
    static let heavyShare: Decimal = 0.2

    /// `sections`: the twelve months from the current one, built with `extrasOnly: false`.
    /// `extrasOnly` changes the marks only: usual days become `.quiet`; rings stay.
    static func overview(
        sections: [MonthSection],
        categoryOf: [UUID: UUID],
        categories: [CategoryInfo],
        extrasOnly: Bool,
        today: Date,
        calendar: Calendar
    ) -> YearOverview {
        let todayStart = calendar.startOfDay(for: today)
        let laidOut = sections.map { CalendarMonthBuilder.month($0, today: today, calendar: calendar) }

        let totals = laidOut.map { month in month.days.reduce(Decimal(0)) { $0 + $1.total } }
        let extraTotals = laidOut.map { month in
            month.days.flatMap(\.entries).filter(\.isExtra).reduce(Decimal(0)) { $0 + ($1.amount ?? 0) }
        }
        let usualMonth = median(zip(totals, extraTotals).map { $0 - $1 })
        let threshold = usualMonth * heavyShare

        func colour(of entry: TimelineEntry) -> CategoryColour? {
            categoryOf[entry.expenseID].flatMap { id in categories.first { $0.id == id }?.colour }
        }

        func mark(for day: CalendarDay) -> YearMark {
            if day.date == todayStart { return .today }

            // `day.entries` is already costliest first, so "first" is the costliest.
            let extras = day.entries.filter(\.isExtra)
            if let costliest = extras.first {
                let sum = extras.reduce(Decimal(0)) { $0 + ($1.amount ?? 0) }
                return .extra(colour(of: costliest), isLarge: sum > 0 && sum >= threshold)
            }

            let usual = day.entries
            if let ringing = usual.first(where: isChange) {
                return .change(colour(of: ringing), isZero: ringing.amount == 0)
            }
            return usual.isEmpty || extrasOnly ? .quiet : .usual
        }

        let months = zip(laidOut, zip(totals, extraTotals)).map { month, sums in
            YearMonth(
                month: month.section.month,
                total: sums.0,
                extrasTotal: sums.1,
                isHeavy: sums.1 > 0 && sums.1 >= threshold,
                leadingDays: month.leadingDays,
                marks: month.days.map(mark(for:))
            )
        }

        let hasExtras = laidOut.contains { month in month.days.contains { $0.entries.contains(where: \.isExtra) } }
        return YearOverview(
            months: months,
            total: totals.reduce(0, +),
            extrasTotal: extraTotals.reduce(0, +),
            usualMonth: usualMonth,
            hasExtras: hasExtras
        )
    }

    /// A usual bill's new record (a new bill, or a price change), its last charge, or a charge of
    /// nothing. Every month in the year is the current month or later, so a record starting at all
    /// is one worth a ring.
    private static func isChange(_ entry: TimelineEntry) -> Bool {
        entry.startsRecord || entry.scheduledDate == entry.endDate || entry.amount == 0
    }

    /// The middle value, or the mean of the middle two, rounded to whole units like every amount.
    private static func median(_ values: [Decimal]) -> Decimal {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        let value = sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
        return TimelineBuilder.roundedToWholeUnits(value)
    }
}
