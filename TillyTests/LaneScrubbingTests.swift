import CoreGraphics
import Testing
@testable import Tilly

@Suite struct LaneScrubbingTests {
    /// Thirty days across 290pt: day d sits at 10 + (d − 1) × 10.
    static let plot: ClosedRange<CGFloat> = 10...300
    static func x(day: CGFloat) -> CGFloat { 10 + (day - 1) * 10 }

    static func snapped(_ x: CGFloat, _ days: [Int]) -> Int? {
        LaneScrubbing.snappedDay(at: x, plot: plot, daysInMonth: 30, chargeDays: days)
    }

    @Test func snapsToTheNearestChargeDay() {
        #expect(Self.snapped(Self.x(day: 11), [1, 8, 15, 22]) == 8)
        #expect(Self.snapped(Self.x(day: 12), [1, 8, 15, 22]) == 15)
    }

    @Test func aTieGoesToTheEarlierDay() {
        #expect(Self.snapped(Self.x(day: 9), [10, 8]) == 8)
    }

    @Test func beforeThePlotSnapsToTheFirstCharge() {
        #expect(Self.snapped(-40, [5, 20]) == 5)
    }

    @Test func pastThePlotSnapsToTheLast() {
        #expect(Self.snapped(400, [5, 20]) == 20)
    }

    @Test func noChargesSnapsNowhere() {
        #expect(Self.snapped(Self.x(day: 9), []) == nil)
    }

    @Test func oneChargeAlwaysSnapsToIt() {
        #expect(Self.snapped(-40, [17]) == 17)
        #expect(Self.snapped(Self.x(day: 1), [17]) == 17)
        #expect(Self.snapped(400, [17]) == 17)
    }
}
