import SwiftUI

/// One month of lanes: the day axis, a line at today, and one lane per category, each starting
/// with its emoji, its charges as dots on their days, and ending with its total. See "The
/// category view" in `docs/DESIGN.md`.
///
/// Dragging across the plot starts on touch and moves charge to charge; the parent draws the
/// readout from `onScrub`. A quick touch is a tap instead, and opens the nearest dot. The emoji
/// column sits outside the drag, so picking a category never starts one.
struct LanesView: View {
    let month: CategoryMonth
    let laneHeight: CGFloat
    let today: Date
    /// The lane picked out, by `CategoryLane.id`; the others fade, and dragging reads only it.
    let picked: String?
    /// The day under a dragging finger, which the line and the dots follow.
    let scrubDay: Int?
    let onPick: (CategoryLane) -> Void
    let onOpen: (TimelineEntry) -> Void
    /// A new day under the finger, with the line's x in this view; nil when the finger lifts.
    let onScrub: (Scrub?) -> Void

    struct Scrub: Equatable {
        let day: Int
        let lineX: CGFloat
    }

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    /// When the touch under way began, to tell a tap from a drag.
    @State private var touchStart: Date?
    /// True while a finger is down. Gesture state resets even when the scroll view takes the
    /// touch over and `onEnded` never runs, which would otherwise leave the line standing.
    @GestureState private var isTouching = false

    private static let space = "lanes"

