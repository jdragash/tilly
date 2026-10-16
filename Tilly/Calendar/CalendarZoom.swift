import SwiftUI

/// Where a change of level zooms: about the month or day that was tapped, starting at that thing's
/// own size, as Calendar's year grows out of the month you touch and shrinks back into it. Without
/// one, as for a month the year has never shown, it zooms gently about the middle.
struct CalendarZoom: Equatable {
    /// The point that holds still while the levels change, as a share of the levels' frame.
    var anchor: UnitPoint
    /// The closer level's size at the far end of the zoom, against its full size: the tapped cell's
    /// width over the screen's, kept from shrinking past `Scale.zoomMin`.
    var scale: CGFloat
    /// The further level's size at the near end, the inverse, kept from passing `Scale.zoomMax`:
    /// a day cell is an eighth of the screen, and the month flying past at eight times was noise.
    var outerScale: CGFloat { min(1 / scale, Tokens.Scale.zoomMax) }

    static let centre = CalendarZoom(anchor: .center, scale: Tokens.Scale.zoomIn)

    /// The coordinate space the levels share, which cells report their frames in.
    static let space = "calendarLevels"

    init(anchor: UnitPoint, scale: CGFloat) {
        self.anchor = anchor
        self.scale = scale
    }

    /// About `frame`, a cell in a container of `size`.
    init(frame: CGRect, in size: CGSize) {
        guard size.width > 0, size.height > 0, !frame.isEmpty else {
            self = .centre
            return
        }
        anchor = UnitPoint(x: frame.midX / size.width, y: frame.midY / size.height)
        scale = min(1, max(Tokens.Scale.zoomMin, frame.width / size.width))
    }
}

/// The frames a zoom can start from or end at. Kept by reference and outside the view's state, so
/// a cell reporting as the year scrolls doesn't redraw the whole calendar for it.
@MainActor
final class CalendarZoomFrames {
    var size: CGSize = .zero
    /// The year's month cells, from the last time the year was laid out.
    var months: [MonthKey: CGRect] = [:]
    /// The month grid's day cells, for the month it last showed.
    var days: [Date: CGRect] = [:]
    /// The day last opened from the grid, which the way back out shrinks into.
    var openedDay: Date?
    /// Set while the levels zoom: a scale in flight reports scaled frames, which aren't kept.
    var isZooming = false

    func zoom(forMonth month: MonthKey) -> CalendarZoom {
        months[month].map { CalendarZoom(frame: $0, in: size) } ?? .centre
    }

    func zoom(forDay day: Date) -> CalendarZoom {
        days[day].map { CalendarZoom(frame: $0, in: size) } ?? .centre
    }

    func report(month: MonthKey, frame: CGRect) {
        guard !isZooming else { return }
        months[month] = frame
    }

    func report(day: Date, frame: CGRect) {
        guard !isZooming else { return }
        days[day] = frame
    }
}
