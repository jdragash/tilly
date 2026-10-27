#if DEBUG
/// The category screens' dials, written once and built for whichever DialKit runs: the Mac
/// inspector in the Simulator (`CategoryDials`), the in-app drawer on a phone (`CategoryDrawer`).
/// Each dial reads and writes a field of `CategoryLayout`.
struct CategoryDialSpec {
    enum Kind {
        case points(WritableKeyPath<CategoryLayout, Double>, ClosedRange<Double>, step: Double, unit: Bool)
        case count(WritableKeyPath<CategoryLayout, Int>, ClosedRange<Int>)
    }

    let key: String
    let label: String
    let kind: Kind

    static func points(
        _ key: String, _ path: WritableKeyPath<CategoryLayout, Double>, _ label: String,
        _ range: ClosedRange<Double>, step: Double, unit: Bool
    ) -> CategoryDialSpec {
        CategoryDialSpec(key: key, label: label, kind: .points(path, range, step: step, unit: unit))
    }

    static func count(
        _ key: String, _ path: WritableKeyPath<CategoryLayout, Int>, _ label: String, _ range: ClosedRange<Int>
    ) -> CategoryDialSpec {
        CategoryDialSpec(key: key, label: label, kind: .count(path, range))
    }
}

struct CategoryDialGroup {
    let title: String
    let dials: [CategoryDialSpec]
}

enum CategoryDialSpecs {
    /// The panel's name in both tools.
    static let panelName = "Categories"

