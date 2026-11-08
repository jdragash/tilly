import Foundation
import Testing
import TillyCore
@testable import Tilly

@Suite struct TimelineBuilderMonthsTests {
    typealias Fixture = TimelineBuilderTests
    static let calendar = Fixture.calendar
    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date { Fixture.date(year, month, day) }
    static let today = date(2027, 6, 15)

    static func keys(from start: MonthKey, count: Int) -> [MonthKey] {
        (0..<count).map { start.advanced(by: $0) }
    }

    static func override(
        _ scheduled: Date, amount: Decimal? = nil, moved: Date? = nil, skipped: Bool = false
    ) -> OccurrenceOverride {
        OccurrenceOverride(scheduledDate: scheduled, actualAmount: amount, movedDate: moved, isSkipped: skipped)
    }

    /// A spread of bills hitting every path the bucketing could get wrong.
    static func variedExpenses() -> [TimelineExpense] {
        let splitEnd = date(2027, 5, 10)
        let first = Fixture.expense(
            name: "Split", amount: 12, anchoredOn: date(2026, 9, 10), endDate: splitEnd, seriesEndDate: splitEnd
        )
        let second = Fixture.expense(
            name: "Split", amount: 18, anchoredOn: splitEnd, seriesEndDate: splitEnd
        )
        return [
            Fixture.expense(name: "Rent", amount: 900, anchoredOn: date(2026, 8, 31)),
            Fixture.expense(name: "Weekly", amount: 7, anchoredOn: date(2026, 9, 2), interval: 1, unit: .week),
            Fixture.expense(name: "Every 2 months", amount: 40, anchoredOn: date(2026, 9, 20), interval: 2),
            Fixture.expense(name: "Yearly", amount: 120, anchoredOn: date(2026, 11, 3), unit: .year),
            Fixture.expense(name: "Ending", amount: 25, anchoredOn: date(2026, 9, 5), endDate: date(2027, 3, 5)),
            first, second,
            // Moved forward across a month boundary, and backward across one.
            Fixture.expense(
                name: "Moved on", amount: 30, anchoredOn: date(2026, 9, 28),
                overrides: [override(date(2027, 1, 28), moved: date(2027, 2, 3))]
            ),
            Fixture.expense(
                name: "Moved back", amount: 31, anchoredOn: date(2026, 9, 2),
                overrides: [override(date(2027, 4, 2), moved: date(2027, 3, 29))]
            ),
            Fixture.expense(
                name: "Skipped", amount: 50, anchoredOn: date(2026, 9, 12),
                overrides: [override(date(2027, 2, 12), skipped: true)]
            ),
            Fixture.expense(
                name: "Changed", amount: 60, anchoredOn: date(2026, 9, 14),
                overrides: [override(date(2027, 5, 14), amount: 75)]
            ),
            Fixture.expense(name: "Archived", amount: 5, anchoredOn: date(2026, 9, 9), isArchived: true)
        ]
    }

    @Test func monthsMatchesMonthForEveryKey() {
        let expenses = Self.variedExpenses()
        let keys = Self.keys(from: MonthKey(year: 2026, month: 8), count: 30)
        for extrasOnly in [false, true] {
            let built = TimelineBuilder.months(
                keys, expenses: expenses, today: Self.today, calendar: Self.calendar, extrasOnly: extrasOnly
            )
            #expect(built.count == keys.count)
            for key in keys {
                let single = TimelineBuilder.month(
                    key, expenses: expenses, today: Self.today, calendar: Self.calendar, extrasOnly: extrasOnly
                )
                #expect(built[key] == single, "\(key) extrasOnly=\(extrasOnly)")
            }
        }
    }

    @Test func monthsOfNothingIsEmpty() {
        let built = TimelineBuilder.months(
            [], expenses: Self.variedExpenses(), today: Self.today, calendar: Self.calendar, extrasOnly: false
        )
        #expect(built.isEmpty)
    }

    @Test func aMonthNobodyAskedForNeverAppears() {
        // A gap between two requested months: the bills run through it, but it isn't a key.
        let requested = [MonthKey(year: 2026, month: 10), MonthKey(year: 2027, month: 2)]
        let built = TimelineBuilder.months(
            requested, expenses: Self.variedExpenses(), today: Self.today, calendar: Self.calendar,
            extrasOnly: false
        )
        #expect(Set(built.keys) == Set(requested))
    }

    @Test func fiftyBillsOverFifteenYearsBuildWithinBudget() {
        let expenses: [TimelineExpense] = (0..<50).map { index in
            let unit: RecurrenceUnit = index % 5 == 0 ? .week : (index % 7 == 0 ? .year : .month)
            return Fixture.expense(
                name: "Bill \(index)", amount: Decimal(10 + index),
                anchoredOn: Self.date(2025, 1 + index % 12, 1 + index % 28),
                interval: 1 + index % 3, unit: unit
            )
        }
        let keys = Self.keys(from: MonthKey(year: 2025, month: 1), count: 180)
        let clock = ContinuousClock()

        func best(_ work: () -> Void) -> Duration {
            (0..<5).map { _ in clock.measure(work) }.min()!
        }
        let new = best {
            _ = TimelineBuilder.months(
                keys, expenses: expenses, today: Self.today, calendar: Self.calendar, extrasOnly: false
            )
        }
        let old = best {
            for key in keys {
                _ = TimelineBuilder.month(
                    key, expenses: expenses, today: Self.today, calendar: Self.calendar, extrasOnly: false
                )
            }
        }
        // Measured 2026-11-08 in the Simulator: months 0.096s, month-per-key loop 0.159s (best of 5).
        // The budget is about 4x the new figure: it catches a gross slowdown without flaking on a slow
        // machine. It can't tell this from the old loop, which is only 1.65x slower.
        #expect(new < .seconds(0.4), "months took \(new); the loop took \(old)")
    }
}
