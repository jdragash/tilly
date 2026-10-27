import Foundation
import Testing
@testable import Tilly

@Suite struct DaySeamsTests {
    static let calendar = TimelineBuilderTests.calendar
    static let january = MonthKey(year: 2027, month: 1)

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        TimelineBuilderTests.date(year, month, day)
    }

    static func entry(_ name: String, day: Int, state: OccurrenceState = .upcoming, month: Int = 1) -> TimelineEntry {
        TimelineEntry(
            id: "\(name)\(day)", expenseID: UUID(), scheduledDate: date(2027, month, day), name: name, picture: .none,
            colour: nil, date: date(2027, month, day), amount: 10, state: state, endDate: nil, endHasPassed: false,
            isExtra: false, startsRecord: false, isYearly: false
        )
    }

    /// Entries are given in any order and sorted newest first, as a built section's are.
    static func seams(
        _ entries: [TimelineEntry], key: MonthKey = january, isCurrent: Bool = false, today: Date = date(2027, 1, 15)
    ) -> [Int: [Date]] {
        let section = MonthSection(
            month: key, entries: entries.sorted { $0.date > $1.date }, total: 0, remaining: 0,
            isCurrent: isCurrent, showsExtrasOnly: false
        )
        return DaySeams.seams(for: section, today: today, calendar: calendar)
    }

    static func days(_ days: Int...) -> [Date] { days.map { date(2027, 1, $0) } }

    @Test func emptyMonthPutsEveryDayAtZero() {
        let result = Self.seams([])
        #expect(result.keys.sorted() == [0])
        #expect(result[0]?.count == 31)
    }

    @Test func dayBetweenTwoRowsSitsAboveTheOlder() {
        let result = Self.seams([Self.entry("A", day: 20), Self.entry("B", day: 10)])
        // Rows: 20 (index 0), 10 (index 1). Days 11...19 sit above the 10th.
        #expect(result[1] == (11...19).reversed().map { Self.date(2027, 1, $0) })
    }

    @Test func dayNewerThanEveryRowSitsAtZero() {
        let result = Self.seams([Self.entry("A", day: 20), Self.entry("B", day: 10)])
        #expect(result[0] == (21...31).reversed().map { Self.date(2027, 1, $0) })
    }

    @Test func dayOlderThanEveryRowSitsAfterTheLast() {
        let result = Self.seams([Self.entry("A", day: 20), Self.entry("B", day: 10)])
        #expect(result[2] == (1...9).reversed().map { Self.date(2027, 1, $0) })
    }

    @Test func daysWithRowsAreLeftOut() {
        let result = Self.seams([Self.entry("A", day: 20), Self.entry("B", day: 10)])
        let all = result.values.flatMap { $0 }
        #expect(!all.contains(Self.date(2027, 1, 20)))
        #expect(!all.contains(Self.date(2027, 1, 10)))
        #expect(all.count == 29)
    }

    @Test func twoChargesOnADayAreOneSeam() {
        let result = Self.seams([Self.entry("A", day: 20), Self.entry("B", day: 20), Self.entry("C", day: 10)])
        // Rows: 20, 20, 10. Days 11...19 sit above the 10th, at index 2.
        #expect(result[2] == (11...19).reversed().map { Self.date(2027, 1, $0) })
        #expect(result[1] == nil)
        #expect(result.values.flatMap { $0 }.count == 29)
    }

    @Test func futureDayInCurrentMonthSitsAboveTheDivider() {
        // Today is the 15th. Rows: 20 upcoming (0), 12 charged (1). The divider sits before index 1.
        let result = Self.seams(
            [Self.entry("A", day: 20), Self.entry("B", day: 12, state: .charged)], isCurrent: true
        )
        // The 18th is still to come: above the 12th's row, which is where the divider goes.
        #expect(result[1]?.contains(Self.date(2027, 1, 18)) == true)
    }

    @Test func pastDayInCurrentMonthSitsBelowTheDivider() {
        // Today is the 15th. Rows: 20 upcoming (0), 15 charged (1), 10 charged (2). The divider sits
        // before index 1; the 12th is a passed day, below it, above the 10th's row.
        let result = Self.seams(
            [Self.entry("A", day: 20), Self.entry("B", day: 15, state: .charged), Self.entry("C", day: 10, state: .charged)],
            isCurrent: true
        )
        #expect(result[2]?.contains(Self.date(2027, 1, 12)) == true)
        #expect(result[1]?.contains(Self.date(2027, 1, 12)) != true)
    }

    @Test func todayIsLeftOutWhenTheDividerShows() {
        let result = Self.seams([Self.entry("A", day: 20), Self.entry("B", day: 10, state: .charged)], isCurrent: true)
        #expect(!result.values.flatMap { $0 }.contains(Self.date(2027, 1, 15)))
        #expect(result.values.flatMap { $0 }.count == 28)
    }

    @Test func todayIsKeptWhenNothingIsChargedYet() {
        let result = Self.seams([Self.entry("A", day: 20)], isCurrent: true)
        #expect(result[1]?.contains(Self.date(2027, 1, 15)) == true)
    }

    @Test func thirtyFirstOfAShortMonthDoesNotExist() {
        let february = MonthKey(year: 2027, month: 2)
        let result = Self.seams([], key: february, today: Self.date(2027, 1, 15))
        let all = result.values.flatMap { $0 }
        #expect(all.count == 28)
        #expect(all.first == Self.date(2027, 2, 28))
        #expect(all.last == Self.date(2027, 2, 1))
    }

    @Test func listsRunNewestFirst() {
        let result = Self.seams([Self.entry("A", day: 20), Self.entry("B", day: 10)])
        for list in result.values {
            #expect(list == list.sorted(by: >))
        }
        #expect(result[1]?.first == Self.date(2027, 1, 19))
        #expect(result[1]?.last == Self.date(2027, 1, 11))
    }
}
