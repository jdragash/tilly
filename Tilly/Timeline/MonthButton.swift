import SwiftUI

/// Bottom left, always there, naming the current month. Tapping it brings the reader back to
/// the current month from anywhere. It never appears, fades or changes on its own, like
/// Calendar's Today. See "Getting back" in `docs/DESIGN.md`.
///
/// Liquid Glass, because a control floating over moving content is what the material is for.
/// Applied with `glassEffect` for the same reason as `BottomTrailingControls`, so the two share
/// one height across the bottom row.
///
/// A nil `action` hides it, as the year does, where there is no month to return to. It keeps its
/// place in the row, hidden rather than removed, so the row's height, which the list's bottom
/// inset follows, doesn't change with it; hidden, it is also out of the accessibility tree.
struct MonthButton: View {
    let month: MonthKey
    let today: Date
    let action: (() -> Void)?

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    var body: some View {
        if let action {
            button(action)
        } else {
            button {}.hidden()
        }
    }

    private func button(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(month.name(in: calendar, relativeTo: today, locale: locale))
                .font(Tokens.Text.monthButton)
                .foregroundStyle(Tokens.Ink.primary)
                .padding(.horizontal, Tokens.Space.monthButtonHorizontal)
                .frame(minHeight: Tokens.Size.bottomButton)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Capsule())
        // The visible copy is only the month; the verb belongs to VoiceOver.
        .accessibilityLabel("Back to \(month.name(in: calendar, relativeTo: today, locale: locale))")
    }
}
