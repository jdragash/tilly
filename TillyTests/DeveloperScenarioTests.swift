import Foundation
import SwiftData
import Testing
@testable import Tilly

@Suite struct DeveloperScenarioTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static let today = calendar.date(from: DateComponents(year: 2026, month: 9, day: 19))!
    static let currentMonth = MonthKey(containing: today, calendar: calendar)

    /// Seeds `scenario` into a fresh in-memory store and returns what it holds.
    static func seeded(_ scenario: DeveloperScenario) throws -> (expenses: [Expense], categories: [ExpenseCategory]) {
        let context = ModelContext(try TillyStore.container(inMemory: true))
        try scenario.seed(into: context, today: today, calendar: calendar)
        return (try context.fetch(FetchDescriptor<Expense>()), try context.fetch(FetchDescriptor<ExpenseCategory>()))
    }

    @Test func emptyInsertsNothing() throws {
        let (expenses, categories) = try Self.seeded(.empty)
        #expect(expenses.isEmpty)
        #expect(categories.isEmpty)
    }

    @Test func yourDataInsertsNothing() throws {
        let (expenses, categories) = try Self.seeded(.yourData)
        #expect(expenses.isEmpty)
        #expect(categories.isEmpty)
    }

    @Test func oneExpenseInsertsOneOfEach() throws {
        let (expenses, categories) = try Self.seeded(.oneExpense)
        #expect(expenses.count == 1)
        #expect(categories.count == 1)
        #expect(expenses.first?.anchorDate == Self.today)
    }

    @Test func typicalYearMatchesPreviewData() throws {
        let (expenses, categories) = try Self.seeded(.typicalYear)
        #expect(expenses.count == 9)
        #expect(categories.count == 6)
        #expect(TimelineFloor.month(for: expenses, calendar: Self.calendar) == Self.currentMonth.advanced(by: -9))
    }

    @Test func longHistoryReachesBackThreeYears() throws {
        let (expenses, _) = try Self.seeded(.longHistory)
        #expect(expenses.count == 9)
        #expect(TimelineFloor.month(for: expenses, calendar: Self.calendar) == Self.currentMonth.advanced(by: -39))
    }

    @Test func nothingChargedYetHasNoChargedEntryThisMonth() throws {
        let (expenses, _) = try Self.seeded(.nothingChargedYet)
        #expect(expenses.count == 2)
        let built = TimelineBuilder.month(
            Self.currentMonth, expenses: expenses.map(\.timelineExpense), today: Self.today, calendar: Self.calendar
        )
        let section = MonthSection(
            month: built.month, entries: built.entries, total: built.total, remaining: built.remaining, isCurrent: true
        )
        #expect(!section.entries.isEmpty)
        #expect(!section.hasChargedEntry)
    }

    @Test func titlesAreInOrder() {
        #expect(DeveloperScenario.allCases.map(\.title) == [
            "Your data", "Empty", "One expense", "Typical year", "Long history", "Nothing charged yet",
        ])
    }
}
