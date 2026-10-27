#if DEBUG
import Combine
import DialkitmacOS
import DialkitmacOSAgent
import Foundation

/// The category screens' dials, in DialKit's Mac inspector: run `swift run dialkit-macos` from a
/// checkout of github.com/mikelikesdesign/dialkit-macos, then the app in the Simulator, and a
/// "Categories" panel appears. Each change lands in `LayoutTuning` and redraws what reads it. Debug
/// builds only; a value worth keeping is copied into `CategoryLayout`'s defaults.
@MainActor
final class CategoryDials {
    static let shared = CategoryDials()

    private let panel: DialPanelState<CategoryLayout>
    private var watching: AnyCancellable?

    private init() {
        func pt(_ key: String, _ path: WritableKeyPath<CategoryLayout, Double>, _ label: String,
                _ range: ClosedRange<Double>, step: Double = 1) -> DialControl<CategoryLayout> {
            .slider(key, keyPath: path, label: label, range: range, step: step, unit: "pt")
        }
        func plain(_ key: String, _ path: WritableKeyPath<CategoryLayout, Double>, _ label: String,
                   _ range: ClosedRange<Double>, step: Double) -> DialControl<CategoryLayout> {
            .slider(key, keyPath: path, label: label, range: range, step: step)
        }
        panel = DialPanelState(
            // Fixed, so a relaunch or a preview edits the same panel.
            id: UUID(uuidString: "6E0B2C5A-3F4D-4E8B-9A71-2C1D5B7E9F30")!,
            name: "Categories",
            initial: LayoutTuning.shared.layout,
            controls: [
                .group("Picker grid", children: [
                    .slider("columns", keyPath: \.columns, range: 2...6, step: 1),
                    pt("gap", \.gap, "Gap", 0...30),
                    pt("side", \.side, "Side margin", 0...40),
                    pt("top", \.top, "Top margin", 0...40),
                    pt("cardHeight", \.cardHeight, "Card height", 60...160),
                    pt("cornerRadius", \.cornerRadius, "Corner radius", 0...30),
                    pt("pictureSize", \.pictureSize, "Picture", 20...64),
                    pt("pictureTop", \.pictureTop, "Picture from top", 0...40),
                    pt("nameSize", \.nameSize, "Name size", 9...20, step: 0.5),
                    pt("nameSide", \.nameSide, "Name side inset", 0...20),
                    pt("nameBottom", \.nameBottom, "Name from bottom", 0...40),
                    pt("stripHeight", \.stripHeight, "Colour strip", 0...20, step: 0.5),
                    plain("stripOpacity", \.stripOpacity, "Strip opacity", 0...1, step: 0.01),
                    pt("edgeWobble", \.edgeWobble, "Edge wobble", 0...6, step: 0.1),
                    plain("shadowOpacity", \.shadowOpacity, "Shadow", 0...0.4, step: 0.01),
                    pt("shadowRadius", \.shadowRadius, "Shadow blur", 0...10, step: 0.5),
                    pt("shadowY", \.shadowY, "Shadow drop", 0...10, step: 0.5),
                ]),
                .group("Sheet card", children: [
                    pt("sheetCardWidth", \.sheetCardWidth, "Width", 100...200),
                    pt("sheetCardHeight", \.sheetCardHeight, "Height", 120...240),
                    pt("sheetCardRadius", \.sheetCardRadius, "Corner radius", 0...30),
                    pt("sheetStrip", \.sheetStrip, "Colour strip", 0...20, step: 0.5),
                    pt("sheetPictureSize", \.sheetPictureSize, "Picture", 30...96),
                    pt("sheetPictureTop", \.sheetPictureTop, "Picture from top", 0...50),
                    pt("sheetNameSize", \.sheetNameSize, "Name size", 12...28, step: 0.5),
                    pt("sheetNameBottom", \.sheetNameBottom, "Name from bottom", 0...50),
                    pt("sheetNameInset", \.sheetNameInset, "Name side inset", 0...30),
                    pt("sheetOutlineWidth", \.sheetOutlineWidth, "Outline width", 0...5, step: 0.5),
                    pt("sheetOutlineRadius", \.sheetOutlineRadius, "Outline radius", 0...30),
                    plain("sheetOutlineOpacity", \.sheetOutlineOpacity, "Outline opacity", 0...1, step: 0.05),
                    pt("sheetCardTop", \.sheetCardTop, "Above card", 0...30),
                    pt("sheetCardBottom", \.sheetCardBottom, "Below card", 0...40),
                    plain("sheetShadowOpacity", \.sheetShadowOpacity, "Shadow", 0...0.4, step: 0.01),
                    pt("sheetShadowRadius", \.sheetShadowRadius, "Shadow blur", 0...20, step: 0.5),
                    pt("sheetShadowY", \.sheetShadowY, "Shadow drop", 0...20, step: 0.5),
                ]),
                .group("Sheet colours and symbols", children: [
                    pt("swatchDot", \.swatchDot, "Colour dot", 16...36),
                    pt("swatchTarget", \.swatchTarget, "Dot touch target", 24...48),
                    pt("swatchRingWidth", \.swatchRingWidth, "Dot ring", 0...5, step: 0.5),
                    pt("swatchRingOutset", \.swatchRingOutset, "Dot ring outside", 0...8, step: 0.5),
                    pt("swatchTop", \.swatchTop, "Colours above", 0...30),
                    pt("swatchBottom", \.swatchBottom, "Colours below", 0...30),
                    pt("gutter", \.gutter, "Side margin", 12...40),
                    .slider("symbolsAcross", keyPath: \.symbolsAcross, label: "Symbols across", range: 4...8, step: 1),
                    pt("symbolSize", \.symbolSize, "Symbol size", 30...56),
                    pt("symbolGap", \.symbolGap, "Symbol gap", 0...20),
                    pt("symbolRingWidth", \.symbolRingWidth, "Picked ring", 0...5, step: 0.5),
                    pt("symbolRingOutset", \.symbolRingOutset, "Picked ring outside", 0...10, step: 0.5),
                    pt("hairline", \.hairline, "Hairline", 0...2, step: 0.5),
                    pt("searchHeight", \.searchHeight, "Search height", 32...64),
                    pt("searchRadius", \.searchRadius, "Search radius", 0...32),
                    pt("searchTop", \.searchTop, "Search above", 0...30),
                    pt("searchBottom", \.searchBottom, "Search below", 0...30),
                ]),
                .group("Settings", children: [
                    pt("settingsCardHeightFigure", \.settingsCardHeightFigure, "Card height with figure", 90...140),
                    pt("settingsNameBottomFigure", \.settingsNameBottomFigure, "Name from bottom with figure", 16...40),
                    pt("settingsFigureSize", \.settingsFigureSize, "Figure size", 8...14, step: 0.5),
                    pt("settingsFigureBottom", \.settingsFigureBottom, "Figure from bottom", 4...20),
                    pt("settingsFigureSide", \.settingsFigureSide, "Figure side inset", 0...12),
                    pt("settingsTile", \.settingsTile, "Categories tile", 20...48),
                    pt("settingsTileRadius", \.settingsTileRadius, "Tile radius", 0...24),
                ]),
                .group("Symbol guess", children: [
                    plain("guessDistance", \.guessDistance, "Max distance", 0.8...1.3, step: 0.01),
                ]),
            ],
            persistKey: "tilly.categories"
        )
        watching = panel.$values.sink { values in
            MainActor.assumeIsolated { LayoutTuning.shared.layout = values }
        }
    }

    /// Connects to the inspector, retrying until it's running. Safe to call more than once.
    func start() {
        DialKitAgent.shared.start(appName: "Tilly")
    }
}
#endif
