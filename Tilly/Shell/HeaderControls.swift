import SwiftUI

/// Settings, alone in a glass capsule at the header row's trailing end, where the month's arrows
/// join it on their left. See "The shell" in `docs/DESIGN.md`.
struct HeaderControls: View {
    let onSettings: () -> Void

    var body: some View {
        Button(action: onSettings) {
            Image(systemName: "gearshape")
                .font(Tokens.Text.floatingSymbol)
                // The slot is a fixed size, as toolbar symbols are, so the symbol stops growing
                // before it'd fill it.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .foregroundStyle(Tokens.Ink.primary)
                .frame(width: Tokens.Size.groupSlot, height: Tokens.Size.floatingButton)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Capsule())
        .accessibilityLabel("Settings")
    }
}
