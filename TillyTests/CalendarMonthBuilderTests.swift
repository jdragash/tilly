import Foundation
import Testing
@testable import Tilly

@Suite struct CalendarMonthBuilderTests {
    static func calendar(firstWeekday: Int = 1) -> Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        cal.firstWeekday = firstWeekday
        return cal
    }

    static let january = MonthKey(year: 2027, month: 1) // starts on a Friday, 31 days
    static let february = MonthKey(year: 2027, month: 2) // starts on a Monday, 28 days

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar().date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func entry(
        _ name: String, day: Int, amount: Decimal?, state: OccurrenceState = .upcoming, month: Int = 1
    ) -> TimelineEntry {
        TimelineEntry(
            id: "\(name)\(day)", expenseID: UUID(), scheduledDate: date(2027, month, day), name: name, emoji: nil,
            date: date(2027, month, day), amount: amount, state: state, endDate: nil, endHasPassed: false,
            isExtra: false, startsRecord: false
        )
    }

    static func build(
        _ entries: [TimelineEntry], key: MonthKey = january, today: Date = date(2027, 1, 15), firstWeekday: Int = 1
    ) -> CalendarMonth {
        let section = MonthSection(
            month: key, entries: entries, total: 0, remaining: 0, isCurrent: false, showsExtrasOnly: false
        )
        return CalendarMonthBuilder.month(section, today: today, calendar: calendar(firstWeekday: firstWeekday))
    }

    @Test func everyDayIsPresent() {
        let month = Self.build([])
        #expect(month.days.count == 31)
        #expect(month.days.map(\.day) == Array(1...31))
        #expect(month.days.first?.date == Self.date(2027, 1, 1))
        #expect(month.days.allSatisfy { $0.entries.isEmpty && $0.total == 0 })
    }

    @Test func leadingDaysFollowFirstWeekday() {
        // 1 January 2027 is a Friday.
        #expect(Self.build([], firstWeekday: 1).leadingDays == 5)
        #expect(Self.build([], firstWeekday: 2).leadingDays == 4)
        // 1 February 2027 is a Monday.
        #expect(Self.build([], key: Self.february, firstWeekday: 1).leadingDays == 1)
        #expect(Self.build([], key: Self.february, firstWeekday: 2).leadingDays == 0)
    }

    @Test func trailingDaysCompleteTheWeek() {
        #expect(Self.build([], firstWeekday: 1).trailingDays == 6) // 5 + 31 = 36 cells
        #expect(Self.build([], firstWeekday: 2).trailingDays == 0) // 4 + 31 = 35 cells
        #expect(Self.build([], key: Self.february, firstWeekday: 1).trailingDays == 6) // 1 + 28 = 29 cells
        #expect(Self.build([], key: Self.february, firstWeekday: 2).trailingDays == 0) // 0 + 28 cells
    }

    @Test func dayEntriesSortByAmount() {
        let month = Self.build([
            Self.entry("Unknown", day: 5, amount: nil),
            Self.entry("Gym", day: 5, amount: 20),
            Self.entry("Rent", day: 5, amount: 950),
            Self.entry("Phone", day: 5, amount: 950),
        ])
        #expect(month.days[4].entries.map(\.name) == ["Phone", "Rent", "Gym", "Unknown"])
    }

    @Test func skippedChargeLeavesTheDay() {
        let month = Self.build([
            Self.entry("Rent", day: 10, amount: 950, state: .skipped),
            Self.entry("Gym", day: 10, amount: 20),
        ])
        #expect(month.days[9].entries.map(\.name) == ["Gym"])
        #expect(month.days[9].total == 20)
    }

    @Test func nilAmountAddsNothing() {
        let month = Self.build([
            Self.entry("Gym", day: 10, amount: 40),
            Self.entry("Unknown", day: 10, amount: nil),
        ])
        #expect(month.days[9].entries.count == 2)
        #expect(month.days[9].total == 40)
    }

    @Test func todayIsNotUpcoming() {
        let month = Self.build([], today: Self.date(2027, 1, 15))
        #expect(!month.days[13].isUpcoming) // the 14th
        #expect(!month.days[14].isUpcoming) // the 15th, today
        #expect(month.days[15].isUpcoming) // the 16th
    }
}
