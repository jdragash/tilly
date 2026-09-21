import SwiftUI

/// A glass circle holding one symbol: + at the top, settings at the bottom. Both float over
/// the timeline, each at its row's size: `Tokens.Size.floatingButton` at the top and
/// `bottomButton` at the bottom, as Calendar's are.
///
/// The system glass, applied with `glassEffect` rather than the `.glass` button style: that
/// style pads around its label, measured at 58pt for a 44pt label, and + has to sit exactly in
/// the header row.
struct GlassCircleButton: View {
    let systemImage: String
    let label: String
    var diameter: CGFloat = Tokens.Size.floatingButton
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(Tokens.Text.floatingSymbol)
                // The circle is a fixed size, as toolbar symbols are, so the symbol stops
                // growing before it would fill it.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .foregroundStyle(Tokens.Ink.primary)
                .frame(width: diameter, height: diameter)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Circle())
        .accessibilityLabel(label)
    }
}
