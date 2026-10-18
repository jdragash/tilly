import SwiftUI

/// A colour laid down as a wash: paper first, so it hides what's beneath, then the colour at
/// `cardFill` with its edge at `cardEdge`, its alpha varied by `bloom`.
struct Wash: View {
    let colour: Color
    let cornerRadii: RectangleCornerRadii
    let seed: UInt64

    var body: some View {
        // The path is inset by half the edge, so the line ends on the view's bounds.
        let shape = RoughRoundedRectangle(cornerRadii: cornerRadii, seed: seed, inset: Tokens.Drawn.edgeWidth / 2)
        ZStack {
            shape
                .fill(Tokens.Drawn.paper)
                .overlay { shape.stroke(Tokens.Drawn.paper, style: Self.edge) }
            shape
                .fill(colour.opacity(Tokens.Drawn.cardFill))
                .overlay { shape.stroke(colour.opacity(Tokens.Drawn.cardEdge), style: Self.edge) }
                .colorEffect(ShaderLibrary.bloom(
                    .float(Tokens.Drawn.bloomFrequency), .float(Tokens.Drawn.bloom),
                    .float(Tokens.Drawn.bloomSeed + Float(seed % 80))
                ))
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
