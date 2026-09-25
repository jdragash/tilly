import Foundation
import TillyCore

/// Reduces a set of expenses to one month of lanes. Built on `TimelineBuilder.month`, so rounding,
/// state and the effective date are the timeline's own. Pure, so it's tested without a simulator.
enum CategoryMonthBuilder {
    /// How far ahead `next` and `QuietCategory.next` look.
    static let lookAheadMonths = 13

    /// `categories` in Settings order. `categoryOf` maps an expense's snapshot id to its category.
    static func month(
        _ month: MonthKey,
        expenses: [TimelineExpense],
        categoryOf: [UUID: UUID],
        categories: [CategoryInfo],
        today: Date,
        calendar: Calendar,
        isCurrent: Bool
    ) -> CategoryMonth {
        let built = TimelineBuilder.month(month, expenses: expenses, today: today, calendar: calendar)
        let section = MonthSection(
            month: built.month, entries: built.entries, total: built.total, remaining: built.remaining, isCurrent: isCurrent
        )
        let known = Set(categories.map(\.id))
        // A category id that no longer names a category reads as none.
        func categoryID(of entry: TimelineEntry) -> UUID? {
            categoryOf[entry.expenseID].flatMap { known.contains($0) ? $0 : nil }
        }

        let charged = section.entries.filter { $0.state != .skipped }
        let byCategory = Dictionary(grouping: charged, by: categoryID(of:))

        var lanes = categories.compactMap { category in
            byCategory[category.id].map { lane(category, $0, calendar: calendar) }
        }
        if let uncategorised = byCategory[nil] {
            lanes.append(lane(nil, uncategorised, calendar: calendar))
        }

        // Charges from the day after this month to the look-ahead's end, soonest first.
        let monthEnd = month.interval(in: calendar).end
        let after = upcoming(
            expenses, from: calendar.date(byAdding: .day, value: 1, to: monthEnd)!,
            today: today, calendar: calendar
        )
        let categoriesWithBills = Set(expenses.compactMap { categoryOf[$0.snapshot.id] })
        let quiet = categories
            .filter { categoriesWithBills.contains($0.id) && byCategory[$0.id] == nil }
            .map { category in
                QuietCategory(category: category, next: after.first { categoryID(of: $0) == category.id }?.date)
            }

        var next: [NextCharge] = []
        if isCurrent {
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today))!
            var seen: Set<UUID?> = []
            for entry in upcoming(expenses, from: tomorrow, today: today, calendar: calendar) {
                let id = categoryID(of: entry)
                guard !seen.contains(id) else { continue }
                seen.insert(id)
                next.append(NextCharge(entry: entry, category: categories.first { $0.id == id }))
                if next.count == 3 { break }
            }
        }

        return CategoryMonth(section: section, lanes: lanes, quiet: quiet, next: next, dotScale: dotScale(expenses))
    }

    private static func lane(_ category: CategoryInfo?, _ entries: [TimelineEntry], calendar: Calendar) -> CategoryLane {
        let dots = entries
            .map { LaneDot(entry: $0, day: calendar.component(.day, from: $0.date)) }
            .sorted { lhs, rhs in
                if lhs.day != rhs.day { return lhs.day < rhs.day }
                return (lhs.entry.amount ?? -1) > (rhs.entry.amount ?? -1)
            }
        let total = dots.reduce(Decimal(0)) { $0 + ($1.entry.amount ?? 0) }
        return CategoryLane(category: category, dots: dots, total: total)
    }

    /// Every charge that isn't skipped, from `start` through `lookAheadMonths` months past today's
    /// month, soonest first; a day's by amount descending.
    private static func upcoming(_ expenses: [TimelineExpense], from start: Date, today: Date, calendar: Calendar) -> [TimelineEntry] {
        let first = MonthKey(containing: start, calendar: calendar)
        let last = MonthKey(containing: today, calendar: calendar).advanced(by: lookAheadMonths)
        guard first <= last else { return [] }
        var entries: [TimelineEntry] = []
        var key = first
        while key <= last {
            entries += TimelineBuilder.month(key, expenses: expenses, today: today, calendar: calendar).entries
            key = key.advanced(by: 1)
        }
        return entries
            .filter { $0.state != .skipped && $0.date >= start }
            .sorted { lhs, rhs in
                if lhs.date != rhs.date { return lhs.date < rhs.date }
                return (lhs.amount ?? -1) > (rhs.amount ?? -1)
            }
    }

    /// The largest amount any rule or override sets, rounded as the timeline rounds.
    private static func dotScale(_ expenses: [TimelineExpense]) -> Decimal {
        let amounts = expenses.flatMap { expense in
            [expense.snapshot.amount] + expense.overrides.map(\.actualAmount)
        }
        let largest = amounts.compactMap { $0 }.max() ?? 0
        var result = Decimal()
        var input = largest
        NSDecimalRound(&result, &input, 0, .plain)
        return result
    }
}
