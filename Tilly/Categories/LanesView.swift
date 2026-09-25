import SwiftUI

/// One month of lanes: the day axis, a line at today, and one lane per category, each starting
/// with its emoji, its charges as dots on their days, and ending with its total. See "The
/// category view" in `docs/DESIGN.md`.
struct LanesView: View {
    let month: CategoryMonth
    let laneHeight: CGFloat
    let today: Date
    /// The lane picked out, by `CategoryLane.id`; the others fade.
    let picked: String?
    let onPick: (CategoryLane) -> Void
    let onOpen: (TimelineEntry) -> Void

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    var body: some View {
        GeometryReader { proxy in
            let plot = PlotGeometry(width: proxy.size.width, daysInMonth: daysInMonth, laneHeight: laneHeight, dotScale: month.dotScale)
            VStack(spacing: 0) {
                axis(plot)
                ZStack(alignment: .topLeading) {
                    if let todayDay {
                        Rectangle()
                            .fill(Tokens.Ink.primary)
                            .opacity(Tokens.Opacity.todayLine)
                            .frame(width: Tokens.Size.todayLine, height: laneHeight * CGFloat(month.lanes.count))
                            .position(x: plot.x(day: todayDay), y: laneHeight * CGFloat(month.lanes.count) / 2)
                            .accessibilityHidden(true)
                    }
                    VStack(spacing: 0) {
                        ForEach(Array(month.lanes.enumerated()), id: \.element.id) { index, lane in
                            laneRow(lane, plot: plot, isLast: index == month.lanes.count - 1)
                        }
                    }
                }
            }
        }
        .frame(height: Tokens.Size.laneAxis + laneHeight * CGFloat(month.lanes.count))
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
                    dotButton(placed.dot, colour: colour(of: lane), plot: plot)
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

    private func dotButton(_ dot: LaneDot, colour: Color, plot: PlotGeometry) -> some View {
        let diameter = plot.diameter(dot.entry.amount)
        return Button { onOpen(dot.entry) } label: {
            LaneDotMark(entry: dot.entry, colour: colour, diameter: diameter)
                .contentShape(Circle().inset(by: -Tokens.Size.dotHalo))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(TimelineFormatting.accessibilityLabel(for: dot.entry, calendar: calendar, locale: locale))
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
