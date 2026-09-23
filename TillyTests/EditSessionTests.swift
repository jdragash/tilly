import Foundation
import SwiftData
import Testing
import TillyCore
@testable import Tilly

@MainActor
@Suite struct EditSessionTests {
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

    @discardableResult
    static func category(in context: ModelContext) -> ExpenseCategory {
        let category = ExpenseCategory(name: "Home", emoji: "🏠")
        context.insert(category)
        return category
    }

    /// A month-end (31st) anchored bill, per CLAUDE.md's clamp-sensitive convention.
    @discardableResult
    static func makeBill(
        in context: ModelContext, amount: Decimal = 50, anchor: Date, endDate: Date? = nil,
        category: ExpenseCategory
    ) -> Expense {
        let expense = Expense(name: "Gym", amount: amount, anchorDate: anchor, endDate: endDate, category: category)
        context.insert(expense)
        return expense
    }

    @Test func aPlainChargeOpensWithTheRuleAmount() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()

        let session = try #require(
            try EditSession.make(expenseID: expense.id, scheduledDate: anchor, context: context, calendar: Self.calendar)
        )
        #expect(session.draft.digits == "50")
        #expect(session.draft.date == anchor)
    }

    @Test func anOverriddenChargeOpensWithItsAmount() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        context.insert(OverrideRecord(scheduledDate: anchor, actualAmount: 65, expense: expense))
        try context.save()

        let session = try #require(
            try EditSession.make(expenseID: expense.id, scheduledDate: anchor, context: context, calendar: Self.calendar)
        )
        #expect(session.draft.digits == "65")
    }

    @Test func aFreeChargeOpensAtZero() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        context.insert(OverrideRecord(scheduledDate: anchor, actualAmount: 0, expense: expense))
        try context.save()

        let session = try #require(
            try EditSession.make(expenseID: expense.id, scheduledDate: anchor, context: context, calendar: Self.calendar)
        )
        #expect(session.draft.digits == "0")
    }

    @Test func aMovedChargeOpensOnItsNewDate() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        let moved = Self.date(2026, 2, 2)
        context.insert(OverrideRecord(scheduledDate: anchor, movedDate: moved, expense: expense))
        try context.save()

        let session = try #require(
            try EditSession.make(expenseID: expense.id, scheduledDate: anchor, context: context, calendar: Self.calendar)
        )
        #expect(session.draft.date == moved)
    }

    @Test func theCountIsTheWholeBills() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(
            in: context, amount: 50, anchor: anchor, endDate: Self.date(2026, 3, 31), category: category
        ) // 3 charges
        let second = Self.makeBill(
            in: context, amount: 60, anchor: Self.date(2026, 4, 30), endDate: Self.date(2026, 6, 30), category: category
        ) // 3 more
        second.seriesID = expense.seriesKey
        try context.save()

        let session = try #require(
            try EditSession.make(expenseID: expense.id, scheduledDate: anchor, context: context, calendar: Self.calendar)
        )
        #expect(session.draft.paymentCount == 6)
    }

    @Test func aBillWithNoEndHasNoCount() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()

        let session = try #require(
            try EditSession.make(expenseID: expense.id, scheduledDate: anchor, context: context, calendar: Self.calendar)
        )
        #expect(session.draft.paymentCount == nil)
    }

    @Test func theChargeIndexCountsFromTheRecordsAnchor() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()

        let fourthCharge = Self.date(2026, 4, 30)
        let session = try #require(
            try EditSession.make(expenseID: expense.id, scheduledDate: fourthCharge, context: context, calendar: Self.calendar)
        )
        #expect(session.draft.baseline?.chargeIndex == 3)
    }

    @Test func paymentsBeforeRuleCountsEarlierRecords() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(
            in: context, amount: 50, anchor: anchor, endDate: Self.date(2026, 3, 31), category: category
        ) // 3 charges
        let second = Self.makeBill(in: context, amount: 60, anchor: Self.date(2026, 4, 30), category: category)
        second.seriesID = expense.seriesKey
        try context.save()

        let session = try #require(
            try EditSession.make(
                expenseID: second.id, scheduledDate: Self.date(2026, 4, 30), context: context, calendar: Self.calendar
            )
        )
        #expect(session.draft.baseline?.paymentsBeforeRule == 3)
    }

    @Test func thePreviousChargeOfARecordsFirstIsTheEarlierRecordsLast() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(
            in: context, amount: 50, anchor: anchor, endDate: Self.date(2026, 3, 31), category: category
        )
        let second = Self.makeBill(in: context, amount: 60, anchor: Self.date(2026, 4, 30), category: category)
        second.seriesID = expense.seriesKey
        try context.save()

        let session = try #require(
            try EditSession.make(
                expenseID: second.id, scheduledDate: Self.date(2026, 4, 30), context: context, calendar: Self.calendar
            )
        )
        #expect(session.previousChargeDate == Self.date(2026, 3, 31))
    }

    @Test func anUnknownExpenseGivesNil() throws {
        let context = try Self.makeContext()
        let session = try EditSession.make(
            expenseID: UUID(), scheduledDate: Self.date(2026, 1, 31), context: context, calendar: Self.calendar
        )
        #expect(session == nil)
    }
}
