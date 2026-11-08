import Foundation
import SwiftData
import TillyCore

/// The store as it first shipped, frozen: days stored as the instant each began where the bill was
/// made. Never edit these definitions; they are how stores on disk were written. `TillyMigrationPlan`
/// carries a store from here to the current schema.
enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Expense.self, OverrideRecord.self, ExpenseCategory.self]
    }

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
        var category: ExpenseCategory?
        var seriesID: UUID?

        @Relationship(deleteRule: .cascade, inverse: \OverrideRecord.expense)
        var overrides: [OverrideRecord]?

        init(
            id: UUID = UUID(), name: String = "", amount: Decimal? = nil, isEstimate: Bool = false,
            isArchived: Bool = false, recurrenceInterval: Int = 1, recurrenceUnit: RecurrenceUnit = .month,
            anchorDate: Date = Date(), endDate: Date? = nil, category: ExpenseCategory? = nil, seriesID: UUID? = nil
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
            self.seriesID = seriesID
        }
    }

    @Model
    final class OverrideRecord {
        var scheduledDate: Date = Date()
        var actualAmount: Decimal?
        var movedDate: Date?
        var isSkipped: Bool = false
        var expense: Expense?

        init(
            scheduledDate: Date = Date(), actualAmount: Decimal? = nil, movedDate: Date? = nil,
            isSkipped: Bool = false, expense: Expense? = nil
        ) {
            self.scheduledDate = scheduledDate
            self.actualAmount = actualAmount
            self.movedDate = movedDate
            self.isSkipped = isSkipped
            self.expense = expense
        }
    }

    @Model
    final class ExpenseCategory {
        var id: UUID = UUID()
        var name: String = ""
        var emoji: String = ""
        var symbol: String = ""
        var createdAt: Date = Date()
        var colourRaw: String = ""
        var sortOrder: Int = 0

        @Relationship(deleteRule: .nullify, inverse: \Expense.category)
        var expenses: [Expense]?

        init(
            id: UUID = UUID(), name: String, emoji: String = "", symbol: String = "", colourRaw: String = "",
            sortOrder: Int = 0, createdAt: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.emoji = emoji
            self.symbol = symbol
            self.colourRaw = colourRaw
            self.sortOrder = sortOrder
            self.createdAt = createdAt
        }
    }
}
