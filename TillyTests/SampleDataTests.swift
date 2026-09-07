import Foundation
import SwiftData
import Testing
import TillyCore
@testable import Tilly

@Suite struct SampleDataTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static let today = date(2026, 9, 15)

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    /// Mirrors the day-in-month helper `SampleData.insert` uses internally, so tests can
    /// name the same dates without duplicating its month/year arithmetic.
    static func day(_ day: Int, monthOffset: Int = 0, from anchor: Date = today) -> Date {
        let components = calendar.dateComponents([.year, .month], from: anchor)
        return calendar.date(from: DateComponents(year: components.year, month: (components.month ?? 1) + monthOffset, day: day))!
    }

    static func makeContext() throws -> ModelContext {
        let container = try TillyStore.container(inMemory: true)
        return ModelContext(container)
    }

    static func makeDefaults(suiteName: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func seedingAnEmptyStoreInsertsTheWholeSet() throws {
        let context = try Self.makeContext()
        try SampleData.insert(into: context, today: Self.today, calendar: Self.calendar)

        #expect(try context.fetch(FetchDescriptor<Expense>()).count == 11)
        #expect(try context.fetch(FetchDescriptor<OverrideRecord>()).count == 2)
    }

    @Test func seedingTwiceInsertsNothingTheSecondTime() throws {
        let suiteName = "SampleDataTests.seedingTwice"
        let defaults = Self.makeDefaults(suiteName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let context = try Self.makeContext()
        try SampleData.seedIfNeeded(into: context, today: Self.today, calendar: Self.calendar, defaults: defaults)
        try SampleData.seedIfNeeded(into: context, today: Self.today, calendar: Self.calendar, defaults: defaults)

        #expect(try context.fetch(FetchDescriptor<Expense>()).count == 11)
    }

    @Test func theCurrentMonthShowsEveryStateAtOnce() throws {
        let context = try Self.makeContext()
        try SampleData.insert(into: context, today: Self.today, calendar: Self.calendar)

        let expenses = try context.fetch(FetchDescriptor<Expense>()).map(\.timelineExpense)
        let month = MonthKey(containing: Self.today, calendar: Self.calendar)
        let section = TimelineBuilder.month(month, expenses: expenses, today: Self.today, calendar: Self.calendar)
        let entries = section.days.flatMap(\.entries)

        #expect(entries.contains { $0.state == .upcoming })
        #expect(entries.contains { $0.state == .charged })
        #expect(entries.contains { $0.state == .skipped })
        #expect(section.days.contains { $0.isGrouped })
    }

    @Test func oneSeededNameIsLongEnoughToTruncate() throws {
        let context = try Self.makeContext()
        try SampleData.insert(into: context, today: Self.today, calendar: Self.calendar)

        let names = try context.fetch(FetchDescriptor<Expense>()).map(\.name)
        #expect(names.contains { $0.count > 20 })
    }

    @Test func theMovedBillLandsInThisMonthAndLeavesThePreviousOne() throws {
        let context = try Self.makeContext()
        try SampleData.insert(into: context, today: Self.today, calendar: Self.calendar)

        let expenses = try context.fetch(FetchDescriptor<Expense>()).map(\.timelineExpense)
        let thisMonth = MonthKey(containing: Self.today, calendar: Self.calendar)
        let previousMonth = thisMonth.advanced(by: -1)

        let thisSection = TimelineBuilder.month(thisMonth, expenses: expenses, today: Self.today, calendar: Self.calendar)
        let previousSection = TimelineBuilder.month(previousMonth, expenses: expenses, today: Self.today, calendar: Self.calendar)

        let landedDay = Self.day(3)
        #expect(thisSection.days.contains { day in
            day.date == landedDay && day.entries.contains { $0.name == "Home internet" }
        })

        let originalDay = Self.day(22, monthOffset: -1)
        #expect(!previousSection.days.contains { $0.date == originalDay })
    }

    @Test func theSkippedBillIsListedAndOutOfItsDayTotal() throws {
        let context = try Self.makeContext()
        try SampleData.insert(into: context, today: Self.today, calendar: Self.calendar)

        let expenses = try context.fetch(FetchDescriptor<Expense>()).map(\.timelineExpense)
        let month = MonthKey(containing: Self.today, calendar: Self.calendar)
        let section = TimelineBuilder.month(month, expenses: expenses, today: Self.today, calendar: Self.calendar)

        let group = try #require(section.days.first { $0.date == Self.day(1) })
        #expect(group.entries.count == 2)
        #expect(group.total == 950)
    }

    @Test func everySeededExpenseSurvivesASaveAndFetch() throws {
        let context = try Self.makeContext()
        try SampleData.insert(into: context, today: Self.today, calendar: Self.calendar)

        let names = Set(try context.fetch(FetchDescriptor<Expense>()).map(\.name))
        #expect(names == [
            "Rent", "Streaming video", "Music streaming", "Cloud storage", "Gym membership",
            "Electricity", "Home & contents insurance", "Water", "Home internet", "Council tax",
            "Mobile phone"
        ])
    }

    @Test func theEmptyStoreFlagSuppressesSeeding() throws {
        let suiteName = "SampleDataTests.emptyStoreFlag"
        let defaults = Self.makeDefaults(suiteName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: "tillyEmptyStore")

        let context = try Self.makeContext()
        try SampleData.seedIfNeeded(into: context, today: Self.today, calendar: Self.calendar, defaults: defaults)

        #expect(try context.fetch(FetchDescriptor<Expense>()).isEmpty)
    }
}
