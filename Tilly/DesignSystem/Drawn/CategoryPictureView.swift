import SwiftUI

/// A category's picture as Tilly draws it. A symbol is drawn by `PictureDrawing`, baked into three
/// images by `BoilFrames`. An emoji is drawn as itself. `.none` draws nothing. `size` is the
/// picture's side, wash included.
struct CategoryPictureView: View {
    let picture: CategoryPicture
    let colour: CategoryColour?
    let size: CGFloat
    var onCard: Bool = false
    /// The prototype's `catPic`: a round, roughened wash a little inside the square and a finer,
    /// smaller symbol. The timeline's rows and the category picker draw it; elsewhere keeps the
    /// rounded well.
    var round: Bool = false
    /// Three drawings, baked once (`BoilFrames`), swapped every `Tokens.Motion.boilStep` by Core
    /// Animation; held on the first under Reduce Motion, or when a picture is told not to.
    var boils: Bool = true
    /// Where the picture is: the editor and its pickers boil when the setting is "Editor", every
    /// place when it is "Everywhere".
    var place: BoilPlace = .list

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale

    /// Whether this picture is boiling now.
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
            let frames = BoilFrames.images(
                name: name, colour: colour, size: size, onCard: onCard, round: round,
                scheme: colorScheme, scale: displayScale
            )
            BoilingPicture(frames: frames, boils: isBoiling, size: size)
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        case .emoji(let emoji):
            Text(emoji)
                .font(.system(size: size * Tokens.Drawn.emojiScale))
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        case .none:
            EmptyView()
        }
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
