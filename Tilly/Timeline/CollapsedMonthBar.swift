import SwiftUI

/// A collapsed neighbour of the expanded range: a name and its plain total, never the
/// current month's "left" word — a bar always shows the plain total, including the bar for
/// the current month once a neighbour is open. Tapping it is the accessible equivalent of
/// pulling it open, which Step 6 adds; nothing about the bar's appearance changes between
/// the two. See "★ A collapsed bar can also be tapped" in `docs/plans/timeline.md`.
struct CollapsedMonthBar: View {
    enum Direction {
        case above, below

        var systemImage: String {
            switch self {
            case .above: "chevron.up"
            case .below: "chevron.down"
            }
        }
    }

    let section: MonthSection
    let direction: Direction
    let today: Date
    let open: () -> Void

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: open) {
            VStack(spacing: 0) {
                HStack(spacing: Tokens.Space.tight) {
                    Image(systemName: direction.systemImage)
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
