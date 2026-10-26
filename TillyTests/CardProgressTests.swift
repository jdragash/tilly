import Foundation
import Testing
import TillyCore
@testable import Tilly

@Suite struct CardProgressTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static let today = calendar.date(from: DateComponents(year: 2026, month: 9, day: 19))!

    /// A new bill's draft with the given amount text and name.
    static func draft(digits: String = "", name: String = "") -> ExpenseDraft {
        var draft = ExpenseDraft(today: today, calendar: calendar)
        draft.digits = digits
        draft.name = name
        return draft
    }

    static func progress(
        digits: String = "",
        name: String = "",
        categoryExists: Bool = false
    ) -> CardProgress {
        CardProgress(
            draft: draft(digits: digits, name: name),
            categoryExists: categoryExists
        )
    }

    // MARK: Missing

    @Test func emptyDraftMissesAmountNameCategory() {
        let progress = Self.progress()
        #expect(progress.isMissing(.amount))
        #expect(progress.isMissing(.name))
        #expect(progress.isMissing(.category))
    }

    @Test func dateAndRepeatAreNeverMissing() {
        let progress = Self.progress()
        #expect(!progress.isMissing(.date))
        #expect(!progress.isMissing(.repeat))
    }

    @Test func editAtZeroCountsTheAmountAsFilled() {
        let baseline = EditBaseline(
            digits: "12", name: "Rent", date: Self.today, interval: 1, unit: .month,
            paymentCount: nil, categoryID: UUID(), ruleAnchor: Self.today,
            paymentsBeforeRule: 0, chargeIndex: 0
        )
        var draft = ExpenseDraft(editing: baseline)
        draft.digits = "0"
        let progress = CardProgress(draft: draft, categoryExists: true)
        #expect(!progress.isMissing(.amount))
    }

    @Test func newBillAtZeroIsMissingTheAmount() {
        #expect(Self.progress(digits: "0").isMissing(.amount))
    }

    @Test func whitespaceNameIsMissing() {
        #expect(Self.progress(digits: "12", name: "  \n ").isMissing(.name))
    }

    // MARK: Next

    @Test func nextAfterAmountIsName() {
        #expect(Self.progress(digits: "12").next(after: .amount) == .name)
    }

    @Test func nextAfterNameIsCategory() {
        #expect(Self.progress(digits: "12", name: "Rent").next(after: .name) == .category)
    }

    @Test func nextWrapsToAmount() {
        let progress = Self.progress(name: "Rent", categoryExists: true)
        #expect(progress.next(after: .category) == .amount)
    }

    @Test func nextIsNilWhenComplete() {
        let progress = Self.progress(digits: "12", name: "Rent", categoryExists: true)
        #expect(progress.next(after: .amount) == nil)
        #expect(progress.next(after: nil) == nil)
    }

    // MARK: Breathing

    @Test func nothingBreathesWithoutAnAmount() {
        #expect(Self.progress().breathing(focused: nil) == nil)
        #expect(Self.progress(digits: "0").breathing(focused: nil) == nil)
    }

    @Test func nameBreathesAfterTheAmount() {
        #expect(Self.progress(digits: "12").breathing(focused: nil) == .name)
    }

    @Test func focusedPartDoesNotBreathe() {
        let progress = Self.progress(digits: "12")
        #expect(progress.breathing(focused: .name) != .name)
    }

    @Test func categoryBreathesLast() {
        let progress = Self.progress(digits: "12", name: "Rent")
        #expect(progress.breathing(focused: nil) == .category)
    }
}
