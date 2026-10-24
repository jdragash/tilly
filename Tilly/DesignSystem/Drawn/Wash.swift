import SwiftUI

/// A colour laid down as a wash: paper first, so it hides what's beneath, then the colour at
/// `cardFill` with its edge at `cardEdge`, its alpha varied by `bloom`.
///
/// Drawn once into an image, cached by what it looks like, and then shown as a plain picture. Drawn
/// live, as a shape with a shader and a blurred shadow, every card cost the GPU on every frame of
/// every scroll, keystroke and boil, which a phone doesn't keep up with.
struct Wash: View {
    let colour: Color
    let cornerRadii: RectangleCornerRadii
    let seed: UInt64

    @Environment(\.self) private var environment
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: WashImage.image(
                colour: colour.resolve(in: environment), paper: Tokens.Drawn.paper.resolve(in: environment),
                size: geometry.size, cornerRadii: cornerRadii, seed: seed, scale: displayScale
            ))
            .resizable()
            .frame(width: geometry.size.width + 2 * WashImage.margin, height: geometry.size.height + 2 * WashImage.margin)
            .offset(x: -WashImage.margin, y: -WashImage.margin)
            .allowsHitTesting(false)
        }
        .accessibilityHidden(true)
    }

    static let edge = StrokeStyle(lineWidth: Tokens.Drawn.edgeWidth, lineJoin: .round)
}

/// What's still to come: paper inside a dotted line in the colour.
struct DottedOutline: View {
    let colour: Color
    let cornerRadii: RectangleCornerRadii
    let seed: UInt64

    var body: some View {
        let shape = RoughRoundedRectangle(cornerRadii: cornerRadii, seed: seed, inset: Tokens.Drawn.edgeWidth / 2)
        ZStack {
            shape.fill(Tokens.Drawn.paper)
            shape
                .stroke(
                    colour.opacity(Tokens.Drawn.dotOpacity),
                    style: StrokeStyle(lineWidth: Tokens.Drawn.dotWidth, lineCap: .round, dash: Tokens.Drawn.dotDash)
                )
        }
        .accessibilityHidden(true)
    }
}

/// What's charged: a solid paper card, `Drawn.paperCard`, on the rough shape. No colour, no shadow.
struct PaperCard: View {
    let cornerRadii: RectangleCornerRadii
    let seed: UInt64

    var body: some View {
        RoughRoundedRectangle(cornerRadii: cornerRadii, seed: seed)
            .fill(Tokens.Drawn.paperCard)
            .accessibilityHidden(true)
    }
}

/// What's still to come: paper inside a faint dashed line, `Drawn.dashFaint`, `Stroke.rowDash`.
struct DashedOutline: View {
    let cornerRadii: RectangleCornerRadii
    let seed: UInt64

    var body: some View {
        let dash = Tokens.Stroke.rowDash
        RoughRoundedRectangle(cornerRadii: cornerRadii, seed: seed, inset: dash.lineWidth / 2)
            .stroke(Tokens.Drawn.dashFaint, style: dash)
            .accessibilityHidden(true)
    }
}
