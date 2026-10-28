import SwiftUI

/// A wave on each side of "Today, 24 Oct", in `Drawn.ink2`: between the current month's last row
/// still to come and its first charged one.
struct TodayDivider: View {
    let today: Date

    /// The divider's scroll target and its key among the reported frames: the month button lands it
    /// in the middle of the list.
    static let scrollID = "today-divider"
    /// Its unscaled size among the reported frames, under its own key.
    static let sizeID = "today-divider-size"
    /// Its frame in the list's content, under its own key.
    static let contentID = "today-divider-content"

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    var body: some View {
        HStack(spacing: Tokens.Space.dividerGap) {
            wave
            Text(TimelineFormatting.todayDivider(today, calendar: calendar, locale: locale))
                .font(Tokens.Text.todayDivider)
                .foregroundStyle(Tokens.Drawn.ink2)
                .fixedSize()
            wave
        }
        .padding(.horizontal, Tokens.Space.dividerSide)
        .padding(.vertical, Tokens.Space.dividerVertical)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(TimelineFormatting.spokenTodayDivider(today, calendar: calendar, locale: locale))
    }

    private var wave: some View {
        Squiggle(period: Tokens.Size.squigglePeriod, height: Tokens.Size.squiggle)
            .stroke(Tokens.Drawn.ink2, lineWidth: Tokens.Stroke.squiggle)
            .opacity(Tokens.Opacity.squiggle)
            .frame(maxWidth: .infinity)
            .frame(height: Tokens.Size.squiggle)
    }
}

/// A sine-like wave across `rect`'s width, centred, period `Size.squigglePeriod` (12pt) and
/// height `Size.squiggle` (6pt), drawn as quad curves as the prototype's mask is. Given its sizes
/// rather than reading `Tokens`, since a shape draws off the main actor.
nonisolated struct Squiggle: Shape {
    var period: CGFloat
    var height: CGFloat

    func path(in rect: CGRect) -> Path {
        let half = height / 2
        let mid = rect.midY
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: mid))
        var x = rect.minX
        var up = true
        // Half a period at a time, each a quad curve whose control alternates above and below.
        while x < rect.maxX {
            let end = min(x + period / 2, rect.maxX)
            let control = CGPoint(x: (x + end) / 2, y: up ? mid - half : mid + half)
            path.addQuadCurve(to: CGPoint(x: end, y: mid), control: control)
            x = end
            up.toggle()
        }
        return path
    }
}
