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
    /// How much of its own height the row takes, 0 … 1: its frame and its card are cut to it, from
    /// the top, so a landing can open the row's place in the stack. Animates.
    var heightFraction: CGFloat = 1
    /// False while a flying card stands in for this one: the row keeps its place, drawn empty.
    var showsCard = true
    /// 0 … 1: at 0 the card fills the frame with `Radius.card` on every corner and no `stackInset`,
    /// as the editor's card does; at 1 it is the row. The content keeps the row's layout. A flying
    /// card's back is drawn this way.
    var morph: CGFloat = 1
    /// Whether the card runs on beneath the next one. A card in flight leaves it out unless it is the
    /// month's last, so where it lands it ends exactly where the row's own card shows, and nothing
    /// pops when the row takes its place.
    var tucksUnder = true
    /// The card drawn this tall, past the content, as a flying card's back is; nil for a row.
    var cardHeight: CGFloat? = nil
    /// Reports the row's frame at its whole height, in `CardFlightLayer.space`, while held, however
    /// little of it shows: where a card lands. Nil reports nothing.
    var onFullFrame: ((CGRect) -> Void)? = nil

    /// The scroll target at the top of a day's first row, for a calendar tap to land on. A
    /// string, so it can't collide with a month's `Int` id in the same list.
    static func dayScrollID(_ day: Date) -> String {
        "day-\(Int(day.timeIntervalSinceReferenceDate))"
    }

    /// The row's own scroll target, for a landing to jump to: a held row at height 0 is zero high,
    /// so its top is where it lands, as a day's marker's is.
    static func rowScrollID(_ entryID: String) -> String {
        "row-\(entryID)"
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    var body: some View {
        let reportsFullFrame = onFullFrame != nil
        return RowHeightLayout(fraction: heightFraction) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    accessibleLayout
                } else {
                    standardLayout
                }
            }
            .frame(minHeight: cardHeight, alignment: .top)
            // Behind the row and no part of its height, so the row's height stays the row's own and
            // a day's zero-high scroll marker still lands on the row's top.
            .background { card }
            // Laid out whole inside the cut, so this is the row's full frame. Every row carries it,
            // so a hold coming and going changes nothing about the row's identity; unheld, it
            // reads nil and never reports.
            .onGeometryChange(for: CGRect?.self) { proxy in
                reportsFullFrame ? proxy.frame(in: .named(CardFlightLayer.space)) : nil
            } action: { frame in
                if let frame { onFullFrame?(frame) }
            }
        }
        .clipShape(RowHeightClip(fraction: heightFraction))
        .opacity(showsCard ? 1 : 0)
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
        .padding(.horizontal, Tokens.Space.stackInset * morphed)
        .padding(.bottom, tucksUnder ? -Tokens.Space.stackTuck * morphed : 0)
        .accessibilityHidden(true)
    }

    private var colour: Color {
        entry.colour.map(Tokens.CategoryColour.color) ?? Tokens.Chart.uncoloured
    }

    /// From the occurrence's id, so a row draws the same edge every time it's built.
    private var seed: UInt64 { stableSeed(entry.id) }

    private var morphed: CGFloat { min(1, max(0, morph)) }

    /// The row's corners, from the editor's card's at `morph` 0.
    private var cornerRadii: RectangleCornerRadii {
        let card = Tokens.Radius.card
        let top = card + (Tokens.Radius.stackCard - card) * morphed
        let bottom = card + ((isLast ? Tokens.Radius.stackCard : 0) - card) * morphed
        return RectangleCornerRadii(
            topLeading: top, bottomLeading: bottom,
            bottomTrailing: bottom, topTrailing: top
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

/// Lays the row out at its own height and takes `fraction` of it, the row drawn from the top.
/// Animatable, so a held row opens on whatever spring sets its fraction.
private struct RowHeightLayout: Layout {
    var fraction: CGFloat

    var animatableData: CGFloat {
        get { fraction }
        set { fraction = newValue }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let size = natural(proposal, subviews)
        return CGSize(width: size.width, height: size.height * min(1, max(0, fraction)))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let size = natural(proposal, subviews)
        for subview in subviews {
            subview.place(at: bounds.origin, anchor: .topLeading, proposal: ProposedViewSize(size))
        }
    }

    private func natural(_ proposal: ProposedViewSize, _ subviews: Subviews) -> CGSize {
        let width = ProposedViewSize(width: proposal.width, height: nil)
        return subviews.reduce(CGSize.zero) { size, subview in
            let fit = subview.sizeThatFits(width)
            return CGSize(width: max(size.width, fit.width), height: max(size.height, fit.height))
        }
    }
}

/// Uncut at the whole height, so the card's tuck, wobble and shadow reach past the row as ever.
/// Below it, the row is cut at its shortened bottom and its top, and left open at the sides.
nonisolated private struct RowHeightClip: Shape {
    var fraction: CGFloat

    var animatableData: CGFloat {
        get { fraction }
        set { fraction = newValue }
    }

    func path(in rect: CGRect) -> Path {
        guard fraction < 1 else {
            return Path(rect.insetBy(dx: -rect.width, dy: -max(rect.height, rect.width)))
        }
        return Path(CGRect(x: rect.minX - rect.width, y: rect.minY, width: rect.width * 3, height: rect.height))
    }
}
