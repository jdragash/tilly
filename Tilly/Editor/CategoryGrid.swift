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

    /// The card, as `CategoryCardFace` draws it, with the picked one's ring outside it.
    private func card(_ category: ExpenseCategory) -> some View {
        CategoryCardFace(
            colour: category.colour, seed: stableSeed(category.id.uuidString), metrics: .grid, name: category.name
        ) {
            CategoryPictureView(
                picture: CategoryPicture(category), colour: category.colour,
                size: Tokens.Size.pickerPicture, round: true, place: .editor
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
                CategoryCardName(name: String(localized: "New"), ink: Tokens.Drawn.ink2)
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
