import SwiftUI

/// All bills and settings: one glass capsule at the bottom right, in every view, as the view
/// button and + share one at the top. Applied with `glassEffect` on the group rather than the
/// `.glass` button style, which pads around its label (see `.claude/rules/swiftui-controls.md`),
/// so the capsule is exactly `Tokens.Size.bottomButton` high, as the month button beside it is.
struct BottomTrailingControls: View {
    let onBills: () -> Void
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            button("list.bullet", label: "All bills", action: onBills)
            button("gearshape", label: "Settings", action: onSettings)
        }
        .glassEffect(.regular.interactive(), in: Capsule())
    }

    private func button(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(Tokens.Text.floatingSymbol)
                // A fixed-size slot, as the symbols in the other glass groups are.
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .foregroundStyle(Tokens.Ink.primary)
                .frame(width: Tokens.Size.groupSlot, height: Tokens.Size.bottomButton)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
