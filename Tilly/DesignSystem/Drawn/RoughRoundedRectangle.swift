import SwiftUI

/// A rounded rectangle whose edge wobbles by seeded noise: the same seed draws the same edge, so
/// a row redrawn while scrolling doesn't shimmer. Two wobbles: a slow one of `wobble` points, and
/// a fine one of `Tokens.Drawn.roughAmplitude`. A corner of radius 0 stays a corner.
nonisolated struct RoughRoundedRectangle: Shape {
    var cornerRadii: RectangleCornerRadii
    var seed: UInt64
    var wobble: CGFloat = Tokens.Drawn.edgeWobble
    /// How fast the wobble varies, in cycles per pt: the prototype's paper filter is slow, its wash
    /// filter quicker.
    var frequency: CGFloat = Tokens.Drawn.edgeFrequency
    /// Drawn this far inside the rect, so a stroke of twice this ends on its bounds.
    var inset: CGFloat = 0

    /// Paths already made, by what they're made from: the same card is drawn again and again as a
    /// list scrolls, and its edge costs a few thousand sines to find.
    private final class PathBox: @unchecked Sendable { let path: Path; init(_ path: Path) { self.path = path } }
    nonisolated(unsafe) private static let cache: NSCache<NSString, PathBox> = {
        let cache = NSCache<NSString, PathBox>()
        cache.countLimit = 600
        return cache
    }()

    func path(in rect: CGRect) -> Path {
        let key = "\(seed)|\(rect.origin.x),\(rect.origin.y),\(rect.width),\(rect.height)|\(cornerRadii.topLeading),\(cornerRadii.bottomLeading),\(cornerRadii.bottomTrailing),\(cornerRadii.topTrailing)|\(wobble)|\(frequency)|\(inset)" as NSString
        if let hit = Self.cache.object(forKey: key) { return hit.path }
        let made = makePath(in: rect)
        Self.cache.setObject(PathBox(made), forKey: key)
        return made
    }

    private func makePath(in rect: CGRect) -> Path {
        let outline = Self.outline(of: rect.insetBy(dx: inset, dy: inset), radii: cornerRadii, step: Tokens.Drawn.edgeStep)
        guard outline.count > 1 else { return Path() }

        // `edgeFrequency` is cycles per pt, as the prototype's filter has it; the noise wants radians.
        let slowRate = Double(frequency) * 2 * .pi
        let slow = (x: SmoothNoise(seed: seed &* 31 &+ 7, frequency: slowRate),
                    y: SmoothNoise(seed: seed &* 17 &+ 5, frequency: slowRate))
        let fine = (x: SmoothNoise(seed: seed &* 13 &+ 3, frequency: Tokens.Drawn.roughEdgeFrequency),
                    y: SmoothNoise(seed: seed &* 29 &+ 11, frequency: Tokens.Drawn.roughEdgeFrequency))
        // Each axis moves by amount/√2, so a point never leaves a circle of that radius.
        let slowAxis = Double(wobble) / 2.0.squareRoot()
        let fineAxis = Double(Tokens.Drawn.roughAmplitude) / 2.0.squareRoot()

        // Distance along the edge to each point, and all the way round, so the noise can be made
        // to close on itself: without that the outline has a notch where it ends.
        var distances: [Double] = [0]
        for index in 1..<outline.count {
            distances.append(distances[index - 1] + Double(hypot(outline[index].x - outline[index - 1].x, outline[index].y - outline[index - 1].y)))
        }
        let total = max(
            distances.last! + Double(hypot(outline[0].x - outline[outline.count - 1].x, outline[0].y - outline[outline.count - 1].y)), 0.001
        )
        /// The noise at `t` along a loop of `total`: over its last stretch it is blended into the
        /// noise one loop back, so at `total` it is exactly the noise at 0.
        func closed(_ noise: SmoothNoise, _ t: Double) -> Double {
            let start = 0.85 * total
            guard t > start else { return noise(t) }
            let w = (t - start) / (total - start)
            let eased = w * w * (3 - 2 * w)
            return noise(t) * (1 - eased) + noise(t - total) * eased
        }

        let points = outline.enumerated().map { index, point -> CGPoint in
            let t = distances[index]
            return CGPoint(
                x: point.x + CGFloat(slowAxis * closed(slow.x, t) + fineAxis * closed(fine.x, t)),
                y: point.y + CGFloat(slowAxis * closed(slow.y, t) + fineAxis * closed(fine.y, t))
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
