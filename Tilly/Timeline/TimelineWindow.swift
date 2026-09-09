import Foundation

/// Where the list starts and stops. The next month is always expanded; `unlocked` counts
/// months opened beyond it, one at a time, and closes back to 0 once the reader returns to
/// the current month. See "The timeline is one list you scroll, bounded at both ends" in
/// `docs/DECISIONS.md`.
struct TimelineWindow: Equatable, Sendable {
    let floor: MonthKey
    let current: MonthKey
    var unlocked: Int = 0

    var top: MonthKey { current.advanced(by: 1 + unlocked) }

    /// `top` down to `floor`, descending. Pure range arithmetic — filtering out empty
    /// months needs `MonthSection`s and belongs in the view.
    var months: [MonthKey] {
        var result: [MonthKey] = []
        var key = top
        while key >= floor {
            result.append(key)
            key = key.advanced(by: -1)
        }
        return result
    }
}
