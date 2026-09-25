import SwiftUI

/// Pages the category view a month at a time, and stops, dimmed, at the oldest charge and the
/// timeline's last month. One glass capsule left of the view-and-+ pair. See "The category view"
/// in `docs/DESIGN.md`.
struct MonthArrows: View {
    let canGoBack: Bool
    let canGoForward: Bool
    let step: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            arrow("chevron.left", label: "Previous month", enabled: canGoBack) { step(-1) }
            arrow("chevron.right", label: "Next month", enabled: canGoForward) { step(1) }
        }
        .glassEffect(.regular.interactive(), in: Capsule())
    }

    private func arrow(_ systemImage: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(Tokens.Text.floatingSymbol)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .foregroundStyle(Tokens.Ink.primary)
                .opacity(enabled ? 1 : Tokens.Opacity.disabledArrow)
                .frame(width: Tokens.Size.groupSlot, height: Tokens.Size.floatingButton)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}
