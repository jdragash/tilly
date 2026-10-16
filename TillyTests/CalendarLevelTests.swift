import Testing
@testable import Tilly

@Suite struct CalendarLevelTests {
    /// Stored in `@AppStorage`: a renamed case would reopen the Calendar on the wrong level.
    @Test func rawValuesAreStable() {
        #expect(CalendarLevel.year.rawValue == "year")
        #expect(CalendarLevel.month.rawValue == "month")
        #expect(CalendarLevel.day.rawValue == "day")
    }
}
