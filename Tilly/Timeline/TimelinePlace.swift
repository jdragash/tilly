import Foundation

/// A scroll position and nothing else — there is no expanded state to go with it, because
/// an unlocked month closes itself and stays open only for the session that opened it. See
/// "The timeline never resets your position" in `docs/DECISIONS.md`.
struct TimelinePlace: Codable, Equatable, Sendable {
    var anchorMonthID: Int      // MonthKey.id, the month under the middle of the viewport
    var anchorOffset: Double    // its top, in points, relative to the container's top

    /// Pulled inside `window`'s current range in case the floor has moved since this place
    /// was saved — an expense whose anchor set the floor can be edited or removed between
    /// launches. A month that no longer resolves lands at the boundary it fell past, at that
    /// boundary's own top rather than at a stale offset that no longer means anything.
    func clamped(into window: TimelineWindow) -> TimelinePlace {
        let bounds = window.floor.id...window.top.id
        guard !bounds.contains(anchorMonthID) else { return self }
        let clampedID = min(max(anchorMonthID, window.floor.id), window.top.id)
        return TimelinePlace(anchorMonthID: clampedID, anchorOffset: 0)
    }
}

/// Reads and writes the single saved `TimelinePlace`. One reader's place at a time — there
/// is no history of places, only the most recent.
struct TimelinePlaceStore: Sendable {
    private let defaults: UserDefaults
    private static let key = "tillyTimelinePlace"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> TimelinePlace? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(TimelinePlace.self, from: data)
    }

    func save(_ place: TimelinePlace) {
        guard let data = try? JSONEncoder().encode(place) else { return }
        defaults.set(data, forKey: Self.key)
    }

    func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}
