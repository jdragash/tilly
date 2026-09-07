import Foundation
import Testing
import TillyCore
@testable import Tilly

@Suite struct TimelineBuilderTests {
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

    /// A monthly-recurring expense anchored exactly on `date`, so within a one-month query
    /// window it produces at most one occurrence, on that date.
    static func expense(
        name: String = "Test",
        amount: Decimal? = 10,
        anchoredOn anchor: Date,
        isArchived: Bool = false,
        overrides: [OccurrenceOverride] = []
    ) -> TimelineExpense {
        let rule = RecurrenceRule(interval: 1, unit: .month, anchorDate: anchor)
        let snapshot = ExpenseSnapshot(id: UUID(), amount: amount, isEstimate: false, rule: rule, isArchived: isArchived)
        return TimelineExpense(name: name, snapshot: snapshot, overrides: overrides)
    }

    static func month(
        _ expenses: [TimelineExpense],
        key: MonthKey = thisMonth,
        today: Date = today
    ) -> MonthSection {
        TimelineBuilder.month(key, expenses: expenses, today: today, calendar: calendar)
    }

    // MARK: Shape and ordering

    @Test func aMonthWithNoExpensesHasNoDays() {
        let section = Self.month([])
        #expect(section.days.isEmpty)
        #expect(section.total == 0)
    }

    @Test func daysDescendSoTheFutureSitsAbove() {
        let expenses = [2, 15, 28].map { Self.expense(anchoredOn: Self.date(2027, 1, $0)) }
        let section = Self.month(expenses)
        #expect(section.days.map(\.date) == [28, 15, 2].map { Self.date(2027, 1, $0) })
    }

    @Test func aDayWithOneChargeIsNotGrouped() {
        let section = Self.month([Self.expense(anchoredOn: Self.date(2027, 1, 10))])
        #expect(section.days.first?.isGrouped == false)
    }

    @Test func twoChargesOnOneDayGroupWithADayTotal() {
        let day = Self.date(2027, 1, 10)
        let expenses = [
            Self.expense(name: "First", amount: 20, anchoredOn: day),
            Self.expense(name: "Second", amount: 30, anchoredOn: day)
        ]
        let section = Self.month(expenses)
        #expect(section.days.count == 1)
        let group = try! #require(section.days.first)
        #expect(group.entries.count == 2)
        #expect(group.total == 50)
    }

    @Test func entriesInADayDescendByAmount() {
        let day = Self.date(2027, 1, 10)
        let expenses = [
            Self.expense(name: "Small", amount: 3, anchoredOn: day),
            Self.expense(name: "Large", amount: 11, anchoredOn: day)
        ]
        let section = Self.month(expenses)
        let group = try! #require(section.days.first)
        #expect(group.entries.map(\.amount) == [11, 3])
    }

    @Test func entriesOfEqualAmountOrderByName() {
        let day = Self.date(2027, 1, 10)
        let expenses = [
            Self.expense(name: "Beta", amount: 20, anchoredOn: day),
            Self.expense(name: "Alpha", amount: 20, anchoredOn: day)
        ]
        let section = Self.month(expenses)
        let group = try! #require(section.days.first)
        #expect(group.entries.map(\.name) == ["Alpha", "Beta"])
    }

    @Test func anEntryWithNoAmountSortsLast() {
        let day = Self.date(2027, 1, 10)
        let expenses = [
            Self.expense(name: "No amount", amount: nil, anchoredOn: day),
            Self.expense(name: "Has amount", amount: 5, anchoredOn: day)
        ]
        let section = Self.month(expenses)
        let group = try! #require(section.days.first)
        #expect(group.entries.map(\.name) == ["Has amount", "No amount"])
    }

    // MARK: Time

    @Test func anOccurrenceDatedTodayIsCharged() {
        let section = Self.month([Self.expense(anchoredOn: Self.today)])
        #expect(section.days.first?.entries.first?.state == .charged)
    }

