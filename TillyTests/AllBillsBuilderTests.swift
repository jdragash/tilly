import Foundation
import SwiftData
import Testing
import TillyCore
@testable import Tilly

@Suite struct AllBillsBuilderTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static let today = date(2027, 1, 15)

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func category(_ name: String) -> CategoryInfo {
        CategoryInfo(id: UUID(), emoji: "🏠", name: name, colour: nil)
    }

    /// One record of a bill; records sharing `series` are one bill.
    static func input(
        _ name: String = "Bill",
        series: UUID = UUID(),
        amount: Decimal? = 100,
        on anchor: Date = date(2026, 6, 10),
        every interval: Int = 1,
        _ unit: RecurrenceUnit = .month,
        endDate: Date? = nil,
        category: CategoryInfo? = nil,
        overrides: [OccurrenceOverride] = []
    ) -> BillInput {
        let id = UUID()
        let rule = RecurrenceRule(interval: interval, unit: unit, anchorDate: anchor, endDate: endDate)
        return BillInput(
            seriesKey: series, expenseID: id, name: name, categoryID: category?.id,
            snapshot: ExpenseSnapshot(id: id, amount: amount, isEstimate: false, rule: rule, isArchived: false),
            overrides: overrides
        )
    }

    static func bills(
        _ inputs: [BillInput], categories: [CategoryInfo] = [], period: BillPeriod = .month
    ) -> AllBills {
        AllBillsBuilder.bills(inputs, categories: categories, period: period, today: today, calendar: calendar)
    }

    static func rows(_ bills: AllBills) -> [BillRow] {
        bills.cards.flatMap(\.rows)
    }

    static func skip(_ scheduled: Date) -> OccurrenceOverride {
        OccurrenceOverride(scheduledDate: scheduled, actualAmount: nil, movedDate: nil, isSkipped: true)
    }

    @Test func seriesIsOneRow() {
        let series = UUID()
        let old = Self.input("Phone", series: series, amount: 30, on: Self.date(2026, 6, 10))
        let new = Self.input("Phone", series: series, amount: 35, on: Self.date(2026, 12, 10))
        let other = Self.input("Gym")
        let bills = Self.bills([old, new, other])
        #expect(Self.rows(bills).count == 2)
        #expect(Self.rows(bills).contains { $0.id == series })
    }

    @Test func latestRecordNamesTheRow() {
        let series = UUID()
        let old = Self.input("Phone", series: series, amount: 30, on: Self.date(2026, 6, 10))
        let new = Self.input("Phone Plus", series: series, amount: 35, on: Self.date(2026, 12, 10))
        let row = Self.rows(Self.bills([new, old])).first
        #expect(row?.name == "Phone Plus")
        #expect(row?.charge == 35)
        #expect(row?.state == .runs)
    }

    @Test func yearlyFigureNormalises() {
        let monthly = Self.input("Rent", amount: 100)
        let yearly = Self.input("Tax", amount: 640, every: 1, .year)
        let quarterly = Self.input("Water", amount: 41, every: 3, .month)
        let fortnightly = Self.input("Cleaner", amount: 15, every: 2, .week)
        let figures = Dictionary(
            uniqueKeysWithValues: Self.rows(Self.bills([monthly, yearly, quarterly, fortnightly], period: .year))
                .map { ($0.name, $0.figure) }
        )
        #expect(figures == ["Rent": 1200, "Tax": 640, "Water": 164, "Cleaner": 390])
    }

    @Test func monthlyFigureIsYearOverTwelve() {
        let monthly = Self.input("Rent", amount: 100)
        let yearly = Self.input("Tax", amount: 640, every: 1, .year) // 53.33
        let bimonthly = Self.input("Water", amount: 41, every: 2, .month) // 246 / 12 = 20.5
        let figures = Dictionary(
            uniqueKeysWithValues: Self.rows(Self.bills([monthly, yearly, bimonthly], period: .month))
                .map { ($0.name, $0.figure) }
        )
        #expect(figures == ["Rent": 100, "Tax": 53, "Water": 21])
    }

    @Test func totalsSumRoundedRows() {
        // Each 640 a year is 53 a month once rounded: two make 106, not the 107 of 1280 / 12.
        let home = Self.category("Home")
        let bills = Self.bills(
            [Self.input("A", amount: 640, every: 1, .year, category: home),
             Self.input("B", amount: 640, every: 1, .year, category: home)],
            categories: [home]
        )
        #expect(bills.cards.first?.total == 106)
        #expect(bills.total == 106)
    }

    @Test func cardsSortByTotal() {
        let first = Self.category("First")
        let second = Self.category("Second")
        let third = Self.category("Third")
        let bills = Self.bills(
            [Self.input("Small", amount: 10, category: first),
             Self.input("Big", amount: 500, category: second),
             Self.input("Tied", amount: 10, category: third),
             Self.input("None", amount: 10)],
            categories: [first, second, third]
        )
        // Totals descending; ties in Settings order, the uncategorised card last.
        #expect(bills.cards.map(\.category?.name) == ["Second", "First", "Third", nil])
    }

    @Test func rowsSortByFigure() {
        let home = Self.category("Home")
        let bills = Self.bills(
            [Self.input("Zed", amount: 50, category: home),
             Self.input("Unknown", amount: nil, category: home),
             Self.input("Big", amount: 900, category: home),
             Self.input("Abe", amount: 50, category: home)],
            categories: [home]
        )
        #expect(bills.cards.first?.rows.map(\.name) == ["Big", "Abe", "Zed", "Unknown"])
    }

    @Test func endedBillLeavesCards() {
        let gone = Self.input("Gym", amount: 40, endDate: Self.date(2026, 11, 10))
        let stays = Self.input("Rent", amount: 100)
        let bills = Self.bills([gone, stays])
        #expect(Self.rows(bills).map(\.name) == ["Rent"])
        #expect(bills.total == 100)
        #expect(bills.ended.map(\.name) == ["Gym"])
        #expect(bills.ended.first?.state == .ended(Self.date(2026, 11, 10)))
    }

    @Test func endedOnTodayIsEnded() {
        let bills = Self.bills([Self.input("Gym", endDate: Self.today)])
        #expect(bills.cards.isEmpty)
        #expect(bills.ended.first?.state == .ended(Self.today))
    }

    @Test func endedBillsSortByWhatTheyCostInAll() {
        let small = Self.input("Small", amount: 10, on: Self.date(2026, 10, 10), endDate: Self.date(2026, 12, 10))
        let large = Self.input("Large", amount: 100, on: Self.date(2026, 10, 10), endDate: Self.date(2026, 12, 10))
        #expect(Self.bills([small, large]).ended.map(\.name) == ["Large", "Small"])
    }

    @Test func paidInAllSkipsSkipped() {
        // Charges on 10 Oct, 10 Nov, 10 Dec and 10 Jan; November is skipped.
        let rent = Self.input(
            "Rent", amount: 100, on: Self.date(2026, 10, 10), overrides: [Self.skip(Self.date(2026, 11, 10))]
        )
        #expect(Self.rows(Self.bills([rent])).first?.paidInAll == 300)
    }

    @Test func paidInAllSumsTheWholeSeries() {
        let series = UUID()
        let old = Self.input(
            "Phone", series: series, amount: 30, on: Self.date(2026, 10, 10), endDate: Self.date(2026, 11, 9)
        )
        let new = Self.input("Phone", series: series, amount: 35, on: Self.date(2026, 12, 10))
        // 10 Oct 30; then 10 Dec and 10 Jan at 35.
        #expect(Self.rows(Self.bills([old, new])).first?.paidInAll == 100)
    }

    @Test func opensNextCharge() {
        let rent = Self.input("Rent", on: Self.date(2026, 10, 10))
        let row = Self.rows(Self.bills([rent])).first
        #expect(row?.opens == ChargeRef(expenseID: rent.expenseID, scheduledDate: Self.date(2027, 2, 10)))
    }

    @Test func opensTheNextChargeThatIsNotSkipped() {
        let rent = Self.input("Rent", on: Self.date(2026, 10, 10), overrides: [Self.skip(Self.date(2027, 2, 10))])
        let row = Self.rows(Self.bills([rent])).first
        #expect(row?.opens == ChargeRef(expenseID: rent.expenseID, scheduledDate: Self.date(2027, 3, 10)))
    }

    @Test func opensTheNextChargeOfALaterRecord() {
        let series = UUID()
        let old = Self.input("Phone", series: series, on: Self.date(2026, 6, 10), endDate: Self.date(2027, 2, 9))
        let new = Self.input("Phone", series: series, on: Self.date(2027, 3, 10))
        let row = Self.rows(Self.bills([old, new])).first
        #expect(row?.opens == ChargeRef(expenseID: new.expenseID, scheduledDate: Self.date(2027, 3, 10)))
    }

    @Test func endedOpensLastCharge() {
        let gym = Self.input("Gym", on: Self.date(2026, 6, 10), endDate: Self.date(2026, 11, 10))
        let row = Self.bills([gym]).ended.first
        #expect(row?.opens == ChargeRef(expenseID: gym.expenseID, scheduledDate: Self.date(2026, 11, 10)))
    }

    @Test func changeStateNamesOldAmount() {
        let series = UUID()
        let old = Self.input("Phone", series: series, amount: 30, on: Self.date(2026, 6, 10), endDate: Self.date(2027, 3, 9))
        let new = Self.input("Phone", series: series, amount: 35, on: Self.date(2027, 3, 10))
        let row = Self.rows(Self.bills([old, new])).first
        #expect(row?.state == .changes(Self.date(2027, 3, 10), from: 30))
        #expect(row?.charge == 35)
    }

    @Test func startsStateForFutureFirstCharge() {
        let row = Self.rows(Self.bills([Self.input("Gym", on: Self.date(2027, 2, 18))])).first
        #expect(row?.state == .starts(Self.date(2027, 2, 18)))
        #expect(row?.paidInAll == 0)
    }

    @Test func endsStateForALaterEnd() {
        let row = Self.rows(Self.bills([Self.input("Loan", endDate: Self.date(2027, 5, 10))])).first
        #expect(row?.state == .ends(Self.date(2027, 5, 10)))
    }

    @Test func nilAmountRowHasNoFigure() {
        let home = Self.category("Home")
        let bills = Self.bills(
            [Self.input("Unknown", amount: nil, category: home), Self.input("Rent", amount: 100, category: home)],
            categories: [home]
        )
        let unknown = Self.rows(bills).first { $0.name == "Unknown" }
        #expect(unknown?.figure == nil)
        #expect(unknown?.charge == nil)
        #expect(bills.cards.first?.total == 100)
    }

    @Test func aBillWithNoKnownCategoryIsUncategorised() {
        let bills = Self.bills([Self.input("Orphan", category: Self.category("Gone"))])
        #expect(bills.cards.map(\.category) == [nil])
    }

    @Test func archivedLeftOut() throws {
        let container = try TillyStore.container(inMemory: true)
        let context = ModelContext(container)
        let live = Expense(name: "Rent", amount: 100, anchorDate: Self.date(2026, 6, 10))
        let archived = Expense(name: "Old", amount: 10, isArchived: true, anchorDate: Self.date(2026, 6, 10))
        context.insert(live)
        context.insert(archived)

        let inputs = Expense.billInputs([live, archived])
        #expect(inputs.map(\.name) == ["Rent"])
        #expect(inputs.first?.expenseID == live.id)
        #expect(inputs.first?.seriesKey == live.seriesKey)
    }
}
