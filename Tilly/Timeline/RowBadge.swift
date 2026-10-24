import SwiftUI

/// The small disc at a row picture's lower right: a looped arrow for a bill that repeats, an arrow
/// to a bar for one with an end, drawn from the prototype's own paths. Paper card with a ring of
/// page paper when charged; page paper with a hairline when still to come.
struct RowBadge: View {
    let ends: Bool
    let state: OccurrenceState

    var body: some View {
        BadgeGlyph(ends: ends)
            .stroke(
                Tokens.Drawn.ink2,
                style: StrokeStyle(
                    lineWidth: Tokens.Size.rowBadgeSymbol * Tokens.Stroke.badgeGlyph,
                    lineCap: .round, lineJoin: .round
                )
            )
            .frame(width: Tokens.Size.rowBadgeSymbol, height: Tokens.Size.rowBadgeSymbol)
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

/// The prototype's badge glyphs, on its 12-unit grid, scaled to the rect.
nonisolated struct BadgeGlyph: Shape {
    let ends: Bool

    func path(in rect: CGRect) -> Path {
        let unit = rect.width / 12
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * unit, y: rect.minY + y * unit)
        }
        var path = Path()
        if ends {
            // M1.6 6 h6.6 · M5.8 3.4 L8.4 6 L5.8 8.6 · M10.4 2.6 v6.8
            path.move(to: point(1.6, 6)); path.addLine(to: point(8.2, 6))
            path.move(to: point(5.8, 3.4)); path.addLine(to: point(8.4, 6)); path.addLine(to: point(5.8, 8.6))
            path.move(to: point(10.4, 2.6)); path.addLine(to: point(10.4, 9.4))
        } else {
            // M9.6 6.4 A3.6 3.6 0 1 1 8.4 3.3: the long way round a circle of 3.6 centred at
            // (6.02, 6.00), from 6.3° to 311.3°, angles growing downward as SVG's do.
            let centre = (x: 6.022, y: 6.003)
            let start = 6.33 * Double.pi / 180
            let end = 311.34 * Double.pi / 180
            let steps = 48
            for step in 0...steps {
                let angle = start + (end - start) * Double(step) / Double(steps)
                let p = point(CGFloat(centre.x + 3.6 * cos(angle)), CGFloat(centre.y + 3.6 * sin(angle)))
                if step == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            // M8.9 1.4 l-0.3 2.1 -2.1 -0.3
            path.move(to: point(8.9, 1.4)); path.addLine(to: point(8.6, 3.5)); path.addLine(to: point(6.5, 3.2))
        }
        return path
    }
}
