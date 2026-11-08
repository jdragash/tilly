import Foundation
import SwiftData
import TillyCore

/// A step between versions, frozen, that no app ever opens on its own: V1's fields with the
/// calendar-day fields beside them, so the migration can read each stored instant and write its
/// day in one schema. `SchemaV3` then drops the instants. Never edit these definitions.
enum SchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

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
        var anchorYear: Int = 2000
        var anchorMonth: Int = 1
        var anchorDay: Int = 1
        var endYear: Int?
        var endMonth: Int?
        var endDay: Int?
        var category: ExpenseCategory?
        var seriesID: UUID?

        @Relationship(deleteRule: .cascade, inverse: \OverrideRecord.expense)
        var overrides: [OverrideRecord]?

        init() {}
    }

    @Model
    final class OverrideRecord {
        var scheduledDate: Date = Date()
        var actualAmount: Decimal?
        var movedDate: Date?
        var isSkipped: Bool = false
        var scheduledYear: Int = 2000
        var scheduledMonth: Int = 1
        var scheduledDay: Int = 1
        var movedYear: Int?
        var movedMonth: Int?
        var movedDay: Int?
        var expense: Expense?

        init() {}
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

        init() {}
    }
}
