import Foundation
import SwiftData
import Testing
import TillyCore
@testable import Tilly

/// A store on disk, saved and closed, then reopened the way a launch opens it: through
/// `TillyStore` and its migration plan. When a `SchemaV2` arrives, this is the test that says an
/// existing person's bills come through it.
@MainActor
@Suite struct StoreMigrationTests {
    @Test func aSavedStoreReopensThroughTheMigrationPlan() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("StoreMigrationTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
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
                recurrenceInterval: 1, recurrenceUnit: .month, anchorDate: anchor, category: category
            )
            context.insert(category)
            context.insert(bill)
            context.insert(OverrideRecord(
                scheduledDate: scheduled, actualAmount: Decimal(55), movedDate: moved, expense: bill
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
        #expect(bill.anchorDate == anchor)
        #expect(bill.endDate == nil)

        let category = try #require(bill.category)
        #expect(category.name == "Home")
        #expect(category.symbol == "house")
        #expect(category.colour == .violet)
        #expect(category.sortOrder == 2)

        let overrides = bill.overrides ?? []
        #expect(overrides.count == 1)
        #expect(overrides.first?.scheduledDate == scheduled)
        #expect(overrides.first?.actualAmount == Decimal(55))
        #expect(overrides.first?.movedDate == moved)
        #expect(overrides.first?.isSkipped == false)
    }
}
