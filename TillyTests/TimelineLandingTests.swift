import CoreGraphics
import Foundation
import Testing
import TillyCore
@testable import Tilly

@Suite struct TimelineLandingTests {
    typealias Builder = TimelineBuilderTests

    /// The months a few either side of `thisMonth`, built as the timeline builds them.
    static func sections(
        _ expenses: [TimelineExpense], months: ClosedRange<Int> = -2...2, extrasOnly: Bool = false
    ) -> [MonthKey: MonthSection] {
        var result: [MonthKey: MonthSection] = [:]
        for offset in months {
            let key = Builder.thisMonth.advanced(by: offset)
            result[key] = Builder.month(expenses, key: key, extrasOnly: extrasOnly)
        }
        return result
    }

    @Test func targetIsTheChargeOnItsDate() {
        let bill = Builder.expense(name: "Rent", anchoredOn: Builder.date(2026, 10, 31))
        let other = Builder.expense(name: "Gym", anchoredOn: Builder.date(2026, 11, 20))
        let sections = Self.sections([bill, other])
        // Mid-afternoon: the date a save carries needn't be the start of its day.
        let saved = Builder.calendar.date(byAdding: .hour, value: 15, to: Builder.date(2027, 2, 28))!
        let target = TimelineLanding.target(
            expenseID: bill.snapshot.id, date: saved, in: sections, calendar: Builder.calendar
        )
        #expect(target?.expenseID == bill.snapshot.id)
        // Anchored on the 31st, February's charge clamps to the 28th.
        #expect(target?.date == Builder.date(2027, 2, 28))
    }

    @Test func targetFollowsAMovedCharge() {
        let scheduled = Builder.date(2027, 1, 10)
        let moved = Builder.date(2027, 1, 22)
        let bill = Builder.expense(
            anchoredOn: Builder.date(2026, 12, 10),
            overrides: [OccurrenceOverride(scheduledDate: scheduled, actualAmount: nil, movedDate: moved, isSkipped: false)]
        )
        let sections = Self.sections([bill])
        let target = TimelineLanding.target(
            expenseID: bill.snapshot.id, date: moved, in: sections, calendar: Builder.calendar
        )
        #expect(target?.date == moved)
        #expect(target?.scheduledDate == scheduled)
        #expect(TimelineLanding.target(
            expenseID: bill.snapshot.id, date: scheduled, in: sections, calendar: Builder.calendar
        ) == nil)
    }

    @Test func targetIsNilOutsideWindow() {
        let bill = Builder.expense(anchoredOn: Builder.date(2026, 11, 5))
        let sections = Self.sections([bill])
        // Two months either side are built; five months on isn't.
        let target = TimelineLanding.target(
            expenseID: bill.snapshot.id, date: Builder.date(2027, 6, 5), in: sections, calendar: Builder.calendar
        )
        #expect(target == nil)
    }

    @Test func targetIsNilWhenExtrasHidesIt() {
        let monthly = Builder.expense(anchoredOn: Builder.date(2026, 11, 5))
        let quarterly = Builder.expense(anchoredOn: Builder.date(2026, 10, 8), interval: 3)
        let sections = Self.sections([monthly, quarterly], extrasOnly: true)
        #expect(TimelineLanding.target(
            expenseID: monthly.snapshot.id, date: Builder.date(2027, 1, 5), in: sections, calendar: Builder.calendar
        ) == nil)
        #expect(TimelineLanding.target(
            expenseID: quarterly.snapshot.id, date: Builder.date(2027, 1, 8), in: sections, calendar: Builder.calendar
        ) != nil)
    }

    @Test func inViewNeedsWholeRowUnderHeader() {
        let listTop: CGFloat = 60
        let header: CGFloat = 60
        let listBottom: CGFloat = 700
        func inView(_ minY: CGFloat) -> Bool {
            TimelineLanding.isInView(
                CGRect(x: 0, y: minY, width: 402, height: 64),
                listTop: listTop, headerHeight: header, listBottom: listBottom
            )
        }
        #expect(inView(120))
        #expect(inView(300))
        // Half a point under the header is under it.
        #expect(!inView(119.5))
        #expect(!inView(80))
        #expect(!inView(-200))
    }

    @Test func inViewFalseWhenUnderBottomRow() {
        func inView(_ minY: CGFloat) -> Bool {
            TimelineLanding.isInView(
                CGRect(x: 0, y: minY, width: 402, height: 64),
                listTop: 60, headerHeight: 60, listBottom: 700
            )
        }
        #expect(inView(636))
        #expect(!inView(636.5))
        #expect(!inView(690))
        #expect(!inView(900))
    }
}
