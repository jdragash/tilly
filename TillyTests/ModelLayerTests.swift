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
}