    var body: some View {
        GeometryReader { proxy in
            let plot = PlotGeometry(width: proxy.size.width, daysInMonth: daysInMonth, laneHeight: laneHeight, dotScale: month.dotScale)
            VStack(spacing: 0) {
                axis(plot)
                ZStack(alignment: .topLeading) {
                    if let todayDay {
                        Rectangle()
                            .fill(Tokens.Ink.primary)
                            .opacity(scrubDay == nil ? Tokens.Opacity.todayLine : Tokens.Opacity.todayLineWhileDragging)
                            .frame(width: Tokens.Size.todayLine, height: lanesHeight)
                            .position(x: plot.x(day: todayDay), y: lanesHeight / 2)
                            .accessibilityHidden(true)
                    }
                    VStack(spacing: 0) {
                        ForEach(Array(month.lanes.enumerated()), id: \.element.id) { index, lane in
                            laneRow(lane, plot: plot, isLast: index == month.lanes.count - 1)
                        }
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                if let scrubDay {
                    // Across the axis too, so the line meets the day's number.
                    Rectangle()
                        .fill(Tokens.Ink.primary)
                        .frame(width: Tokens.Size.dragLine, height: Tokens.Size.laneAxis + lanesHeight)
                        .position(x: plot.x(day: scrubDay), y: (Tokens.Size.laneAxis + lanesHeight) / 2)
                        // Jumps from charge to charge, as the tick does, rather than sliding.
                        .transaction { $0.animation = nil }
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .overlay { dragSurface(plot) }
            .coordinateSpace(.named(Self.space))
        }
        .onChange(of: isTouching) { _, touching in
            // Only ever clears. Setting the start here landed a view update late, after `onEnded`
            // had cleared it, and the stale start made the next tap read as a long hold.
            guard !touching else { return }
            touchStart = nil
            if scrubDay != nil { onScrub(nil) }
        }
        .frame(height: Tokens.Size.laneAxis + lanesHeight)
        .animation(.easeOut(duration: Tokens.Motion.scrub), value: scrubDay)
    }

    private var lanesHeight: CGFloat { laneHeight * CGFloat(month.lanes.count) }

    // MARK: Dragging

    /// Clear, over the plot and the totals but not the emoji column.
    private func dragSurface(_ plot: PlotGeometry) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(scrubGesture(plot))
            .padding(.leading, Tokens.Space.laneLeading + Tokens.Size.laneEmojiColumn)
            .accessibilityHidden(true)
    }

    private func scrubGesture(_ plot: PlotGeometry) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
            .updating($isTouching) { _, touching, _ in touching = true }
            .onChanged { value in
                if touchStart == nil { touchStart = value.time }
                let day = LaneScrubbing.snappedDay(
                    at: value.location.x, plot: plot.start...plot.end, daysInMonth: daysInMonth, chargeDays: chargeDays
                )
                if day != scrubDay {
                    onScrub(day.map { Scrub(day: $0, lineX: plot.x(day: $0)) })
                }
            }
            .onEnded { value in
                let travel = hypot(value.translation.width, value.translation.height)
                let isTap = travel < LaneScrubbing.tapSlop
                    && value.time.timeIntervalSince(touchStart ?? value.time) < LaneScrubbing.tapDuration
                touchStart = nil
                onScrub(nil)
                if isTap, let entry = dot(nearest: value.location, plot: plot) {
                    onOpen(entry)
                }
            }
    }

    /// Days with a charge, in the picked-out lane alone while one is.
    private var chargeDays: [Int] {
        let lanes = month.lanes.filter { picked == nil || $0.id == picked }
        return Array(Set(lanes.flatMap { $0.dots.map(\.day) }))
    }

    /// The dot whose edge is nearest `point`, within `dotTapReach`.
    private func dot(nearest point: CGPoint, plot: PlotGeometry) -> TimelineEntry? {
        var best: (entry: TimelineEntry, distance: CGFloat)?
        for (index, lane) in month.lanes.enumerated() {
            let centreY = Tokens.Size.laneAxis + CGFloat(index) * laneHeight + laneHeight / 2
            for placed in placedDots(lane) {
                let centreX = plot.x(day: placed.dot.day) + CGFloat(placed.sameDayIndex) * Tokens.Space.sameDayOffset
                let distance = hypot(point.x - centreX, point.y - centreY) - plot.diameter(placed.dot.entry.amount) / 2
                if distance < Tokens.Size.dotTapReach, distance < (best?.distance ?? .infinity) {
                    best = (placed.dot.entry, distance)
                }
            }
        }
        return best?.entry
    }

    // MARK: The axis

    /// Days 1, 8, 15, 22 and the last, dropping any within two days of today, which is drawn
    /// bold in their place.
    private func axis(_ plot: PlotGeometry) -> some View {
        let days = [1, 8, 15, 22, daysInMonth].filter { day in
            todayDay.map { abs(day - $0) > 2 } ?? true
        }
        return ZStack(alignment: .topLeading) {
            ForEach(days, id: \.self) { day in
                axisLabel(day, font: Tokens.Text.axisDay, ink: Tokens.Ink.secondary, plot: plot)
            }
            if let todayDay {
                axisLabel(todayDay, font: Tokens.Text.axisToday, ink: Tokens.Ink.primary, plot: plot)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: Tokens.Size.laneAxis)
        // The days are for reading the dots by eye; VoiceOver reads each dot's own date.
        .accessibilityHidden(true)
    }

    private func axisLabel(_ day: Int, font: Font, ink: Color, plot: PlotGeometry) -> some View {
        Text(day, format: .number)
            .font(font)
            .monospacedDigit()
            .foregroundStyle(ink)
            // Accessibility text sizes aren't designed here; the axis only has to stay in its band.
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .fixedSize()
            .position(x: plot.x(day: day), y: Tokens.Size.laneAxis / 2)
    }

    // MARK: A lane

    private func laneRow(_ lane: CategoryLane, plot: PlotGeometry, isLast: Bool) -> some View {
        let isPicked = picked == lane.id
        let fades = picked != nil && !isPicked
        return ZStack(alignment: .topLeading) {
            emojiButton(lane, isPicked: isPicked)
                .position(x: Tokens.Space.laneLeading + Tokens.Size.laneEmojiColumn / 2, y: laneHeight / 2)

            ZStack(alignment: .topLeading) {
                ForEach(placedDots(lane), id: \.dot.id) { placed in
                    dotMark(placed.dot, colour: colour(of: lane), plot: plot)
                        .position(x: plot.x(day: placed.dot.day) + CGFloat(placed.sameDayIndex) * Tokens.Space.sameDayOffset,
                                  y: laneHeight / 2)
                }
            }
            .opacity(fades ? Tokens.Opacity.unpickedLane : 1)

            Text(TimelineFormatting.amount(lane.total, locale: locale))
                .font(Tokens.Text.laneTotal)
                .monospacedDigit()
                .foregroundStyle(Tokens.Ink.primary)
                .lineLimit(1)
                .minimumScaleFactor(Tokens.Scale.laneTotalMin)
                .frame(width: Tokens.Size.laneTotalsColumn, alignment: .trailing)
                .position(x: plot.totalsCentre, y: laneHeight / 2)
                // The emoji button speaks the lane's total.
                .accessibilityHidden(true)
        }
        .frame(width: plot.width, height: laneHeight)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Tokens.Chart.laneRule)
                    .frame(height: Tokens.Size.hairline)
                    .accessibilityHidden(true)
            }
        }
    }

