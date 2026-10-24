import SwiftUI

/// The small disc at a row picture's lower right: ↻ for a bill that repeats, an arrow to a bar for
/// one with an end. Paper card with a ring of page paper when charged; page paper with a hairline
/// when still to come.
struct RowBadge: View {
    let ends: Bool
    let state: OccurrenceState

    var body: some View {
        Image(systemName: ends ? "arrow.right.to.line" : "arrow.clockwise")
            .font(Tokens.Text.rowBadge)
            .foregroundStyle(Tokens.Drawn.ink2)
            .frame(width: Tokens.Size.rowBadge, height: Tokens.Size.rowBadge)
            .background { disc }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var disc: some View {
        if state == .charged {
            ZStack {
                Circle().fill(Tokens.Drawn.paper).padding(-Tokens.Stroke.badgeRing)
                Circle().fill(Tokens.Drawn.paperCard)
            }
            .compositingGroup()
            .shadow(color: Tokens.Shadow.rowBadgeColour, radius: Tokens.Shadow.rowBadgeRadius, y: Tokens.Shadow.rowBadgeY)
        } else {
            Circle()
                .fill(Tokens.Drawn.paper)
                .overlay(Circle().strokeBorder(Tokens.Drawn.hairline, lineWidth: Tokens.Stroke.badgeHairline))
        }
    }
}
