import Foundation
import SwiftData
import Testing
import TillyCore
@testable import Tilly

@MainActor
@Suite struct BillEditorTests {
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
    static func category(in context: ModelContext, name: String = "Home", emoji: String = "🏠") -> ExpenseCategory {
        let category = ExpenseCategory(name: name, emoji: emoji)
        context.insert(category)
        return category
    }

    /// A month-end (31st) anchored bill, per CLAUDE.md's clamp-sensitive convention.
    @discardableResult
    static func makeBill(
        in context: ModelContext, name: String = "Gym", amount: Decimal = 50,
        anchor: Date, interval: Int = 1, unit: RecurrenceUnit = .month, endDate: Date? = nil,
        category: ExpenseCategory
    ) -> Expense {
        let expense = Expense(
            name: name, amount: amount, recurrenceInterval: interval, recurrenceUnit: unit,
            anchorDate: anchor, endDate: endDate, category: category
        )
        context.insert(expense)
        return expense
    }

    /// A draft holding `digits`, `name`, `date` and `categoryID` for the given amount and
    /// category, so a test only has to set what it means to change.
    static func draft(
        today: Date, digits: String, name: String, date: Date, category: ExpenseCategory,
        interval: Int = 1, unit: RecurrenceUnit = .month, paymentCount: Int? = nil
    ) -> ExpenseDraft {
        var draft = ExpenseDraft(today: today, calendar: calendar)
        draft.digits = digits
        draft.name = name
        draft.date = date
        draft.interval = interval
        draft.unit = unit
        draft.categoryID = category.id
        draft.paymentCount = paymentCount
        return draft
    }

    // MARK: This charge

    @Test func thisChargeWritesAnAmountOverride() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()

        let draft = Self.draft(today: anchor, digits: "60", name: "Gym", date: anchor, category: category)
        try BillEditor.saveThisCharge(
            draft, expense: expense, scheduledDate: anchor, category: category, context: context, calendar: Self.calendar
        )

