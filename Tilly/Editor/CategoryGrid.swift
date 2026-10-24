import SwiftUI

/// The categories four across, in the Settings order, each a paper card, and a dashed `New` last.
/// One tap picks; the picked card carries a ring. Scrolls when the cards outgrow the panel. See
/// "The picker is a grid of category cards" in `docs/DESIGN.md`.
struct CategoryGrid: View {
    let categories: [ExpenseCategory]   // Settings order
    let selection: UUID?
    let newBreathes: Bool
    let onPick: (UUID) -> Void
    let onNew: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Tokens.Space.pickerGap), count: Tokens.Size.pickerColumns)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Tokens.Space.pickerGap) {
                ForEach(categories) { category in
                    Button { onPick(category.id) } label: { card(category) }
                        .buttonStyle(.plain)
                        .accessibilityLabel(category.name)
                        .accessibilityHint("Puts the bill in this category")
                        .accessibilityAddTraits(category.id == selection ? .isSelected : [])
                }
                Button(action: onNew) { newCard }
                    .buttonStyle(.plain)
                    .accessibilityLabel("New category")
                    .accessibilityHint("Picks a symbol to make one")
            }
            // Room for the picked card's ring, which sits outside the card.
            .padding(Tokens.Space.pickerRingOutset)
            .padding(.top, Tokens.Space.pickerTop - Tokens.Space.pickerRingOutset)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var cornerRadii: RectangleCornerRadii {
        let radius = Tokens.Radius.pickerCard
        return RectangleCornerRadii(topLeading: radius, bottomLeading: radius, bottomTrailing: radius, topTrailing: radius)
    }

    /// A paper card: the picture on its wash near the top, the name above the bottom, and a strip of
    /// the colour along the bottom, inside the card's shape. `pickerCard` tall, or taller where a
    /// larger text size needs the room for two lines of name.
    private func card(_ category: ExpenseCategory) -> some View {
        let seed = stableSeed(category.id.uuidString)
        let colour = category.colour.map(Tokens.CategoryColour.color) ?? Tokens.Chart.uncoloured
        let shape = RoughRoundedRectangle(cornerRadii: cornerRadii, seed: seed, wobble: Tokens.Drawn.pickerCardWobble)
        return VStack(spacing: 0) {
            CategoryPictureView(
                picture: CategoryPicture(category), colour: category.colour,
                size: Tokens.Size.pickerPicture, round: true, place: .editor
            )
            .padding(.top, Tokens.Space.pickerPictureTop)
            Spacer(minLength: Tokens.Space.pickerNameTop)
            Text(category.name)
                .font(Tokens.Text.pickerName)
                .foregroundStyle(Tokens.Ink.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(Tokens.Scale.headerMin)
                .padding(.horizontal, Tokens.Space.pickerNameSide)
                .padding(.bottom, Tokens.Space.pickerNameBottom)
        }
        // As tall as the row, so a row's cards line up when one name needs more room.
        .frame(maxWidth: .infinity, minHeight: Tokens.Size.pickerCard, maxHeight: .infinity)
        .background {
            PaperCard(cornerRadii: cornerRadii, seed: seed, wobble: Tokens.Drawn.pickerCardWobble)
                .overlay(alignment: .bottom) {
                    // A wash, speckled as the prototype's `washF` speckles it.
                    RoughRoundedRectangle(
                        cornerRadii: RectangleCornerRadii(), seed: seed,
                        wobble: Tokens.Drawn.stripWobble, frequency: Tokens.Drawn.stripFrequency
                    )
                        .fill(colour.opacity(Tokens.Opacity.pickerStrip))
                        .frame(height: Tokens.Size.pickerStrip)
                        .mask {
                            Image(uiImage: Grain.speckle)
                                .resizable(resizingMode: .tile)
                                .interpolation(.medium)
                        }
                }
                .clipShape(shape)
                .shadow(
                    color: colorScheme == .light ? Tokens.Shadow.pickerCardColour : .clear,
                    radius: Tokens.Shadow.pickerCardRadius, y: Tokens.Shadow.pickerCardY
                )
        }
        .overlay {
            if category.id == selection {
                RoundedRectangle(cornerRadius: Tokens.Radius.pickerRing, style: .continuous)
                    .stroke(Tokens.Ink.accent, lineWidth: Tokens.Stroke.pickerRing)
                    .padding(-Tokens.Space.pickerRingOutset)
            }
        }
        .contentShape(Rectangle())
    }

    /// `New`: a dashed outline, a light plus and its name, breathing while it's the next step.
    private var newCard: some View {
        RoundedRectangle(cornerRadius: Tokens.Radius.pickerCard, style: .continuous)
            .strokeBorder(Tokens.Drawn.ink2, style: Tokens.Stroke.pickerNew)
            .frame(minHeight: Tokens.Size.pickerCard, maxHeight: .infinity)
            .overlay(alignment: .top) {
                // A light "+" set as text, as the prototype's is, not the heavier symbol.
                Text(verbatim: "+")
                    .font(Tokens.Text.pickerPlus)
                    .frame(height: Tokens.Size.pickerPlus)
                    .padding(.top, Tokens.Space.pickerPlusTop)
            }
            .overlay(alignment: .bottom) {
                Text("New")
                    .font(Tokens.Text.pickerName)
                    .padding(.bottom, Tokens.Space.pickerNameBottom)
            }
            .foregroundStyle(Tokens.Drawn.ink2)
            .contentShape(Rectangle())
            .phaseAnimator(newBreathes ? [1, Tokens.Motion.breatheOpacity] : [1]) { view, opacity in
                view.opacity(opacity)
            } animation: { _ in
                .easeInOut(duration: Tokens.Motion.breathe / 2)
            }
    }
}
