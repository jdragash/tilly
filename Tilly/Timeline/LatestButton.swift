import SwiftUI

/// The floating pill that returns the reader to the current month. It appears once they are
/// `Tokens.Space.returnThreshold` from the resting position, pointing the way they will
/// travel to get there, and disappears once they arrive. See "Getting back" in
/// `docs/DESIGN.md`.
///
/// Liquid Glass, via the stock `.glass` button style rather than a hand-built capsule: a
/// control floating over moving content is exactly what the material is for, and the style
/// carries the press response and the accessibility contrast behaviours with it.
struct LatestButton: View {
    enum Direction: Equatable {
        case up, down

        var systemImage: String {
            switch self {
            case .up: "chevron.up"
            case .down: "chevron.down"
            }
        }
    }

    let month: MonthKey
    let direction: Direction
    let today: Date
    let action: () -> Void

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    var body: some View {
        Button(action: action) {
            HStack(spacing: Tokens.Space.tight) {
                Image(systemName: direction.systemImage)
                    .accessibilityHidden(true)
                Text(month.name(in: calendar, relativeTo: today, locale: locale))
                    .font(Tokens.Text.barName)
            }
            .foregroundStyle(Tokens.Ink.primary)
            .padding(.horizontal, Tokens.Space.pillHorizontal)
            .frame(minHeight: Tokens.Size.pill)
        }
        .buttonStyle(.glass)
        .accessibilityElement(children: .combine)
        // VoiceOver has no arrow to read, so the verb the visible copy deliberately omits
        // belongs in the label instead.
        .accessibilityLabel("Back to \(month.name(in: calendar, relativeTo: today, locale: locale))")
    }
}
