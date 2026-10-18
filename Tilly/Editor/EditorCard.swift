import SwiftData
import SwiftUI

/// The Wallet card, live: every part is a button that reports itself, and the name is the
/// text field itself. See "The card is the input" in `docs/DESIGN.md`.
struct EditorCard: View {
    let draft: ExpenseDraft
    @Binding var name: String
    var nameFocus: FocusState<Bool>.Binding
    let category: ExpenseCategory?          // the one the card wears; nil = grey
    let progress: CardProgress
    let focused: CardPart?
    let today: Date
    let onTap: (CardPart?) -> Void          // nil = the card's background
    let onNameSubmit: () -> Void

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var amountSize = Tokens.Size.cardAmount
    @ScaledMetric(relativeTo: .title) private var tileSize = Tokens.Size.cardCategoryTile

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            stacked
        } else {
            standard
        }
    }

    // MARK: Layouts

    /// Amount top left, date and repeat top right, name bottom left, the emoji bottom right.
    private var standard: some View {
        fill
            .aspectRatio(Tokens.Size.cardAspect, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay {
                // The background button sits over the fill, which would otherwise take its taps,
                // and under the parts.
                backgroundButton
            }
            .overlay {
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: Tokens.Space.gap) {
                        amount
                        Spacer(minLength: 0)
                        VStack(alignment: .trailing, spacing: Tokens.Space.cardWhenGap) {
                            date
                            repeatLine
                        }
                        .fixedSize()
                    }
                    Spacer(minLength: 0)
                    HStack(alignment: .bottom, spacing: Tokens.Space.gap) {
                        nameField
                        Spacer(minLength: 0)
                        categoryTile
                    }
                }
                .padding(.horizontal, Tokens.Space.cardHorizontal)
                .padding(.vertical, Tokens.Space.cardVertical)
            }
            .shadow(color: Tokens.Shadow.cardColour, radius: Tokens.Shadow.cardRadius, y: Tokens.Shadow.cardY)
    }

    /// At accessibility sizes the parts stack, full width, in `CardPart.allCases` order, and the
    /// card is only as tall as they are.
    private var stacked: some View {
        VStack(alignment: .leading, spacing: Tokens.Space.tight) {
            ForEach(CardPart.allCases, id: \.self) { part in
                switch part {
                case .amount: amount
                case .name: nameField
                case .date: date
                case .repeat: repeatLine
                case .category: categoryTile
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Tokens.Space.cardHorizontal)
        .padding(.vertical, Tokens.Space.cardVertical)
        .background {
            ZStack {
                fill
                backgroundButton
            }
        }
        .shadow(color: Tokens.Shadow.cardColour, radius: Tokens.Shadow.cardRadius, y: Tokens.Shadow.cardY)
    }

    /// The card's colour. A new category crossfades over the old one rather than blending
    /// through it.
    private var fill: some View {
        ZStack {
            cardShape
                .fill(Tokens.CategoryColour.cardFill(category?.colour))
                .id(category?.id)
                .transition(.opacity)
        }
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Tokens.Radius.card, style: .continuous)
    }

    /// The card's own ground, under its parts: a tap there opens the category, which
    /// `onTap(nil)` leaves to the sheet. VoiceOver reaches the category through its tile.
    private var backgroundButton: some View {
        Button { onTap(nil) } label: {
            cardShape.fill(.clear).contentShape(cardShape)
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
    }

    // MARK: Parts

    private var amount: some View {
        let text = draft.amountText(locale: locale)
        return Button { onTap(.amount) } label: {
            SwiftUI.TimelineView(.periodic(from: .now, by: Tokens.Motion.caretBlink)) { context in
                let tick = Int(context.date.timeIntervalSinceReferenceDate / Tokens.Motion.caretBlink)
                Text(text)
                    .font(Tokens.Text.cardAmount(size: amountSize))
                    .foregroundStyle(progress.isMissing(.amount) ? Tokens.Ink.onCardSoft : Tokens.Ink.onCard)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(Tokens.Scale.editorAmountMin)
                    .textRenderer(AmountCaret(isShown: focused == .amount && tick.isMultiple(of: 2)))
                    // Room for the caret, which is drawn past the text's own width.
                    .padding(.trailing, focused == .amount ? amountSize * Tokens.Size.caretRoomRatio : 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .layoutPriority(1)
        .accessibilityLabel("Amount")
        .accessibilityValue(text)
        .accessibilityHint("Opens the keypad")
    }

    /// The field itself. Empty, it's a dashed box round `Name`, solid while it's being typed in;
    /// filled, it's plain text.
    private var nameField: some View {
        let isEmpty = progress.isMissing(.name)
        let isFocused = nameFocus.wrappedValue
        let field = RoundedRectangle(cornerRadius: Tokens.Radius.cardField, style: .continuous)
        return TextField("Name", text: $name, prompt: Text("Name").foregroundStyle(Tokens.Ink.onCardSoft))
            .font(Tokens.Text.cardName)
            .foregroundStyle(Tokens.Ink.onCard)
            .tint(Tokens.Ink.onCard)
            .focused(nameFocus)
            .onSubmit(onNameSubmit)
            .fixedSize(horizontal: isEmpty, vertical: false)
            .padding(.horizontal, isEmpty ? Tokens.Space.cardFieldHorizontal : 0)
            .padding(.vertical, isEmpty ? Tokens.Space.cardFieldVertical : 0)
            .overlay {
                if isEmpty {
                    if isFocused {
                        field.strokeBorder(Tokens.Ink.onCard, lineWidth: Tokens.Stroke.cardDash.lineWidth)
                    } else {
                        field.strokeBorder(Tokens.Ink.onCardDash, style: Tokens.Stroke.cardDash)
                            .breathing(progress.breathing(focused: focused) == .name)
                    }
                }
            }
            .onChange(of: isFocused) { _, nowFocused in
                if nowFocused { onTap(.name) }
            }
            .accessibilityLabel("Name")
            .accessibilityHint("Opens the keyboard")
    }

    private var date: some View {
        let label = draft.dateLabel(calendar: calendar, locale: locale)
        let isFuture = draft.isFuture(today: today, calendar: calendar)
        return whenButton(.date, label: "Date", value: label, hint: "Opens the calendar") {
            if isFuture {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Tokens.Ink.onCardSoft)
            }
            Text(label)
        }
    }

    private var repeatLine: some View {
        let label = draft.repeatLabel(calendar: calendar, locale: locale)
        return whenButton(.repeat, label: "Repeat", value: label, hint: "Opens the repeat wheel") {
            if draft.paymentCount != nil {
                Image(systemName: "arrow.right.to.line")
                    .foregroundStyle(Tokens.Ink.onCardSoft)
            }
            Text(label)
        }
    }

    /// The date's line or the repeat's: always filled in, so always followed by the pencil.
    private func whenButton<Content: View>(
        _ part: CardPart,
        label: String,
        value: String,
        hint: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let isOpen = focused == part
        let ring = RoundedRectangle(cornerRadius: Tokens.Radius.cardFocus, style: .continuous)
        return Button { onTap(part) } label: {
            HStack(spacing: Tokens.Space.cardMarkGap) {
                content()
                pencil
            }
            .font(Tokens.Text.cardWhen)
            .foregroundStyle(Tokens.Ink.onCard)
            .lineLimit(1)
            .contentShape(Rectangle())
            .overlay {
                if isOpen {
                    ring.stroke(Tokens.Ink.onCard, lineWidth: Tokens.Stroke.cardFocus)
                        .padding(-Tokens.Stroke.cardFocus)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(value)
        .accessibilityHint(hint)
        .accessibilityAddTraits(isOpen ? .isSelected : [])
    }

    /// Dashed until a category is chosen, then its emoji with the pencil on its corner.
    private var categoryTile: some View {
        let isMissing = progress.isMissing(.category)
        let isOpen = focused == .category
        let radius = Tokens.Radius.cardCategoryTile * tileSize / Tokens.Size.cardCategoryTile
        let tile = RoundedRectangle(cornerRadius: radius, style: .continuous)
        return Button { onTap(.category) } label: {
            ZStack {
                if isMissing {
                    tile.strokeBorder(Tokens.Ink.onCardDash, style: Tokens.Stroke.cardDash)
                        .breathing(progress.breathing(focused: focused) == .category)
                } else if let category {
                    CategoryPictureView(
                        picture: CategoryPicture(category), colour: category.colour, size: tileSize,
                        onCard: true
                    )
                        .id(category.id)
                        .transition(.emojiDrop)
                }
            }
            .frame(width: tileSize, height: tileSize)
            .overlay {
                if isOpen {
                    tile.stroke(Tokens.Ink.onCard, lineWidth: Tokens.Stroke.cardFocus)
                        .padding(-Tokens.Stroke.cardFocus)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if !isMissing { badge }
            }
            .contentShape(tile)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Category")
        .accessibilityValue(isMissing ? "None" : category?.name ?? "None")
        .accessibilityHint("Opens the categories")
        .accessibilityAddTraits(isOpen ? .isSelected : [])
    }

    private var pencil: some View {
        Image(systemName: "pencil")
            .foregroundStyle(Tokens.Ink.onCardSoft)
            .accessibilityHidden(true)
    }

    /// The pencil, small, on a chosen category's tile.
    private var badge: some View {
        Image(systemName: "pencil")
            .font(Tokens.Text.cardBadge)
            .foregroundStyle(Tokens.Ink.secondary)
            .frame(width: Tokens.Size.cardBadge, height: Tokens.Size.cardBadge)
            .background(Tokens.Surface.cardBadge, in: Circle())
            .shadow(color: Tokens.Shadow.badgeColour, radius: Tokens.Shadow.badgeRadius, y: Tokens.Shadow.badgeY)
            .offset(x: Tokens.Size.cardBadgeOverhang, y: Tokens.Size.cardBadgeOverhang)
            .accessibilityHidden(true)
    }
}

/// Draws the amount, then the caret after it while the keypad is up. Drawn from the laid-out line,
/// so the caret shrinks with a long amount, as the prototype's does.
private struct AmountCaret: TextRenderer {
    var isShown: Bool

    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout { context.draw(line) }
        guard isShown, let line = layout.last else { return }
        let bounds = line.typographicBounds.rect
        let height = bounds.height * Tokens.Size.caretHeightOfLine
        let width = max(Tokens.Size.caretMinWidth, height * Tokens.Size.caretWidthOfHeight)
        let caret = CGRect(
            x: bounds.maxX + height * Tokens.Size.caretGapOfHeight,
            y: bounds.midY - height / 2,
            width: width,
            height: height
        )
        context.fill(Capsule().path(in: caret), with: .color(Tokens.Ink.onCard))
    }
}

private extension AnyTransition {
    /// The emoji drops into its tile: from a little larger and higher, to rest.
    static var emojiDrop: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: Tokens.Scale.emojiDrop)
                .combined(with: .offset(y: -Tokens.Space.emojiDrop))
                .combined(with: .opacity),
            removal: .opacity
        )
    }
}

private struct Breathing: ViewModifier {
    let isOn: Bool

    func body(content: Content) -> some View {
        if isOn {
            content.phaseAnimator([1, Tokens.Motion.breatheOpacity]) { view, opacity in
                view.opacity(opacity)
            } animation: { _ in
                .easeInOut(duration: Tokens.Motion.breathe / 2)
            }
        } else {
            content
        }
    }
}

private extension View {
    /// The slow pulse on the dashes of the part still needed next.
    func breathing(_ isOn: Bool) -> some View { modifier(Breathing(isOn: isOn)) }
}

// MARK: - Previews

/// Holds the name and its focus, which `EditorCard` only binds to.
private struct EditorCardPreview: View {
    @State var draft: ExpenseDraft
    var category: ExpenseCategory?
    var focused: CardPart?
    @FocusState private var nameFocused: Bool

    var body: some View {
        let progress = CardProgress(draft: draft, categoryExists: category != nil, isMakingCategory: false)
        EditorCard(
            draft: draft,
            name: $draft.name,
            nameFocus: $nameFocused,
            category: category,
            progress: progress,
            focused: focused,
            today: Date(),
            onTap: { _ in },
            onNameSubmit: {}
        )
        .padding(.horizontal, Tokens.Space.editorCardInset)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Tokens.Surface.base)
    }
}

private func previewDraft(_ keys: [KeypadKey] = [], name: String = "") -> ExpenseDraft {
    var draft = ExpenseDraft(today: Date(), calendar: .current)
    for key in keys { draft.press(key) }
    draft.name = name
    return draft
}

/// The container is returned too: a model whose container is released can't be shown.
private func previewCategory() -> (ModelContainer, ExpenseCategory) {
    let container = try! TillyStore.container(inMemory: true)
    let category = ExpenseCategory(name: "Home", emoji: "🏠", colour: .blue)
    container.mainContext.insert(category)
    return (container, category)
}

#Preview("Empty") {
    EditorCardPreview(draft: previewDraft(), focused: .amount)
}

#Preview("Amount, no name") {
    EditorCardPreview(draft: previewDraft([.digit(9), .digit(5), .digit(0)]), focused: .amount)
}

#Preview("Complete, in a colour") {
    let (container, category) = previewCategory()
    EditorCardPreview(draft: previewDraft([.digit(9), .digit(5), .digit(0)], name: "Rent"), category: category)
        .modelContainer(container)
}

#Preview("Future date, counted repeat") {
    var draft = previewDraft([.digit(1), .digit(2), .digit(5), .digit(0), .decimal, .digit(5)], name: "Sofa")
    draft.date = Calendar.current.date(byAdding: .day, value: 12, to: draft.date)!
    draft.paymentCount = 12
    let (container, category) = previewCategory()
    return EditorCardPreview(draft: draft, category: category, focused: .repeat)
        .modelContainer(container)
}

#Preview("Dark") {
    let (container, category) = previewCategory()
    EditorCardPreview(draft: previewDraft([.digit(9), .digit(5), .digit(0)], name: "Rent"), category: category)
        .modelContainer(container)
        .preferredColorScheme(.dark)
}

#Preview("Accessibility size") {
    EditorCardPreview(draft: previewDraft([.digit(9), .digit(5), .digit(0)]))
        .dynamicTypeSize(.accessibility3)
}
