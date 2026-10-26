import Observation
import SwiftUI

/// The category screens' layout as one value, so a debug build can dial it live from the Mac. These
/// defaults are what ships: `Tokens` reads them through `LayoutTuning.shared`, so a release build sees
/// exactly these, and a value settled in the inspector is copied back here. From the prototype's
/// Layout panel as it was set (`docs/prototypes/category-editor.html`).
nonisolated struct CategoryLayout: Codable, Equatable, Sendable {
    // MARK: Picker grid cards (the picker's and Settings' alike)
    var columns = 4
    var gap = 8.0
    var side = 22.0
    var top = 6.0
    var cardHeight = 102.0
    var cornerRadius = 16.0
    var pictureSize = 36.0
    var pictureTop = 16.0
    var nameSize = 13.5
    var nameSide = 5.0
    var nameBottom = 16.0
    var stripHeight = 3.0
    var stripOpacity = 0.92
    var edgeWobble = 2.5
    var shadowOpacity = 0.1
    var shadowRadius = 1.0
    var shadowY = 1.0

    // MARK: Sheet
    var sheetCardWidth = 126.0
    var sheetCardHeight = 164.0
    var sheetCardRadius = 16.0
    var sheetStrip = 6.0
    var sheetPictureSize = 60.0
    var sheetPictureTop = 26.0
    var sheetNameSize = 18.0
    var sheetNameBottom = 24.0
    var sheetNameInset = 8.0
    var sheetOutlineWidth = 2.0
    var sheetOutlineRadius = 10.0
    var sheetOutlineOpacity = 0.7
    var sheetCardTop = 0.0
    var sheetCardBottom = 16.0
    var sheetShadowOpacity = 0.12
    var sheetShadowRadius = 5.0
    var sheetShadowY = 2.0
    var sparkSize = 17.0
    var sparkSymbol = 12.0
    var sparkRight = 6.0
    var sparkUp = 4.0
    var swatchDot = 26.0
    var swatchTarget = 32.0
    var swatchRingWidth = 2.0
    var swatchRingOutset = 3.0
    var swatchTop = 10.0
    var swatchBottom = 4.0
    var gutter = 24.0
    var symbolsAcross = 6
    var symbolGap = 8.0
    var symbolRingWidth = 2.5
    var symbolRingOutset = 5.0
    var hairline = 0.5
    var searchHeight = 48.0
    var searchRadius = 24.0
    var searchTop = 10.0
    var searchBottom = 8.0

    // MARK: Settings
    var settingsCardHeightFigure = 114.0
    var settingsNameBottomFigure = 27.0
    var settingsFigureSize = 9.0
    var settingsFigureBottom = 14.0
    var settingsFigureSide = 4.0
    var settingsTile = 32.0
    var settingsTileRadius = 8.0

    // MARK: Symbol guess
    /// How far a name's word may be from a catalogue word and still count as that symbol.
    var guessDistance = 1.06
}

/// The layout values views read now. Only `CategoryDials`, in a debug build, ever changes them.
@MainActor @Observable
final class LayoutTuning {
    static let shared = LayoutTuning()

    var layout = CategoryLayout()
}
