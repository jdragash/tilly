import Foundation

/// A single rendered occurrence: a rule-generated `scheduledDate`, with any override
/// applied. `scheduledDate` stays fixed so a moved or amended occurrence still matches
/// its override on re-run; `effectiveDate` is what the timeline actually shows.
public struct Occurrence: Equatable, Sendable, Identifiable {
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
        isSkipped: Bool
    ) {
        self.expenseID = expenseID
        self.scheduledDate = scheduledDate
        self.effectiveDate = effectiveDate
        self.amount = amount
        self.isEstimate = isEstimate
        self.isSkipped = isSkipped
    }

    /// Seconds since the epoch rather than a formatted date: an absolute instant is
    /// timezone-free and stable, where a date string would need a calendar this value
    /// type doesn't carry. This is identity, not date arithmetic.
    public var id: String {
        "\(expenseID.uuidString)-\(Int(scheduledDate.timeIntervalSince1970))"
    }
}
