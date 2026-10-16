import Foundation
import TillyCore

/// Reduces every bill to rows, the rows to category cards, and each bill to one figure per
/// period, so a bill that comes every two months and one that comes weekly can be read side by
/// side. Pure, so it's tested without a simulator. See `.claude/rules/core-engine.md`.
enum AllBillsBuilder {
    static func bills(
        _ inputs: [BillInput],
        categories: [CategoryInfo],
        period: BillPeriod,
        today: Date,
        calendar: Calendar
    ) -> AllBills {
        let todayStart = calendar.startOfDay(for: today)
        let rows = Dictionary(grouping: inputs, by: \.seriesKey).values.map {
            row(for: $0, period: period, today: todayStart, calendar: calendar)
        }

        let running = rows.filter { !isEnded($0.state) }
        let ended = rows
            .filter { isEnded($0.state) }
            .sorted { lhs, rhs in
                lhs.paidInAll == rhs.paidInAll ? lhs.name < rhs.name : lhs.paidInAll > rhs.paidInAll
            }

        // A category id that no longer names a category reads as none.
        let known = Set(categories.map(\.id))
        let byCategory = Dictionary(grouping: running) { row in row.categoryID.flatMap { known.contains($0) ? $0 : nil } }
        var cards = categories.compactMap { category in
            byCategory[category.id].map { card(category, $0) }
        }
        if let uncategorised = byCategory[nil] {
            cards.append(card(nil, uncategorised))
        }
        // `sorted` isn't stable, so ties keep Settings order explicitly: `cards` is in that order,
        // with the uncategorised card last.
        let order = Dictionary(uniqueKeysWithValues: cards.enumerated().map { ($1.id, $0) })
        cards.sort { lhs, rhs in
            lhs.total == rhs.total ? order[lhs.id]! < order[rhs.id]! : lhs.total > rhs.total
        }

        return AllBills(cards: cards, ended: ended, total: cards.reduce(Decimal(0)) { $0 + $1.total })
    }

    private static func isEnded(_ state: BillState) -> Bool {
        if case .ended = state { return true }
        return false
    }

    private static func card(_ category: CategoryInfo?, _ rows: [BillRow]) -> BillCard {
        let sorted = rows.sorted { lhs, rhs in
            switch (lhs.figure, rhs.figure) {
            case let (lhsFigure?, rhsFigure?):
                return lhsFigure == rhsFigure ? lhs.name < rhs.name : lhsFigure > rhsFigure
            case (nil, nil): return lhs.name < rhs.name
            case (nil, _): return false
            case (_, nil): return true
            }
        }
        return BillCard(category: category, rows: sorted, total: rows.reduce(Decimal(0)) { $0 + ($1.figure ?? 0) })
    }

    // MARK: Rows

    private static func row(for records: [BillInput], period: BillPeriod, today: Date, calendar: Calendar) -> BillRow {
        let ordered = records.sorted { $0.snapshot.rule.anchorDate < $1.snapshot.rule.anchorDate }
        let latest = ordered[ordered.count - 1]
        let rule = latest.snapshot.rule
        let charge = latest.snapshot.amount

        let past = ordered.map { pastOccurrences(of: $0, through: today, calendar: calendar) }
        let paid = past.joined()
            .filter { !$0.isSkipped }
            .reduce(Decimal(0)) { $0 + ($1.amount.map(TimelineBuilder.roundedToWholeUnits) ?? 0) }

        let next = ordered
            .compactMap { nextCharge(of: $0, after: today, calendar: calendar) }
            .min { ($0.effectiveDate, $0.scheduledDate) < ($1.effectiveDate, $1.scheduledDate) }
        let last = past.joined()
            .filter { !$0.isSkipped }
            .max { ($0.effectiveDate, $0.scheduledDate) < ($1.effectiveDate, $1.scheduledDate) }
        let opens = (next ?? last).map { ChargeRef(expenseID: $0.expenseID, scheduledDate: $0.scheduledDate) }

        return BillRow(
            id: latest.seriesKey,
            name: latest.name,
            categoryID: latest.categoryID,
            charge: charge,
            rule: rule,
            figure: figure(charge, rule: rule, period: period),
            state: state(of: ordered, today: today, calendar: calendar),
            paidInAll: paid,
            opens: opens
        )
    }

    /// Yearly is the charge times how often it comes, rounded; monthly is that over twelve,
    /// rounded again. Each row is rounded before anything is totalled.
    private static func figure(_ charge: Decimal?, rule: RecurrenceRule, period: BillPeriod) -> Decimal? {
        guard let charge else { return nil }
        let yearly = TimelineBuilder.roundedToWholeUnits(charge * rule.paymentsPerYear)
        switch period {
        case .year: return yearly
        case .month: return TimelineBuilder.roundedToWholeUnits(yearly / 12)
        }
    }

    /// First match wins: over; a later record still to come; not begun; ending; running.
    /// The series' end is its latest record's.
    private static func state(of ordered: [BillInput], today: Date, calendar: Calendar) -> BillState {
        let latest = ordered[ordered.count - 1].snapshot.rule
        let latestAnchor = calendar.startOfDay(for: latest.anchorDate)
        let end = latest.endDate.map { calendar.startOfDay(for: $0) }

        if let end, end <= today { return .ended(end) }
        if ordered.count > 1, latestAnchor > today {
            return .changes(latestAnchor, from: ordered[ordered.count - 2].snapshot.amount)
        }
        let firstAnchor = calendar.startOfDay(for: ordered[0].snapshot.rule.anchorDate)
        if firstAnchor > today { return .starts(firstAnchor) }
        if let end { return .ends(end) }
        return .runs
    }

    // MARK: Charges

    /// Every occurrence from the record's anchor through today, by effective date.
    private static func pastOccurrences(of record: BillInput, through today: Date, calendar: Calendar) -> [Occurrence] {
        let anchor = calendar.startOfDay(for: record.snapshot.rule.anchorDate)
        guard anchor <= today else { return [] }
        return RecurrenceEngine.occurrences(
            for: record.snapshot, overrides: record.overrides,
            in: DateInterval(start: anchor, end: today), calendar: calendar
        )
    }

    /// The record's first charge after `today` that isn't skipped, found in one window of
    /// `2 × overrides + 2` rule periods. A skipped charge is an override, and so is one moved out
    /// of its place, so that many periods always reach past them to a charge that counts. The
    /// engine stops at the record's end and windows on effective dates by itself.
    private static func nextCharge(of record: BillInput, after today: Date, calendar: Calendar) -> Occurrence? {
        let rule = record.snapshot.rule
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let start = max(tomorrow, calendar.startOfDay(for: rule.anchorDate))
        let span = period(of: rule)
        let periods = 2 * record.overrides.count + 2
        let after = calendar.date(byAdding: span.component, value: span.value * periods, to: start)!
        let end = calendar.date(byAdding: .day, value: -1, to: after)!
        return RecurrenceEngine.occurrences(
            for: record.snapshot, overrides: record.overrides,
            in: DateInterval(start: start, end: end), calendar: calendar
        )
        .first { !$0.isSkipped }
    }

    private static func period(of rule: RecurrenceRule) -> (component: Calendar.Component, value: Int) {
        switch rule.unit {
        case .day: (.day, rule.interval)
        case .week: (.day, rule.interval * 7)
        case .month: (.month, rule.interval)
        case .year: (.year, rule.interval)
        }
    }
}
