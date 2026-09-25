import SwiftUI

/// The view button and +, one glass capsule at the header row's trailing end in both views. The
/// view button's icon names the view you're in; its menu lists the views with a checkmark on the
/// current one. See "The shell" in `docs/DESIGN.md`.
///
/// A `Menu`, not a `confirmationDialog`: a menu acts on the tap itself (see
/// `.claude/rules/swiftui-controls.md`).
struct HeaderControls: View {
    @Binding var mode: ViewMode
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Menu {
                Picker("View", selection: $mode) {
                    ForEach(ViewMode.allCases) { mode in
                        Label(mode.title, systemImage: mode.systemImage).tag(mode)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                slot(systemImage: mode.systemImage)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .accessibilityLabel("View")
            .accessibilityValue(mode.title)

            Button(action: onAdd) {
                slot(systemImage: "plus")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add an expense")
        }
        .glassEffect(.regular.interactive(), in: Capsule())
    }

    private func slot(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(Tokens.Text.floatingSymbol)
            // The slots are a fixed size, as toolbar symbols are; see `GlassCircleButton`.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .foregroundStyle(Tokens.Ink.primary)
            .frame(width: Tokens.Size.groupSlot, height: Tokens.Size.floatingButton)
            .contentShape(Rectangle())
    }
}
