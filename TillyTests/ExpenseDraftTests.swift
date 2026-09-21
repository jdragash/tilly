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
