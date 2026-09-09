import Testing
@testable import Tilly

@Suite struct TimelineWindowTests {
    static let floor = MonthKey(year: 2026, month: 12)
    static let current = MonthKey(year: 2027, month: 6)

    @Test func theTopIsOneMonthAheadWhenNothingIsUnlocked() {
        let window = TimelineWindow(floor: Self.floor, current: Self.current)
        #expect(window.top == Self.current.advanced(by: 1))
    }

    @Test func unlockingRaisesTheTop() {
        let window = TimelineWindow(floor: Self.floor, current: Self.current, unlocked: 2)
        #expect(window.top == Self.current.advanced(by: 3))
    }

    @Test func theWindowRunsFromTheTopDownToTheFloor() {
        let window = TimelineWindow(floor: Self.floor, current: Self.current)
        let months = window.months

        #expect(months.first == window.top)
        #expect(months.last == window.floor)
        #expect(months.count == window.top.id - window.floor.id + 1)
    }

    @Test func aWindowCrossingDecemberLandsInJanuary() {
        let window = TimelineWindow(floor: Self.floor, current: MonthKey(year: 2026, month: 12))
        #expect(window.top == MonthKey(year: 2027, month: 1))
    }
}
