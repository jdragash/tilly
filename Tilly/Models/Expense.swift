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
    var recurrenceUnitRaw: String = RecurrenceUnit.month.rawValue
    var anchorDate: Date = Date()
    var endDate: Date?

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
        endDate: Date? = nil
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
    }
}

extension Expense {
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
