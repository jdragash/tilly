import Foundation
import SwiftData

/// The store as it first shipped, frozen. The models live inside it and the app reaches them
/// through top-level typealiases, so a later version adds `SchemaV2` beside this one, moves the
/// aliases to it, and leaves these definitions exactly as stores on disk were written.
enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Expense.self, OverrideRecord.self, ExpenseCategory.self]
    }
}

/// Every version the store has had, oldest first, and the steps between them. One version so far,
/// so no stages: an existing store opens unchanged.
enum TillyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
