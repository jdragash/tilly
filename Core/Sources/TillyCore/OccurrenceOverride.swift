import Foundation

/// A recorded deviation from a rule-generated occurrence. Identified by `scheduledDate`,
/// never by array position — so a moved or amended occurrence still matches on re-run.
public struct OccurrenceOverride: Equatable, Sendable {
    public let scheduledDate: Date
    public let actualAmount: Decimal?
    public let movedDate: Date?
    public let isSkipped: Bool

    public init(scheduledDate: Date, actualAmount: Decimal?, movedDate: Date?, isSkipped: Bool) {
        self.scheduledDate = scheduledDate
        self.actualAmount = actualAmount
        self.movedDate = movedDate
        self.isSkipped = isSkipped
    }
}
