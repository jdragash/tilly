import SwiftUI
import UIKit

/// The wash as a picture: paper laid first, then the colour with its rough edge, its alpha varied
/// across it so it blooms, and the faint shadow under it. Made on the CPU the first time a look is
/// wanted and kept, so showing a card afterwards costs a bitmap, not a shader.
enum WashImage {
    /// Room left round the card for its shadow, and for the edge's wobble.
    static let margin: CGFloat = 6

    private final class Box { let image: UIImage; init(_ image: UIImage) { self.image = image } }
    nonisolated(unsafe) private static let cache: NSCache<NSString, Box> = {
        let cache = NSCache<NSString, Box>()
        cache.countLimit = 400
        return cache
    }()

    /// A size is rounded up to the next few points, so a card that grows or shrinks through an animation
    /// meets a handful of images, not one for every frame; the picture is stretched the last bit.
    private static let bucket: CGFloat = 8

    @MainActor
    static func image(
        colour: Color.Resolved, paper: Color.Resolved, size: CGSize, cornerRadii: RectangleCornerRadii,
        seed: UInt64, scale: CGFloat
    ) -> UIImage {
        let width = max(bucket, (size.width / bucket).rounded() * bucket)
        let height = max(bucket, (size.height / bucket).rounded() * bucket)
        let key = "\(colour.red),\(colour.green),\(colour.blue),\(paper.red)|\(width)x\(height)|\(cornerRadii.topLeading),\(cornerRadii.bottomLeading),\(cornerRadii.bottomTrailing),\(cornerRadii.topTrailing)|\(seed)|\(scale)" as NSString
        if let hit = cache.object(forKey: key) { return hit.image }
        let made = render(
            colour: colour, paper: paper, size: CGSize(width: width, height: height),
            cornerRadii: cornerRadii, seed: seed, scale: scale
        )
        cache.setObject(Box(made), forKey: key)
        return made
    }

    @MainActor
    private static func render(
        colour: Color.Resolved, paper: Color.Resolved, size: CGSize, cornerRadii: RectangleCornerRadii,
        seed: UInt64, scale: CGFloat
    ) -> UIImage {
        let canvas = CGSize(width: size.width + 2 * margin, height: size.height + 2 * margin)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let rect = CGRect(origin: CGPoint(x: margin, y: margin), size: size)
        let shape = RoughRoundedRectangle(cornerRadii: cornerRadii, seed: seed, inset: Tokens.Drawn.edgeWidth / 2)
        let path = shape.path(in: rect).cgPath
        let paperColour = UIColor(red: CGFloat(paper.red), green: CGFloat(paper.green), blue: CGFloat(paper.blue), alpha: 1)
        let ink = UIColor(red: CGFloat(colour.red), green: CGFloat(colour.green), blue: CGFloat(colour.blue), alpha: 1)

        return UIGraphicsImageRenderer(size: canvas, format: format).image { renderer in
            let context = renderer.cgContext
            context.setLineJoin(.round)
            context.setLineWidth(Tokens.Drawn.edgeWidth)

            // Paper first, with the card's shadow under it, so a card hides the one behind it.
            context.saveGState()
            context.setShadow(
                offset: CGSize(width: 0, height: -Tokens.Shadow.stackY),
                blur: Tokens.Shadow.stackRadius * 2,
                color: UIColor.black.withAlphaComponent(0.16).cgColor
            )
            context.setFillColor(paperColour.cgColor)
            context.setStrokeColor(paperColour.cgColor)
            context.addPath(path)
            context.drawPath(using: .fillStroke)
            context.restoreGState()

            // The colour, its alpha varied across the card: a small grid of alphas, drawn up to size
            // with smoothing, clipped to the card's shape.
            context.saveGState()
            context.addPath(path)
            context.clip()
            if let bloom = bloomImage(for: ink, size: size, seed: seed) {
                context.interpolationQuality = .high
                // Core Graphics draws an image upside down in this context.
                context.translateBy(x: rect.minX, y: rect.maxY)
                context.scaleBy(x: 1, y: -1)
                context.draw(bloom, in: CGRect(origin: .zero, size: size))
            }
            context.restoreGState()

            // The edge, solid.
            context.setStrokeColor(ink.withAlphaComponent(Tokens.Drawn.cardEdge).cgColor)
            context.addPath(path)
            context.strokePath()
        }
    }

    /// The colour at `cardFill`, its alpha moved by `bloom` across a grid a few points apart, so scaled up
    /// it varies smoothly.
    private static func bloomImage(for colour: UIColor, size: CGSize, seed: UInt64) -> CGImage? {
        let cell: CGFloat = 8
        let columns = max(2, Int((size.width / cell).rounded(.up)) + 1)
        let rows = max(2, Int((size.height / cell).rounded(.up)) + 1)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        colour.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let frequency = Double(Tokens.Drawn.bloomFrequency) * Double(cell)
        let strength = Double(Tokens.Drawn.bloom)
        let offset = Double(seed % 80) + Double(Tokens.Drawn.bloomSeed)
        var bytes = [UInt8](repeating: 0, count: columns * rows * 4)
        for row in 0..<rows {
            for column in 0..<columns {
                let n = 0.65 * valueNoise(Double(column) * frequency, Double(row) * frequency, seed: offset)
                    + 0.35 * valueNoise(Double(column) * frequency * 2.1, Double(row) * frequency * 2.1, seed: offset + 3)
                let factor = min(1, max(0, 1 - strength / 2 + strength * n))
                let a = Tokens.Drawn.cardFill * factor
                let index = (row * columns + column) * 4
                bytes[index] = UInt8((Double(red) * a * 255).rounded())
                bytes[index + 1] = UInt8((Double(green) * a * 255).rounded())
                bytes[index + 2] = UInt8((Double(blue) * a * 255).rounded())
                bytes[index + 3] = UInt8((a * 255).rounded())
            }
        }
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else { return nil }
        return CGImage(
            width: columns, height: rows, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: columns * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent
        )
    }

    /// Value noise in 0…1, smooth between lattice points; the CPU twin of the shader's.
    private static func valueNoise(_ x: Double, _ y: Double, seed: Double) -> Double {
        let px = x + seed * 17.3, py = y + seed * 11.1
        let ix = floor(px), iy = floor(py)
        let fx = px - ix, fy = py - iy
        func hash(_ a: Double, _ b: Double) -> Double {
            var h = sin(a * 127.1 + b * 311.7) * 43758.5453
            h -= floor(h)
            return h
        }
        let a = hash(ix, iy), b = hash(ix + 1, iy), c = hash(ix, iy + 1), d = hash(ix + 1, iy + 1)
        let ux = fx * fx * (3 - 2 * fx), uy = fy * fy * (3 - 2 * fy)
        return (a * (1 - ux) + b * ux) * (1 - uy) + (c * (1 - ux) + d * ux) * uy
    }
}
