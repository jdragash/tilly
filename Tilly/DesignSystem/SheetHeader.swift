import SwiftUI

/// A sheet's top row: ✕ on the left, the sheet's own buttons on the right, and a title between them
/// when it has one. Glass circles the size and place of the system sheet's toolbar buttons, which
/// this row replaced when the editor stopped being a system sheet; the category sheet shares it.
struct SheetHeader<Trailing: View>: View {
    var title: String?
    var closeLabel = "Close"
    let onClose: () -> Void
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: Tokens.Space.sheetButtonGap) {
            Button(action: onClose) {
                SheetHeaderSymbol(name: "xmark", ink: Tokens.Ink.primary)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: Circle())
            .accessibilityLabel(closeLabel)
            Spacer(minLength: 0)
            trailing
        }
        .overlay {
            if let title {
                Text(title)
                    .font(Tokens.Text.sheetTitle)
                    .foregroundStyle(Tokens.Ink.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(Tokens.Scale.headerMin)
                    // Capped as the buttons beside it are, so it isn't squeezed out between them.
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    // Clear of the buttons on both sides, whichever side has more.
                    .padding(.horizontal, Tokens.Size.sheetTitleClearance)
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .padding(.horizontal, Tokens.Space.sheetButtonInset)
        .padding(.top, Tokens.Space.sheetButtonInset)
        .padding(.bottom, Tokens.Space.sheetHeaderBottom)
    }
}

/// A symbol in a header circle, fixed in size as toolbar symbols are: the circle doesn't grow with
/// the text.
struct SheetHeaderSymbol: View {
    let name: String
    let ink: Color

    var body: some View {
        Image(systemName: name)
            .font(Tokens.Text.floatingSymbol)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .foregroundStyle(ink)
            .frame(width: Tokens.Size.floatingButton, height: Tokens.Size.floatingButton)
            .contentShape(Circle())
    }
}

/// A button that draws its label as it is, enabled or not; its glass answers the press. The
/// system's disabled ✓ keeps it white on grey glass, where `.plain` would dim it.
struct UndimmedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
