import SwiftUI
import UIKit

/// The category sheet's and Settings' numbers, from the prototype's Layout panel as it was set
/// (`docs/prototypes/category-editor.html`). Each reads `LayoutTuning`, so a debug build can dial it
/// live; a release build sees the defaults in `CategoryLayout`. The sheet (step 5) and Settings
/// (step 7) are the readers.
extension Tokens {
    enum CategorySheet {
        private static var l: CategoryLayout { LayoutTuning.shared.layout }

        // The card: fixed under the header, the name typed on it.
        static var cardWidth: CGFloat { l.sheetCardWidth }
        static var cardHeight: CGFloat { l.sheetCardHeight }
        static var cardRadius: CGFloat { l.sheetCardRadius }
        static var cardStrip: CGFloat { l.sheetStrip }
        static var pictureSize: CGFloat { l.sheetPictureSize }
        static var pictureTop: CGFloat { l.sheetPictureTop }
        /// The name, rounded bold 18 at the default text size, scaling as `title3` does.
        static func nameFont(_ dynamicTypeSize: DynamicTypeSize) -> Font {
            .system(size: Tokens.Text.scaled(l.sheetNameSize, as: .title3, at: dynamicTypeSize),
                    weight: .bold, design: .rounded)
        }
        static var nameBottom: CGFloat { l.sheetNameBottom }
        static var nameInset: CGFloat { l.sheetNameInset }
        /// The dashed outline while the card is empty.
        static var outlineWidth: CGFloat { l.sheetOutlineWidth }
        static var outlineRadius: CGFloat { l.sheetOutlineRadius }
        static var outlineOpacity: Double { l.sheetOutlineOpacity }
        static var cardTop: CGFloat { l.sheetCardTop }
        static var cardBottom: CGFloat { l.sheetCardBottom }
        static var shadowColour: Color { .black.opacity(l.sheetShadowOpacity) }
        static var shadowRadius: CGFloat { l.sheetShadowRadius }
        static var shadowY: CGFloat { l.sheetShadowY }

        // The spark badge on the picture while a guess is showing.
        static var sparkSize: CGFloat { l.sparkSize }
        static var sparkSymbol: CGFloat { l.sparkSymbol }
        static var sparkRight: CGFloat { l.sparkRight }
        static var sparkUp: CGFloat { l.sparkUp }

        // Colour swatches, spread across the width.
        static var swatchDot: CGFloat { l.swatchDot }
        static var swatchTarget: CGFloat { l.swatchTarget }
        static var swatchRingWidth: CGFloat { l.swatchRingWidth }
        static var swatchRingOutset: CGFloat { l.swatchRingOutset }
        static var swatchTop: CGFloat { l.swatchTop }
        static var swatchBottom: CGFloat { l.swatchBottom }

        // The symbols: one grid, each drawn at the grid card's picture size.
        static var gutter: CGFloat { l.gutter }
        static var symbolsAcross: Int { l.symbolsAcross }
        static var symbolGap: CGFloat { l.symbolGap }
        static var symbolPicture: CGFloat { Tokens.Size.pickerPicture }
        static var symbolRingWidth: CGFloat { l.symbolRingWidth }
        static var symbolRingOutset: CGFloat { l.symbolRingOutset }
        static var hairline: CGFloat { l.hairline }

        // The search field, sticking at the top of the symbols.
        static var searchHeight: CGFloat { l.searchHeight }
        static var searchRadius: CGFloat { l.searchRadius }
        static var searchTop: CGFloat { l.searchTop }
        static var searchBottom: CGFloat { l.searchBottom }
    }

    enum SettingsCategories {
        private static var l: CategoryLayout { LayoutTuning.shared.layout }

        /// A card with the figure under its name (`€95/mo`, `No bills`).
        static var cardHeightFigure: CGFloat { l.settingsCardHeightFigure }
        static var nameBottomFigure: CGFloat { l.settingsNameBottomFigure }
        /// The figure: 9 medium, `ink2`.
        static func figureFont(_ dynamicTypeSize: DynamicTypeSize) -> Font {
            .system(size: Tokens.Text.scaled(l.settingsFigureSize, as: .caption2, at: dynamicTypeSize),
                    weight: .medium)
        }
        static var figureBottom: CGFloat { l.settingsFigureBottom }
        static var figureSide: CGFloat { l.settingsFigureSide }

        /// The `Categories` row's tile: white `square.grid.2x2` on `#5A6CE8`.
        static var tile: CGFloat { l.settingsTile }
        static var tileRadius: CGFloat { l.settingsTileRadius }
        static let tileColour = Color(red: 0x5A / 255, green: 0x6C / 255, blue: 0xE8 / 255)
    }
}
