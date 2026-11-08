import SwiftUI
import UIKit

/// A symbol picture's three drawings, one for each of `Tokens.Drawn.boilSeeds`, rendered once and
/// kept. The boil swaps between them on Core Animation's clock (`BoilingPicture`), so a screenful
/// of pictures redraws nothing on the main thread; before, every picture's body ran on every tick.
@MainActor
enum BoilFrames {
    private final class Box { let images: [UIImage]; init(_ images: [UIImage]) { self.images = images } }
    nonisolated(unsafe) private static let cache: NSCache<NSString, Box> = {
        let cache = NSCache<NSString, Box>()
        cache.countLimit = 600
        return cache
    }()

    static func images(
        name: String, colour: CategoryColour?, size: CGFloat, onCard: Bool, round: Bool,
        scheme: ColorScheme, scale: CGFloat
    ) -> [UIImage] {
        let amount = round ? Tokens.Drawn.roundRoughAmount : Tokens.Drawn.roughAmount
        let key = "\(name)|\(colour?.rawValue ?? "-")|\(size)|\(onCard)|\(round)|\(scheme)|\(scale)|\(amount)" as NSString
        if let hit = cache.object(forKey: key) { return hit.images }
        let made = Tokens.Drawn.boilSeeds.compactMap { seed -> UIImage? in
            let drawing = PictureDrawing(
                name: name, colour: colour, size: size, onCard: onCard, round: round, seed: seed, amount: amount
            )
            .environment(\.colorScheme, scheme)
            .fontDesign(Tokens.Text.design)
            let renderer = ImageRenderer(content: drawing)
            renderer.scale = scale
            renderer.proposedSize = ProposedViewSize(width: size, height: size)
            return renderer.uiImage
        }
        cache.setObject(Box(made), forKey: key)
        return made
    }
}

/// One drawing of a symbol picture: the symbol roughened with `seed`, in its colour on a faint wash,
/// or white on a faint white wash on its own solid card. `size` is the picture's side, wash included.
struct PictureDrawing: View {
    let name: String
    let colour: CategoryColour?
    let size: CGFloat
    let onCard: Bool
    /// The prototype's `catPic`: a round, roughened wash a little inside the square and a finer,
    /// smaller symbol. Otherwise the rounded well.
    let round: Bool
    let seed: Float
    let amount: Float

    var body: some View {
        let ink = onCard ? Tokens.Ink.onCard : (colour.map(Tokens.CategoryColour.color) ?? Tokens.Chart.uncoloured)
        let wash = onCard ? Tokens.Drawn.onCardWash : Tokens.Drawn.washWell
        let reach = CGFloat(amount) * 2
        let scale = round ? Tokens.Drawn.roundSymbolScale : Tokens.Drawn.symbolScale
        let weight: Font.Weight = round ? Tokens.Drawn.roundSymbolWeight : .regular
        glyph(size: size * scale, weight: weight)
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
    }

    /// The symbol at `side`. In the round picture it is fitted whole inside a `side` square, as the
    /// prototype's glyphs fill their box, so a wide symbol (a game controller) is no larger than a
    /// tall one (a bolt); in the rounded well it is set at `side` as type.
    @ViewBuilder
    private func glyph(size side: CGFloat, weight: Font.Weight) -> some View {
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
        // From the symbol, so a category's wash keeps one edge wherever it's drawn.
        let shape = RoughRoundedRectangle(cornerRadii: radii, seed: stableSeed(name), inset: edge / 2)
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
}

/// A picture's drawings, shown by Core Animation: looped every `boilStep` while `boils`, else the
/// first held still. Every loop counts from one moment, so pictures boil in step, as they did off
/// a shared clock. Reports `size` as its own, so it lays out as the drawing did.
struct BoilingPicture: UIViewRepresentable {
    let frames: [UIImage]
    let boils: Bool
    let size: CGFloat

    func makeUIView(context: Context) -> BoilView { BoilView() }

    func updateUIView(_ view: BoilView, context: Context) {
        view.show(frames, boils: boils)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: BoilView, context: Context) -> CGSize? {
        CGSize(width: size, height: size)
    }
}

final class BoilView: UIView {
    /// When every boil's loop began, in media time.
    private static let epoch = CACurrentMediaTime()
    private var frames: [UIImage] = []
    private var boils = false
    private var foreground: NSObjectProtocol?

    init() {
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        layer.contentsGravity = .resize
        // A loop dropped while the app was away starts again where the others are.
        foreground = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.restart() }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    isolated deinit {
        if let foreground { NotificationCenter.default.removeObserver(foreground) }
    }

    func show(_ frames: [UIImage], boils: Bool) {
        guard frames != self.frames || boils != self.boils else { return }
        self.frames = frames
        self.boils = boils
        layer.contents = frames.first?.cgImage
        layer.contentsScale = frames.first?.scale ?? 1
        restart()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        restart()
    }

    private func restart() {
        layer.removeAnimation(forKey: "boil")
        guard boils, window != nil, frames.count > 1 else { return }
        let loop = CAKeyframeAnimation(keyPath: "contents")
        loop.values = frames.compactMap(\.cgImage)
        loop.calculationMode = .discrete
        loop.duration = Double(frames.count) * Tokens.Motion.boilStep
        loop.repeatCount = .infinity
        loop.isRemovedOnCompletion = false
        loop.beginTime = layer.convertTime(Self.epoch, from: nil)
        layer.add(loop, forKey: "boil")
    }
}
