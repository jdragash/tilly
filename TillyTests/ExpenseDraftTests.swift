import Foundation
import Testing
import TillyCore
@testable import Tilly

@Suite struct ExpenseDraftTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    /// US formatting with the euro, the currency the design's examples are written in.
    static let locale = Locale(identifier: "en_US@currency=EUR")

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static let today = date(2026, 9, 19)

    static func draft() -> ExpenseDraft {
        ExpenseDraft(today: today, calendar: calendar)
    }

    /// Presses keys from a string: digits, "." for the decimal point, "<" for delete.
    static func typed(_ keys: String) -> ExpenseDraft {
        var draft = Self.draft()
        for character in keys {
            switch character {
            case ".": draft.press(.decimal)
            case "<": draft.press(.delete)
            default: draft.press(.digit(character.wholeNumberValue!))
            }
        }
        return draft
    }

    static func validDraft() -> ExpenseDraft {
        var draft = typed("12")
        draft.name = "Rent"
        draft.categoryID = UUID()
        return draft
    }

    static func baseline(
        digits: String = "12",
        name: String = "Rent",
        date: Date = today,
        interval: Int = 1,
        unit: RecurrenceUnit = .month,
        paymentCount: Int? = nil,
        categoryID: UUID? = UUID(),
        ruleAnchor: Date = today,
        paymentsBeforeRule: Int = 0,
        chargeIndex: Int = 0
    ) -> EditBaseline {
        EditBaseline(
            digits: digits, name: name, date: date, interval: interval, unit: unit,
            paymentCount: paymentCount, categoryID: categoryID, ruleAnchor: ruleAnchor,
            paymentsBeforeRule: paymentsBeforeRule, chargeIndex: chargeIndex
        )
    }

    // MARK: Keypad

    @Test func digitsAppend() {
        #expect(Self.typed("123").digits == "123")
    }

    @Test func aLeadingZeroIsReplaced() {
        #expect(Self.typed("05").digits == "5")
        #expect(Self.typed("00").digits == "0")
    }

    @Test func aDecimalOnEmptyBecomesZeroPoint() {
        #expect(Self.typed(".").digits == "0.")
    }

    @Test func onlyOneDecimalPoint() {
        #expect(Self.typed("1.2.").digits == "1.2")
    }

    @Test func atMostTwoDecimals() {
        #expect(Self.typed("1.234").digits == "1.23")
    }

    @Test func atMostSevenWholeDigits() {
        #expect(Self.typed("12345678").digits == "1234567")
        #expect(Self.typed("12345678.5").digits == "1234567.5")
    }

    @Test func deleteRemovesTheLast() {
        #expect(Self.typed("12<").digits == "1")
        #expect(Self.typed("1.<").digits == "1")
    }

    @Test func deleteOnEmptyDoesNothing() {
        #expect(Self.typed("<").digits == "")
    }

    // MARK: Amount

    @Test func anEmptyOrZeroAmountIsNil() {
        for keys in ["", "0", ".", "0.00"] {
            #expect(Self.typed(keys).amount == nil)
        }
    }

    @Test func amountParsesDecimals() {
        #expect(Self.typed("1250.5").amount == Decimal(string: "1250.5"))
        #expect(Self.typed("12.").amount == 12)
    }

    // MARK: Validity

    @Test func invalidWithoutAmount() {
        var draft = Self.draft()
        draft.name = "Rent"
        draft.categoryID = UUID()
        #expect(!draft.isValid(categoryExists: { _ in true }))
    }

    @Test func invalidWithBlankName() {
        var draft = Self.validDraft()
        draft.name = "  "
        #expect(!draft.isValid(categoryExists: { _ in true }))
    }

    @Test func invalidWithoutCategory() {
        var draft = Self.validDraft()
        draft.categoryID = nil
        #expect(!draft.isValid(categoryExists: { _ in true }))
    }

    @Test func invalidWhenTheCategoryNoLongerExists() {
        let draft = Self.validDraft()
        #expect(!draft.isValid(categoryExists: { _ in false }))
    }

    @Test func validWithAllThree() {
        let draft = Self.validDraft()
        #expect(draft.isValid(categoryExists: { _ in true }))
    }

    // MARK: Date

    @Test func todayIsNotFuture() {
        #expect(!Self.draft().isFuture(today: Self.today, calendar: Self.calendar))
    }

    @Test func tomorrowIsFuture() {
        var draft = Self.draft()
        draft.date = Self.date(2026, 9, 20)
        #expect(draft.isFuture(today: Self.today, calendar: Self.calendar))
    }

    @Test func theDateStartsAsTodayAtStartOfDay() {
        let midAfternoon = Self.calendar.date(from: DateComponents(year: 2026, month: 9, day: 19, hour: 15))!
        let draft = ExpenseDraft(today: midAfternoon, calendar: Self.calendar)
        #expect(draft.date == Self.date(2026, 9, 19))
    }

    // MARK: Labels

    @Test func repeatLabelsForIntervalOne() {
        var draft = Self.draft()
        let expected: [(RecurrenceUnit, String)] = [
            (.day, "Daily"), (.week, "Weekly"), (.month, "Monthly"), (.year, "Yearly")
        ]
        for (unit, label) in expected {
            draft.unit = unit
            #expect(draft.repeatLabel(calendar: Self.calendar, locale: Self.locale) == label)
        }
    }

    @Test func repeatLabelPluralises() {
        var draft = Self.draft()
        draft.interval = 3
        draft.unit = .month
        #expect(draft.repeatLabel(calendar: Self.calendar, locale: Self.locale) == "3 months")
        draft.interval = 2
        draft.unit = .week
        #expect(draft.repeatLabel(calendar: Self.calendar, locale: Self.locale) == "2 weeks")
    }

    @Test func aCountedRepeatShowsTheLastPaymentMonth() {
        var draft = Self.draft()
        draft.date = Self.date(2026, 6, 18)
        draft.paymentCount = 12
        #expect(draft.repeatLabel(calendar: Self.calendar, locale: Self.locale) == "05/27")
    }

    @Test func dateLabelHasNoYear() {
        var draft = Self.draft()
        draft.date = Self.date(2027, 3, 3)
        #expect(draft.dateLabel(calendar: Self.calendar, locale: Self.locale) == "Mar 3")
    }

    @Test func amountTextOnEmptyIsZero() {
        #expect(Self.draft().amountText(locale: Self.locale) == "\u{20AC}0")
    }

    @Test func amountTextKeepsATrailingDecimal() {
        #expect(Self.typed("1250.").amountText(locale: Self.locale) == "\u{20AC}1,250.")
        #expect(Self.typed("1250.5").amountText(locale: Self.locale) == "\u{20AC}1,250.5")
    }

    @Test func amountTextUsesTheLocalesOwnCurrency() {
        let text = Self.typed("1250.5").amountText(locale: Locale(identifier: "en_US"))
        #expect(text == "$1,250.5")
    }

    // MARK: The end

    @Test func aCountedRuleEndsOnTheLastPayment() {
        var draft = Self.draft()
        draft.date = Self.date(2026, 6, 18)
        draft.paymentCount = 12
        let rule = draft.rule(calendar: Self.calendar)
        #expect(rule.anchorDate == Self.date(2026, 6, 18))
        #expect(rule.endDate == Self.date(2027, 5, 18))
        #expect(draft.lastPaymentDate(calendar: Self.calendar) == Self.date(2027, 5, 18))
    }

    @Test func anUncountedRuleHasNoEnd() {
        let draft = Self.draft()
        #expect(draft.rule(calendar: Self.calendar).endDate == nil)
        #expect(draft.lastPaymentDate(calendar: Self.calendar) == nil)
    }

    @Test func theCaptionNamesTheLastPayment() {
        var draft = Self.draft()
        draft.date = Self.date(2026, 10, 30)
        draft.paymentCount = 12
        let caption = draft.lastPaymentCaption(calendar: Self.calendar, locale: Self.locale)
        #expect(caption == "Last payment Sep 30, 2027")
        #expect(Self.draft().lastPaymentCaption(calendar: Self.calendar, locale: Self.locale) == nil)
    }

    // MARK: Editing — digits from a stored amount

    @Test func digitsForWholeAmount() {
        #expect(ExpenseDraft.digits(for: 950) == "950")
    }

    @Test func digitsForOneDecimal() {
        #expect(ExpenseDraft.digits(for: Decimal(string: "74.1")!) == "74.1")
    }

    @Test func digitsDropATrailingZero() {
        #expect(ExpenseDraft.digits(for: Decimal(string: "12.50")!) == "12.5")
    }

    // MARK: Editing — opening a baseline

    @Test func editingCopiesTheBaseline() {
        let categoryID = UUID()
        let baseline = Self.baseline(
            digits: "45", name: "Gym", date: Self.date(2026, 10, 1), interval: 2, unit: .week,
            paymentCount: 20, categoryID: categoryID, ruleAnchor: Self.date(2026, 1, 1),
            paymentsBeforeRule: 2, chargeIndex: 5
        )
        let draft = ExpenseDraft(editing: baseline)
        #expect(draft.digits == "45")
        #expect(draft.name == "Gym")
        #expect(draft.date == Self.date(2026, 10, 1))
        #expect(draft.interval == 2)
        #expect(draft.unit == .week)
        #expect(draft.paymentCount == 20)
        #expect(draft.categoryID == categoryID)
        #expect(draft.baseline == baseline)
    }

    @Test func anUntouchedEditHasNoChanges() {
        let draft = ExpenseDraft(editing: Self.baseline())
        #expect(!draft.changes.any)
    }

    @Test func retypingTheSameAmountIsNoChange() {
        var draft = ExpenseDraft(editing: Self.baseline(digits: "12"))
        draft.digits = "12.00"
        #expect(!draft.changes.amount)
    }

    @Test func aTrailingSpaceInTheNameIsNoChange() {
        var draft = ExpenseDraft(editing: Self.baseline(name: "Rent"))
        draft.name = "Rent  "
        #expect(!draft.changes.name)
    }

    // MARK: Editing — validity

    @Test func zeroIsValidWhenEditing() {
        var draft = ExpenseDraft(editing: Self.baseline(digits: "12"))
        draft.digits = "0"
        #expect(draft.isValid(categoryExists: { _ in true }))
    }

    @Test func zeroIsInvalidWhenAdding() {
        var draft = Self.draft()
        draft.digits = "0"
        draft.name = "Rent"
        draft.categoryID = UUID()
        #expect(!draft.isValid(categoryExists: { _ in true }))
    }

    @Test func zeroWithARepeatChangeIsInvalid() {
        var draft = ExpenseDraft(editing: Self.baseline(digits: "12"))
        draft.digits = "0"
        draft.interval = 3
        #expect(!draft.isValid(categoryExists: { _ in true }))
    }

    // MARK: Editing — save intent

    @Test func intentIsNothingWithoutAChange() {
        let draft = ExpenseDraft(editing: Self.baseline())
        #expect(draft.saveIntent(hasLaterCharge: true) == .nothing)
    }

    @Test func aRepeatChangeIsFutureWithoutAsking() {
        var draft = ExpenseDraft(editing: Self.baseline())
        draft.interval = 3
        #expect(draft.saveIntent(hasLaterCharge: true) == .futureCharges)
        #expect(draft.saveIntent(hasLaterCharge: false) == .futureCharges)
    }

    @Test func zeroSavesForThisChargeWithoutAsking() {
        var draft = ExpenseDraft(editing: Self.baseline(digits: "12"))
        draft.digits = "0"
        #expect(draft.saveIntent(hasLaterCharge: true) == .thisCharge)
    }

    @Test func anAmountChangeAsksWhenAChargeFollows() {
        var draft = ExpenseDraft(editing: Self.baseline(digits: "12"))
        draft.digits = "15"
        #expect(draft.saveIntent(hasLaterCharge: true) == .askScope)
    }

    @Test func anAmountChangeOnTheLastChargeIsThisCharge() {
        var draft = ExpenseDraft(editing: Self.baseline(digits: "12"))
        draft.digits = "15"
        #expect(draft.saveIntent(hasLaterCharge: false) == .thisCharge)
    }

    @Test func aDateChangeAsks() {
        var draft = ExpenseDraft(editing: Self.baseline())
        draft.date = Self.date(2026, 9, 20)
        #expect(draft.saveIntent(hasLaterCharge: true) == .askScope)
        #expect(draft.saveIntent(hasLaterCharge: false) == .thisCharge)
    }

    @Test func aNameChangeIsTheWholeBill() {
        var draft = ExpenseDraft(editing: Self.baseline())
        draft.name = "Gym membership"
        #expect(draft.saveIntent(hasLaterCharge: true) == .wholeBill)
    }

    @Test func aCountChangeIsTheWholeBill() {
        var draft = ExpenseDraft(editing: Self.baseline(paymentCount: 12))
        draft.paymentCount = 10
        #expect(draft.saveIntent(hasLaterCharge: true) == .wholeBill)
    }

    // MARK: Editing — the minimum count

    @Test func theMinimumCountIncludesTheOpenCharge() {
        let draft = ExpenseDraft(editing: Self.baseline(paymentsBeforeRule: 4, chargeIndex: 3))
        #expect(draft.minimumPaymentCount == 8)
    }

    @Test func theMinimumCountIsNeverBelowTwo() {
        let draft = ExpenseDraft(editing: Self.baseline(paymentsBeforeRule: 0, chargeIndex: 0))
        #expect(draft.minimumPaymentCount == 2)
    }

    // MARK: Editing — the last payment

    @Test func lastPaymentCountsTheWholeBill() {
        let baseline = Self.baseline(
            date: Self.date(2026, 9, 18), paymentCount: 12, ruleAnchor: Self.date(2026, 6, 18),
            paymentsBeforeRule: 0, chargeIndex: 3
        )
        let draft = ExpenseDraft(editing: baseline)
        #expect(draft.lastPaymentDate(calendar: Self.calendar) == Self.date(2027, 5, 18))
    }

    @Test func lastPaymentCountsEarlierRecords() {
        let baseline = Self.baseline(
            date: Self.date(2026, 6, 18), paymentCount: 12, ruleAnchor: Self.date(2026, 6, 18),
            paymentsBeforeRule: 4, chargeIndex: 0
        )
        let draft = ExpenseDraft(editing: baseline)
        #expect(draft.lastPaymentDate(calendar: Self.calendar) == Self.date(2027, 1, 18))
    }

    @Test func lastPaymentFromAMonthEndAnchorDoesNotDrift() throws {
        let baseline = Self.baseline(
            date: Self.date(2027, 2, 28), paymentCount: 12, ruleAnchor: Self.date(2027, 1, 31),
            paymentsBeforeRule: 0, chargeIndex: 1
        )
        let draft = ExpenseDraft(editing: baseline)
        let last = try #require(draft.lastPaymentDate(calendar: Self.calendar))
        #expect(Self.calendar.component(.day, from: last) == 31)
    }

    @Test func lastPaymentAfterARepeatChangeCountsFromTheCharge() {
        let baseline = Self.baseline(
            date: Self.date(2026, 9, 18), paymentCount: 12, ruleAnchor: Self.date(2026, 6, 18),
            paymentsBeforeRule: 0, chargeIndex: 3
        )
        var draft = ExpenseDraft(editing: baseline)
        draft.unit = .week
        #expect(draft.lastPaymentDate(calendar: Self.calendar) == Self.date(2026, 11, 13))
    }
}

@Suite struct EmojiInputTests {
    @Test func takesTheLastEmoji() {
        #expect(EmojiInput.emoji(from: "🏠🚗") == "🚗")
        #expect(EmojiInput.emoji(from: "ab🏠x") == "🏠")
    }

    @Test func keepsAFlagWhole() {
        #expect(EmojiInput.emoji(from: "🇮🇪") == "🇮🇪")
        #expect(EmojiInput.emoji(from: "x🇮🇪") == "🇮🇪")
    }

    @Test func keepsASkinToneWhole() {
        #expect(EmojiInput.emoji(from: "👍🏽") == "👍🏽")
    }

    @Test func keepsAJoinedSequenceWhole() {
        #expect(EmojiInput.emoji(from: "🏠👨‍👩‍👧") == "👨‍👩‍👧")
    }

    @Test func rejectsPlainLetters() {
        #expect(EmojiInput.emoji(from: "abc") == nil)
        #expect(EmojiInput.emoji(from: "123") == nil)
    }

    @Test func emptyGivesNil() {
        #expect(EmojiInput.emoji(from: "") == nil)
    }
}
