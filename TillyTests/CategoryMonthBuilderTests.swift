import Foundation
import Testing
import TillyCore
@testable import Tilly

@Suite struct CategoryMonthBuilderTests {
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

    static func category(_ name: String, _ emoji: String = "🏠") -> CategoryInfo {
        CategoryInfo(id: UUID(), emoji: emoji, name: name, colour: nil)
    }

    /// A bill in `category` (none when nil), repeating every `interval` `unit` from `anchor`.
    struct Bill {
        let expense: TimelineExpense
        let category: CategoryInfo?
    }

    static func bill(
        _ category: CategoryInfo?,
        amount: Decimal? = 10,
        on anchor: Date,
        every interval: Int = 1,
        _ unit: RecurrenceUnit = .month,
        endDate: Date? = nil,
        overrides: [OccurrenceOverride] = [],
        name: String = "Bill"
    ) -> Bill {
        let rule = RecurrenceRule(interval: interval, unit: unit, anchorDate: anchor, endDate: endDate)
        let snapshot = ExpenseSnapshot(id: UUID(), amount: amount, isEstimate: false, rule: rule, isArchived: false)
        return Bill(
            expense: TimelineExpense(name: name, emoji: category?.emoji, snapshot: snapshot, overrides: overrides, seriesEndDate: endDate),
            category: category
        )
    }

    static func month(
        _ bills: [Bill],
        categories: [CategoryInfo],
        key: MonthKey = thisMonth,
        isCurrent: Bool = true
    ) -> CategoryMonth {
        var categoryOf: [UUID: UUID] = [:]
        for bill in bills {
            if let category = bill.category { categoryOf[bill.expense.snapshot.id] = category.id }
        }
        return CategoryMonthBuilder.month(
            key, expenses: bills.map(\.expense), categoryOf: categoryOf,
            categories: categories, today: today, calendar: calendar, isCurrent: isCurrent
        )
    }

    static func skip(_ date: Date) -> OccurrenceOverride {
        OccurrenceOverride(scheduledDate: date, actualAmount: nil, movedDate: nil, isSkipped: true)
    }

    // MARK: Lanes

    @Test func lanesFollowSettingsOrderNotSize() {
        let small = Self.category("Small")
        let large = Self.category("Large")
        let bills = [
            Self.bill(small, amount: 10, on: Self.date(2027, 1, 3)),
            Self.bill(large, amount: 500, on: Self.date(2027, 1, 5)),
        ]
        #expect(Self.month(bills, categories: [small, large]).lanes.map(\.category) == [small, large])
        #expect(Self.month(bills, categories: [large, small]).lanes.map(\.category) == [large, small])
    }

    @Test func laneTotalEqualsItsDots() throws {
        let home = Self.category("Home")
        let bills = [
            Self.bill(home, amount: 10, on: Self.date(2027, 1, 3)),
            Self.bill(home, amount: 25, on: Self.date(2027, 1, 20)),
        ]
        let lane = try #require(Self.month(bills, categories: [home]).lanes.first)
        #expect(lane.total == 35)
        #expect(lane.total == lane.dots.reduce(Decimal(0)) { $0 + ($1.entry.amount ?? 0) })
    }

    @Test func laneTotalsSumToTheMonthTotal() {
        let home = Self.category("Home")
        let car = Self.category("Car")
        let bills = [
            Self.bill(home, amount: 950, on: Self.date(2027, 1, 1)),
            Self.bill(home, amount: 68, on: Self.date(2027, 1, 8)),
            Self.bill(car, amount: 120, on: Self.date(2027, 1, 20)),
            Self.bill(nil, amount: 13, on: Self.date(2027, 1, 22)),
            Self.bill(car, amount: 40, on: Self.date(2027, 1, 9), overrides: [Self.skip(Self.date(2027, 1, 9))]),
        ]
        let month = Self.month(bills, categories: [home, car])
        #expect(month.lanes.reduce(Decimal(0)) { $0 + $1.total } == month.section.total)
        #expect(month.section.total == 1151)
    }

    @Test func aCategoryWithNothingThisMonthIsQuietWithItsNextDate() throws {
        let books = Self.category("Books", "📗")
        let bills = [Self.bill(books, on: Self.date(2026, 11, 3), every: 3, .month)]
        let month = Self.month(bills, categories: [books])
        #expect(month.lanes.isEmpty)
        let quiet = try #require(month.quiet.first)
        #expect(quiet.category == books)
        #expect(quiet.next == Self.date(2027, 2, 3))
    }

    @Test func aQuietCategoryWithNoFutureChargeHasNoNext() throws {
        let gym = Self.category("Gym")
        let bills = [Self.bill(gym, on: Self.date(2026, 6, 1), endDate: Self.date(2026, 10, 1))]
        let month = Self.month(bills, categories: [gym])
        let quiet = try #require(month.quiet.first)
        #expect(quiet.category == gym)
        #expect(quiet.next == nil)
    }

    @Test func aCategoryWithNoBillsAtAllIsLeftOut() {
        let home = Self.category("Home")
        let unused = Self.category("Unused")
        let month = Self.month([Self.bill(home, on: Self.date(2027, 1, 3))], categories: [home, unused])
        #expect(month.lanes.map(\.category) == [home])
        #expect(month.quiet.isEmpty)
    }

    @Test func uncategorisedChargesFormTheLastLane() {
        let home = Self.category("Home")
        let car = Self.category("Car")
        let bills = [
            Self.bill(nil, amount: 999, on: Self.date(2027, 1, 2)),
            Self.bill(home, on: Self.date(2027, 1, 3)),
            Self.bill(car, on: Self.date(2027, 1, 4)),
        ]
        let lanes = Self.month(bills, categories: [home, car]).lanes
        #expect(lanes.map(\.category) == [home, car, nil])
        #expect(lanes.last?.id == "uncategorised")
    }