    static var groups: [CategoryDialGroup] {
        [
        CategoryDialGroup(title: "Picker grid", dials: [
            .count("columns", \.columns, "Columns", 2...6),
            .points("gap", \.gap, "Gap", 0...30, step: 1, unit: true),
            .points("side", \.side, "Side margin", 0...40, step: 1, unit: true),
            .points("top", \.top, "Top margin", 0...40, step: 1, unit: true),
            .points("cardHeight", \.cardHeight, "Card height", 60...160, step: 1, unit: true),
            .points("cornerRadius", \.cornerRadius, "Corner radius", 0...30, step: 1, unit: true),
            .points("pictureSize", \.pictureSize, "Picture", 20...64, step: 1, unit: true),
            .points("pictureTop", \.pictureTop, "Picture from top", 0...40, step: 1, unit: true),
            .points("nameSize", \.nameSize, "Name size", 9...20, step: 0.5, unit: true),
            .points("nameSide", \.nameSide, "Name side inset", 0...20, step: 1, unit: true),
            .points("nameBottom", \.nameBottom, "Name from bottom", 0...40, step: 1, unit: true),
            .points("stripHeight", \.stripHeight, "Colour strip", 0...20, step: 0.5, unit: true),
            .points("stripOpacity", \.stripOpacity, "Strip opacity", 0...1, step: 0.01, unit: false),
            .points("edgeWobble", \.edgeWobble, "Edge wobble", 0...6, step: 0.1, unit: true),
            .points("shadowOpacity", \.shadowOpacity, "Shadow", 0...0.4, step: 0.01, unit: false),
            .points("shadowRadius", \.shadowRadius, "Shadow blur", 0...10, step: 0.5, unit: true),
            .points("shadowY", \.shadowY, "Shadow drop", 0...10, step: 0.5, unit: true),
        ]),
        CategoryDialGroup(title: "Sheet card", dials: [
            .points("sheetCardWidth", \.sheetCardWidth, "Width", 100...200, step: 1, unit: true),
            .points("sheetCardHeight", \.sheetCardHeight, "Height", 120...240, step: 1, unit: true),
            .points("sheetCardRadius", \.sheetCardRadius, "Corner radius", 0...30, step: 1, unit: true),
            .points("sheetStrip", \.sheetStrip, "Colour strip", 0...20, step: 0.5, unit: true),
            .points("sheetPictureSize", \.sheetPictureSize, "Picture", 30...96, step: 1, unit: true),
            .points("sheetPictureTop", \.sheetPictureTop, "Picture from top", 0...50, step: 1, unit: true),
            .points("sheetNameSize", \.sheetNameSize, "Name size", 12...28, step: 0.5, unit: true),
            .points("sheetNameBottom", \.sheetNameBottom, "Name from bottom", 0...50, step: 1, unit: true),
            .points("sheetNameInset", \.sheetNameInset, "Name side inset", 0...30, step: 1, unit: true),
            .points("sheetOutlineWidth", \.sheetOutlineWidth, "Outline width", 0...5, step: 0.5, unit: true),
            .points("sheetOutlineRadius", \.sheetOutlineRadius, "Outline radius", 0...30, step: 1, unit: true),
            .points("sheetOutlineOpacity", \.sheetOutlineOpacity, "Outline opacity", 0...1, step: 0.05, unit: false),
            .points("sheetCardTop", \.sheetCardTop, "Above card", 0...30, step: 1, unit: true),
            .points("sheetCardBottom", \.sheetCardBottom, "Below card", 0...40, step: 1, unit: true),
            .points("sheetShadowOpacity", \.sheetShadowOpacity, "Shadow", 0...0.4, step: 0.01, unit: false),
            .points("sheetShadowRadius", \.sheetShadowRadius, "Shadow blur", 0...20, step: 0.5, unit: true),
            .points("sheetShadowY", \.sheetShadowY, "Shadow drop", 0...20, step: 0.5, unit: true),
        ]),
        CategoryDialGroup(title: "Sheet colours and symbols", dials: [
            .points("swatchDot", \.swatchDot, "Colour dot", 16...36, step: 1, unit: true),
            .points("swatchTarget", \.swatchTarget, "Dot touch target", 24...48, step: 1, unit: true),
            .points("swatchRingWidth", \.swatchRingWidth, "Dot ring", 0...5, step: 0.5, unit: true),
            .points("swatchRingOutset", \.swatchRingOutset, "Dot ring outside", 0...8, step: 0.5, unit: true),
            .points("swatchTop", \.swatchTop, "Colours above", 0...30, step: 1, unit: true),
            .points("swatchBottom", \.swatchBottom, "Colours below", 0...30, step: 1, unit: true),
            .points("gutter", \.gutter, "Side margin", 12...40, step: 1, unit: true),
            .count("symbolsAcross", \.symbolsAcross, "Symbols across", 4...8),
            .points("symbolSize", \.symbolSize, "Symbol size", 30...56, step: 1, unit: true),
            .points("symbolGap", \.symbolGap, "Symbol gap", 0...20, step: 1, unit: true),
            .points("symbolRingWidth", \.symbolRingWidth, "Picked ring", 0...5, step: 0.5, unit: true),
            .points("symbolRingOutset", \.symbolRingOutset, "Picked ring outside", 0...10, step: 0.5, unit: true),
            .points("hairline", \.hairline, "Hairline", 0...2, step: 0.5, unit: true),
            .points("searchHeight", \.searchHeight, "Search height", 32...64, step: 1, unit: true),
            .points("searchRadius", \.searchRadius, "Search radius", 0...32, step: 1, unit: true),
            .points("searchTop", \.searchTop, "Search above", 0...30, step: 1, unit: true),
            .points("searchBottom", \.searchBottom, "Search below", 0...30, step: 1, unit: true),
        ]),
        CategoryDialGroup(title: "Settings", dials: [
            .points("settingsCardHeightFigure", \.settingsCardHeightFigure, "Card height with figure", 90...140, step: 1, unit: true),
            .points("settingsNameBottomFigure", \.settingsNameBottomFigure, "Name from bottom with figure", 16...40, step: 1, unit: true),
            .points("settingsFigureSize", \.settingsFigureSize, "Figure size", 8...14, step: 0.5, unit: true),
            .points("settingsFigureBottom", \.settingsFigureBottom, "Figure from bottom", 4...20, step: 1, unit: true),
            .points("settingsFigureSide", \.settingsFigureSide, "Figure side inset", 0...12, step: 1, unit: true),
            .points("settingsTile", \.settingsTile, "Categories tile", 20...48, step: 1, unit: true),
            .points("settingsTileRadius", \.settingsTileRadius, "Tile radius", 0...24, step: 1, unit: true),
        ]),
        CategoryDialGroup(title: "Symbol guess", dials: [
            .points("guessDistance", \.guessDistance, "Max distance", 0.8...1.3, step: 0.01, unit: false),
        ]),
        ]
    }
}
#endif