    @Test func anOccurrenceDatedTomorrowIsUpcoming() {
        let tomorrow = Self.date(2027, 1, 16)
        let section = Self.month([Self.expense(anchoredOn: tomorrow)])
        #expect(section.days.first?.entries.first?.state == .upcoming)
    }

    @Test func anOccurrenceDatedYesterdayIsCharged() {
        let yesterday = Self.date(2027, 1, 14)
        let section = Self.month([Self.expense(anchoredOn: yesterday)])
        #expect(section.days.first?.entries.first?.state == .charged)
    }

    @Test func aDayHeadingTakesTheDaysOwnState() {
        let futureDay = Self.date(2027, 1, 20)
        let override = OccurrenceOverride(scheduledDate: futureDay, actualAmount: nil, movedDate: nil, isSkipped: true)
        let section = Self.month([Self.expense(anchoredOn: futureDay, overrides: [override])])
        let group = try! #require(section.days.first)
        #expect(group.state == .upcoming)
        #expect(group.entries.first?.state == .skipped)
    }

    // MARK: Skipping

    @Test func aSkippedOccurrenceStaysInItsDayAndOutOfTheDayTotal() {
        let day = Self.date(2027, 1, 10)
        let skipOverride = OccurrenceOverride(scheduledDate: day, actualAmount: nil, movedDate: nil, isSkipped: true)
        let expenses = [
            Self.expense(name: "Skipped", amount: 50, anchoredOn: day, overrides: [skipOverride]),
            Self.expense(name: "Charged", amount: 30, anchoredOn: day)
        ]
        let section = Self.month(expenses)
        let group = try! #require(section.days.first)
        #expect(group.entries.count == 2)
        #expect(group.total == 30)
    }

    @Test func aSkippedOccurrenceIsOutOfTheMonthTotal() {
        let day = Self.date(2027, 1, 10)
        let override = OccurrenceOverride(scheduledDate: day, actualAmount: nil, movedDate: nil, isSkipped: true)
        let section = Self.month([Self.expense(amount: 50, anchoredOn: day, overrides: [override])])
        #expect(section.total == 0)
    }

    @Test func aSkippedOccurrenceInTheFutureIsStillSkipped() {
        let futureDay = Self.date(2027, 1, 25)
        let override = OccurrenceOverride(scheduledDate: futureDay, actualAmount: nil, movedDate: nil, isSkipped: true)
        let section = Self.month([Self.expense(anchoredOn: futureDay, overrides: [override])])
        #expect(section.days.first?.entries.first?.state == .skipped)
    }

    // MARK: Amounts

    @Test func amountsRoundToWholeUnitsBeforeTotalling() {
        let dayA = Self.date(2027, 1, 5)
        let dayB = Self.date(2027, 1, 6)
        let expenses = [
            Self.expense(amount: Decimal(string: "74.10"), anchoredOn: dayA),
            Self.expense(amount: Decimal(string: "74.60"), anchoredOn: dayB)
        ]
        let section = Self.month(expenses)
        #expect(section.days.first { $0.date == dayA }?.entries.first?.amount == 74)
        #expect(section.days.first { $0.date == dayB }?.entries.first?.amount == 75)
        #expect(section.total == 149)
    }

    @Test func anEntryWithNoAmountContributesNothingToTheTotal() {
        let section = Self.month([Self.expense(amount: nil, anchoredOn: Self.date(2027, 1, 10))])
        #expect(section.days.first?.entries.first?.amount == nil)
        #expect(section.total == 0)
    }

    @Test func aFutureMonthsRemainingEqualsItsTotal() {
        let futureDay = Self.date(2027, 1, 20)
        let section = Self.month([Self.expense(amount: 40, anchoredOn: futureDay)])
        #expect(section.remaining == section.total)
        #expect(section.remaining == 40)
    }

