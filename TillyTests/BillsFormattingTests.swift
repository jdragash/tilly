import Foundation
import Testing
import TillyCore
@testable import Tilly

@Suite struct BillsFormattingTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    /// Euros with US ordering, so "Nov 10" reads as the spec writes it.
    static let euro = Locale(identifier: "en_US@currency=EUR")
    static let us = Locale(identifier: "en_US")

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func row(
        charge: Decimal? = 25, every interval: Int = 1, _ unit: RecurrenceUnit = .month, state: BillState = .runs
    ) -> BillRow {
        BillRow(
            id: UUID(), name: "Bill", categoryID: nil, charge: charge,
            rule: RecurrenceRule(interval: interval, unit: unit, anchorDate: date(2026, 1, 1)),
            figure: charge, state: state, paidInAll: 0, opens: nil
        )
    }

    static func note(_ row: BillRow, _ period: BillPeriod, locale: Locale = euro) -> String {
        BillsFormatting.note(for: row, period: period, calendar: calendar, locale: locale)
    }

    @Test func aMonthlyBillInMonthlyIsJustMonthly() {
        #expect(Self.note(Self.row(), .month) == "Monthly")
    }

    @Test func aYearlyBillInYearlyIsJustYearly() {
        #expect(Self.note(Self.row(every: 1, .year), .year) == "Yearly")
    }

    @Test func aYearlyBillInMonthlyNamesItsCharge() {
        #expect(Self.note(Self.row(charge: 640, every: 1, .year), .month) == "\u{20AC}640 yearly")
    }

    @Test func aMonthlyBillInYearlyNamesItsCharge() {
        #expect(Self.note(Self.row(charge: 1150, every: 1, .month), .year) == "\u{20AC}1,150 monthly")
    }

    @Test func aLongerRhythmNamesItsInterval() {
        #expect(Self.note(Self.row(charge: 41, every: 2, .month), .month) == "\u{20AC}41 every 2 months")
        #expect(Self.note(Self.row(charge: 41, every: 2, .month), .year) == "\u{20AC}41 every 2 months")
        #expect(Self.note(Self.row(charge: 15, every: 2, .week), .month) == "\u{20AC}15 every 2 weeks")
        #expect(Self.note(Self.row(charge: 3, every: 1, .day), .month) == "\u{20AC}3 daily")
        #expect(Self.note(Self.row(charge: 3, every: 1, .week), .year) == "\u{20AC}3 weekly")
        #expect(Self.note(Self.row(charge: 90, every: 2, .year), .month) == "\u{20AC}90 every 2 years")
    }

    @Test func aChangeNamesTheOldAmountAndTheDate() {
        let row = Self.row(state: .changes(Self.date(2027, 11, 10), from: 25))
        #expect(Self.note(row, .month) == "\u{20AC}25 until Nov 10")
        // In Yearly a monthly bill is no longer its own figure, so its charge is named first.
        #expect(Self.note(row, .year) == "\u{20AC}25 monthly \u{00B7} \u{20AC}25 until Nov 10")
    }

    @Test func aChangeFollowsTheChargeWhenItIsNamed() {
        let row = Self.row(charge: 640, every: 1, .year, state: .changes(Self.date(2027, 11, 10), from: 600))
        #expect(Self.note(row, .month) == "\u{20AC}640 yearly \u{00B7} \u{20AC}600 until Nov 10")
    }

    @Test func aBillNotStartedYetReadsFrom() {
        let row = Self.row(state: .starts(Self.date(2027, 10, 18)))
        #expect(Self.note(row, .month) == "from Oct 18")
    }

    @Test func aBillWithAnEndReadsEnds() {
        let row = Self.row(state: .ends(Self.date(2027, 12, 10)))
        #expect(Self.note(row, .month) == "ends 12/27")
        let named = Self.row(charge: 640, every: 1, .year, state: .ends(Self.date(2027, 12, 10)))
        #expect(Self.note(named, .month) == "\u{20AC}640 yearly \u{00B7} ends 12/27")
    }

    @Test func anEndedBillReadsEndedAlone() {
        let row = Self.row(charge: 640, every: 1, .year, state: .ended(Self.date(2026, 8, 10)))
        #expect(Self.note(row, .month) == "ended 08/26")
    }

    @Test func dollarsFollowTheLocale() {
        #expect(Self.note(Self.row(charge: 640, every: 1, .year), .month, locale: Self.us) == "$640 yearly")
        let row = Self.row(state: .changes(Self.date(2027, 11, 10), from: 25))
        #expect(Self.note(row, .month, locale: Self.us) == "$25 until Nov 10")
    }

    @Test func totalsReadAMonthOrAYear() {
        #expect(BillsFormatting.total(1563, period: .month, locale: Self.euro) == "\u{20AC}1,563 a month")
        #expect(BillsFormatting.total(18756, period: .year, locale: Self.euro) == "\u{20AC}18,756 a year")
        #expect(BillsFormatting.total(1563, period: .month, locale: Self.us) == "$1,563 a month")
    }
}
