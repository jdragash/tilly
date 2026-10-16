import Foundation
import Testing
import TillyCore
@testable import Tilly

@Suite struct YearBuilderTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static let today = date(2027, 1, 15)
    static let thisMonth = MonthKey(year: 2027, month: 1)

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func category(_ name: String, _ colour: CategoryColour?) -> CategoryInfo {
        CategoryInfo(id: UUID(), emoji: "🏠", name: name, colour: colour)
    }

    struct Bill {
        let expense: TimelineExpense
        let category: CategoryInfo?
    }

    /// A bill repeating every `interval` `unit`s from `anchor`. Its series ends when it does, unless
    /// `seriesRunsOn`: the record stops but a later one in the same series carries on.
    static func bill(
        _ name: String = "Bill",
        amount: Decimal? = 10,
        on anchor: Date,
        every interval: Int = 1,
        _ unit: RecurrenceUnit = .month,
        endDate: Date? = nil,
        seriesRunsOn: Bool = false,
        category: CategoryInfo? = nil
    ) -> Bill {
        let rule = RecurrenceRule(interval: interval, unit: unit, anchorDate: anchor, endDate: endDate)
        let snapshot = ExpenseSnapshot(id: UUID(), amount: amount, isEstimate: false, rule: rule, isArchived: false)
        return Bill(
            expense: TimelineExpense(
                name: name, emoji: nil, snapshot: snapshot, overrides: [], seriesEndDate: seriesRunsOn ? nil : endDate
            ),
            category: category
        )
    }

    /// A yearly bill, so an extra, on the given month and day of an earlier year.
    static func extra(
        _ name: String = "Extra", amount: Decimal, month: Int, day: Int, category: CategoryInfo? = nil
    ) -> Bill {
        bill(name, amount: amount, on: date(2026, month, day), every: 1, .year, category: category)
    }

    static func overview(
        _ bills: [Bill], categories: [CategoryInfo] = [], extrasOnly: Bool = false
    ) -> YearOverview {
        var categoryOf: [UUID: UUID] = [:]
        for bill in bills {
            if let category = bill.category { categoryOf[bill.expense.snapshot.id] = category.id }
        }
        let sections = (0..<12).map { offset in
            TimelineBuilder.month(
                thisMonth.advanced(by: offset), expenses: bills.map(\.expense),
                today: today, calendar: calendar, extrasOnly: false
            )
        }
        return YearBuilder.overview(
            sections: sections, categoryOf: categoryOf, categories: categories,
            extrasOnly: extrasOnly, today: today, calendar: calendar
        )
    }

    /// The mark for a day of the month `offset` months after the current one.
    static func mark(_ overview: YearOverview, month offset: Int, day: Int) -> YearMark {
        overview.months[offset].marks[day - 1]
    }

    @Test func twelveMonthsFromCurrent() {
        let overview = Self.overview([])
        #expect(overview.months.count == 12)
        #expect(overview.months.first?.month == Self.thisMonth)
        #expect(overview.months.last?.month == MonthKey(year: 2027, month: 12))
        #expect(overview.months[0].marks.count == 31)
        #expect(overview.months[1].marks.count == 28)
        // 1 January 2027 is a Friday; the calendar's firstWeekday is Sunday.
        #expect(overview.months[0].leadingDays == 5)
    }

    @Test func usualMonthIsMedian() {
        // Rent runs all year; a second bill ends after June. Six months at 100 and six at 151:
        // the mean of the middle two is 125.5, rounded to whole units.
        let rent = Self.bill("Rent", amount: 100, on: Self.date(2026, 12, 3))
        let gym = Self.bill("Gym", amount: 51, on: Self.date(2026, 12, 5), endDate: Self.date(2027, 6, 5))
        let overview = Self.overview([rent, gym])
        #expect(overview.usualMonth == 126)
    }

    @Test func steadyUserHasNoExtrasAndUsualDots() {
        let rent = Self.bill("Rent", amount: 950, on: Self.date(2026, 12, 3))
        let overview = Self.overview([rent])
        #expect(!overview.hasExtras)
        #expect(overview.extrasTotal == 0)
        #expect(overview.total == Decimal(11400))
        #expect(overview.usualMonth == 950)
        #expect(overview.months.allSatisfy { !$0.isHeavy && $0.extrasTotal == 0 && $0.total == 950 })
        #expect(Self.mark(overview, month: 1, day: 3) == .usual)
        #expect(Self.mark(overview, month: 1, day: 4) == .quiet)
    }

    @Test func extraTakesCostliestColour() {
        let blue = Self.category("Fun", .blue)
        let red = Self.category("Travel", .red)
        let small = Self.extra("Magazine", amount: 40, month: 3, day: 10, category: blue)
        let big = Self.extra("Flights", amount: 300, month: 3, day: 10, category: red)
        let overview = Self.overview([small, big], categories: [blue, red])
        #expect(overview.hasExtras)
        #expect(Self.mark(overview, month: 2, day: 10) == .extra(.red, isLarge: true))
    }

    @Test func anExtraWithNoCategoryHasNoColour() {
        let overview = Self.overview([Self.extra(amount: 300, month: 3, day: 10)])
        #expect(Self.mark(overview, month: 2, day: 10) == .extra(nil, isLarge: true))
    }

    @Test func largeExtraAtHeavyShare() {
        // A usual month of 1000: a fifth is 200.
        let rent = Self.bill("Rent", amount: 1000, on: Self.date(2026, 12, 1))
        let atShare = Self.extra("Tax", amount: 200, month: 3, day: 10)
        let underShare = Self.extra("Fee", amount: 199, month: 4, day: 10)
        let overview = Self.overview([rent, atShare, underShare])
        #expect(Self.mark(overview, month: 2, day: 10) == .extra(nil, isLarge: true))
        #expect(Self.mark(overview, month: 3, day: 10) == .extra(nil, isLarge: false))
    }

    @Test func monthIsHeavyAtShare() {
        let rent = Self.bill("Rent", amount: 1000, on: Self.date(2026, 12, 1))
        let atShare = Self.extra("Tax", amount: 200, month: 3, day: 10)
        let underShare = Self.extra("Fee", amount: 199, month: 4, day: 10)
        let overview = Self.overview([rent, atShare, underShare])
        #expect(overview.months[2].isHeavy)
        #expect(!overview.months[3].isHeavy)
        #expect(overview.months[2].extrasTotal == 200)
        #expect(overview.extrasTotal == 399)
    }

    @Test func emptyMonthIsNotHeavy() {
        let overview = Self.overview([])
        #expect(overview.usualMonth == 0)
        #expect(overview.months.allSatisfy { !$0.isHeavy })
        #expect(!overview.hasExtras)
    }

    @Test func ringOnPriceChange() {
        // A "future charges" edit: the old record stops on 10 February, a new one starts on 10 March.
        // Both belong to one series that runs on, so neither reads as the bill ending.
        let old = Self.bill("Phone", amount: 30, on: Self.date(2026, 6, 10), endDate: Self.date(2027, 2, 10), seriesRunsOn: true)
        let new = Self.bill("Phone", amount: 35, on: Self.date(2027, 3, 10))
        let overview = Self.overview([old, new])
        #expect(Self.mark(overview, month: 1, day: 10) == .usual) // the old record's last charge
        #expect(Self.mark(overview, month: 2, day: 10) == .change(nil, isZero: false))
        #expect(Self.mark(overview, month: 3, day: 10) == .usual)
    }

    @Test func ringOnLastCharge() {
        let loan = Self.bill("Loan", amount: 120, on: Self.date(2026, 6, 10), endDate: Self.date(2027, 4, 10))
        let overview = Self.overview([loan])
        #expect(Self.mark(overview, month: 2, day: 10) == .usual)
        #expect(Self.mark(overview, month: 3, day: 10) == .change(nil, isZero: false))
        #expect(overview.months[4].total == 0)
    }

    @Test func dashedRingOnZero() {
        let free = Self.bill("Trial", amount: 0, on: Self.date(2026, 12, 10), category: Self.category("Apps", .green))
        let overview = Self.overview([free], categories: [free.category!])
        #expect(Self.mark(overview, month: 1, day: 10) == .change(.green, isZero: true))
    }

    @Test func extrasOnlyQuietsUsualDays() {
        let rent = Self.bill("Rent", amount: 950, on: Self.date(2026, 12, 3))
        let newBill = Self.bill("Gym", amount: 40, on: Self.date(2027, 2, 20))
        let tax = Self.extra("Tax", amount: 300, month: 3, day: 10)
        let all = Self.overview([rent, newBill, tax])
        let extras = Self.overview([rent, newBill, tax], extrasOnly: true)
        #expect(Self.mark(all, month: 1, day: 3) == .usual)
        #expect(Self.mark(extras, month: 1, day: 3) == .quiet)
        #expect(Self.mark(extras, month: 1, day: 20) == .change(nil, isZero: false))
        #expect(Self.mark(extras, month: 2, day: 10) == .extra(nil, isLarge: true))
        // The figures are the same either way: only the marks change.
        #expect(extras.total == all.total)
        #expect(extras.usualMonth == all.usualMonth)
    }

    @Test func todayWins() {
        let rent = Self.bill("Rent", amount: 950, on: Self.date(2026, 12, 15))
        let tax = Self.extra("Tax", amount: 300, month: 1, day: 15)
        let overview = Self.overview([rent, tax])
        #expect(Self.mark(overview, month: 0, day: 15) == .today)
        #expect(Self.mark(overview, month: 1, day: 15) == .usual)
    }

    @Test func skippedChargesMarkNothingAndCountTowardNothing() {
        let skipped = OccurrenceOverride(
            scheduledDate: Self.date(2027, 3, 10), actualAmount: nil, movedDate: nil, isSkipped: true
        )
        var tax = Self.extra("Tax", amount: 300, month: 3, day: 10)
        tax = Bill(
            expense: TimelineExpense(
                name: "Tax", emoji: nil, snapshot: tax.expense.snapshot, overrides: [skipped], seriesEndDate: nil
            ),
            category: nil
        )
        let overview = Self.overview([tax])
        #expect(Self.mark(overview, month: 2, day: 10) == .quiet)
        #expect(overview.months[2].total == 0)
        #expect(!overview.hasExtras)
    }
}
