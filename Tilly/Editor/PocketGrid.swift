import SwiftUI

/// The pockets, three across in the keypad's place, `New` last. See "The pockets are the
/// category picker" in `docs/DESIGN.md`.
struct PocketGrid: View {
    let pockets: [PocketContent]
    let selection: UUID?
    let draftName: String          // on the card standing in the chosen pocket
    let newBreathes: Bool          // first bill, amount and name in
    let filing: UUID?              // step 6; nil here
    let onPick: (UUID) -> Void
    let onNew: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .footnote) private var width = Tokens.Size.pocketWidth
    @ScaledMetric(relativeTo: .footnote) private var height = Tokens.Size.pocketHeight
    @ScaledMetric(relativeTo: .footnote) private var lip = Tokens.Size.pocketLip
    @ScaledMetric(relativeTo: .caption2) private var peekHeight = Tokens.Size.pocketPeekHeight
    @ScaledMetric(relativeTo: .caption2) private var peekStep = Tokens.Space.pocketPeekStep
    @ScaledMetric(relativeTo: .footnote) private var front = Tokens.Space.pocketFront

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Tokens.Space.pocketRow) {
                ForEach(pockets) { pocket in
                    pocketButton(pocket)
                }
                newPocket
            }
            .padding(.top, Tokens.Space.pocketsTop)
            .padding(.bottom, Tokens.Space.section)
        }
        .scrollBounceBehavior(.basedOnSize)
    }

    /// Three fixed columns, or two filling the width at accessibility sizes.
    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            return Array(repeating: GridItem(.flexible(), spacing: Tokens.Space.pocketColumn), count: 2)
        }
        return Array(repeating: GridItem(.fixed(width), spacing: Tokens.Space.pocketColumn), count: 3)
    }

    // MARK: A category's pocket

    private func pocketButton(_ pocket: PocketContent) -> some View {
        let isChosen = pocket.id == selection
        return Button { onPick(pocket.id) } label: {
            pocketView(pocket, isChosen: isChosen)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(pocket.name)
        .accessibilityValue(pocket.peeking.reversed().joined(separator: ", "))
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }

    /// Its back in the category's colour, the bills peeking out of it, the newest in front, and its
    /// lip with the emoji and name. The chosen one lifts, with the card's name standing in front.
    private func pocketView(_ pocket: PocketContent, isChosen: Bool) -> some View {
        let colour = pocket.colour.map(Tokens.CategoryColour.color) ?? Tokens.Chart.uncoloured
        let back = RoundedRectangle(cornerRadius: Tokens.Radius.pocket, style: .continuous)
        var slips = pocket.peeking.map { Slip(name: $0, isDraft: false) }
        if isChosen { slips.append(Slip(name: draftName.isEmpty ? "Name" : draftName, isDraft: true)) }
        let frontTop = height - lip - front
        return ZStack(alignment: .top) {
            back.fill(colour.opacity(Tokens.Opacity.pocketBack))
                .overlay {
                    if isChosen {
                        back.strokeBorder(Tokens.Ink.accent, lineWidth: Tokens.Stroke.pocketRing)
                    }
                }
            ForEach(Array(slips.enumerated()), id: \.offset) { index, slip in
                slipView(slip)
                    .offset(y: frontTop - CGFloat(slips.count - 1 - index) * peekStep)
            }
            lipView(pocket, colour: colour)
                .offset(y: height - lip + (isChosen ? Tokens.Space.pocketLipDrop : 0))
        }
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .top)
        .offset(y: isChosen ? -Tokens.Size.pocketLift : 0)
        .contentShape(back)
    }

    private struct Slip {
        let name: String
        let isDraft: Bool
    }

    private func slipView(_ slip: Slip) -> some View {
        Text(slip.name)
            .font(Tokens.Text.pocketPeek)
            .foregroundStyle(Tokens.Ink.onPocketPeek)
            .lineLimit(1)
            .padding(.horizontal, Tokens.Space.pocketPeekTextHorizontal)
            .padding(.top, Tokens.Space.pocketPeekTextTop)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .frame(height: peekHeight)
            .background(
                Tokens.Surface.pocketPeek,
                in: RoundedRectangle(cornerRadius: Tokens.Radius.pocketPeek, style: .continuous)
            )
            .shadow(color: Tokens.Shadow.pocketColour, radius: Tokens.Shadow.pocketRadius, y: Tokens.Shadow.pocketY)
            .padding(.horizontal, Tokens.Space.pocketPeekInset)
            .accessibilityHidden(true)
    }

    private func lipView(_ pocket: PocketContent, colour: Color) -> some View {
        HStack(spacing: Tokens.Space.pocketLipGap) {
            Text(pocket.emoji)
            Text(pocket.name)
                .lineLimit(1)
        }
        .font(Tokens.Text.pocketName)
        .foregroundStyle(Tokens.Ink.onCard)
        .padding(.horizontal, Tokens.Space.pocketLipHorizontal)
        .frame(maxWidth: .infinity)
        .frame(height: lip)
        .background(
            Tokens.CategoryColour.cardFill(pocket.colour).opacity(Tokens.Opacity.pocketLip),
            in: lipShape
        )
        .shadow(color: Tokens.Shadow.pocketColour, radius: Tokens.Shadow.pocketRadius, y: Tokens.Shadow.pocketY)
        .accessibilityHidden(true)
    }

    private var lipShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: Tokens.Radius.pocketLipTop,
            bottomLeadingRadius: Tokens.Radius.pocket,
            bottomTrailingRadius: Tokens.Radius.pocket,
            topTrailingRadius: Tokens.Radius.pocketLipTop,
            style: .continuous
        )
    }

    // MARK: New

    /// A dashed pocket with nothing in it. With no categories yet, it's the only pocket, and it
    /// breathes once the amount and name are in.
    private var newPocket: some View {
        let back = RoundedRectangle(cornerRadius: Tokens.Radius.pocket, style: .continuous)
        return Button(action: onNew) {
            ZStack(alignment: .top) {
                back.strokeBorder(newBreathes ? Tokens.Ink.accent : Tokens.Ink.tertiary, style: Tokens.Stroke.pocketNew)
                    .background(newBreathes ? Tokens.Ink.accent.opacity(Tokens.Opacity.pocketBack) : .clear, in: back)
                HStack(spacing: Tokens.Space.pocketLipGap) {
                    Image(systemName: "plus")
                    Text("New")
                }
                .font(Tokens.Text.pocketName)
                .foregroundStyle(newBreathes ? Tokens.Ink.accent : Tokens.Ink.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: lip)
                .offset(y: height - lip)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height, alignment: .top)
            .contentShape(back)
            .phaseAnimator(newBreathes ? [1, Tokens.Motion.breatheOpacity] : [1]) { view, opacity in
                view.opacity(opacity)
            } animation: { _ in
                .easeInOut(duration: Tokens.Motion.breathe / 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("New category")
    }
}

// MARK: - Previews

private func previewPockets(_ count: Int) -> [PocketContent] {
    let names = ["Home", "Subscriptions", "Car", "Phone", "Insurance", "Gym", "Savings"]
    let emoji = ["🏠", "📺", "🚗", "📱", "🛡️", "🏋️", "🐷"]
    let colours = CategoryColour.allCases
    return (0..<count).map { index in
        PocketContent(
            id: UUID(),
            emoji: emoji[index % emoji.count],
            name: names[index % names.count],
            colour: colours[index % colours.count],
            peeking: Array(["Rent", "Water", "Power"].prefix(index % 4))
        )
    }
}

#Preview("Seven, one chosen") {
    let pockets = previewPockets(7)
    PocketGrid(pockets: pockets, selection: pockets[1].id, draftName: "Video", newBreathes: false,
               filing: nil, onPick: { _ in }, onNew: {})
        .frame(height: Tokens.Size.editorPanel)
}

#Preview("None yet, New breathing") {
    PocketGrid(pockets: [], selection: nil, draftName: "Rent", newBreathes: true,
               filing: nil, onPick: { _ in }, onNew: {})
        .frame(height: Tokens.Size.editorPanel)
}
