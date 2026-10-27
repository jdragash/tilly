import SwiftUI

/// A category's paper card: its picture near the top, its name above the bottom, and a strip of its
/// colour along the bottom inside the card's shape. One drawing at two sizes, so the picker's and
/// Settings' cards and the category sheet's card stay the same card. The picture and the name are
/// the caller's: the grid writes the name, the sheet types it.
struct CategoryCardFace<Picture: View, Name: View>: View {
    /// A card's measurements, read from `Tokens` when it's drawn so the dials redraw it.
    struct Metrics {
        var height: CGFloat
        var radius: CGFloat
        var strip: CGFloat
        var pictureTop: CGFloat
        /// The least room between the picture and the name, where a large text size grows the card.
        var nameTop: CGFloat
        var nameBottom: CGFloat
        var nameSide: CGFloat
        var wobble: CGFloat
        var shadowColour: Color
        var shadowRadius: CGFloat
        var shadowY: CGFloat

        /// The picker's and Settings' card.
        static var grid: Metrics {
            Metrics(
                height: Tokens.Size.pickerCard, radius: Tokens.Radius.pickerCard, strip: Tokens.Size.pickerStrip,
                pictureTop: Tokens.Space.pickerPictureTop, nameTop: Tokens.Space.pickerNameTop,
                nameBottom: Tokens.Space.pickerNameBottom, nameSide: Tokens.Space.pickerNameSide,
                wobble: Tokens.Drawn.pickerCardWobble, shadowColour: Tokens.Shadow.pickerCardColour,
                shadowRadius: Tokens.Shadow.pickerCardRadius, shadowY: Tokens.Shadow.pickerCardY
            )
        }

        /// Settings' card: the grid's, taller by the room for its figure under the name.
        static func settings(_ dynamicTypeSize: DynamicTypeSize) -> Metrics {
            var metrics = grid
            metrics.height = Tokens.SettingsCategories.cardHeightFigure
            metrics.nameBottom = Tokens.SettingsCategories.nameBottomFigure(dynamicTypeSize)
            return metrics
        }

        /// The category sheet's card.
        static var sheet: Metrics {
            Metrics(
                height: Tokens.CategorySheet.cardHeight, radius: Tokens.CategorySheet.cardRadius,
                strip: Tokens.CategorySheet.cardStrip, pictureTop: Tokens.CategorySheet.pictureTop,
                nameTop: Tokens.Space.pickerNameTop, nameBottom: Tokens.CategorySheet.nameBottom,
                nameSide: Tokens.CategorySheet.nameInset, wobble: Tokens.Drawn.pickerCardWobble,
                shadowColour: Tokens.CategorySheet.shadowColour, shadowRadius: Tokens.CategorySheet.shadowRadius,
                shadowY: Tokens.CategorySheet.shadowY
            )
        }
    }

    let colour: CategoryColour?
    let seed: UInt64
    let metrics: Metrics
    @ViewBuilder let picture: Picture
    @ViewBuilder let name: Name

    var body: some View {
        VStack(spacing: 0) {
            picture
                .padding(.top, metrics.pictureTop)
            Spacer(minLength: metrics.nameTop)
            name
                .padding(.horizontal, metrics.nameSide)
                .padding(.bottom, metrics.nameBottom)
        }
        // As tall as the row in a grid, so a row's cards line up when one name needs more room.
        .frame(maxWidth: .infinity, minHeight: metrics.height, maxHeight: .infinity)
        .background {
            CategoryCardBackground(
                colour: colour, seed: seed, radius: metrics.radius, strip: metrics.strip, wobble: metrics.wobble,
                shadowColour: metrics.shadowColour, shadowRadius: metrics.shadowRadius, shadowY: metrics.shadowY
            )
        }
    }
}

/// A category card's ground: paper, a speckled strip of its colour along the bottom inside the card's
/// shape, and a light shadow. Behind the grids' cards and All bills', which differ only in their
/// contents.
struct CategoryCardBackground: View {
    let colour: CategoryColour?
    let seed: UInt64
    let radius: CGFloat
    let strip: CGFloat
    let wobble: CGFloat
    let shadowColour: Color
    let shadowRadius: CGFloat
    let shadowY: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    private var cornerRadii: RectangleCornerRadii {
        return RectangleCornerRadii(topLeading: radius, bottomLeading: radius, bottomTrailing: radius, topTrailing: radius)
    }

    var body: some View {
        let ink = colour.map(Tokens.CategoryColour.color) ?? Tokens.Chart.uncoloured
        let shape = RoughRoundedRectangle(cornerRadii: cornerRadii, seed: seed, wobble: wobble)
        PaperCard(cornerRadii: cornerRadii, seed: seed, wobble: wobble)
            .overlay(alignment: .bottom) {
                // A wash, speckled as the prototype's `washF` speckles it.
                RoughRoundedRectangle(
                    cornerRadii: RectangleCornerRadii(), seed: seed,
                    wobble: Tokens.Drawn.stripWobble, frequency: Tokens.Drawn.stripFrequency
                )
                    .fill(ink.opacity(Tokens.Opacity.pickerStrip))
                    .frame(height: strip)
                    .mask {
                        Image(uiImage: Grain.speckle)
                            .resizable(resizingMode: .tile)
                            .interpolation(.medium)
                    }
            }
            .clipShape(shape)
            .shadow(
                color: colorScheme == .light ? shadowColour : .clear,
                radius: shadowRadius, y: shadowY
            )
    }
}

extension CategoryCardFace where Name == CategoryCardName {
    /// A card with its name written on it, as the grids draw it.
    init(colour: CategoryColour?, seed: UInt64, metrics: Metrics, name: String, @ViewBuilder picture: () -> Picture) {
        self.init(colour: colour, seed: seed, metrics: metrics, picture: picture) {
            CategoryCardName(name: name)
        }
    }
}

/// A card's name: two lines, then smaller down to `Tokens.Scale.cardName` (`NameFit`), then it breaks.
struct CategoryCardName: View {
    let name: String
    var ink: Color = Tokens.Ink.primary

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var width: CGFloat = 0

    var body: some View {
        let full = Tokens.Text.pickerNameSize(dynamicTypeSize)
        Text(name)
            .font(Tokens.Text.pickerName(size: NameFit.size(name, full: full, width: width)))
            .foregroundStyle(ink)
            .multilineTextAlignment(.center)
            // `NameFit` has already shrunk it as far as it goes; past that it breaks, never smaller.
            .lineLimit(2)
            .frame(maxWidth: .infinity)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }
}
