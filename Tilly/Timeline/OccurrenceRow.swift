import SwiftUI

/// The state grammar's weight ladder, stated once here so every screen that renders an
/// `OccurrenceState` inherits it rather than re-deriving it in a view. See "State grammar"
/// in `docs/DESIGN.md`.
extension OccurrenceState {
    /// The ink a row's name and amount take.
    var primaryInk: Color {
        switch self {
        case .charged: Tokens.Ink.primary
        case .upcoming: Tokens.Ink.secondary
        case .skipped: Tokens.Ink.tertiary
        }
    }

    /// The ink a row's date line takes — one rung back from `primaryInk`.
    var secondaryInk: Color {
        switch self {
        case .charged: Tokens.Ink.secondary
        case .upcoming: Tokens.Ink.tertiary
        case .skipped: Tokens.Ink.quaternary
        }
    }
}

/// One occurrence: the category's emoji in a well, then name with the date beneath it, then
/// the amount. Every charge is its own row and carries its own date.
struct OccurrenceRow: View {
    let entry: TimelineEntry

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibleLayout
            } else {
                standardLayout
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(TimelineFormatting.accessibilityLabel(for: entry, calendar: calendar, locale: locale))
    }

    private var standardLayout: some View {
        HStack(spacing: Tokens.Space.gap) {
            iconWell(size: Tokens.Size.icon, radius: Tokens.Radius.icon)
            VStack(alignment: .leading, spacing: 0) {
                nameText(wraps: false)
                dateText
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            amountText
                .layoutPriority(1)
        }
        .padding(.horizontal, Tokens.Space.gutter)
        .frame(minHeight: Tokens.Size.row)
    }

    private var accessibleLayout: some View {
        HStack(alignment: .top, spacing: Tokens.Space.gap) {
            iconWell(size: Tokens.Size.iconAccessible, radius: Tokens.Radius.iconAccessible)
            VStack(alignment: .leading, spacing: Tokens.Space.tight) {
                nameText(wraps: true)
                dateText
                amountText
            }
        }
        // Without this the row sizes to its own content and the enclosing stack centres
        // it, so at accessibility sizes every row lands at a different left inset and a
        // wide one overflows both edges. The standard layout is saved from this by the
        // `maxWidth: .infinity` on its text column.
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Tokens.Space.gutter)
        .padding(.vertical, Tokens.Space.rowVerticalAccessible)
    }

    private func iconWell(size: CGFloat, radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Tokens.Surface.iconWell)
            .frame(width: size, height: size)
            .overlay {
                if let emoji = entry.emoji {
                    Text(emoji)
                        .font(Tokens.Text.rowEmoji)
                }
            }
            // An upcoming or skipped row sits back with its icon, the way its ink does.
            .opacity(entry.state == .charged ? 1 : Tokens.Opacity.upcomingIcon)
            .accessibilityHidden(true)
    }

    private func nameText(wraps: Bool) -> some View {
        Text(entry.name)
            .font(Tokens.Text.name)
            .foregroundStyle(entry.state.primaryInk)
            .lineLimit(wraps ? nil : 1)
            .truncationMode(.tail)
    }

    private var dateText: some View {
        Text(TimelineFormatting.dateLine(for: entry, calendar: calendar, locale: locale))
            .font(Tokens.Text.caption)
            .foregroundStyle(entry.state.secondaryInk)
    }

    private var amountText: some View {
        Text(TimelineFormatting.amount(entry.amount, locale: locale))
            .font(Tokens.Text.amount)
            .foregroundStyle(entry.state.primaryInk)
            .monospacedDigit()
            .strikethrough(entry.state == .skipped)
            .fixedSize()
    }
}
