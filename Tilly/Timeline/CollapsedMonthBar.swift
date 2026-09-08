import SwiftUI

/// The unlock bar at the very top of the list: the month after next, named with its plain
/// total, never the "left" word — that stays inside the current month's own header. Tapping
/// it opens that month; the bar then offers the one after. It is also a `Button`, so it is
/// reachable by VoiceOver and Switch Control — there is no other way to reach it, since
/// pull-to-unlock was rejected for the same reason. See "Looking further ahead is a
/// deliberate unlock" in `docs/DECISIONS.md`.
struct CollapsedMonthBar: View {
    let section: MonthSection
    let today: Date
    let open: () -> Void

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: open) {
            VStack(spacing: 0) {
                HStack(spacing: Tokens.Space.tight) {
                    Image(systemName: "chevron.up")
                        .foregroundStyle(Tokens.Ink.tertiary)
                        .accessibilityHidden(true)
                    Text(section.month.name(in: calendar, relativeTo: today, locale: locale))
                        .font(Tokens.Text.barName)
                        .foregroundStyle(Tokens.Ink.secondary)
                    Spacer()
                    Text(TimelineFormatting.amount(section.total, locale: locale))
                        .font(Tokens.Text.barTotal)
                        .monospacedDigit()
                        .foregroundStyle(Tokens.Ink.secondary)
                        .fixedSize()
                }
                .padding(.horizontal, Tokens.Space.gutter)
                .frame(height: dynamicTypeSize.isAccessibilitySize ? Tokens.Size.monthBarAccessible : Tokens.Size.monthBar)
                .contentShape(Rectangle())
                hairline
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(TimelineFormatting.accessibilityLabel(forBar: section, calendar: calendar, today: today, locale: locale))
        .accessibilityHint("Opens this month")
    }

    private var hairline: some View {
        Rectangle()
            .fill(Tokens.Surface.rule)
            .frame(height: Tokens.Size.hairline)
            .padding(.horizontal, Tokens.Space.gutter)
    }
}
