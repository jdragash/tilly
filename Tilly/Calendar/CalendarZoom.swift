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
    /// Set while the levels zoom: a scale in flight reports scaled frames, which are held aside
    /// rather than kept. A level's last report lands as it settles, often before the zoom is
    /// declared over, so what was held is kept for the level that shows once a zoom settles.
    var isZooming = false
    private var pendingMonths: [MonthKey: CGRect] = [:]
    private var pendingDays: [Date: CGRect] = [:]

    func zoom(forMonth month: MonthKey) -> CalendarZoom {
        months[month].map { CalendarZoom(frame: $0, in: size) } ?? .centre
    }

    func zoom(forDay day: Date) -> CalendarZoom {
        days[day].map { CalendarZoom(frame: $0, in: size) } ?? .centre
    }

    func report(month: MonthKey, frame: CGRect) {
        if isZooming { pendingMonths[month] = frame } else { months[month] = frame }
    }

    func report(day: Date, frame: CGRect) {
        if isZooming { pendingDays[day] = frame } else { days[day] = frame }
    }

    /// A zoom is over. `settled`: it ran to its end, so the last frames held are the ones at rest,
    /// and `showing`'s are kept; cut short, they were mid-scale and go.
    func zoomEnded(settled: Bool, showing: CalendarLevel) {
        if settled, showing == .year { months.merge(pendingMonths) { $1 } }
        if settled, showing == .month { days.merge(pendingDays) { $1 } }
        pendingMonths = [:]
        pendingDays = [:]
        isZooming = false
    }
}

extension CalendarZoom {
    /// How far in a change of level is: 0 shows the further level, 1 the closer.
    /// The closer level's scale and opacity at `t`: from `scale` and 0 to 1 and 1.
    func closer(at t: CGFloat) -> (scale: CGFloat, opacity: Double) {
        (scale + (1 - scale) * t, Double(t))
    }

    /// The further level's: from 1 and 1 to `outerScale` and 0.
    func further(at t: CGFloat) -> (scale: CGFloat, opacity: Double) {
        (1 + (outerScale - 1) * t, Double(1 - t))
    }
}

enum PinchDirection: Equatable { case `in`, out }

/// One pinch, from the gesture's magnification, as the prototype's `pMove` and `pEnd` read it.
struct PinchProgress: Equatable {
    /// nil until the magnification leaves 1/pinchStart...pinchStart.
    static func direction(magnification: CGFloat) -> PinchDirection? {
        if magnification > Tokens.Scale.pinchStart { return .in }
        if magnification < 1 / Tokens.Scale.pinchStart { return .out }
        return nil
    }

    /// How far along its direction: ln(spread) / ln(pinchFull), clamped to 0...1, where spread is
    /// the magnification going in and its inverse going out.
    static func progress(magnification: CGFloat, direction: PinchDirection) -> CGFloat {
        let spread = direction == .in ? magnification : 1 / magnification
        return min(1, max(0, log(spread) / log(Tokens.Scale.pinchFull)))
    }

    /// The same per second, from the gesture's magnification velocity: the derivative of
    /// `progress` over time, velocity / (magnification * ln(pinchFull)), negated going out.
    /// Unclamped, so a pinch past either end still reports how fast the fingers move.
    static func speed(magnification: CGFloat, velocity: CGFloat, direction: PinchDirection) -> CGFloat {
        let rate = velocity / (magnification * log(Tokens.Scale.pinchFull))
        return direction == .in ? rate : -rate
    }

    /// Whether a lifted pinch finishes: past pinchFinish, or faster than pinchFlick.
    static func finishes(progress: CGFloat, speed: CGFloat) -> Bool {
        progress > Tokens.Motion.pinchFinish || speed > Tokens.Motion.pinchFlick
    }

    /// How long the rest takes: zoomDuration times the distance left, at least pinchSettleMin.
    static func settleDuration(from t: CGFloat, to end: CGFloat) -> TimeInterval {
        max(Tokens.Motion.pinchSettleMin, Tokens.Motion.zoomDuration * TimeInterval(abs(end - t)))
    }
}
