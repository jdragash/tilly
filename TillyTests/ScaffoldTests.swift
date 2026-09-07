import Foundation
import Testing
import TillyCore

struct ScaffoldTests {
    @Test func tillyCoreIsLinked() {
        let rule = RecurrenceRule(interval: 0, unit: .month, anchorDate: Date())
        #expect(rule.interval == 1)
    }
}