    private func emojiButton(_ lane: CategoryLane, isPicked: Bool) -> some View {
        Button { onPick(lane) } label: {
            Group {
                if let emoji = lane.category?.emoji {
                    Text(emoji).font(Tokens.Text.laneEmoji(laneHeight: laneHeight))
                } else {
                    // Charges saved before categories existed carry no emoji.
                    Image(systemName: "circle.dashed")
                        .font(Tokens.Text.laneEmoji(laneHeight: laneHeight))
                        .foregroundStyle(Tokens.Ink.secondary)
                }
            }
            .frame(width: Tokens.Size.laneEmojiColumn, height: laneHeight)
            .background {
                if isPicked {
                    RoundedRectangle(cornerRadius: Tokens.Radius.icon).fill(Tokens.Surface.pickedLane)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(CategoryFormatting.laneLabel(lane, locale: locale))
        .accessibilityHint("Picks out this category")
        .accessibilityAddTraits(isPicked ? .isSelected : [])
    }

    /// Touch reaches a dot through the drag surface's tap; VoiceOver reaches it as a button.
    private func dotMark(_ dot: LaneDot, colour: Color, plot: PlotGeometry) -> some View {
        let onLine = scrubDay == dot.day
        return LaneDotMark(entry: dot.entry, colour: colour, diameter: plot.diameter(dot.entry.amount))
            .scaleEffect(onLine ? Tokens.Scale.dotOnLine : 1)
            .opacity(scrubDay == nil || onLine ? 1 : Tokens.Opacity.offLineDot)
            .zIndex(onLine ? 1 : 0)
            .accessibilityElement()
            .accessibilityLabel(TimelineFormatting.accessibilityLabel(for: dot.entry, calendar: calendar, locale: locale))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onOpen(dot.entry) }
    }

    // MARK: Helpers

    private var daysInMonth: Int {
        let interval = month.section.month.interval(in: calendar)
        return (calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 0) + 1
    }

    /// Today's day of the month, on the current month only.
    private var todayDay: Int? {
        month.section.isCurrent ? calendar.component(.day, from: today) : nil
    }

    private func colour(of lane: CategoryLane) -> Color {
        lane.category?.colour.map(Tokens.CategoryColour.color) ?? Tokens.Chart.uncoloured
    }

    /// Each dot with its place among the day's charges: the largest first, each after it
    /// `sameDayOffset` further right and drawn over it.
    private func placedDots(_ lane: CategoryLane) -> [(dot: LaneDot, sameDayIndex: Int)] {
        var seen: [Int: Int] = [:]
        return lane.dots.map { dot in
            let index = seen[dot.day, default: 0]
            seen[dot.day] = index + 1
            return (dot, index)
        }
    }
}

/// Where days and dots fall across the lanes' width.
private struct PlotGeometry {
    let width: CGFloat
    let daysInMonth: Int
    let laneHeight: CGFloat
    let dotScale: Decimal

    /// Day 1, after the emoji column.
    var start: CGFloat { Tokens.Space.laneLeading + Tokens.Size.laneEmojiColumn + Tokens.Space.lanePlotLeading }
    /// The last day, where the totals column begins.
    var end: CGFloat { width - Tokens.Space.gutter - Tokens.Size.laneTotalsColumn }
    var totalsCentre: CGFloat { width - Tokens.Space.gutter - Tokens.Size.laneTotalsColumn / 2 }

    func x(day: Int) -> CGFloat {
        guard daysInMonth > 1 else { return start }
        return start + CGFloat(day - 1) / CGFloat(daysInMonth - 1) * (end - start)
    }

    /// A dot's area follows its amount on one scale for every month: `dotMin` up to the largest
    /// a lane this tall allows, at the largest amount any bill has ever set.
    func diameter(_ amount: Decimal?) -> CGFloat {
        guard let amount, amount != 0, dotScale > 0 else { return Tokens.Size.dotZero }
        let largest = min(Tokens.Size.dotMaxRatio * laneHeight, Tokens.Size.dotMax)
        let ratio = min(1, NSDecimalNumber(decimal: abs(amount) / dotScale).doubleValue)
        return Tokens.Size.dotMin + (largest - Tokens.Size.dotMin) * CGFloat(ratio.squareRoot())
    }
}

/// A charge in its category's colour: filled once charged, a ring while still to come, a dashed
/// ring at €0 or with no amount. Every dot carries a ring of the page's ground, so dots that touch
/// stay apart.
private struct LaneDotMark: View {
    let entry: TimelineEntry
    let colour: Color
    let diameter: CGFloat

    var body: some View {
        mark
            .frame(width: diameter, height: diameter)
            .background {
                Circle()
                    .fill(Tokens.Surface.base)
                    .padding(-Tokens.Size.dotHalo)
            }
    }

    @ViewBuilder
    private var mark: some View {
        if entry.amount == nil || entry.amount == 0 {
            Circle()
                .fill(Tokens.Surface.base)
                .overlay { Circle().strokeBorder(colour, style: Tokens.Stroke.zeroDot) }
        } else if entry.state == .charged {
            Circle().fill(colour)
        } else {
            Circle()
                .fill(Tokens.Surface.base)
                .overlay { Circle().strokeBorder(colour, lineWidth: Tokens.Stroke.upcomingDot) }
        }
    }
}
