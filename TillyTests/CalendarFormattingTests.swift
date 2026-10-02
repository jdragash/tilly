import Foundation
import Testing
@testable import Tilly

@Suite struct CalendarFormattingTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static let euro = Locale(identifier: "en_IE")
    static let us = Locale(identifier: "en_US")

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func entry(_ name: String, day: Int, amount: Decimal?) -> TimelineEntry {
        TimelineEntry(
            id: "\(name)\(day)", expenseID: UUID(), scheduledDate: date(2027, 1, day), name: name, emoji: nil,
            date: date(2027, 1, day), amount: amount, state: .upcoming, endDate: nil, endHasPassed: false,
            isExtra: true, startsRecord: false
        )
    }

    static func section(
        entries: [TimelineEntry] = [], total: Decimal = 0, remaining: Decimal = 0,
        isCurrent: Bool = false, extrasOnly: Bool = false
    ) -> MonthSection {
        MonthSection(
            month: MonthKey(year: 2027, month: 1), entries: entries, total: total, remaining: remaining,
            isCurrent: isCurrent, showsExtrasOnly: extrasOnly
        )
    }

    // The 4th of January 2027 is a Monday.
    static func day(_ entries: [TimelineEntry], total: Decimal) -> CalendarDay {
        CalendarDay(day: 4, date: date(2027, 1, 4), entries: entries, total: total, isUpcoming: true)
    }

    @Test func emptyMonthSaysNothing() {
        #expect(CalendarFormatting.monthFigure(for: Self.section(), locale: Self.euro) == "Nothing this month")
    }

    @Test func emptyCurrentMonthKeepsLeft() {
        let figure = CalendarFormatting.monthFigure(for: Self.section(isCurrent: true), locale: Self.euro)
        #expect(figure == "\u{20AC}0 left")
    }

    @Test func aMonthWithChargesReadsAsTheTimelineDoes() {
        let section = Self.section(entries: [Self.entry("Rent", day: 3, amount: 950)], total: 950, remaining: 950)
        #expect(CalendarFormatting.monthFigure(for: section, locale: Self.euro) == "\u{20AC}950")
    }

    @Test func extrasFigureHasPlusAndOnTop() {
        let entries = [Self.entry("Insurance", day: 3, amount: 351)]
        let past = Self.section(entries: entries, total: 351, remaining: 0, extrasOnly: true)
        let current = Self.section(entries: entries, total: 351, remaining: 100, isCurrent: true, extrasOnly: true)
        #expect(CalendarFormatting.monthFigure(for: past, locale: Self.euro) == "+\u{20AC}351 on top")
        #expect(TimelineFormatting.headerFigure(for: current, locale: Self.euro) == "+\u{20AC}351 on top")
        #expect(CalendarFormatting.monthFigure(for: current, locale: Self.euro) == "+\u{20AC}351 on top")
    }

    @Test func extrasEmptySaysNothingOnTop() {
        let empty = Self.section(extrasOnly: true)
        let current = Self.section(isCurrent: true, extrasOnly: true)
        #expect(CalendarFormatting.monthFigure(for: empty, locale: Self.euro) == "Nothing on top")
        #expect(TimelineFormatting.headerFigure(for: empty, locale: Self.euro) == "Nothing on top")
        #expect(CalendarFormatting.monthFigure(for: current, locale: Self.euro) == "Nothing on top")
    }

    @Test func dayLabelReadsChargesAndTotal() {
        let entries = [Self.entry("Rent", day: 4, amount: 950), Self.entry("Gym", day: 4, amount: 235)]
        let day = Self.day(entries, total: 1185)
        #expect(CalendarFormatting.dayLabel(day, calendar: Self.calendar, locale: Self.euro) == "Mon 4, 2 charges, 1,185 euros out")
        #expect(CalendarFormatting.dayLabel(day, calendar: Self.calendar, locale: Self.us) == "Mon 4, 2 charges, 1,185 US dollars out")
    }

    @Test func dayLabelUsesTheSingularForOneCharge() {
        let day = Self.day([Self.entry("Rent", day: 4, amount: 950)], total: 950)
        #expect(CalendarFormatting.dayLabel(day, calendar: Self.calendar, locale: Self.euro) == "Mon 4, 1 charge, 950 euros out")
    }

    @Test func dayLabelForAnEmptyDay() {
        let day = Self.day([], total: 0)
        #expect(CalendarFormatting.dayLabel(day, calendar: Self.calendar, locale: Self.euro) == "Mon 4, no charges")
    }
}
