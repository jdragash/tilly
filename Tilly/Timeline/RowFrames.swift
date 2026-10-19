import Foundation
import Observation
import SwiftUI

/// What the list is doing with one row while a card stands in for it: how much of its own height
/// it takes, and whether its card shows. Landing, a row opens from 0 as the card drops into it;
/// opened in the sheet, it keeps its whole height with its card gone.
struct RowHold: Equatable {
    let entryID: String
    /// 0 … 1 of the row's own height; 1 while a row is open in the sheet.
    var height: CGFloat
    /// False while the flyer is its card.
    var showsCard: Bool
}

/// The rows on screen, by entry id, in `CardFlightLayer.space`. Rows report on appear and change,
/// and drop out on disappear. Read in actions, never in `body`, so a scroll's stream of reports
/// redraws nothing.
@MainActor @Observable
final class RowFrames {
    private(set) var frames: [String: CGRect] = [:]
    /// A held row's frame at its whole height, which `frames` cuts to what shows.
    private(set) var fullFrames: [String: CGRect] = [:]

    func report(_ id: String, frame: CGRect?) {
        frames[id] = frame
        if frame == nil { fullFrames[id] = nil }
    }

    func reportFull(_ id: String, frame: CGRect) {
        fullFrames[id] = frame
    }
}

/// Where a saved bill lands in the timeline, and whether its row is already in view. Pure, so it
/// is tested without views.
enum TimelineLanding {
    /// The entry a save lands on: the bill's charge on `date` (its effective date), from the built
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
