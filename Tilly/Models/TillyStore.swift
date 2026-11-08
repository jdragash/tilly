import Foundation
import OSLog
import SwiftData

enum TillyStore {
    static let logger = Logger(subsystem: "com.jdragash.Tilly", category: "TillyStore")

    static let schema = Schema(versionedSchema: SchemaV3.self)

    static func container(inMemory: Bool = false) throws -> ModelContainer {
        try container(ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory))
    }

    /// Opens a store at `url` through the migration plan. The tests use it to reopen a store on
    /// disk the way a launch does.
    static func container(url: URL) throws -> ModelContainer {
        try container(ModelConfiguration(schema: schema, url: url))
    }

    private static func container(_ configuration: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(for: schema, migrationPlan: TillyMigrationPlan.self, configurations: [configuration])
    }
}
