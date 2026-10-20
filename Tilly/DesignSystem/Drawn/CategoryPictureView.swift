import SwiftUI

/// A category's picture as Tilly draws it. A symbol is roughened (`roughen`), in its colour on a
/// faint wash, or white on a faint white wash where it sits on its own solid card. An emoji is
/// drawn as itself. `.none` draws nothing. `size` is the picture's side, wash included.
struct CategoryPictureView: View {
    let picture: CategoryPicture
    let colour: CategoryColour?
    let size: CGFloat
    var onCard: Bool = false
    /// Three drawings swapped every `Tokens.Motion.boilStep`, off the shared `BoilClock`; held on the
    /// first under Reduce Motion, or when a picture is told not to.
    var boils: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        switch picture {
        case .symbol(let name):
            let seeds = Tokens.Drawn.boilSeeds
            let step = boils && !reduceMotion ? BoilClock.shared.step : 0
            symbol(name, seed: seeds[step % seeds.count])
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: size * Tokens.Drawn.emojiScale))
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        case .none:
            EmptyView()
        }
    }

    private func symbol(_ name: String, seed: Float) -> some View {
        let ink = onCard ? Tokens.Ink.onCard : (colour.map(Tokens.CategoryColour.color) ?? Tokens.Chart.uncoloured)
        let wash = onCard ? Tokens.Drawn.onCardWash : Tokens.Drawn.washWell
        let reach = CGFloat(Tokens.Drawn.roughAmount) * 2
        return Image(systemName: name)
            .font(.system(size: size * Tokens.Drawn.symbolScale, weight: .regular))
            .foregroundStyle(ink)
            .distortionEffect(
                ShaderLibrary.roughen(
                    .float(Tokens.Drawn.roughFrequency), .float(Tokens.Drawn.roughAmount), .float(seed)
                ),
                maxSampleOffset: CGSize(width: reach, height: reach)
            )
            .frame(width: size, height: size)
            .background(
                ink.opacity(wash),
                in: RoundedRectangle(cornerRadius: size * Tokens.Drawn.wellRadius, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Pictures") {
    let pictures: [CategoryPicture] = [.symbol("house"), .symbol("car"), .emoji("🏠"), .none]
    VStack(spacing: 20) {
        ForEach([false, true], id: \.self) { onCard in
            HStack(spacing: 20) {
                ForEach(Array(pictures.enumerated()), id: \.offset) { _, picture in
                    CategoryPictureView(picture: picture, colour: .blue, size: 48, onCard: onCard)
                }
            }
            .padding()
            .background(onCard ? Tokens.CategoryColour.color(.blue) : Tokens.Drawn.paper)
        }
        HStack(spacing: 20) {
            CategoryPictureView(picture: .symbol("house"), colour: .orange, size: 64, boils: true)
            CategoryPictureView(picture: .symbol("tv"), colour: .magenta, size: 64, onCard: true, boils: true)
        }
        .padding()
    }
    .drawnGround()
}
#endif
