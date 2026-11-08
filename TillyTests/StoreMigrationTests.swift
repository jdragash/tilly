import Foundation
import SwiftData
import Testing
import TillyCore
@testable import Tilly

/// Stores on disk, saved and closed, then reopened the way a launch opens them: through
/// `TillyStore` and its migration plan.
@MainActor
@Suite(.serialized) struct StoreMigrationTests {
    static func folder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("StoreMigrationTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    /// A store saved with today's models reopens unchanged.
    @Test func aSavedStoreReopensThroughTheMigrationPlan() throws {
        let folder = try Self.folder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("Tilly.store")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let anchor = calendar.date(from: DateComponents(year: 2026, month: 1, day: 31))!
        let moved = calendar.date(from: DateComponents(year: 2026, month: 3, day: 2))!
        let scheduled = calendar.date(from: DateComponents(year: 2026, month: 2, day: 28))!
        let billID = UUID()

        // Written and closed: the container goes out of scope at the end of the block.
        do {
            let context = ModelContext(try TillyStore.container(url: url))
            let category = ExpenseCategory(name: "Home", emoji: "🏠", symbol: "house", colour: .violet, sortOrder: 2)
            let bill = Expense(
                id: billID, name: "Gym", amount: Decimal(string: "49.99"), isEstimate: true,
                recurrenceInterval: 1, recurrenceUnit: .month, anchorDate: anchor, category: category,
                calendar: calendar
            )
            context.insert(category)
            context.insert(bill)
            context.insert(OverrideRecord(
                scheduledDate: scheduled, actualAmount: Decimal(55), movedDate: moved, expense: bill, calendar: calendar
            ))
            try context.save()
        }

        let reopened = ModelContext(try TillyStore.container(url: url))
        let bills = try reopened.fetch(FetchDescriptor<Expense>())
        #expect(bills.count == 1)
        let bill = try #require(bills.first)
        #expect(bill.id == billID)
        #expect(bill.name == "Gym")
        #expect(bill.amount == Decimal(string: "49.99"))
        #expect(bill.isEstimate)
        #expect(bill.recurrenceUnit == .month)
        #expect(bill.anchor == CalendarDay(year: 2026, month: 1, day: 31))
        #expect(bill.end == nil)

        let category = try #require(bill.category)
        #expect(category.name == "Home")
        #expect(category.symbol == "house")
        #expect(category.colour == .violet)
        #expect(category.sortOrder == 2)

        let overrides = bill.overrides ?? []
        #expect(overrides.count == 1)
        #expect(overrides.first?.scheduled == CalendarDay(year: 2026, month: 2, day: 28))
        #expect(overrides.first?.actualAmount == Decimal(55))
        #expect(overrides.first?.moved == CalendarDay(year: 2026, month: 3, day: 2))
        #expect(overrides.first?.isSkipped == false)
    }

    /// A store saved by the first schema, days stored as the instant each began, opens through the
    /// plan with the same days. The first schema's days were made in the phone's own calendar,
    /// and the migration reads them in it, so this one is made and checked in `Calendar.current`.
    @Test func aFirstSchemaStoreMigratesToCalendarDays() throws {
        let folder = try Self.folder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("Tilly.store")
        let calendar = Calendar.current
        func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
            calendar.startOfDay(for: calendar.date(from: DateComponents(year: year, month: month, day: day))!)
        }
        let billID = UUID()
        let categoryID = UUID()

        do {
            let schema = Schema(versionedSchema: SchemaV1.self)
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url)])
            let context = ModelContext(container)
            let category = SchemaV1.ExpenseCategory(
                id: categoryID, name: "Home", symbol: "house", colourRaw: CategoryColour.blue.rawValue, sortOrder: 1
            )
            let bill = SchemaV1.Expense(
                id: billID, name: "Rent", amount: 950, recurrenceInterval: 1, recurrenceUnit: .month,
                anchorDate: day(2026, 1, 31), endDate: day(2026, 12, 31), category: category
            )
            let unended = SchemaV1.Expense(name: "Water", amount: 45, anchorDate: day(2025, 11, 22), category: category)
            context.insert(category)
            context.insert(bill)
            context.insert(unended)
            context.insert(SchemaV1.OverrideRecord(
                scheduledDate: day(2026, 2, 28), actualAmount: 975, movedDate: day(2026, 3, 2), expense: bill
            ))
            context.insert(SchemaV1.OverrideRecord(scheduledDate: day(2026, 4, 30), isSkipped: true, expense: bill))
            try context.save()
        }

        let context = ModelContext(try TillyStore.container(url: url))
        let bills = try context.fetch(FetchDescriptor<Expense>())
        #expect(bills.count == 2)

        let rent = try #require(bills.first { $0.id == billID })
        #expect(rent.name == "Rent")
        #expect(rent.amount == 950)
        #expect(rent.anchor == CalendarDay(year: 2026, month: 1, day: 31))
        #expect(rent.end == CalendarDay(year: 2026, month: 12, day: 31))
        #expect(rent.category?.id == categoryID)
        #expect(rent.category?.colour == .blue)

        let overrides = (rent.overrides ?? []).sorted { $0.scheduled < $1.scheduled }
        #expect(overrides.count == 2)
        #expect(overrides.first?.scheduled == CalendarDay(year: 2026, month: 2, day: 28))
        #expect(overrides.first?.moved == CalendarDay(year: 2026, month: 3, day: 2))
        #expect(overrides.first?.actualAmount == 975)
        #expect(overrides.last?.scheduled == CalendarDay(year: 2026, month: 4, day: 30))
        #expect(overrides.last?.moved == nil)
        #expect(overrides.last?.isSkipped == true)

        let water = try #require(bills.first { $0.id != billID })
        #expect(water.anchor == CalendarDay(year: 2025, month: 11, day: 22))
        #expect(water.end == nil)

        // And the engine sees the same charges as before: the moved, re-priced February charge
        // on 2 March, the skipped April one flagged.
        let charges = RecurrenceEngine.occurrences(
            for: rent.snapshot(calendar: calendar), overrides: rent.overrideSnapshots(calendar: calendar),
            in: DateInterval(start: day(2026, 2, 1), end: day(2026, 4, 30)), calendar: calendar
        )
        #expect(charges.map { CalendarDay($0.effectiveDate, calendar: calendar).id } == ["2026-03-02", "2026-03-31", "2026-04-30"])
        #expect(charges.map(\.amount) == [975, 950, 950])
        #expect(charges.map(\.isSkipped) == [false, false, true])
    }
}
