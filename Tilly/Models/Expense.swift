import Foundation
import SwiftData
import TillyCore

@Model
final class Expense {
    var id: UUID = UUID()
    var name: String = ""
    var amount: Decimal?
    var isEstimate: Bool = false
    var isArchived: Bool = false
    var recurrenceInterval: Int = 1
    /// A plain `String` rather than the enum: CloudKit-safe, readable in the store, and
    /// usable in a `#Predicate`. A stored enum goes through `Codable` into an opaque blob.
    var recurrenceUnitRaw: String = RecurrenceUnit.month.rawValue
    var anchorDate: Date = Date()
    var endDate: Date?
    /// Optional because CloudKit requires it; the editor requires one, so `nil` only occurs in a
    /// store saved before categories existed.
    var category: ExpenseCategory?

    @Relationship(deleteRule: .cascade, inverse: \OverrideRecord.expense)
    var overrides: [OverrideRecord]?

    init(
        id: UUID = UUID(),
        name: String = "",
        amount: Decimal? = nil,
        isEstimate: Bool = false,
        isArchived: Bool = false,
        recurrenceInterval: Int = 1,
        recurrenceUnit: RecurrenceUnit = .month,
        anchorDate: Date = Date(),
        endDate: Date? = nil,
        category: ExpenseCategory? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.isEstimate = isEstimate
        self.isArchived = isArchived
        self.recurrenceInterval = recurrenceInterval
        self.recurrenceUnitRaw = recurrenceUnit.rawValue
        self.anchorDate = anchorDate
        self.endDate = endDate
        self.category = category
    }
}

extension Expense {
    /// Falls back to `.month` rather than failing. Mapping to the engine is total: a bill shown
    /// with a defaulted unit is an obvious fault, and one that silently vanishes is not.
    var recurrenceUnit: RecurrenceUnit {
        RecurrenceUnit(rawValue: recurrenceUnitRaw) ?? .month
    }

    var rule: RecurrenceRule {
        RecurrenceRule(
            interval: recurrenceInterval,
            unit: recurrenceUnit,
            anchorDate: anchorDate,
            endDate: endDate
        )
    }

    var snapshot: ExpenseSnapshot {
        ExpenseSnapshot(id: id, amount: amount, isEstimate: isEstimate, rule: rule, isArchived: isArchived)
    }

    var overrideSnapshots: [OccurrenceOverride] {
        (overrides ?? []).map(\.snapshot)
    }
}
