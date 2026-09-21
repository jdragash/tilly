import Foundation

/// Where the list starts and stops: every month from the ceiling down to the floor, built
/// once, so nothing is ever inserted above the reader. See
/// "The timeline is one list, future above and past below, and the future runs five years on" in
/// `docs/DECISIONS.md`.
struct TimelineWindow: Equatable, Sendable {
    /// How far ahead the list is built when no bill ends: five years, which is about
    /// 27,000 points of scrolling, and about 18ms to build. Further is affordable — a month
    /// costs about 0.3ms — but a list the reader sits at the bottom of costs its whole height
    /// at launch, because the scroll back to this month lays out everything above it first.
    static let monthsAhead = 60

    let floor: MonthKey
    let ceiling: MonthKey
    let current: MonthKey

    init(floor: MonthKey, ceiling: MonthKey, current: MonthKey) {
        self.floor = floor
        self.ceiling = ceiling
        self.current = current
    }

    /// `ceiling` down to `floor`, descending. Pure range arithmetic — filtering out empty
    /// months needs `MonthSection`s and belongs in the view.
    var months: [MonthKey] {
        var result: [MonthKey] = []
        var key = ceiling
        while key >= floor {
            result.append(key)
            key = key.advanced(by: -1)
        }
        return result
    }
}
