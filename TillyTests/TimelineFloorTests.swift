import Foundation
import SwiftData
import Testing
@testable import Tilly

@Suite struct TimelineFloorTests {
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

    @Test func theFloorIsTheEarliestAnchor() throws {
        let context = try Self.makeContext()
        context.insert(Expense(anchorDate: Self.date(2026, 3, 15)))
        context.insert(Expense(anchorDate: Self.date(2026, 9, 1)))
        try context.save()

        let expenses = try context.fetch(FetchDescriptor<Expense>())
        #expect(TimelineFloor.month(for: expenses, calendar: Self.calendar) == MonthKey(year: 2026, month: 3))
    }

    @Test func anOverrideMovedEarlierThanEveryAnchorBecomesTheFloor() throws {
        let context = try Self.makeContext()
        let expense = Expense(anchorDate: Self.date(2026, 6, 1))
        context.insert(expense)
        context.insert(OverrideRecord(
            scheduledDate: Self.date(2026, 6, 1),
            movedDate: Self.date(2026, 1, 10),
            expense: expense
        ))
        try context.save()

        let expenses = try context.fetch(FetchDescriptor<Expense>())
        #expect(TimelineFloor.month(for: expenses, calendar: Self.calendar) == MonthKey(year: 2026, month: 1))
    }

    @Test func noExpensesHasNoFloor() {
        #expect(TimelineFloor.month(for: [], calendar: Self.calendar) == nil)
    }

    @Test func theFloorIsTheAnchorsMonthNotItsDay() throws {
        let context = try Self.makeContext()
        context.insert(Expense(anchorDate: Self.date(2026, 3, 28)))
        try context.save()

        let expenses = try context.fetch(FetchDescriptor<Expense>())
        #expect(TimelineFloor.month(for: expenses, calendar: Self.calendar) == MonthKey(year: 2026, month: 3))
    }

    @Test func anArchivedExpensesAnchorDoesNotSetTheFloor() throws {
        let context = try Self.makeContext()
        context.insert(Expense(isArchived: true, anchorDate: Self.date(2020, 1, 1)))
        context.insert(Expense(anchorDate: Self.date(2026, 6, 1)))
        try context.save()

        let expenses = try context.fetch(FetchDescriptor<Expense>())
        #expect(TimelineFloor.month(for: expenses, calendar: Self.calendar) == MonthKey(year: 2026, month: 6))
    }
}
