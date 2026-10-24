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

/// One occurrence, drawn like a category card: a solid paper card once charged, a faint dashed
/// outline while still to come. The picture on its wash with a badge, then the name over the date
/// line, then the amount. Every charge is its own row and carries its own date. See "The timeline"
/// in `docs/DESIGN.md`.
struct OccurrenceRow: View {
    let entry: TimelineEntry
    /// Near dates read as words, and ends count months, from here.
    let today: Date
    /// Picked out by a calendar tap on its day or a save, then faded: `Tokens.Motion.dayMark`.
    var isMarked = false

    /// The scroll target at the top of a day's first row, for a calendar tap to land on. A
    /// string, so it can't collide with a month's `Int` id in the same list.
    static func dayScrollID(_ day: Date) -> String {
        "day-\(Int(day.timeIntervalSinceReferenceDate))"
    }

    /// The row's own scroll target, for a save to bring the row into view.
    static func rowScrollID(_ entryID: String) -> String {
        "row-\(entryID)"
    }

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
        // Behind the row and no part of its height, so the row's height stays the row's own and
        // a day's zero-high scroll marker still lands on the row's top.
        .background { card }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(TimelineFormatting.accessibilityLabel(for: entry, today: today, calendar: calendar, locale: locale))
    }

    private var standardLayout: some View {
        HStack(spacing: Tokens.Space.gap) {
            picture(size: Tokens.Size.rowPicture)
            VStack(alignment: .leading, spacing: 0) {
                nameText(wraps: false)
                dateLine
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            amountText
                .layoutPriority(1)
        }
        .padding(.leading, Tokens.Space.rowInset + Tokens.Space.rowLeading)
        .padding(.trailing, Tokens.Space.rowInset + Tokens.Space.rowTrailing)
        // Under the content too, so a larger text size grows the card rather than crowding it.
        .padding(.vertical, Tokens.Space.rowGap / 2)
        .frame(minHeight: Tokens.Size.row)
    }

    private var accessibleLayout: some View {
        HStack(alignment: .top, spacing: Tokens.Space.gap) {
            picture(size: Tokens.Size.iconAccessible)
            VStack(alignment: .leading, spacing: Tokens.Space.tight) {
                nameText(wraps: true)
                dateLine
                amountText
            }
        }
        // Without this the row sizes to its own content and the enclosing stack centres
        // it, so at accessibility sizes every row lands at a different left inset and a
        // wide one overflows both edges. The standard layout is saved from this by the
        // `maxWidth: .infinity` on its text column.
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, Tokens.Space.rowInset + Tokens.Space.rowLeading)
        .padding(.trailing, Tokens.Space.rowInset + Tokens.Space.rowTrailing)
        .padding(.vertical, Tokens.Space.rowGap / 2 + Tokens.Space.rowAccessibleVertical)
    }

    // MARK: The card

    /// The card, `rowInset` in from each side and `rowGap / 2` from the row's top and bottom, so
    /// cards stand `rowGap` apart. Charged is a paper card; still to come, a faint dashed outline;
    /// skipped, a dotted outline that has withdrawn to tertiary.
    private var card: some View {
        ZStack {
            switch entry.state {
            case .charged:
                PaperCard(cornerRadii: cornerRadii, seed: seed)
            case .upcoming:
                DashedOutline(cornerRadii: cornerRadii, seed: seed)
            case .skipped:
                DottedOutline(colour: Tokens.Ink.tertiary, cornerRadii: cornerRadii, seed: seed)
            }
            // The mark of a calendar tap or a save, on the card's own shape rather than across the row.
            RoughRoundedRectangle(cornerRadii: cornerRadii, seed: seed)
                .fill(Tokens.Surface.pickedLane)
                .opacity(isMarked ? 1 : 0)
        }
        .padding(.horizontal, Tokens.Space.rowInset)
        .padding(.vertical, Tokens.Space.rowGap / 2)
        .accessibilityHidden(true)
    }

    /// From the occurrence's id, so a row draws the same edge every time it's built.
    private var seed: UInt64 { stableSeed(entry.id) }

    private var cornerRadii: RectangleCornerRadii {
        let radius = Tokens.Radius.row
        return RectangleCornerRadii(topLeading: radius, bottomLeading: radius, bottomTrailing: radius, topTrailing: radius)
    }

    private var isCharged: Bool { entry.state == .charged }

    // MARK: The content

    /// The category's picture on its wash, in a square of `size`, with the badge at its lower right.
    private func picture(size: CGFloat) -> some View {
        CategoryPictureView(picture: entry.picture, colour: entry.colour, size: size)
            .frame(width: size, height: size)
            // Still to come, the picture sits back with its ink.
            .opacity(isCharged ? 1 : Tokens.Opacity.upcomingPicture)
            .overlay(alignment: .bottomTrailing) {
                RowBadge(ends: entry.endDate != nil, state: entry.state)
                    .offset(x: Tokens.Space.rowBadgeOffset, y: Tokens.Space.rowBadgeOffset)
            }
            .accessibilityHidden(true)
    }

    /// Charged reads in full; still to come and skipped sit back.
    private var ink: Color {
        switch entry.state {
        case .charged: Tokens.Ink.primary
        case .upcoming: Tokens.Drawn.ink2
        case .skipped: Tokens.Ink.tertiary
        }
    }

    private func nameText(wraps: Bool) -> some View {
        Text(entry.name)
            .font(isCharged ? Tokens.Text.rowName : Tokens.Text.rowNameSoft)
            .foregroundStyle(ink)
            .lineLimit(wraps ? nil : 1)
            .truncationMode(.tail)
    }

    /// "Today · 24 Oct", a `Yearly` tag when yearly, then " · " and how the bill ends. At an
    /// accessibility size the end takes a line of its own when the three don't fit on one.
    @ViewBuilder
    private var dateLine: some View {
        let end = TimelineFormatting.endLine(for: entry, today: today, calendar: calendar, locale: locale)
        let date = HStack(spacing: Tokens.Space.tagLeading) {
            Text(TimelineFormatting.rowDate(entry.date, today: today, calendar: calendar, locale: locale))
            if entry.isYearly { YearlyTag() }
        }
        Group {
            if dynamicTypeSize.isAccessibilitySize, let end {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Tokens.Space.tagLeading) {
                        date
                        Text("\u{00B7} \(end)")
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        date
                        Text(end)
                    }
                }
            } else {
                HStack(spacing: Tokens.Space.tagLeading) {
                    date
                    if let end { Text("\u{00B7} \(end)") }
                }
            }
        }
        .font(Tokens.Text.caption)
        .foregroundStyle(entry.state == .skipped ? Tokens.Ink.quaternary : Tokens.Drawn.ink2)
        .lineLimit(1)
    }

    private var amountText: some View {
        Text(TimelineFormatting.amount(entry.amount, locale: locale))
            .font(isCharged ? Tokens.Text.rowAmount : Tokens.Text.rowAmountSoft)
            .foregroundStyle(ink)
            .monospacedDigit()
            .strikethrough(entry.state == .skipped)
            .fixedSize()
    }
}
