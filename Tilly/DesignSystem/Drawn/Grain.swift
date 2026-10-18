import SwiftUI
import UIKit

enum Grain {
    /// One tile, made once from a fixed seed, so every launch draws the same paper. A random half
    /// of its pixels carry a faint black or white; the rest are clear.
    static let tile: UIImage = {
        let side = Int(Tokens.Drawn.grainTile)
        var generator = SeededGenerator(seed: Tokens.Drawn.grainSeed)
        let alpha = Tokens.Drawn.grainAlpha
        var bytes = [UInt8](repeating: 0, count: side * side * 4)
        for pixel in 0..<(side * side) {
            let value: UInt8 = generator.unit() < 0.5 ? 0 : 255
            let on = generator.unit() < 0.5
            guard on else { continue }
            // Premultiplied: white at alpha 9 is 9 in each channel; black is 0.
            let premultiplied = UInt8(UInt16(value) * UInt16(alpha) / 255)
            bytes[pixel * 4] = premultiplied
            bytes[pixel * 4 + 1] = premultiplied
            bytes[pixel * 4 + 2] = premultiplied
            bytes[pixel * 4 + 3] = alpha
        }
        let provider = CGDataProvider(data: Data(bytes) as CFData)
        let image = provider.flatMap {
            CGImage(
                width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: side * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: $0, decode: nil, shouldInterpolate: false, intent: .defaultIntent
            )
        }
        return image.map { UIImage(cgImage: $0, scale: 1, orientation: .up) } ?? UIImage()
    }()
}

extension View {
    /// The paper, with the grain tiled over it, ignoring safe areas. A sheet's root takes it as the
    /// sheet's own ground too, so the sheet is paper and not material.
    func drawnGround() -> some View {
        background {
            DrawnGround().ignoresSafeArea()
        }
        .presentationBackground { DrawnGround() }
    }
}

extension View {
    /// The paper and grain behind a screen's own content, which is opaque so what scrolls beneath
    /// a pinned header is hidden. Not for a sheet's root: that takes `drawnGround()`.
    func drawnPaper() -> some View {
        background { DrawnGround() }
    }
}

private struct DrawnGround: View {
    var body: some View {
        Tokens.Drawn.paper
            .overlay {
                Image(uiImage: Grain.tile)
                    .resizable(resizingMode: .tile)
                    .interpolation(.none)
                    .allowsHitTesting(false)
            }
    }
}
