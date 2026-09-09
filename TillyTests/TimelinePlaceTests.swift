import Foundation
import Testing
@testable import Tilly

@Suite struct TimelinePlaceTests {
    static func makeDefaults(suiteName: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func anEmptyStoreLoadsNothing() {
        let suiteName = "TimelinePlaceTests.emptyStore"
        let defaults = Self.makeDefaults(suiteName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = TimelinePlaceStore(defaults: defaults)
        #expect(store.load() == nil)
    }

    @Test func aSavedPlaceRoundTrips() {
        let suiteName = "TimelinePlaceTests.roundTrip"
        let defaults = Self.makeDefaults(suiteName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = TimelinePlaceStore(defaults: defaults)
        let place = TimelinePlace(anchorMonthID: 24315, anchorOffset: 42.5)
        store.save(place)
        #expect(store.load() == place)
    }

    @Test func savingTwiceKeepsTheLatest() {
        let suiteName = "TimelinePlaceTests.savingTwice"
        let defaults = Self.makeDefaults(suiteName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = TimelinePlaceStore(defaults: defaults)
        store.save(TimelinePlace(anchorMonthID: 1, anchorOffset: 1))
        let latest = TimelinePlace(anchorMonthID: 2, anchorOffset: 2)
        store.save(latest)
        #expect(store.load() == latest)
    }

    @Test func clearingRemovesThePlace() {
        let suiteName = "TimelinePlaceTests.clearing"
        let defaults = Self.makeDefaults(suiteName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = TimelinePlaceStore(defaults: defaults)
        store.save(TimelinePlace(anchorMonthID: 1, anchorOffset: 1))
        store.clear()
        #expect(store.load() == nil)
    }

    @Test func aPlaceBelowTheFloorIsClampedIntoTheWindow() {
        let window = TimelineWindow(floor: MonthKey(year: 2026, month: 3), current: MonthKey(year: 2026, month: 9))
        let place = TimelinePlace(anchorMonthID: MonthKey(year: 2026, month: 1).id, anchorOffset: 200)

        let clamped = place.clamped(into: window)

        #expect(clamped.anchorMonthID == window.floor.id)
        #expect(clamped.anchorOffset == 0)
    }
}
