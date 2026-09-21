import Testing
@testable import Tilly

@Suite struct TimelineWindowTests {
    static let floor = MonthKey(year: 2026, month: 12)
    static let current = MonthKey(year: 2027, month: 6)

    @Test func theWindowRunsFromTheCeilingDownToTheFloor() {
        let window = TimelineWindow(floor: Self.floor, ceiling: Self.current.advanced(by: 5), current: Self.current)
        let months = window.months

        #expect(months.first == window.ceiling)
        #expect(months.last == window.floor)
        #expect(months.count == window.ceiling.id - window.floor.id + 1)
    }

    @Test func aWindowCrossingDecemberLandsInJanuary() {
        let current = MonthKey(year: 2026, month: 12)
        let window = TimelineWindow(floor: Self.floor, ceiling: current.advanced(by: 1), current: current)
        #expect(window.months.first == MonthKey(year: 2027, month: 1))
    }
}
