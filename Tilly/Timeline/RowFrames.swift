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
/// out on disappear. Read in actions, never in `body`, so a scroll's stream of reports redraws
/// nothing.
@MainActor @Observable
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
