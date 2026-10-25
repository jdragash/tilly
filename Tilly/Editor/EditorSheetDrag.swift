import SwiftUI

/// Where a drag down must not move the editor's sheet, in global coordinates: a wheel, or a scroll
/// view scrolled away from its top. Everywhere else in the sheet a clearly downward drag moves it,
/// as a system sheet's does.
struct EditorDragExclusionKey: PreferenceKey {
    static let defaultValue: [CGRect] = []
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) {
        value += nextValue()
    }
}

/// Whether a tap in the sheet is a real tap, or the lift of a finger that was dragging the sheet.
/// A key or a card stays under a finger that drags the sheet, because the sheet moves with it, so
/// its button fires on the lift unless it asks here first.
@MainActor final class EditorSheetTouch {
    private(set) var isDragging = false
    private var endedAt: Date = .distantPast

    func began() { isDragging = true }

    func ended() {
        isDragging = false
        endedAt = Date()
    }

    /// False during a sheet drag and for a moment after it ends, whichever of the drag's end and the
    /// button's action comes first.
    var allowsTap: Bool {
        !isDragging && Date().timeIntervalSince(endedAt) > Tokens.Motion.sheetDragTapGrace
    }
}

extension EnvironmentValues {
    /// True while a drag is moving the sheet: a scroll view inside holds still rather than bouncing
    /// under the finger.
    @Entry var editorSheetDragging = false
    @Entry var editorSheetTouch = EditorSheetTouch()
}

extension View {
    /// Keeps a drag starting here from moving the sheet while `excluded` is true.
    func editorDragExcluded(_ excluded: Bool = true) -> some View {
        modifier(EditorDragExclusion(excluded: excluded))
    }

    /// A scroll view in the sheet: it holds the sheet still while it's scrolled away from its top,
    /// and holds itself still while the sheet is dragged.
    func editorSheetScroll() -> some View {
        modifier(EditorSheetScroll())
    }
}

private struct EditorDragExclusion: ViewModifier {
    let excluded: Bool
    @State private var frame: CGRect = .zero

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame = $0 }
            .preference(key: EditorDragExclusionKey.self, value: excluded ? [frame] : [])
    }
}

private struct EditorSheetScroll: ViewModifier {
    @Environment(\.editorSheetDragging) private var sheetDragging
    @State private var isAwayFromTop = false

    func body(content: Content) -> some View {
        content
            .onScrollGeometryChange(for: Bool.self) { geometry in
                geometry.contentOffset.y + geometry.contentInsets.top > Tokens.Space.frameAtRest
            } action: { _, away in
                isAwayFromTop = away
            }
            .scrollDisabled(sheetDragging)
            .editorDragExcluded(isAwayFromTop)
    }
}
