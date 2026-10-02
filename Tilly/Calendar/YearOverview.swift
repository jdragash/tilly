import Foundation

/// What one day of a month in the year overview shows.
enum YearMark: Equatable, Sendable {
    case quiet // nothing charged: a faint dot
    case usual // only usual charges: a grey dot
    case extra(CategoryColour?, isLarge: Bool) // the day's costliest extra's colour
    case change(CategoryColour?, isZero: Bool) // a usual bill starts a record or ends: a ring
    case today
}

struct YearMonth: Identifiable, Equatable, Sendable {
    let month: MonthKey
    let total: Decimal // every non-skipped charge
    let extrasTotal: Decimal
    let isHeavy: Bool // extrasTotal reaches `YearBuilder.heavyShare` of the usual month, and is above 0
    let leadingDays: Int
    let marks: [YearMark] // one per day of the month

    var id: Int { month.id }
}

struct YearOverview: Equatable, Sendable {
    let months: [YearMonth] // twelve, the current month first
    let total: Decimal
    let extrasTotal: Decimal
    let usualMonth: Decimal // median of (total − extrasTotal) over the twelve; mean of the middle two
    let hasExtras: Bool
}
