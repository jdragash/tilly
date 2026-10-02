import SwiftUI

/// A glass capsule naming the level one step out: "‹ October" over the days, "‹ Year" over a
/// month, as Calendar's top left does. `Tokens.Size.floatingButton` high, so it shares the top
/// row with the glass pair.
struct BackButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Tokens.Space.backButtonGap) {
                Image(systemName: "chevron.left")
                    .font(Tokens.Text.floatingSymbol)
                Text(title)
                    .font(Tokens.Text.backButton)
                    .lineLimit(1)
            }
            // A fixed height, as the glass pair beside it is, so the symbol and name stop
            // growing before they'd overflow it.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .foregroundStyle(Tokens.Ink.primary)
            .padding(.leading, Tokens.Space.backButtonLeading)
            .padding(.trailing, Tokens.Space.backButtonTrailing)
            .frame(height: Tokens.Size.floatingButton)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Capsule())
        .accessibilityLabel("Back to \(title)")
    }
}
