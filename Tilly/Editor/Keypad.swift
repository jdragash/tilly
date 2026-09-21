import SwiftUI

/// A 3×4 grid: 1–9, the locale's decimal separator, 0, delete. The rows share the panel's
/// height, so the keypad fills exactly the space every other panel does.
struct Keypad: View {
    let onPress: (KeypadKey) -> Void

    @Environment(\.locale) private var locale

    private static let rows: [[KeypadKey]] = [
        [.digit(1), .digit(2), .digit(3)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(7), .digit(8), .digit(9)],
        [.decimal, .digit(0), .delete]
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Self.rows.indices, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(Self.rows[row].indices, id: \.self) { column in
                        key(Self.rows[row][column])
                    }
                }
            }
        }
    }

    private func key(_ key: KeypadKey) -> some View {
        Button {
            onPress(key)
        } label: {
            keyLabel(key)
                .font(Tokens.Text.keypadKey)
                .foregroundStyle(Tokens.Ink.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(KeyStyle())
        .accessibilityLabel(accessibilityLabel(for: key))
    }

    @ViewBuilder
    private func keyLabel(_ key: KeypadKey) -> some View {
        switch key {
        case .digit(let digit): Text(String(digit))
        case .decimal: Text(locale.decimalSeparator ?? ".")
        case .delete: Image(systemName: "delete.left")
        }
    }

    private func accessibilityLabel(for key: KeypadKey) -> String {
        switch key {
        case .digit(let digit): String(digit)
        case .decimal: "Decimal point"
        case .delete: "Delete"
        }
    }
}

/// Presses show as a soft fill, the way a system key does.
private struct KeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: Tokens.Radius.editorButton, style: .continuous)
                    .fill(configuration.isPressed ? Tokens.Surface.editorButtonActive : Color.clear)
            )
    }
}

#Preview {
    Keypad { _ in }
        .frame(height: Tokens.Size.editorPanel)
}
