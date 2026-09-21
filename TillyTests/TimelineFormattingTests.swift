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

    @Test func aDateLineWithAnEndAddsItsMonth() {
        let entry = TimelineEntry(
            id: "1", name: "Loan", emoji: nil, date: Self.date(2026, 9, 18), amount: 120, state: .upcoming,
            endDate: Self.date(2027, 5, 18)
        )
        let line = TimelineFormatting.dateLine(for: entry, calendar: Self.calendar, locale: Self.locale)
        #expect(line == "Fri 18 \u{00B7} ends 05/27")
    }

    @Test func aDateLineWithNoEndIsJustTheDay() {
        let entry = TimelineEntry(
            id: "1", name: "Rent", emoji: nil, date: Self.date(2026, 9, 18), amount: 950, state: .upcoming, endDate: nil
        )
        let line = TimelineFormatting.dateLine(for: entry, calendar: Self.calendar, locale: Self.locale)
        #expect(line == "Fri 18")
    }

    @Test func anAccessibilityLabelNamesTheEnd() {
        let entry = TimelineEntry(
            id: "1", name: "Loan", emoji: nil, date: Self.date(2026, 9, 18), amount: 120, state: .upcoming,
            endDate: Self.date(2027, 5, 18)
        )
        let label = TimelineFormatting.accessibilityLabel(for: entry, calendar: Self.calendar, locale: Self.locale)
        #expect(label.contains(", ends May 2027, upcoming"))
    }

    @Test func anAccessibilityLabelNamesTheState() {
        let entry = TimelineEntry(
            id: "1", name: "Water", emoji: nil, date: Self.date(2027, 1, 30), amount: 38, state: .upcoming, endDate: nil
        )
        let label = TimelineFormatting.accessibilityLabel(for: entry, calendar: Self.calendar, locale: Self.locale)
        #expect(label.contains("Water"))
        #expect(label.contains("upcoming"))
    }

    /// The label used to say "euro" whatever the device was set to, while the screen beside
    /// it rendered dollars. Pinned to a non-euro locale so the suite would catch it again.
    @Test func aSpokenAmountNamesTheDevicesOwnCurrency() {
        let entry = TimelineEntry(
            id: "1", name: "Rent", emoji: nil, date: Self.date(2027, 1, 30), amount: 950, state: .charged, endDate: nil
        )
        let label = TimelineFormatting.accessibilityLabel(
            for: entry, calendar: Self.calendar, locale: Locale(identifier: "en_US")
        )
        #expect(label.localizedCaseInsensitiveContains("dollars"))
        #expect(!label.localizedCaseInsensitiveContains("euro"))
    }

    @Test func aSkippedRowsLabelSaysSkipped() {
        let entry = TimelineEntry(
            id: "1", name: "Streaming video", emoji: nil, date: Self.date(2027, 1, 1), amount: 18, state: .skipped, endDate: nil
        )
        let label = TimelineFormatting.accessibilityLabel(for: entry, calendar: Self.calendar, locale: Self.locale)
        #expect(label.contains("skipped"))
    }

    @Test func aSectionLabelCarriesTheMonthAndItsTotal() {
        let month = MonthKey(year: 2027, month: 9)
        let section = MonthSection(month: month, entries: [], total: 1521, remaining: 0, isCurrent: false)
        let label = TimelineFormatting.accessibilityLabel(
            for: section, calendar: Self.calendar, today: Self.date(2027, 9, 15), locale: Self.locale
        )
        #expect(label.contains("September"))
        #expect(label.contains("1,521") || label.contains("1521"))
    }

    /// A bar's label never speaks "left", even for the current month — a bar always shows
    /// the plain total, and that includes its accessibility label.
    @Test func theCurrentMonthsLabelSaysWhatIsLeft() {
        let month = MonthKey(year: 2027, month: 9)
        let section = MonthSection(month: month, entries: [], total: 1521, remaining: 162, isCurrent: true)
        let label = TimelineFormatting.accessibilityLabel(
            for: section, calendar: Self.calendar, today: Self.date(2027, 9, 15), locale: Self.locale
        )
        #expect(label.contains("September"))
        #expect(label.contains("left"))
        #expect(label.contains("162"))
    }

    @Test func theCurrentMonthsFigureCarriesTheWord() {
        let section = MonthSection(
            month: MonthKey(year: 2027, month: 9), entries: [], total: 1521, remaining: 162, isCurrent: true
        )
        #expect(TimelineFormatting.headerFigure(for: section, locale: Self.locale) == "\u{2212}\u{20AC}162 left")
    }

    @Test func aPastMonthsFigureIsAPlainTotal() {
        let section = MonthSection(month: MonthKey(year: 2027, month: 8), entries: [], total: 1539, remaining: 0, isCurrent: false)
        #expect(TimelineFormatting.headerFigure(for: section, locale: Self.locale) == "\u{2212}\u{20AC}1,539")
    }

    @Test func aFutureMonthsFigureIsAPlainTotal() {
        let section = MonthSection(month: MonthKey(year: 2027, month: 10), entries: [], total: 1400, remaining: 1400, isCurrent: false)
        #expect(TimelineFormatting.headerFigure(for: section, locale: Self.locale) == "\u{2212}\u{20AC}1,400")
    }

    @Test func aSpentOutCurrentMonthReadsZeroLeft() {
        let section = MonthSection(
            month: MonthKey(year: 2027, month: 9), entries: [], total: 1521, remaining: 0, isCurrent: true
        )
        #expect(TimelineFormatting.headerFigure(for: section, locale: Self.locale) == "\u{20AC}0 left")
    }
}
