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

    @Test func anAmountIsTheMagnitudeWithNoDecimals() {
        #expect(TimelineFormatting.amount(950, locale: Self.locale) == "\u{20AC}950")
    }

    @Test func aZeroTotalCarriesNoSign() {
        #expect(TimelineFormatting.amount(0, locale: Self.locale) == "\u{20AC}0")
    }

    @Test func aMissingAmountRendersAnEmDash() {
        #expect(TimelineFormatting.amount(nil, locale: Self.locale) == "\u{2014}")
    }

    static func entry(
        name: String = "Loan", date: Date, scheduledDate: Date? = nil, state: OccurrenceState = .upcoming,
        endDate: Date? = nil, endHasPassed: Bool = false, isYearly: Bool = false
    ) -> TimelineEntry {
        TimelineEntry(
            id: "1", expenseID: UUID(), scheduledDate: scheduledDate ?? date, name: name, picture: .none, colour: nil,
            date: date, amount: 120, state: state, endDate: endDate, endHasPassed: endHasPassed,
            isExtra: false, startsRecord: false, isYearly: isYearly
        )
    }

    static func rowDate(_ date: Date, today: Date) -> String {
        TimelineFormatting.rowDate(date, today: today, calendar: calendar, locale: locale)
    }

    static func endLine(_ entry: TimelineEntry, today: Date) -> String? {
        TimelineFormatting.endLine(for: entry, today: today, calendar: calendar, locale: locale)
    }

    static func label(_ entry: TimelineEntry, today: Date) -> String {
        TimelineFormatting.accessibilityLabel(for: entry, today: today, calendar: calendar, locale: locale)
    }

    // MARK: Row dates

    @Test func aRowDateIsDayThenMonth() {
        #expect(Self.rowDate(Self.date(2026, 10, 18), today: Self.date(2026, 10, 24)) == "18 Oct")
    }

    @Test func aRowDateTodayLeadsWithTheWord() {
        #expect(Self.rowDate(Self.date(2026, 10, 24), today: Self.date(2026, 10, 24)) == "Today \u{00B7} 24 Oct")
    }

    @Test func tomorrowAndYesterdayLeadWithTheirWords() {
        let today = Self.date(2026, 10, 31)
        #expect(Self.rowDate(Self.date(2026, 11, 1), today: today) == "Tomorrow \u{00B7} 1 Nov")
        #expect(Self.rowDate(Self.date(2026, 10, 30), today: today) == "Yesterday \u{00B7} 30 Oct")
    }

    @Test func twoDaysOffIsJustTheDate() {
        let today = Self.date(2026, 10, 24)
        #expect(Self.rowDate(Self.date(2026, 10, 26), today: today) == "26 Oct")
        #expect(Self.rowDate(Self.date(2026, 10, 22), today: today) == "22 Oct")
    }

    @Test func aRowDateNextYearCarriesNoYear() {
        #expect(Self.rowDate(Self.date(2027, 3, 5), today: Self.date(2026, 10, 24)) == "5 Mar")
    }

    // MARK: Ends

    @Test func anEndThisMonthSaysSo() {
        let entry = Self.entry(date: Self.date(2026, 10, 5), endDate: Self.date(2026, 10, 28))
        #expect(Self.endLine(entry, today: Self.date(2026, 10, 24)) == "ends this month")
    }

    @Test func anEndNextMonthSaysSo() {
        let entry = Self.entry(date: Self.date(2026, 10, 5), endDate: Self.date(2026, 11, 5))
        #expect(Self.endLine(entry, today: Self.date(2026, 10, 24)) == "ends next month")
    }

    @Test func anEndAcrossNewYearCountsCalendarMonths() {
        let entry = Self.entry(date: Self.date(2026, 12, 5), endDate: Self.date(2027, 1, 5))
        #expect(Self.endLine(entry, today: Self.date(2026, 12, 20)) == "ends next month")
    }

    @Test func anEndFurtherOffIsMonthAndYear() {
        let entry = Self.entry(date: Self.date(2026, 9, 18), endDate: Self.date(2027, 5, 18))
        #expect(Self.endLine(entry, today: Self.date(2026, 9, 15)) == "ends 05/27")
    }

    @Test func theLastChargeSaysLastPayment() {
        let end = Self.date(2027, 5, 18)
        let entry = Self.entry(date: end, endDate: end)
        #expect(Self.endLine(entry, today: Self.date(2026, 9, 15)) == "Last payment")
    }

    @Test func aPassedLastChargeStillSaysLastPayment() {
        let end = Self.date(2026, 8, 26)
        let entry = Self.entry(date: end, state: .charged, endDate: end, endHasPassed: true)
        #expect(Self.endLine(entry, today: Self.date(2026, 9, 18)) == "Last payment")
    }

    @Test func anEarlierChargeOfAnEndedBillReadsEnded() {
        let entry = Self.entry(
            date: Self.date(2026, 7, 26), state: .charged, endDate: Self.date(2026, 8, 26), endHasPassed: true
        )
        #expect(Self.endLine(entry, today: Self.date(2026, 9, 18)) == "ended 08/26")
    }

    @Test func noEndHasNoEndLine() {
        let entry = Self.entry(date: Self.date(2026, 9, 18))
        #expect(Self.endLine(entry, today: Self.date(2026, 9, 15)) == nil)
    }

    @Test func theTodayDividerNamesTheDate() {
        let line = TimelineFormatting.todayDivider(Self.date(2026, 10, 24), calendar: Self.calendar, locale: Self.locale)
        #expect(line == "Today, 24 Oct")
    }

    // MARK: Accessibility

    @Test func anAccessibilityLabelSaysLastPayment() {
        let end = Self.date(2027, 5, 18)
        let entry = Self.entry(date: end, endDate: end)
        #expect(Self.label(entry, today: Self.date(2026, 9, 15)).contains(", last payment, upcoming"))
    }

    @Test func aYearlyChargeIsSpokenAsYearly() {
        let entry = Self.entry(date: Self.date(2026, 11, 3), isYearly: true)
        #expect(Self.label(entry, today: Self.date(2026, 9, 15)).contains(" out, yearly, upcoming"))
    }

    @Test func aChargeTodayIsSpokenAsToday() {
        let entry = Self.entry(name: "Rent", date: Self.date(2026, 10, 24), state: .charged)
        #expect(Self.label(entry, today: Self.date(2026, 10, 24)).hasPrefix("Rent, today, Saturday 24 October, "))
    }

    @Test func anAccessibilityLabelNamesTheEnd() {
        let entry = TimelineEntry(
            id: "1", expenseID: UUID(), scheduledDate: Self.date(2026, 9, 18), name: "Loan", picture: .none, colour: nil,
            date: Self.date(2026, 9, 18), amount: 120, state: .upcoming,
            endDate: Self.date(2027, 5, 18), endHasPassed: false, isExtra: false, startsRecord: false, isYearly: false
        )
        let label = TimelineFormatting.accessibilityLabel(for: entry, today: Self.date(2026, 9, 15), calendar: Self.calendar, locale: Self.locale)
        #expect(label.contains(", ends May 2027, upcoming"))
    }

    @Test func aPassedEndIsSpokenAsEnded() {
        let entry = TimelineEntry(
            id: "1", expenseID: UUID(), scheduledDate: Self.date(2026, 9, 18), name: "Gym", picture: .none, colour: nil,
            date: Self.date(2026, 9, 18), amount: 45, state: .charged,
            endDate: Self.date(2026, 8, 26), endHasPassed: true, isExtra: false, startsRecord: false, isYearly: false
        )
        let label = TimelineFormatting.accessibilityLabel(for: entry, today: Self.date(2026, 9, 15), calendar: Self.calendar, locale: Self.locale)
        #expect(label.contains(", ended August 2026, charged"))
    }

    @Test func anAccessibilityLabelNamesTheState() {
        let entry = TimelineEntry(
            id: "1", expenseID: UUID(), scheduledDate: Self.date(2027, 1, 30), name: "Water", picture: .none, colour: nil,
            date: Self.date(2027, 1, 30), amount: 38, state: .upcoming, endDate: nil, endHasPassed: false, isExtra: false, startsRecord: false, isYearly: false
        )
        let label = TimelineFormatting.accessibilityLabel(for: entry, today: Self.date(2026, 9, 15), calendar: Self.calendar, locale: Self.locale)
        #expect(label.contains("Water"))
        #expect(label.contains("upcoming"))
    }

    /// The label used to say "euro" whatever the device was set to, while the screen beside
    /// it rendered dollars. Pinned to a non-euro locale so the suite would catch it again.
    @Test func aSpokenAmountNamesTheDevicesOwnCurrency() {
        let entry = TimelineEntry(
            id: "1", expenseID: UUID(), scheduledDate: Self.date(2027, 1, 30), name: "Rent", picture: .none, colour: nil,
            date: Self.date(2027, 1, 30), amount: 950, state: .charged, endDate: nil, endHasPassed: false, isExtra: false, startsRecord: false, isYearly: false
        )
        let label = TimelineFormatting.accessibilityLabel(
            for: entry, today: Self.date(2026, 9, 15), calendar: Self.calendar, locale: Locale(identifier: "en_US")
        )
        #expect(label.localizedCaseInsensitiveContains("dollars"))
        #expect(!label.localizedCaseInsensitiveContains("euro"))
    }

    @Test func aSkippedRowsLabelSaysSkipped() {
        let entry = TimelineEntry(
            id: "1", expenseID: UUID(), scheduledDate: Self.date(2027, 1, 1), name: "Streaming video", picture: .none, colour: nil,
            date: Self.date(2027, 1, 1), amount: 18, state: .skipped, endDate: nil, endHasPassed: false, isExtra: false, startsRecord: false, isYearly: false
        )
        let label = TimelineFormatting.accessibilityLabel(for: entry, today: Self.date(2026, 9, 15), calendar: Self.calendar, locale: Self.locale)
        #expect(label.contains("skipped"))
    }

    @Test func aSectionLabelCarriesTheMonthAndItsTotal() {
        let month = MonthKey(year: 2027, month: 9)
        let section = MonthSection(month: month, entries: [], total: 1521, remaining: 0, isCurrent: false, showsExtrasOnly: false)
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
        let section = MonthSection(month: month, entries: [], total: 1521, remaining: 162, isCurrent: true, showsExtrasOnly: false)
        let label = TimelineFormatting.accessibilityLabel(
            for: section, calendar: Self.calendar, today: Self.date(2027, 9, 15), locale: Self.locale
        )
        #expect(label.contains("September"))
        #expect(label.contains("left"))
        #expect(label.contains("162"))
    }

    @Test func theCurrentMonthsFigureCarriesTheWord() {
        let section = MonthSection(
            month: MonthKey(year: 2027, month: 9), entries: [], total: 1521, remaining: 162, isCurrent: true, showsExtrasOnly: false
        )
        #expect(TimelineFormatting.headerFigure(for: section, locale: Self.locale) == "\u{20AC}162 left")
    }

    @Test func aPastMonthsFigureIsAPlainTotal() {
        let section = MonthSection(month: MonthKey(year: 2027, month: 8), entries: [], total: 1539, remaining: 0, isCurrent: false, showsExtrasOnly: false)
        #expect(TimelineFormatting.headerFigure(for: section, locale: Self.locale) == "\u{20AC}1,539")
    }

    @Test func aFutureMonthsFigureIsAPlainTotal() {
        let section = MonthSection(month: MonthKey(year: 2027, month: 10), entries: [], total: 1400, remaining: 1400, isCurrent: false, showsExtrasOnly: false)
        #expect(TimelineFormatting.headerFigure(for: section, locale: Self.locale) == "\u{20AC}1,400")
    }

    @Test func aSpentOutCurrentMonthReadsZeroLeft() {
        let section = MonthSection(
            month: MonthKey(year: 2027, month: 9), entries: [], total: 1521, remaining: 0, isCurrent: true, showsExtrasOnly: false
        )
        #expect(TimelineFormatting.headerFigure(for: section, locale: Self.locale) == "\u{20AC}0 left")
    }
}
