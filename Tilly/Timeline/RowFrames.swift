import Foundation
import Observation
import SwiftUI

/// The timeline's coordinate space: rows report in it, and `isInView` reads it. It starts at the
/// safe area's top, as the timeline's root does.
enum TimelineSpace {
    static let name = "timeline"
    /// The list's own content, which scrolling doesn't move: distances measured here hold still
    /// while the list scrolls.
    static let content = "timelineContent"
}

/// The rows on screen, by entry id, in `TimelineSpace`. Rows report on appear and change, and drop
/// out on disappear. Read in actions, never in `body`, and not observed, so a scroll's stream of
/// reports redraws nothing.
@MainActor
final class RowFrames {
    private(set) var frames: [String: CGRect] = [:]

    func report(_ id: String, frame: CGRect?) {
        frames[id] = frame
    }
}

/// Where a saved bill appears in the timeline, and whether its row is already in view. Pure, so it
/// is tested without views.
enum TimelineLanding {
    /// The entry a save puts in place: the bill's charge on `date` (its effective date), from the built
    /// sections. Nil when that charge isn't in the window, or Extras hides it.
    static func target(
        expenseID: UUID, date: Date, in sections: [MonthKey: MonthSection], calendar: Calendar
    ) -> TimelineEntry? {
        let day = calendar.startOfDay(for: date)
        let month = MonthKey(containing: day, calendar: calendar)
        return sections[month]?.entries.first { $0.expenseID == expenseID && $0.date == day }
    }

    /// Whether a row's frame is fully inside the list, under the pinned header and above the
    /// bottom row: `listBottom` is where the bottom row's clearance begins.
    static func isInView(_ frame: CGRect, listTop: CGFloat, headerHeight: CGFloat, listBottom: CGFloat) -> Bool {
        frame.minY >= listTop + headerHeight && frame.maxY <= listBottom
    }
}

/// The timeline list's live geometry, written from its geometry callbacks every scroll frame and
/// read in actions. A plain class, never observed, so the writes redraw nothing; see
/// `TimelineView.publishScrollMonths` for what `body` gets from it.
@MainActor
final class TimelineScrollGeometry {
    /// Each listed month's header, from the scroll view's top. Pinned, a header reads 0 however
    /// deep into its month the list is.
    var headerOffsets: [MonthKey: CGFloat] = [:]
    var headerHeights: [MonthKey: CGFloat] = [:]
    /// The scroll view's own offset, which `LazyVStack` can't stop measuring.
    var scrollOffset: CGFloat = 0
    /// What `scrollOffset` would be with the current month's header at the top.
    var restingContentOffset: CGFloat?
    /// The current month's content top and the floor line's bottom, in the list's own space.
    var currentContentTop: CGFloat?
    var floorLineBottom: CGFloat?
}
