import SwiftUI
import Testing
@testable import Tilly

@Suite struct RoughRoundedRectangleTests {
    static let rect = CGRect(x: 0, y: 0, width: 320, height: 64)
    static let radii = RectangleCornerRadii(topLeading: 14, bottomLeading: 0, bottomTrailing: 0, topTrailing: 14)

    static func points(_ path: Path) -> [CGPoint] {
        var points: [CGPoint] = []
        path.forEach { element in
            switch element {
            case .move(let p), .line(let p): points.append(p)
            default: break
            }
        }
        return points
    }

    /// The distance from `point` to the plain outline of `rect`: the nearest of its sampled points.
    static func distance(_ point: CGPoint, toOutlineOf rect: CGRect, radii: RectangleCornerRadii) -> CGFloat {
        RoughRoundedRectangle.outline(of: rect, radii: radii, step: 0.25)
            .map { hypot($0.x - point.x, $0.y - point.y) }
            .min() ?? .infinity
    }

    @Test func sameSeedSamePath() {
        let a = RoughRoundedRectangle(cornerRadii: Self.radii, seed: 7).path(in: Self.rect)
        let b = RoughRoundedRectangle(cornerRadii: Self.radii, seed: 7).path(in: Self.rect)
        #expect(a == b)
    }

    @Test func differentSeedDifferentPath() {
        let a = RoughRoundedRectangle(cornerRadii: Self.radii, seed: 7).path(in: Self.rect)
        let b = RoughRoundedRectangle(cornerRadii: Self.radii, seed: 8).path(in: Self.rect)
        #expect(a != b)
    }

    @Test func staysWithinWobbleOfRect() {
        let shape = RoughRoundedRectangle(cornerRadii: Self.radii, seed: 3)
        let limit = shape.wobble + Tokens.Drawn.roughAmplitude + 0.01
        for point in Self.points(shape.path(in: Self.rect)) {
            #expect(Self.distance(point, toOutlineOf: Self.rect, radii: Self.radii) <= limit)
        }
    }

    @Test func squareCornersStaySquare() {
        let shape = RoughRoundedRectangle(cornerRadii: Self.radii, seed: 5)
        let points = Self.points(shape.path(in: Self.rect))
        let corner = CGPoint(x: Self.rect.maxX, y: Self.rect.maxY)
        let nearest = points.map { hypot($0.x - corner.x, $0.y - corner.y) }.min() ?? .infinity
        #expect(nearest <= shape.wobble + Tokens.Drawn.roughAmplitude + 0.01)
    }

    @Test func tinyRectStillCloses() {
        for size in [CGSize(width: 4, height: 4), CGSize(width: 0, height: 0), CGSize(width: 1, height: 30)] {
            let path = RoughRoundedRectangle(cornerRadii: .init(topLeading: 14, bottomLeading: 14, bottomTrailing: 14, topTrailing: 14), seed: 1)
                .path(in: CGRect(origin: .zero, size: size))
            let points = Self.points(path)
            #expect(points.count > 1)
            #expect(points.first == points.last)
        }
    }
}
