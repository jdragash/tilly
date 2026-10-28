import SwiftUI

/// A category's picture as Tilly draws it. A symbol is roughened (`roughen`), in its colour on a
/// faint wash, or white on a faint white wash where it sits on its own solid card. An emoji is
/// drawn as itself. `.none` draws nothing. `size` is the picture's side, wash included.
struct CategoryPictureView: View {
    let picture: CategoryPicture
    let colour: CategoryColour?
    let size: CGFloat
    var onCard: Bool = false
    /// The prototype's `catPic`: a round, roughened wash a little inside the square and a finer,
    /// smaller symbol. The timeline's rows and the category picker draw it; elsewhere keeps the
    /// rounded well.
    var round: Bool = false
    /// Three drawings swapped every `Tokens.Motion.boilStep`, off the shared `BoilClock`; held on the
    /// first under Reduce Motion, or when a picture is told not to.
    var boils: Bool = true
    /// Where the picture is: the editor and its pickers boil when the setting is "Editor", every
    /// place when it is "Everywhere".
    var place: BoilPlace = .list

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Whether this picture is boiling now. Reading the clock only then means a picture that holds
    /// still never redraws with it.
    private var isBoiling: Bool {
        guard boils, !reduceMotion else { return false }
        switch BoilSetting.current {
        case .off: return false
        case .editor: return place == .editor
        case .everywhere: return true
        }
    }

    var body: some View {
        switch picture {
        case .symbol(let name):
            let seeds = Tokens.Drawn.boilSeeds
            let step = isBoiling ? (place == .editor ? BoilClock.shared.step : BoilClock.shared.listStep) : 0
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
        let amount = round ? Tokens.Drawn.roundRoughAmount : Tokens.Drawn.roughAmount
        let reach = CGFloat(amount) * 2
        let scale = round ? Tokens.Drawn.roundSymbolScale : Tokens.Drawn.symbolScale
        let weight: Font.Weight = round ? Tokens.Drawn.roundSymbolWeight : .regular
        return glyph(name, size: size * scale, weight: weight)
            .foregroundStyle(ink)
            .distortionEffect(
                ShaderLibrary.roughen(
                    .float(Tokens.Drawn.roughFrequency), .float(amount), .float(seed)
                ),
                maxSampleOffset: CGSize(width: reach, height: reach)
            )
            .frame(width: size, height: size)
            .background {
                if round {
                    roundWash(ink: ink, opacity: wash)
                } else {
                    RoundedRectangle(cornerRadius: size * Tokens.Drawn.wellRadius, style: .continuous)
                        .fill(ink.opacity(wash))
                }
            }
            .accessibilityHidden(true)
    }

    /// The symbol at `side`. In the round picture it is fitted whole inside a `side` square, as the
    /// prototype's glyphs fill their box, so a wide symbol (a game controller) is no larger than a
    /// tall one (a bolt); in the rounded well it is set at `side` as type.
    @ViewBuilder
    private func glyph(_ name: String, size side: CGFloat, weight: Font.Weight) -> some View {
        if round {
            Image(systemName: name)
                .resizable()
                .fontWeight(weight)
                .scaledToFit()
                .frame(width: side, height: side)
        } else {
            Image(systemName: name)
                .font(.system(size: side, weight: weight))
        }
    }

    /// The prototype's blob: a roughened circle `roundWashInset` of the side inside the square, its
    /// fill at `washWell × washFill` and its edge at `washWell × washEdge`.
    private func roundWash(ink: Color, opacity: Double) -> some View {
        let diameter = size * (1 - 2 * Tokens.Drawn.roundWashInset)
        let radii = RectangleCornerRadii(
            topLeading: diameter / 2, bottomLeading: diameter / 2, bottomTrailing: diameter / 2, topTrailing: diameter / 2
        )
        let edge = max(Tokens.Drawn.roundWashEdgeMin, size * Tokens.Drawn.roundWashEdgeRatio)
        let shape = RoughRoundedRectangle(cornerRadii: radii, seed: Self.washSeed(picture), inset: edge / 2)
        return ZStack {
            shape.fill(ink.opacity(opacity * Tokens.Drawn.washFill))
            // Softened, as the prototype's displacement scatters its edge rather than ruling it.
            shape.stroke(ink.opacity(opacity * Tokens.Drawn.washEdge), lineWidth: edge)
                .blur(radius: Tokens.Drawn.roundWashEdgeBlur)
        }
        .frame(width: diameter, height: diameter)
        .mask {
            Image(uiImage: Grain.speckle)
                .resizable(resizingMode: .tile)
                .interpolation(.medium)
        }
    }

    /// From the picture, so a category's wash keeps one edge wherever it's drawn.
    private static func washSeed(_ picture: CategoryPicture) -> UInt64 {
        if case .symbol(let name) = picture { return stableSeed(name) }
        return 1
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


enum BoilPlace: Sendable {
    case list, editor
}

/// Where pictures boil, from the debug panel; in a release build, the default.
enum BoilSetting: Int, Sendable {
    case off, editor, everywhere

    @MainActor static var current: BoilSetting {
        BoilSetting(rawValue: Int(MotionTuning.shared["boil"])) ?? .everywhere
    }
}
