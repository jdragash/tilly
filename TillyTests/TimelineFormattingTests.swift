import Foundation
import Testing
@testable import Tilly

@Suite struct TimelineFormattingTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static let locale = Locale(identifier: "en_IE")

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test func anAmountCarriesAMinusAndNoDecimals() {
        #expect(TimelineFormatting.amount(950, locale: Self.locale) == "\u{2212}\u{20AC}950")
    }

    @Test func aZeroTotalCarriesNoSign() {
        #expect(TimelineFormatting.amount(0, locale: Self.locale) == "\u{20AC}0")
    }

    @Test func aMissingAmountRendersAnEmDash() {
        #expect(TimelineFormatting.amount(nil, locale: Self.locale) == "\u{2014}")
    }

    @Test func aDateLineReadsAsWeekdayThenDay() {
        let line = TimelineFormatting.dayLine(Self.date(2027, 1, 30), calendar: Self.calendar, locale: Self.locale)
        #expect(line == "Sat 30")
    }

    @Test func anAccessibilityLabelNamesTheState() {
        let entry = TimelineEntry(
            id: "1", name: "Water", date: Self.date(2027, 1, 30), amount: 38, state: .upcoming
        )
        let label = TimelineFormatting.accessibilityLabel(for: entry, calendar: Self.calendar, locale: Self.locale)
        #expect(label.contains("Water"))
        #expect(label.contains("upcoming"))
    }

    /// The label used to say "euro" whatever the device was set to, while the screen beside
    /// it rendered dollars. Pinned to a non-euro locale so the suite would catch it again.
    @Test func aSpokenAmountNamesTheDevicesOwnCurrency() {
        let entry = TimelineEntry(
            id: "1", name: "Rent", date: Self.date(2027, 1, 30), amount: 950, state: .charged
        )
        let label = TimelineFormatting.accessibilityLabel(
            for: entry, calendar: Self.calendar, locale: Locale(identifier: "en_US")
        )
        #expect(label.localizedCaseInsensitiveContains("dollars"))
        #expect(!label.localizedCaseInsensitiveContains("euro"))
    }

    @Test func aSkippedRowsLabelSaysSkipped() {
        let entry = TimelineEntry(
            id: "1", name: "Streaming video", date: Self.date(2027, 1, 1), amount: 18, state: .skipped
        )
        let label = TimelineFormatting.accessibilityLabel(for: entry, calendar: Self.calendar, locale: Self.locale)
        #expect(label.contains("skipped"))
    }

    @Test func aSectionLabelCarriesTheMonthAndItsTotal() {
        let month = MonthKey(year: 2027, month: 9)
        let section = MonthSection(month: month, days: [], total: 1521)
        let label = TimelineFormatting.accessibilityLabel(
            for: section, calendar: Self.calendar, today: Self.date(2027, 9, 15), locale: Self.locale
        )
        #expect(label.contains("September"))
        #expect(label.contains("1,521") || label.contains("1521"))
    }
}
