import SwiftUI

/// Bottom left, always there, naming the current month. Tapping it brings the reader back to
/// the current month from anywhere. It never appears, fades or changes on its own, like
/// Calendar's Today. See "Getting back" in `docs/DESIGN.md`.
///
/// Liquid Glass, because a control floating over moving content is what the material is for.
/// Applied with `glassEffect` for the same reason as `GlassCircleButton`, so the two share one
/// height across the bottom row.
struct MonthButton: View {
    let month: MonthKey
    let today: Date
    let action: () -> Void

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    var body: some View {
        Button(action: action) {
            Text(month.name(in: calendar, relativeTo: today, locale: locale))
                .font(Tokens.Text.barName)
                .foregroundStyle(Tokens.Ink.primary)
                .padding(.horizontal, Tokens.Space.monthButtonHorizontal)
                .frame(minHeight: Tokens.Size.floatingButton)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: Capsule())
        // The visible copy is only the month; the verb belongs to VoiceOver.
        .accessibilityLabel("Back to \(month.name(in: calendar, relativeTo: today, locale: locale))")
    }
}