        #expect(expense.overrides?.count == 1)
        #expect(expense.overrides?.first?.actualAmount == 60)
        #expect(expense.overrides?.first?.movedDate == nil)
    }

    @Test func thisChargeBackToTheRuleAmountRemovesTheOverride() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        context.insert(OverrideRecord(scheduledDate: anchor, actualAmount: 60, expense: expense))
        try context.save()

        let draft = Self.draft(today: anchor, digits: "50", name: "Gym", date: anchor, category: category)
        try BillEditor.saveThisCharge(
            draft, expense: expense, scheduledDate: anchor, category: category, context: context, calendar: Self.calendar
        )

        #expect((expense.overrides ?? []).isEmpty)
    }

    @Test func thisChargeWritesAMove() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()

        let moved = Self.date(2026, 2, 2)
        let draft = Self.draft(today: anchor, digits: "50", name: "Gym", date: moved, category: category)
        try BillEditor.saveThisCharge(
            draft, expense: expense, scheduledDate: anchor, category: category, context: context, calendar: Self.calendar
        )

        #expect(expense.overrides?.first?.movedDate == moved)
        #expect(expense.overrides?.first?.actualAmount == nil)
    }

    @Test func editingAMovedChargeReusesItsOverride() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        let moved = Self.date(2026, 2, 2)
        context.insert(OverrideRecord(scheduledDate: anchor, movedDate: moved, expense: expense))
        try context.save()

        let draft = Self.draft(today: anchor, digits: "65", name: "Gym", date: moved, category: category)
        try BillEditor.saveThisCharge(
            draft, expense: expense, scheduledDate: anchor, category: category, context: context, calendar: Self.calendar
        )

        #expect(expense.overrides?.count == 1)
        #expect(expense.overrides?.first?.actualAmount == 65)
        #expect(expense.overrides?.first?.movedDate == moved)
    }

    @Test func zeroIsStoredAsAnAmount() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()

        let draft = Self.draft(today: anchor, digits: "0", name: "Gym", date: anchor, category: category)
        try BillEditor.saveThisCharge(
            draft, expense: expense, scheduledDate: anchor, category: category, context: context, calendar: Self.calendar
        )

        #expect(expense.overrides?.first?.actualAmount == 0)
    }

    // MARK: Future charges

    @Test func futureFromTheFirstChargeEditsInPlace() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()

        let draft = Self.draft(today: anchor, digits: "60", name: "Gym", date: anchor, category: category)
        try BillEditor.saveFutureCharges(
            draft, expense: expense, scheduledDate: anchor, category: category, context: context, calendar: Self.calendar
        )

        let series = try BillEditor.series(of: expense, in: context)
        #expect(series.count == 1)
        #expect(series.first?.amount == 60)
        #expect(series.first?.anchorDate == anchor)
    }

    @Test func futureFromALaterChargeSplitsTheBill() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()

        let fourthCharge = Self.date(2026, 4, 30) // Jan 31, Feb 28, Mar 31, Apr 30 — chargeIndex 3
        let draft = Self.draft(today: fourthCharge, digits: "60", name: "Gym", date: fourthCharge, category: category)
        try BillEditor.saveFutureCharges(
            draft, expense: expense, scheduledDate: fourthCharge, category: category, context: context, calendar: Self.calendar
        )

        let series = try BillEditor.series(of: expense, in: context)
        #expect(series.count == 2)
        #expect(series[0].anchorDate == anchor)
        #expect(series[0].endDate == Self.date(2026, 3, 31))
        #expect(series[0].amount == 50)
        #expect(series[1].anchorDate == fourthCharge)
        #expect(series[1].amount == 60)
    }

    @Test func futureLeavesEveryPastChargeAsItWas() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()

        let fourthCharge = Self.date(2026, 4, 30)
        let draft = Self.draft(today: fourthCharge, digits: "60", name: "Gym", date: fourthCharge, category: category)
        try BillEditor.saveFutureCharges(
            draft, expense: expense, scheduledDate: fourthCharge, category: category, context: context, calendar: Self.calendar
        )

        let series = try BillEditor.series(of: expense, in: context)
        let range = DateInterval(start: Self.date(2026, 1, 1), end: Self.date(2026, 3, 31))
        let earlyDates = RecurrenceEngine.dates(for: series[0].rule, in: range, calendar: Self.calendar)
        #expect(earlyDates == [Self.date(2026, 1, 31), Self.date(2026, 2, 28), Self.date(2026, 3, 31)])
    }

    @Test func futureSharesTheSeriesID() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()

        let fourthCharge = Self.date(2026, 4, 30)
        let draft = Self.draft(today: fourthCharge, digits: "60", name: "Gym", date: fourthCharge, category: category)
        try BillEditor.saveFutureCharges(
            draft, expense: expense, scheduledDate: fourthCharge, category: category, context: context, calendar: Self.calendar
        )

        let series = try BillEditor.series(of: expense, in: context)
        #expect(series[1].seriesID == expense.id)
        #expect(series[0].seriesKey == series[1].seriesKey)
    }

    @Test func futureFromAnAlreadySplitBillReplacesTheLaterRecord() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()

        let fourthCharge = Self.date(2026, 4, 30)
        let firstSplit = Self.draft(today: fourthCharge, digits: "60", name: "Gym", date: fourthCharge, category: category)
        try BillEditor.saveFutureCharges(
            firstSplit, expense: expense, scheduledDate: fourthCharge, category: category, context: context, calendar: Self.calendar
        )
        var series = try BillEditor.series(of: expense, in: context)
        #expect(series.count == 2)
        let firstLaterRecordID = series[1].id

        let secondSplit = Self.draft(today: fourthCharge, digits: "70", name: "Gym", date: fourthCharge, category: category)
        try BillEditor.saveFutureCharges(
            secondSplit, expense: expense, scheduledDate: fourthCharge, category: category, context: context, calendar: Self.calendar
        )

        series = try BillEditor.series(of: expense, in: context)
        #expect(series.count == 2)
        #expect(series[1].amount == 70)
        #expect(series[1].id != firstLaterRecordID)
    }

    @Test func aLaterFreeMonthSurvivesAPriceChange() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        let freeMonth = Self.date(2026, 6, 30) // index 5 from Jan 31: Feb, Mar, Apr, May, Jun
        context.insert(OverrideRecord(scheduledDate: freeMonth, actualAmount: 0, expense: expense))
        try context.save()

        let fourthCharge = Self.date(2026, 4, 30)
        let draft = Self.draft(today: fourthCharge, digits: "60", name: "Gym", date: fourthCharge, category: category)
        try BillEditor.saveFutureCharges(
            draft, expense: expense, scheduledDate: fourthCharge, category: category, context: context, calendar: Self.calendar
        )

        let series = try BillEditor.series(of: expense, in: context)
        let newRecord = series[1]
        #expect(newRecord.overrides?.count == 1)
        #expect(newRecord.overrides?.first?.scheduledDate == freeMonth)
        #expect(newRecord.overrides?.first?.actualAmount == 0)
    }

    @Test func aLaterFreeMonthIsDroppedWhenItsDayNoLongerExists() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        let freeMonth = Self.date(2026, 6, 30)
        context.insert(OverrideRecord(scheduledDate: freeMonth, actualAmount: 0, expense: expense))
        try context.save()

        // Moving this charge to the 15th moves the new rule's whole day-of-month pattern, so
        // it never lands on the 30th again.
        let fourthCharge = Self.date(2026, 4, 30)
        let newDay = Self.date(2026, 4, 15)
        let draft = Self.draft(today: fourthCharge, digits: "60", name: "Gym", date: newDay, category: category)
        try BillEditor.saveFutureCharges(
            draft, expense: expense, scheduledDate: fourthCharge, category: category, context: context, calendar: Self.calendar
        )

        let series = try BillEditor.series(of: expense, in: context)
        #expect((series[1].overrides ?? []).isEmpty)
    }

    @Test func futureDropsTheOpenChargesOwnOverride() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        let fourthCharge = Self.date(2026, 4, 30)
        context.insert(OverrideRecord(scheduledDate: fourthCharge, actualAmount: 55, expense: expense))
        try context.save()

        let draft = Self.draft(today: fourthCharge, digits: "60", name: "Gym", date: fourthCharge, category: category)
        try BillEditor.saveFutureCharges(
            draft, expense: expense, scheduledDate: fourthCharge, category: category, context: context, calendar: Self.calendar
        )

        let series = try BillEditor.series(of: expense, in: context)
        #expect((series[0].overrides ?? []).isEmpty)
        #expect((series[1].overrides ?? []).isEmpty)
    }

    // MARK: Name, category and count reach the whole series

    @Test func aRenameReachesEveryRecord() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()
        let fourthCharge = Self.date(2026, 4, 30)
        let split = Self.draft(today: fourthCharge, digits: "50", name: "Gym", date: fourthCharge, category: category)
        try BillEditor.saveFutureCharges(
            split, expense: expense, scheduledDate: fourthCharge, category: category, context: context, calendar: Self.calendar
        )

        let rename = Self.draft(today: anchor, digits: "50", name: "Gym membership", date: anchor, category: category)
        try BillEditor.saveWholeBill(rename, expense: expense, category: category, context: context, calendar: Self.calendar)

        let series = try BillEditor.series(of: expense, in: context)
        #expect(series.allSatisfy { $0.name == "Gym membership" })
    }

    @Test func aCategoryReachesEveryRecord() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let fitness = Self.category(in: context, name: "Fitness", emoji: "💪")
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()
        let fourthCharge = Self.date(2026, 4, 30)
        let split = Self.draft(today: fourthCharge, digits: "50", name: "Gym", date: fourthCharge, category: category)
        try BillEditor.saveFutureCharges(
            split, expense: expense, scheduledDate: fourthCharge, category: category, context: context, calendar: Self.calendar
        )

        let recategorize = Self.draft(today: anchor, digits: "50", name: "Gym", date: anchor, category: fitness)
        try BillEditor.saveWholeBill(recategorize, expense: expense, category: fitness, context: context, calendar: Self.calendar)

        let series = try BillEditor.series(of: expense, in: context)
        #expect(series.allSatisfy { $0.category?.id == fitness.id })
    }

    @Test func aCountEndingInAnEarlierRecordDeletesTheLaterOnes() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()
        let fourthCharge = Self.date(2026, 4, 30)
        let split = Self.draft(today: fourthCharge, digits: "60", name: "Gym", date: fourthCharge, category: category)
        try BillEditor.saveFutureCharges(
            split, expense: expense, scheduledDate: fourthCharge, category: category, context: context, calendar: Self.calendar
        )

        let countDraft = Self.draft(
            today: anchor, digits: "50", name: "Gym", date: anchor, category: category, paymentCount: 2
        )
        try BillEditor.saveWholeBill(countDraft, expense: expense, category: category, context: context, calendar: Self.calendar)

        let series = try BillEditor.series(of: expense, in: context)
        #expect(series.count == 1)
        #expect(series.first?.endDate == Self.date(2026, 2, 28))
    }

    @Test func noEndReopensTheLastRecord() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(
            in: context, amount: 50, anchor: anchor, endDate: Self.date(2026, 12, 31), category: category
        )
        try context.save()

        let draft = Self.draft(today: anchor, digits: "50", name: "Gym", date: anchor, category: category, paymentCount: nil)
        try BillEditor.saveWholeBill(draft, expense: expense, category: category, context: context, calendar: Self.calendar)

        #expect(expense.endDate == nil)
    }

    @Test func aLongerCountExtendsTheLastRecord() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(
            in: context, amount: 50, anchor: anchor, endDate: Self.date(2026, 3, 31), category: category
        )
        try context.save()

        let draft = Self.draft(
            today: anchor, digits: "50", name: "Gym", date: anchor, category: category, paymentCount: 6
        )
        try BillEditor.saveWholeBill(draft, expense: expense, category: category, context: context, calendar: Self.calendar)

        #expect(expense.endDate == Self.date(2026, 6, 30))
    }

    // MARK: Deleting

    @Test func deleteFutureFromALaterChargeKeepsThePast() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()

        let fourthCharge = Self.date(2026, 4, 30)
        try BillEditor.deleteFutureCharges(from: fourthCharge, of: expense, context: context, calendar: Self.calendar)

        #expect(expense.endDate == Self.date(2026, 3, 31))
        let range = DateInterval(start: Self.date(2026, 1, 1), end: Self.date(2026, 12, 31))
        let dates = RecurrenceEngine.dates(for: expense.rule, in: range, calendar: Self.calendar)
        #expect(dates == [Self.date(2026, 1, 31), Self.date(2026, 2, 28), Self.date(2026, 3, 31)])
    }

    @Test func deleteFutureFromARecordsFirstChargeRemovesIt() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()
        let fourthCharge = Self.date(2026, 4, 30)
        let split = Self.draft(today: fourthCharge, digits: "60", name: "Gym", date: fourthCharge, category: category)
        try BillEditor.saveFutureCharges(
            split, expense: expense, scheduledDate: fourthCharge, category: category, context: context, calendar: Self.calendar
        )
        var series = try BillEditor.series(of: expense, in: context)
        #expect(series.count == 2)
        let laterRecord = series[1]

        try BillEditor.deleteFutureCharges(from: fourthCharge, of: laterRecord, context: context, calendar: Self.calendar)

        series = try BillEditor.series(of: expense, in: context)
        #expect(series.count == 1)
        #expect(series.first?.anchorDate == anchor)
    }

    @Test func deleteFutureRemovesOverridesFromThatChargeOn() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        let secondCharge = Self.date(2026, 2, 28)
        let fifthCharge = Self.date(2026, 5, 31)
        context.insert(OverrideRecord(scheduledDate: secondCharge, actualAmount: 55, expense: expense))
        context.insert(OverrideRecord(scheduledDate: fifthCharge, actualAmount: 65, expense: expense))
        try context.save()

        let fourthCharge = Self.date(2026, 4, 30)
        try BillEditor.deleteFutureCharges(from: fourthCharge, of: expense, context: context, calendar: Self.calendar)

        let remaining = expense.overrides ?? []
        #expect(remaining.count == 1)
        #expect(remaining.first?.scheduledDate == secondCharge)
    }

    @Test func deleteAllRemovesTheWholeSeries() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()
        let fourthCharge = Self.date(2026, 4, 30)
        let split = Self.draft(today: fourthCharge, digits: "60", name: "Gym", date: fourthCharge, category: category)
        try BillEditor.saveFutureCharges(
            split, expense: expense, scheduledDate: fourthCharge, category: category, context: context, calendar: Self.calendar
        )

        try BillEditor.deleteAllCharges(of: expense, context: context)

        let remaining = try context.fetch(FetchDescriptor<Expense>())
        #expect(remaining.isEmpty)
    }

    @Test func deleteAllLeavesOtherBillsAlone() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        let other = Self.makeBill(in: context, name: "Rent", amount: 900, anchor: anchor, category: category)
        try context.save()

        try BillEditor.deleteAllCharges(of: expense, context: context)

        let remaining = try context.fetch(FetchDescriptor<Expense>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == other.id)
    }

    // MARK: Reading helpers

    @Test func hasLaterChargeIsFalseOnTheLastPayment() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(
            in: context, amount: 50, anchor: anchor, endDate: Self.date(2026, 3, 31), category: category
        )
        try context.save()

        let series = try BillEditor.series(of: expense, in: context)
        #expect(!BillEditor.hasLaterCharge(than: Self.date(2026, 3, 31), in: series, calendar: Self.calendar))
    }

    @Test func hasLaterChargeIsTrueWhenTheBillRunsOn() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()

        let series = try BillEditor.series(of: expense, in: context)
        #expect(BillEditor.hasLaterCharge(than: Self.date(2026, 3, 31), in: series, calendar: Self.calendar))
    }

    @Test func theFirstChargeOfALaterRecordIsNotTheBillsFirst() throws {
        let context = try Self.makeContext()
        let category = Self.category(in: context)
        let anchor = Self.date(2026, 1, 31)
        let expense = Self.makeBill(in: context, amount: 50, anchor: anchor, category: category)
        try context.save()
        let fourthCharge = Self.date(2026, 4, 30)
        let split = Self.draft(today: fourthCharge, digits: "60", name: "Gym", date: fourthCharge, category: category)
        try BillEditor.saveFutureCharges(
            split, expense: expense, scheduledDate: fourthCharge, category: category, context: context, calendar: Self.calendar
        )

        let series = try BillEditor.series(of: expense, in: context)
        #expect(BillEditor.isFirstCharge(anchor, of: expense, in: series, calendar: Self.calendar))
        #expect(!BillEditor.isFirstCharge(fourthCharge, of: series[1], in: series, calendar: Self.calendar))
    }
}
