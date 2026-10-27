import Foundation
import SwiftData
import Testing
import TillyCore
@testable import Tilly

@Suite struct CategoryRemovalTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func makeContext() throws -> ModelContext {
        ModelContext(try TillyStore.container(inMemory: true))
    }

    @Test func deletesCategoryAndItsBills() throws {
        let context = try Self.makeContext()
        let home = ExpenseCategory(name: "Home")
        context.insert(home)
        context.insert(Expense(name: "Rent", amount: 950, category: home))
        context.insert(Expense(name: "Water", amount: 31, category: home))
        try context.save()

        try CategoryRemoval.delete(home, context: context)

        #expect(try context.fetch(FetchDescriptor<ExpenseCategory>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Expense>()).isEmpty)
    }

    @Test func deletesEveryRecordOfASeries() throws {
        let context = try Self.makeContext()
        let home = ExpenseCategory(name: "Home")
        context.insert(home)
        let series = UUID()
        context.insert(Expense(name: "Rent", amount: 900, anchorDate: Self.date(2027, 1, 1),
                               endDate: Self.date(2027, 5, 1), category: home, seriesID: series))
        context.insert(Expense(name: "Rent", amount: 950, anchorDate: Self.date(2027, 6, 1),
                               category: home, seriesID: series))
        try context.save()

        try CategoryRemoval.delete(home, context: context)

        #expect(try context.fetch(FetchDescriptor<Expense>()).isEmpty)
    }

    @Test func overridesGoWithTheirBill() throws {
        let context = try Self.makeContext()
        let home = ExpenseCategory(name: "Home")
        context.insert(home)
        let rent = Expense(name: "Rent", amount: 950, category: home)
        context.insert(rent)
        context.insert(OverrideRecord(scheduledDate: Self.date(2027, 1, 1), expense: rent))
        try context.save()

        try CategoryRemoval.delete(home, context: context)

        #expect(try context.fetch(FetchDescriptor<OverrideRecord>()).isEmpty)
    }

    @Test func otherCategoriesBillsStay() throws {
        let context = try Self.makeContext()
        let home = ExpenseCategory(name: "Home")
        let fun = ExpenseCategory(name: "Fun")
        context.insert(home)
        context.insert(fun)
        context.insert(Expense(name: "Rent", amount: 950, category: home))
        let film = Expense(name: "Film club", amount: 13, category: fun)
        context.insert(film)
        context.insert(OverrideRecord(scheduledDate: Self.date(2027, 1, 1), expense: film))
        context.insert(Expense(name: "Loose", amount: 5))
        try context.save()

        try CategoryRemoval.delete(home, context: context)

        let names = try context.fetch(FetchDescriptor<Expense>()).map(\.name).sorted()
        #expect(names == ["Film club", "Loose"])
        #expect(try context.fetch(FetchDescriptor<ExpenseCategory>()).map(\.name) == ["Fun"])
        #expect(try context.fetch(FetchDescriptor<OverrideRecord>()).count == 1)
    }

    @Test func billCountCountsSeriesNotRecords() throws {
        let context = try Self.makeContext()
        let home = ExpenseCategory(name: "Home")
        context.insert(home)
        let series = UUID()
        context.insert(Expense(name: "Rent", amount: 900, category: home, seriesID: series))
        context.insert(Expense(name: "Rent", amount: 950, category: home, seriesID: series))
        context.insert(Expense(name: "Water", amount: 31, category: home))
        try context.save()

        #expect(CategoryRemoval.billCount(of: home) == 2)
    }
}
