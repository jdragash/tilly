import Testing
@testable import Tilly

@Suite struct ViewModeTests {
    /// Stored in `@AppStorage`: a renamed case would reopen the app on the wrong view.
    @Test func rawValuesAreStable() {
        #expect(ViewMode.timeline.rawValue == "timeline")
        #expect(ViewMode.categories.rawValue == "categories")
    }

    @Test func unknownStoredValueReadsAsNothing() {
        // A stored value no case names (a future view, rolled back) reads as nothing.
        #expect(ViewMode(rawValue: "compare") == nil)
    }
}
