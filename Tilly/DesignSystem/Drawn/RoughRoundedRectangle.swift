import SwiftUI

/// A rounded rectangle whose edge wobbles by seeded noise: the same seed draws the same edge, so
/// a row redrawn while scrolling doesn't shimmer. Two wobbles: a slow one of `wobble` points, and
/// a fine one of `Tokens.Drawn.roughAmplitude`. A corner of radius 0 stays a corner.
nonisolated struct RoughRoundedRectangle: Shape {
    var cornerRadii: RectangleCornerRadii
    var seed: UInt64
    var wobble: CGFloat = Tokens.Drawn.edgeWobble
    /// Drawn this far inside the rect, so a stroke of twice this ends on its bounds.
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let outline = Self.outline(of: rect.insetBy(dx: inset, dy: inset), radii: cornerRadii, step: Tokens.Drawn.edgeStep)
        guard outline.count > 1 else { return Path() }

        let slow = (x: SmoothNoise(seed: seed &* 31 &+ 7, frequency: Tokens.Drawn.edgeFrequency),
                    y: SmoothNoise(seed: seed &* 17 &+ 5, frequency: Tokens.Drawn.edgeFrequency))
        let fine = (x: SmoothNoise(seed: seed &* 13 &+ 3, frequency: Tokens.Drawn.roughEdgeFrequency),
                    y: SmoothNoise(seed: seed &* 29 &+ 11, frequency: Tokens.Drawn.roughEdgeFrequency))
        // Each axis moves by amount/√2, so a point never leaves a circle of that radius.
        let slowAxis = Double(wobble) / 2.0.squareRoot()
        let fineAxis = Double(Tokens.Drawn.roughAmplitude) / 2.0.squareRoot()

        var length = 0.0
        var previous = outline[0]
        let points = outline.map { point -> CGPoint in
            length += Double(hypot(point.x - previous.x, point.y - previous.y))
            previous = point
            return CGPoint(
                x: point.x + CGFloat(slowAxis * slow.x(length) + fineAxis * fine.x(length)),
                y: point.y + CGFloat(slowAxis * slow.y(length) + fineAxis * fine.y(length))
            )
        }

        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() { path.addLine(to: point) }
        // Back to where it began, so the line closes without a gap whatever the noise did.
        path.addLine(to: points[0])
        path.closeSubpath()
        return path
    }

    /// The plain rounded rectangle as points about `step` apart, clockwise from the top left's
    /// edge. Radii larger than half the short side are clamped to it.
    static func outline(of rect: CGRect, radii: RectangleCornerRadii, step: CGFloat) -> [CGPoint] {
        let limit = max(0, min(rect.width, rect.height) / 2)
        let tl = min(max(radii.topLeading, 0), limit), tr = min(max(radii.topTrailing, 0), limit)
        let br = min(max(radii.bottomTrailing, 0), limit), bl = min(max(radii.bottomLeading, 0), limit)

        var points: [CGPoint] = []
        func line(_ from: CGPoint, _ to: CGPoint) {
            let count = max(1, Int((hypot(to.x - from.x, to.y - from.y) / step).rounded(.up)))
            for index in 0..<count {
                let t = CGFloat(index) / CGFloat(count)
                points.append(CGPoint(x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t))
            }
        }
        func arc(centre: CGPoint, radius: CGFloat, from start: CGFloat) {
            guard radius > 0 else { return }
            let count = max(2, Int((radius * .pi / 2 / step).rounded(.up)))
            for index in 0..<count {
                let angle = start + (.pi / 2) * CGFloat(index) / CGFloat(count)
                points.append(CGPoint(x: centre.x + cos(angle) * radius, y: centre.y + sin(angle) * radius))
            }
        }

        line(CGPoint(x: rect.minX + tl, y: rect.minY), CGPoint(x: rect.maxX - tr, y: rect.minY))
        arc(centre: CGPoint(x: rect.maxX - tr, y: rect.minY + tr), radius: tr, from: -.pi / 2)
        line(CGPoint(x: rect.maxX, y: rect.minY + tr), CGPoint(x: rect.maxX, y: rect.maxY - br))
        arc(centre: CGPoint(x: rect.maxX - br, y: rect.maxY - br), radius: br, from: 0)
        line(CGPoint(x: rect.maxX - br, y: rect.maxY), CGPoint(x: rect.minX + bl, y: rect.maxY))
        arc(centre: CGPoint(x: rect.minX + bl, y: rect.maxY - bl), radius: bl, from: .pi / 2)
        line(CGPoint(x: rect.minX, y: rect.maxY - bl), CGPoint(x: rect.minX, y: rect.minY + tl))
        arc(centre: CGPoint(x: rect.minX + tl, y: rect.minY + tl), radius: tl, from: .pi)
        return points
    }
}