    @Test func skippedChargesAreNeitherDotsNorTotalled() throws {
        let home = Self.category("Home")
        let streaming = Self.category("Streaming")
        let bills = [
            Self.bill(home, amount: 10, on: Self.date(2027, 1, 5)),
            Self.bill(home, amount: 40, on: Self.date(2027, 1, 9), overrides: [Self.skip(Self.date(2027, 1, 9))]),
            Self.bill(streaming, amount: 13, on: Self.date(2027, 1, 1), overrides: [Self.skip(Self.date(2027, 1, 1))]),
        ]
        let month = Self.month(bills, categories: [home, streaming])
        let lane = try #require(month.lanes.first)
        #expect(month.lanes.count == 1)
        #expect(lane.dots.map(\.day) == [5])
        #expect(lane.total == 10)
        // Its only charge this month skipped, a category is quiet until the next one.
        #expect(month.quiet.map(\.category) == [streaming])
        #expect(month.quiet.first?.next == Self.date(2027, 2, 1))
    }

    @Test func aZeroChargeIsADotAndAddsNothing() throws {
        let home = Self.category("Home")
        let bills = [
            Self.bill(home, amount: 0, on: Self.date(2027, 1, 5)),
            Self.bill(home, amount: 30, on: Self.date(2027, 1, 7)),
        ]
        let lane = try #require(Self.month(bills, categories: [home]).lanes.first)
        #expect(lane.dots.map(\.day) == [5, 7])
        #expect(lane.total == 30)
    }

    @Test func twoChargesOnOneDayAreTwoDotsLargestFirst() throws {
        let home = Self.category("Home")
        let bills = [
            Self.bill(home, amount: 10, on: Self.date(2027, 1, 20)),
            Self.bill(home, amount: 50, on: Self.date(2027, 1, 20)),
            Self.bill(home, amount: 5, on: Self.date(2027, 1, 2)),
        ]
        let lane = try #require(Self.month(bills, categories: [home]).lanes.first)
        #expect(lane.dots.map(\.day) == [2, 20, 20])
        #expect(lane.dots.map(\.entry.amount) == [5, 50, 10])
    }

    @Test func aMovedChargeSitsOnItsNewDay() throws {
        let home = Self.category("Home")
        let moved = OccurrenceOverride(
            scheduledDate: Self.date(2027, 1, 3), actualAmount: nil, movedDate: Self.date(2027, 1, 20), isSkipped: false
        )
        let bills = [Self.bill(home, on: Self.date(2027, 1, 3), overrides: [moved])]
        let lane = try #require(Self.month(bills, categories: [home]).lanes.first)
        #expect(lane.dots.map(\.day) == [20])
    }

    @Test func dotScaleIsTheLargestAmountEverNotThisMonths() {
        let home = Self.category("Home")
        let raised = OccurrenceOverride(
            scheduledDate: Self.date(2027, 6, 3), actualAmount: 400, movedDate: nil, isSkipped: false
        )
        let bills = [
            Self.bill(home, amount: 100, on: Self.date(2027, 1, 3), overrides: [raised]),
            Self.bill(home, amount: 250, on: Self.date(2027, 3, 9), every: 1, .year),
        ]
        #expect(Self.month(bills, categories: [home]).dotScale == 400)
        #expect(Self.month(bills, categories: [home], key: MonthKey(year: 2027, month: 4), isCurrent: false).dotScale == 400)
    }

    // MARK: Next

    @Test func nextIsTheThreeSoonestAtMostOnePerCategory() {
        let home = Self.category("Home")
        let car = Self.category("Car")
        let phone = Self.category("Phone")
        let gym = Self.category("Gym")
        let bills = [
            Self.bill(home, on: Self.date(2026, 12, 18)),
            Self.bill(home, on: Self.date(2026, 12, 19)),
            Self.bill(car, on: Self.date(2026, 12, 25)),
            Self.bill(phone, on: Self.date(2027, 2, 2), every: 1, .year),
            Self.bill(gym, on: Self.date(2027, 3, 1), every: 1, .year),
        ]
        let next = Self.month(bills, categories: [home, car, phone, gym]).next
        #expect(next.map(\.category) == [home, car, phone])
        #expect(next.map(\.entry.date) == [Self.date(2027, 1, 18), Self.date(2027, 1, 25), Self.date(2027, 2, 2)])
    }

    @Test func nextStartsTomorrowNotToday() {
        let home = Self.category("Home")
        let car = Self.category("Car")
        let bills = [
            Self.bill(home, on: Self.date(2026, 12, 15)),
            Self.bill(car, on: Self.date(2026, 12, 16)),
        ]
        let next = Self.month(bills, categories: [home, car]).next
        #expect(next.map(\.entry.date) == [Self.date(2027, 1, 16), Self.date(2027, 2, 15)])
    }

    @Test func nextReachesAYearlyBillElevenMonthsOut() {
        let insurance = Self.category("Insurance")
        let bills = [Self.bill(insurance, on: Self.date(2026, 12, 10), every: 1, .year)]
        let next = Self.month(bills, categories: [insurance]).next
        #expect(next.map(\.entry.date) == [Self.date(2027, 12, 10)])
    }

    @Test func nextIsEmptyForOtherMonths() {
        let home = Self.category("Home")
        let bills = [Self.bill(home, on: Self.date(2026, 12, 20))]
        let month = Self.month(bills, categories: [home], key: MonthKey(year: 2027, month: 2), isCurrent: false)
        #expect(month.next.isEmpty)
        #expect(!month.lanes.isEmpty)
    }
}
