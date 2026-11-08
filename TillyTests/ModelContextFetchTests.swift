import Foundation
import SwiftData
import Testing
@testable import Tilly

@Suite struct ModelContextFetchTests {
    @Test func findsTheRightExpenseAmongThree() throws {
        let context = ModelContext(try TillyStore.container(inMemory: true))
        let rent = Expense(name: "Rent", amount: 950)
        let water = Expense(name: "Water", amount: 31)
        let phone = Expense(name: "Phone", amount: 40)
        for expense in [rent, water, phone] { context.insert(expense) }
        try context.save()

        #expect(try context.expense(id: water.id)?.name == "Water")
        #expect(try context.expense(id: phone.id)?.name == "Phone")
    }

    @Test func returnsNilForAnUnknownID() throws {
        let context = ModelContext(try TillyStore.container(inMemory: true))
        context.insert(Expense(name: "Rent", amount: 950))
        try context.save()

        #expect(try context.expense(id: UUID()) == nil)
    }
}
