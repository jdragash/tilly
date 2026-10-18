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

/// One occurrence, as its bill's card in the Wallet stack: the picture, then the name with the date
/// beneath it, then the amount, along the card's top. The card runs on `stackTuck` under the next
/// row, which covers it, so only its top corners show rounded. Every charge is its own row and
/// carries its own date.
struct OccurrenceRow: View {
    let entry: TimelineEntry
    /// Picked out by a calendar tap on its day, then faded: `Tokens.Motion.dayMark`.
    var isMarked = false
    /// The month's last card is whole; every other one is tucked under the next.
    var isLast = false

    /// The scroll target at the top of a day's first row, for a calendar tap to land on. A
    /// string, so it can't collide with a month's `Int` id in the same list.
    static func dayScrollID(_ day: Date) -> String {
        "day-\(Int(day.timeIntervalSinceReferenceDate))"
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
        .accessibilityLabel(TimelineFormatting.accessibilityLabel(for: entry, calendar: calendar, locale: locale))
    }

    private var standardLayout: some View {
        HStack(alignment: .top, spacing: Tokens.Space.gap) {
            picture(size: Tokens.Size.stackPicture)
            VStack(alignment: .leading, spacing: 0) {
                nameText(wraps: false)
                dateText
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            amountText
                .layoutPriority(1)
        }
        .padding(.horizontal, Tokens.Space.stackInset + Tokens.Space.stackLeading)
        // Under the content too, so a larger text size grows the card rather than crowding it.
        .padding(.vertical, Tokens.Space.stackTop)
        .frame(minHeight: Tokens.Size.stackRow, alignment: .top)
    }

    private var accessibleLayout: some View {
        HStack(alignment: .top, spacing: Tokens.Space.gap) {
            picture(size: Tokens.Size.iconAccessible)
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
        .padding(.horizontal, Tokens.Space.stackInset + Tokens.Space.stackLeading)
        .padding(.top, Tokens.Space.stackTop)
        .padding(.bottom, Tokens.Space.rowVerticalAccessible)
    }

    // MARK: The card

    /// The card, `stackInset` in from each side, from the row's top to `stackTuck` below its
    /// bottom. Charged is a wash in the category's colour; still to come, a dotted outline in it;
    /// skipped, a dotted outline that has withdrawn to tertiary.
    private var card: some View {
        ZStack {
            switch entry.state {
            case .charged:
                Wash(colour: colour, cornerRadii: cornerRadii, seed: seed)
                    .shadow(color: Tokens.Shadow.stackColour, radius: Tokens.Shadow.stackRadius, y: Tokens.Shadow.stackY)
            case .upcoming:
                DottedOutline(colour: colour, cornerRadii: cornerRadii, seed: seed)
            case .skipped:
                DottedOutline(colour: Tokens.Ink.tertiary, cornerRadii: cornerRadii, seed: seed)
            }
            // The calendar tap's mark, on the card's own shape rather than across the row.
            RoughRoundedRectangle(cornerRadii: cornerRadii, seed: seed, inset: Tokens.Drawn.edgeWidth / 2)
                .fill(Tokens.Surface.pickedLane)
                .opacity(isMarked ? 1 : 0)
        }
        .padding(.horizontal, Tokens.Space.stackInset)
        .padding(.bottom, -Tokens.Space.stackTuck)
        .accessibilityHidden(true)
    }

    private var colour: Color {
        entry.colour.map(Tokens.CategoryColour.color) ?? Tokens.Chart.uncoloured
    }

    /// From the occurrence's id, so a row draws the same edge every time it's built.
    private var seed: UInt64 { stableSeed(entry.id) }

    private var cornerRadii: RectangleCornerRadii {
        let bottom = isLast ? Tokens.Radius.stackCard : 0
        return RectangleCornerRadii(
            topLeading: Tokens.Radius.stackCard, bottomLeading: bottom,
            bottomTrailing: bottom, topTrailing: Tokens.Radius.stackCard
        )
    }

    private var isCharged: Bool { entry.state == .charged }

    // MARK: The content

    /// The category's picture in a square of `size`, which draws its own wash: white on a
    /// charged card, in its colour on an outline.
    private func picture(size: CGFloat) -> some View {
        CategoryPictureView(picture: entry.picture, colour: entry.colour, size: size, onCard: isCharged)
            .frame(width: size, height: size)
            // An upcoming or skipped row sits back with its picture, the way its ink does.
            .opacity(isCharged ? 1 : Tokens.Opacity.upcomingIcon)
            .accessibilityHidden(true)
    }

    private func nameText(wraps: Bool) -> some View {
        Text(entry.name)
            .font(Tokens.Text.name)
            .foregroundStyle(isCharged ? Tokens.Ink.onCard : entry.state.primaryInk)
            .lineLimit(wraps ? nil : 1)
            .truncationMode(.tail)
    }

    private var dateText: some View {
        Text(TimelineFormatting.dateLine(for: entry, calendar: calendar, locale: locale))
            .font(Tokens.Text.caption)
            .foregroundStyle(isCharged ? Tokens.Ink.onStackSoft : entry.state.secondaryInk)
    }

    private var amountText: some View {
        Text(TimelineFormatting.amount(entry.amount, locale: locale))
            .font(Tokens.Text.amount)
            .foregroundStyle(isCharged ? Tokens.Ink.onCard : entry.state.primaryInk)
            .monospacedDigit()
            .strikethrough(entry.state == .skipped)
            .fixedSize()
    }
}
