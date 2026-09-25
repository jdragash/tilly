import CoreGraphics
import Foundation

/// Where a finger dragging across the lanes lands. Pure, so it's tested without a simulator.
/// See "The category view" in `docs/DESIGN.md`: dragging moves charge to charge, never stopping
/// on an empty day.
enum LaneScrubbing {
    /// Under this much travel and this long, a touch is a tap.
    static let tapSlop: CGFloat = 6
    static let tapDuration: TimeInterval = 0.4

    /// The charge day nearest the finger's day; ties to the earlier. nil when there are none.
    ///
    /// The finger's day is continuous, not rounded, so a finger exactly between two charges is
    /// a tie rather than whichever side rounding favoured. Outside the plot it clamps to day 1
    /// or the last day.
    static func snappedDay(at x: CGFloat, plot: ClosedRange<CGFloat>, daysInMonth: Int, chargeDays: [Int]) -> Int? {
        guard !chargeDays.isEmpty else { return nil }
        let span = plot.upperBound - plot.lowerBound
        let fraction = span > 0 ? min(1, max(0, (x - plot.lowerBound) / span)) : 0
        let fingerDay = 1 + fraction * CGFloat(max(0, daysInMonth - 1))
        return chargeDays.sorted().min { lhs, rhs in
            abs(CGFloat(lhs) - fingerDay) < abs(CGFloat(rhs) - fingerDay)
        }
    }
}