    @Test func aPastMonthsRemainingIsZero() {
        let pastDay = Self.date(2027, 1, 10)
        let section = Self.month([Self.expense(amount: 40, anchoredOn: pastDay)])
        #expect(section.remaining == 0)
    }

    @Test func aSkippedOccurrenceCountsTowardsNeitherFigure() {
        let futureDay = Self.date(2027, 1, 20)
        let override = OccurrenceOverride(scheduledDate: futureDay, actualAmount: nil, movedDate: nil, isSkipped: true)
        let section = Self.month([Self.expense(amount: 40, anchoredOn: futureDay, overrides: [override])])
        #expect(section.total == 0)
        #expect(section.remaining == 0)
    }

    // MARK: The neighbouring-month trap

    @Test func aBillMovedInFromThePreviousMonthAppearsInThisOne() {
        let scheduled = Self.date(2026, 12, 28)
        let moved = Self.date(2027, 1, 3)
        let override = OccurrenceOverride(scheduledDate: scheduled, actualAmount: nil, movedDate: moved, isSkipped: false)
        let section = Self.month([Self.expense(anchoredOn: scheduled, overrides: [override])])
        #expect(section.days.contains { $0.date == moved })
    }

    @Test func aBillMovedOutOfThisMonthIsAbsentFromIt() {
        let scheduled = Self.date(2027, 1, 22)
        let moved = Self.date(2027, 2, 3)
        let override = OccurrenceOverride(scheduledDate: scheduled, actualAmount: nil, movedDate: moved, isSkipped: false)
        let section = Self.month([Self.expense(anchoredOn: scheduled, overrides: [override])])
        #expect(!section.days.contains { $0.date == scheduled })
    }

    @Test func aBillMovedWithinTheMonthAppearsOnlyAtItsNewDate() {
        let scheduled = Self.date(2027, 1, 5)
        let moved = Self.date(2027, 1, 20)
        let override = OccurrenceOverride(scheduledDate: scheduled, actualAmount: nil, movedDate: moved, isSkipped: false)
        let section = Self.month([Self.expense(anchoredOn: scheduled, overrides: [override])])
        #expect(!section.days.contains { $0.date == scheduled })
        #expect(section.days.contains { $0.date == moved })
    }

    // MARK: Boundaries

    @Test func anArchivedExpenseNeverAppears() {
        let section = Self.month([Self.expense(anchoredOn: Self.date(2027, 1, 10), isArchived: true)])
        #expect(section.isEmpty)
    }

    @Test func aMonthIntervalCoversEveryDayInclusive() {
        let feb2027 = MonthKey(year: 2027, month: 2).interval(in: Self.calendar)
        #expect(feb2027.start == Self.date(2027, 2, 1))
        #expect(feb2027.end == Self.date(2027, 2, 28))

        let feb2028 = MonthKey(year: 2028, month: 2).interval(in: Self.calendar)
        #expect(feb2028.start == Self.date(2028, 2, 1))
        #expect(feb2028.end == Self.date(2028, 2, 29))
    }

    @Test func aMonthKeyAdvancesAcrossAYearBoundary() {
        #expect(MonthKey(year: 2026, month: 12).advanced(by: 1) == MonthKey(year: 2027, month: 1))
        #expect(MonthKey(year: 2027, month: 1).advanced(by: -1) == MonthKey(year: 2026, month: 12))
    }

    @Test func aMonthInThisYearIsNamedWithoutItsYear() {
        let name = MonthKey(year: 2027, month: 9).name(in: Self.calendar, relativeTo: Self.today, locale: Locale(identifier: "en_IE"))
        #expect(name == "September")
    }

    @Test func aMonthInAnotherYearCarriesItsYear() {
        let name = MonthKey(year: 2025, month: 9).name(in: Self.calendar, relativeTo: Self.today, locale: Locale(identifier: "en_IE"))
        #expect(name == "September 2025")
    }
}
