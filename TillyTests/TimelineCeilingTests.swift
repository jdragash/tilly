import Foundation
import SwiftData
import Testing
@testable import Tilly

@Suite struct TimelineCeilingTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static let current = MonthKey(year: 2026, month: 9)

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func expenses(_ make: () -> [Expense]) throws -> [Expense] {
        let context = ModelContext(try TillyStore.container(inMemory: true))
        make().forEach(context.insert)
        try context.save()
        return try context.fetch(FetchDescriptor<Expense>())
    }

    static func ceiling(_ expenses: [Expense]) -> MonthKey? {
        TimelineCeiling.month(for: expenses, current: current, calendar: calendar)
    }

    @Test func aBillWithNoEndRunsFarAhead() throws {
        let expenses = try Self.expenses { [Expense(anchorDate: Self.date(2026, 9, 3))] }
        #expect(Self.ceiling(expenses) == Self.current.advanced(by: TimelineWindow.monthsAhead))
    }

    @Test func whenEveryBillEndsTheCeilingIsTheLastPayment() throws {
        let expenses = try Self.expenses {
            [
                Expense(anchorDate: Self.date(2026, 9, 3), endDate: Self.date(2027, 5, 3)),
                Expense(anchorDate: Self.date(2026, 9, 10), endDate: Self.date(2027, 1, 10)),
            ]
        }
        #expect(Self.ceiling(expenses) == MonthKey(year: 2027, month: 5))
    }

    @Test func theLastPaymentIsTheLastOneOnOrBeforeTheEnd() throws {
        // Every three months from September: December, March, June. An end in August means June.
        let expenses = try Self.expenses {
            [Expense(recurrenceInterval: 3, anchorDate: Self.date(2026, 9, 3), endDate: Self.date(2027, 8, 20))]
        }
        #expect(Self.ceiling(expenses) == MonthKey(year: 2027, month: 6))
    }

    @Test func oneBillWithoutAnEndOutweighsOnesThatEnd() throws {
        let expenses = try Self.expenses {
            [
                Expense(anchorDate: Self.date(2026, 9, 3), endDate: Self.date(2027, 5, 3)),
                Expense(anchorDate: Self.date(2026, 9, 10)),
            ]
        }
        #expect(Self.ceiling(expenses) == Self.current.advanced(by: TimelineWindow.monthsAhead))
    }

    @Test func aLastPaymentBeforeNextMonthStillShowsNextMonth() throws {
        let expenses = try Self.expenses {
            [Expense(anchorDate: Self.date(2026, 3, 3), endDate: Self.date(2026, 7, 3))]
        }
        #expect(Self.ceiling(expenses) == Self.current.advanced(by: 1))
    }

    @Test func noExpensesMeansNoCeiling() {
        #expect(Self.ceiling([]) == nil)
    }

    @Test func isLastPaymentOnlyWhenEveryBillEnds() throws {
        let ending = try Self.expenses {
            [Expense(anchorDate: Self.date(2026, 9, 3), endDate: Self.date(2027, 5, 3))]
        }
        let runningOn = try Self.expenses {
            [
                Expense(anchorDate: Self.date(2026, 9, 3), endDate: Self.date(2027, 5, 3)),
                Expense(anchorDate: Self.date(2026, 9, 10)),
            ]
        }
        let endingCeiling = try #require(Self.ceiling(ending))
        let runningCeiling = try #require(Self.ceiling(runningOn))

        #expect(TimelineCeiling.isLastPayment(endingCeiling, for: ending, current: Self.current, calendar: Self.calendar))
        #expect(!TimelineCeiling.isLastPayment(runningCeiling, for: runningOn, current: Self.current, calendar: Self.calendar))
    }
}
