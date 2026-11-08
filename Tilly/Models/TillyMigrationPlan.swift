import Foundation
import SwiftData
import TillyCore

/// The current schema: days stored as calendar days. The live models are its nested types.
enum SchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Expense.self, OverrideRecord.self, ExpenseCategory.self]
    }
}

/// Every version the store has had, oldest first, and the steps between them.
///
/// V1 to V3 takes two steps, the documented way to change a field's type: V2 adds the day fields
/// beside the instants and, once the store is at V2, copies each instant's day across; V3 then
/// drops the instants. A single custom step can't do it: before it, the day fields don't exist,
/// and after it, the instants are gone.
enum TillyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self, SchemaV3.self] }

    static var stages: [MigrationStage] {
        [
            .custom(fromVersion: SchemaV1.self, toVersion: SchemaV2.self, willMigrate: nil, didMigrate: copyDays),
            .lightweight(fromVersion: SchemaV2.self, toVersion: SchemaV3.self),
        ]
    }

    /// Writes each stored instant's day into the day fields. The one place with no calendar handed
    /// in, so it reads them in `Calendar.current`: the phone's own, the zone the bills were most
    /// likely made in, as they were made with it.
    private static func copyDays(_ context: ModelContext) throws {
        let calendar = Calendar.current
        for expense in try context.fetch(FetchDescriptor<SchemaV2.Expense>()) {
            let anchor = CalendarDay(expense.anchorDate, calendar: calendar)
            expense.anchorYear = anchor.year
            expense.anchorMonth = anchor.month
            expense.anchorDay = anchor.day
            let end = expense.endDate.map { CalendarDay($0, calendar: calendar) }
            expense.endYear = end?.year
            expense.endMonth = end?.month
            expense.endDay = end?.day
        }
        for record in try context.fetch(FetchDescriptor<SchemaV2.OverrideRecord>()) {
            let scheduled = CalendarDay(record.scheduledDate, calendar: calendar)
            record.scheduledYear = scheduled.year
            record.scheduledMonth = scheduled.month
            record.scheduledDay = scheduled.day
            let moved = record.movedDate.map { CalendarDay($0, calendar: calendar) }
            record.movedYear = moved?.year
            record.movedMonth = moved?.month
            record.movedDay = moved?.day
        }
        try context.save()
    }
}
