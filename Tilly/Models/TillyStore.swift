import Foundation
import SwiftData

enum TillyStore {
    static let schema = Schema([Expense.self, OverrideRecord.self])

    static func container(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
