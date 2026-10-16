import Testing
@testable import Tilly

@Suite struct ViewModeTests {
    /// Stored in `@AppStorage`: a renamed case would reopen the app on the wrong view.
    @Test func rawValuesAreStable() {
        #expect(ViewMode.timeline.rawValue == "timeline")
        #expect(ViewMode.categories.rawValue == "categories")
    }

    /// `.timeline` is the Calendar now; only its name changed, never what is stored.
    @Test func timelineIsTitledCalendar() {
        #expect(ViewMode.timeline.title == "Calendar")
        #expect(ViewMode.timeline.systemImage == "calendar")
        #expect(ViewMode.categories.title == "Categories")
    }

    @Test func defaultIsTimeline() {
        #expect(ViewMode.firstRun == .timeline)
        // A stored value no case names (a future view, rolled back) reads as nothing, and
        // `@AppStorage` falls back to `firstRun`.
        #expect(ViewMode(rawValue: "compare") == nil)
    }
}
