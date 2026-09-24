import Foundation
import SwiftData
import Testing
import TillyCore
@testable import Tilly

@Suite struct ModelLayerTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func makeContext() throws -> ModelContext {
        let container = try TillyStore.container(inMemory: true)
        return ModelContext(container)
    }

    @Test func defaultInitialisedExpenseInsertsAndFetches() throws {
        let context = try Self.makeContext()
        context.insert(Expense())
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Expense>())
        #expect(fetched.count == 1)
    }

    @Test func expenseRoundTripsEveryField() throws {
        let context = try Self.makeContext()
        let anchor = Self.date(2027, 3, 15)
        let end = Self.date(2027, 12, 31)
        let expense = Expense(
            name: "Rent",
            amount: 1500,
            isEstimate: true,
            isArchived: true,
            recurrenceInterval: 3,
            recurrenceUnit: .year,
            anchorDate: anchor,
            endDate: end
        )
        context.insert(expense)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Expense>()).first)
        #expect(fetched.name == "Rent")
        #expect(fetched.amount == 1500)
        #expect(fetched.isEstimate == true)
        #expect(fetched.isArchived == true)
        #expect(fetched.recurrenceInterval == 3)
        #expect(fetched.recurrenceUnit == .year)
        #expect(fetched.anchorDate == anchor)
        #expect(fetched.endDate == end)
    }

    @Test func amountOfNilStaysNil() throws {
        let context = try Self.makeContext()
        context.insert(Expense(name: "Variable bill", amount: nil))
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Expense>()).first)
        #expect(fetched.amount == nil)
    }

    @Test func snapshotCarriesTheStoredRule() throws {
        let context = try Self.makeContext()
        let anchor = Self.date(2027, 6, 1)
        let end = Self.date(2028, 6, 1)
        let expense = Expense(
            recurrenceInterval: 3,
            recurrenceUnit: .month,
            anchorDate: anchor,
            endDate: end
        )
        context.insert(expense)
        try context.save()

        #expect(expense.snapshot.rule == RecurrenceRule(interval: 3, unit: .month, anchorDate: anchor, endDate: end))
    }

    @Test func unrecognisedUnitFallsBackToMonthRatherThanVanishing() throws {
        let context = try Self.makeContext()
        let expense = Expense()
        expense.recurrenceUnitRaw = "fortnight"
        context.insert(expense)
        try context.save()

        #expect(expense.snapshot.rule.unit == .month)
        let fetched = try context.fetch(FetchDescriptor<Expense>())
        #expect(fetched.count == 1)
    }

    @Test func zeroIntervalClampsThroughToTheRule() throws {
        let context = try Self.makeContext()
        let expense = Expense(recurrenceInterval: 0)
        context.insert(expense)
        try context.save()

        #expect(expense.snapshot.rule.interval == 1)
    }

    @Test func overrideSnapshotsIncludeOnesScheduledOutsideAnyWindow() throws {
        let context = try Self.makeContext()
        let expense = Expense(recurrenceUnit: .month, anchorDate: Self.date(2027, 1, 1))
        context.insert(expense)

        let dates = [Self.date(2027, 1, 1), Self.date(2027, 6, 1), Self.date(2027, 12, 1)]
        for scheduled in dates {
            context.insert(OverrideRecord(scheduledDate: scheduled, expense: expense))
        }
        try context.save()

        let snapshots = expense.overrideSnapshots
        #expect(snapshots.count == 3)
        #expect(Set(snapshots.map(\.scheduledDate)) == Set(dates))
    }

    @Test func expenseWithNoOverridesGivesAnEmptyArrayNotNil() throws {
        let context = try Self.makeContext()
        let expense = Expense()
        context.insert(expense)
        try context.save()

        #expect(expense.overrideSnapshots.isEmpty)
    }

    @Test func deletingAnExpenseDeletesItsOverrides() throws {
        let context = try Self.makeContext()
        let expense = Expense()
        context.insert(expense)
        context.insert(OverrideRecord(scheduledDate: Self.date(2027, 1, 1), expense: expense))
        try context.save()

        context.delete(expense)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<OverrideRecord>())
        #expect(remaining.isEmpty)
    }

    @Test func storedDataDrivesTheEngineEndToEnd() throws {
        let context = try Self.makeContext()
        let anchor = Self.date(2027, 1, 31)
        let expense = Expense(amount: 100, recurrenceUnit: .month, anchorDate: anchor)
        context.insert(expense)
        context.insert(OverrideRecord(
            scheduledDate: Self.date(2027, 1, 31),
            movedDate: Self.date(2027, 2, 2),
            expense: expense
        ))
        try context.save()

        let range = DateInterval(start: Self.date(2027, 2, 1), end: Self.date(2027, 2, 28))
        let occurrences = RecurrenceEngine.occurrences(
            for: expense.snapshot,
            overrides: expense.overrideSnapshots,
            in: range,
            calendar: Self.calendar
        )

        let moved = try #require(occurrences.first { $0.scheduledDate == Self.date(2027, 1, 31) })
        #expect(moved.effectiveDate == Self.date(2027, 2, 2))

        #expect(occurrences.contains { $0.scheduledDate == Self.date(2027, 2, 28) })
        #expect(occurrences.count == 2)
    }

    // MARK: Categories

    @Test func aCategoryRoundTripsItsNameAndEmoji() throws {
        let context = try Self.makeContext()
        context.insert(ExpenseCategory(name: "Streaming", emoji: "📺"))
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<ExpenseCategory>()).first)
        #expect(fetched.name == "Streaming")
        #expect(fetched.emoji == "📺")
    }

    @Test func categoryDefaultsToNoColourAndOrderZero() throws {
        let context = try Self.makeContext()
        context.insert(ExpenseCategory(name: "Home", emoji: "🏠"))
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<ExpenseCategory>()).first)
        #expect(fetched.colourRaw == "")
        #expect(fetched.colour == nil)
        #expect(fetched.sortOrder == 0)
    }

    @Test func anExpenseKeepsItsCategory() throws {
        let context = try Self.makeContext()
        let category = ExpenseCategory(name: "Home", emoji: "🏠")
        context.insert(category)
        context.insert(Expense(name: "Rent", category: category))
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Expense>()).first)
        #expect(fetched.category?.id == category.id)
        #expect(category.expenses?.count == 1)
    }

    @Test func deletingACategoryLeavesItsExpensesWithNone() throws {
        let context = try Self.makeContext()
        let category = ExpenseCategory(name: "Home", emoji: "🏠")
        context.insert(category)
        context.insert(Expense(name: "Rent", category: category))
        try context.save()

        context.delete(category)
        try context.save()

        let expenses = try context.fetch(FetchDescriptor<Expense>())
        #expect(expenses.count == 1)
        #expect(expenses.first?.category == nil)
    }

    @Test func theTimelineExpenseCarriesTheCategoryEmoji() throws {
        let context = try Self.makeContext()
        let category = ExpenseCategory(name: "Home", emoji: "🏠")
        let expense = Expense(name: "Rent", category: category)
        context.insert(category)
        context.insert(expense)
        try context.save()

        #expect(expense.timelineExpense.emoji == "🏠")
    }

    @Test func anExpenseWithNoCategoryHasNoEmoji() throws {
        let context = try Self.makeContext()
        let expense = Expense(name: "Rent")
        context.insert(expense)
        try context.save()

        #expect(expense.timelineExpense.emoji == nil)
    }

    // MARK: Series

    @Test func seriesIDDefaultsToNil() throws {
        let context = try Self.makeContext()
        let expense = Expense(name: "Rent")
        context.insert(expense)
        try context.save()

        #expect(expense.seriesID == nil)
    }

    @Test func seriesKeyFallsBackToID() throws {
        let context = try Self.makeContext()
        let expense = Expense(name: "Rent")
        context.insert(expense)
        try context.save()

        #expect(expense.seriesKey == expense.id)
    }

    @Test func seriesIDRoundTrips() throws {
        let context = try Self.makeContext()
        let series = UUID()
        let expense = Expense(name: "Rent", seriesID: series)
        context.insert(expense)
        try context.save()

        let fetched = try #require(try context.fetch(FetchDescriptor<Expense>()).first)
        #expect(fetched.seriesID == series)
        #expect(fetched.seriesKey == series)
    }

    @Test func timelineExpensesCarryTheSeriesEnd() throws {
        let context = try Self.makeContext()
        let series = UUID()
        let earlier = Expense(
            name: "Gym", anchorDate: Self.date(2026, 1, 1), endDate: Self.date(2026, 6, 1), seriesID: series
        )
        let later = Expense(name: "Gym", anchorDate: Self.date(2026, 6, 1), endDate: nil, seriesID: series)
        context.insert(earlier)
        context.insert(later)
        try context.save()

        let timelineExpenses = Expense.timelineExpenses([earlier, later])
        #expect(timelineExpenses.allSatisfy { $0.seriesEndDate == nil })
    }

    @Test func aSeriesEndingLaterCarriesTheLaterEnd() throws {
        let context = try Self.makeContext()
        let series = UUID()
        let earlier = Expense(
            name: "Gym", anchorDate: Self.date(2026, 1, 1), endDate: Self.date(2026, 6, 1), seriesID: series
        )
        let later = Expense(
            name: "Gym", anchorDate: Self.date(2026, 6, 1), endDate: Self.date(2027, 3, 1), seriesID: series
        )
        context.insert(earlier)
        context.insert(later)
        try context.save()

        let timelineExpenses = Expense.timelineExpenses([earlier, later])
        #expect(timelineExpenses.allSatisfy { $0.seriesEndDate == Self.date(2027, 3, 1) })
    }

    @Test func separateSeriesKeepTheirOwnEnds() throws {
        let context = try Self.makeContext()
        let gym = Expense(name: "Gym", anchorDate: Self.date(2026, 1, 1), endDate: Self.date(2026, 6, 1))
        let rent = Expense(name: "Rent", anchorDate: Self.date(2026, 1, 1), endDate: nil)
        context.insert(gym)
        context.insert(rent)
        try context.save()

        let timelineExpenses = Expense.timelineExpenses([gym, rent])
        #expect(timelineExpenses.first { $0.name == "Gym" }?.seriesEndDate == Self.date(2026, 6, 1))
        #expect(timelineExpenses.first { $0.name == "Rent" }?.seriesEndDate == nil)
    }
}
