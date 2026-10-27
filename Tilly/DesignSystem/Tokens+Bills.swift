import SwiftUI
import UIKit

/// All bills' numbers: a paper card for each category, read from the prototype's `catCard`
/// (`docs/prototypes/all-bills-folders.html`, Tune: layout `card`, rows `compact`, hairlines) and the
/// All bills sheet in `docs/prototypes/category-editor.html` (`.bt`, `.bsub`, `.brow`).
extension Tokens {
    enum Bills {
        // MARK: Type
        // Pixel sizes at the default text size, scaling as the system style named beside each does.
        // Pass the view's `dynamicTypeSize`.

        static func titleFont(_ size: DynamicTypeSize) -> Font {
            .system(size: Text.scaled(34, as: .largeTitle, at: size), weight: .heavy)
        }
        static func subtitleFont(_ size: DynamicTypeSize) -> Font {
            .system(size: Text.scaled(15, as: .subheadline, at: size))
        }
        static func headerNameFont(_ size: DynamicTypeSize) -> Font {
            .system(size: Text.scaled(18, as: .headline, at: size), weight: .bold)
        }
        static func headerTotalFont(_ size: DynamicTypeSize) -> Font {
            .system(size: Text.scaled(19, as: .headline, at: size), weight: .heavy)
        }
        static func rowNameFont(_ size: DynamicTypeSize) -> Font {
            .system(size: Text.scaled(16, as: .body, at: size), weight: .semibold)
        }
        static let rowNoteFont: Font = .footnote
        static func rowFigureFont(_ size: DynamicTypeSize) -> Font {
            .system(size: Text.scaled(16, as: .body, at: size), weight: .semibold)
        }

        // MARK: Card
        static let cardRadius: CGFloat = 14
        static let cardStrip: CGFloat = 5
        /// The shadow under a card, light mode only: the prototype's `0 1px 2px` at 10% black, whose 2pt
        /// CSS blur is a SwiftUI radius of 1.
        static let shadowColour: Color = .black.opacity(0.1)
        static let shadowRadius: CGFloat = 1
        static let shadowY: CGFloat = 1
        /// Between cards, and from the sheet's sides.
        static let cardGap: CGFloat = 14
        static let sheetSide: CGFloat = 16
        /// Under the last row, where the strip sits.
        static let cardBottom: CGFloat = 12

        // MARK: Header
        static let headerHeight: CGFloat = 58
        static let headerLeading: CGFloat = 14
        static let headerTrailing: CGFloat = 12
        static let pictureToName: CGFloat = 11

        // MARK: Rows
        static let rowHeight: CGFloat = 44
        /// In from the card's sides.
        static let rowInset: CGFloat = 16
        /// Between a row's name and its note, and between the note and the figure.
        static let rowNameToNote: CGFloat = 10
        static let rowNoteToFigure: CGFloat = 8
        /// Above and below a row's text where Dynamic Type has grown it past `rowHeight`.
        static let rowGrownPadding: CGFloat = 8

        // MARK: Sheet title
        /// The title sits 4 in from the cards' edge, 4 under the bar; the subtitle 2 under it, and 18
        /// above the first card.
        static let titleInset: CGFloat = 4
        static let titleTop: CGFloat = 4
        static let subtitleTop: CGFloat = 2
        static let subtitleBottom: CGFloat = 18
        static let sheetBottom: CGFloat = 40
        /// Above and below the ended bills' toggle.
        static let endedToggleVertical: CGFloat = 14
        static let endedToggleFont: Font = .subheadline
    }
}
