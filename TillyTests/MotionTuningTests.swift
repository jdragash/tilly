import Foundation
import Testing
@testable import Tilly

@MainActor @Suite struct MotionTuningTests {
    static func suite() -> UserDefaults {
        let name = "MotionTuningTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func defaultsMatchCatalogue() {
        let tuning = MotionTuning(defaults: Self.suite())
        for value in MotionTuning.values {
            #expect(tuning[value.id] == value.defaultValue, "\(value.id)")
        }
    }

    @Test func setPersistsAcrossInstances() {
        let defaults = Self.suite()
        MotionTuning(defaults: defaults)["sheetExit"] = 0.7
        #expect(MotionTuning(defaults: defaults)["sheetExit"] == 0.7)
    }

    @Test func resetRestoresDefaults() {
        let defaults = Self.suite()
        let tuning = MotionTuning(defaults: defaults)
        tuning["sheetExit"] = 0.7
        tuning["dayDrop"] = 60
        tuning.reset()
        #expect(tuning["sheetExit"] == 0.55)
        #expect(tuning["dayDrop"] == 48)
        #expect(MotionTuning(defaults: defaults)["sheetExit"] == 0.55)
    }

    @Test func snippetListsOnlyChangedValues() {
        let tuning = MotionTuning(defaults: Self.suite())
        tuning["sheetExit"] = 0.7
        tuning["dayDrop"] = 60
        tuning["sheetRiseBounce"] = 0.2
        #expect(tuning.swiftSnippet == """
            static let sheetExit: TimeInterval = 0.7
            static let sheetRiseBounce: Double = 0.2
            static let dayDrop: CGFloat = 60
            """)
    }

    @Test func snippetIsEmptyWhenNothingChanged() {
        let tuning = MotionTuning(defaults: Self.suite())
        #expect(tuning.swiftSnippet.isEmpty)
        tuning["sheetExit"] = 0.7
        tuning["sheetExit"] = 0.55
        #expect(tuning.swiftSnippet.isEmpty)
    }

    @Test func everyValueIsInsideItsRange() {
        for value in MotionTuning.values {
            #expect(value.range.contains(value.defaultValue), "\(value.id)")
            #expect(value.step > 0 && value.step <= value.range.upperBound - value.range.lowerBound, "\(value.id)")
        }
        #expect(Set(MotionTuning.values.map(\.id)).count == MotionTuning.values.count)
    }
}
