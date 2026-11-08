import Foundation

/// A single rendered occurrence: a rule-generated `scheduledDate`, with any override
/// applied. `scheduledDate` stays fixed so a moved or amended occurrence still matches
/// its override on re-run; `effectiveDate` is what the timeline actually shows.
public struct Occurrence: Equatable, Sendable, Identifiable {
    /// The bill and the calendar day it was scheduled on ("…-2026-03-15"): the same in every
    /// time zone, as the day itself is. This is identity, not date arithmetic.
    public let id: String
    public let expenseID: UUID
    public let scheduledDate: Date
    public let effectiveDate: Date
    public let amount: Decimal?
    public let isEstimate: Bool
    public let isSkipped: Bool

    public init(
        expenseID: UUID,
        scheduledDate: Date,
        effectiveDate: Date,
        amount: Decimal?,
        isEstimate: Bool,
        isSkipped: Bool,
        calendar: Calendar
    ) {
        self.id = "\(expenseID.uuidString)-\(CalendarDay(scheduledDate, calendar: calendar).id)"
        self.expenseID = expenseID
        self.scheduledDate = scheduledDate
        self.effectiveDate = effectiveDate
        self.amount = amount
        self.isEstimate = isEstimate
        self.isSkipped = isSkipped
    }
}
