import Foundation

/// A plain-value view of an expense, mapped in from the app's persistence layer at the
/// boundary. Core never sees a SwiftData type — see docs/DECISIONS.md.
public struct ExpenseSnapshot: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let amount: Decimal?
    public let isEstimate: Bool
    public let rule: RecurrenceRule
    public let isArchived: Bool

    public init(id: UUID, amount: Decimal?, isEstimate: Bool, rule: RecurrenceRule, isArchived: Bool) {
        self.id = id
        self.amount = amount
        self.isEstimate = isEstimate
        self.rule = rule
        self.isArchived = isArchived
    }
}
