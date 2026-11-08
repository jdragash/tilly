import Foundation
import SwiftData
import Testing
@testable import Tilly

@Suite struct ModelContextFetchTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    @Test func findsTheRightExpenseAmongThree() throws {
        let context = ModelContext(try TillyStore.container(inMemory: true))
        let rent = Expense(name: "Rent", amount: 950, anchorDate: Date(), calendar: Self.calendar)
        let water = Expense(name: "Water", amount: 31, anchorDate: Date(), calendar: Self.calendar)
        let phone = Expense(name: "Phone", amount: 40, anchorDate: Date(), calendar: Self.calendar)
        for expense in [rent, water, phone] { context.insert(expense) }
        try context.save()

        #expect(try context.expense(id: water.id)?.name == "Water")
        #expect(try context.expense(id: phone.id)?.name == "Phone")
    }

    @Test func returnsNilForAnUnknownID() throws {
        let context = ModelContext(try TillyStore.container(inMemory: true))
        context.insert(Expense(name: "Rent", amount: 950, anchorDate: Date(), calendar: Self.calendar))
        try context.save()

        #expect(try context.expense(id: UUID()) == nil)
    }
}
