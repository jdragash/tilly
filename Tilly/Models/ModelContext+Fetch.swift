import Foundation
import SwiftData

extension ModelContext {
    /// The expense with this id, fetched on its own rather than by loading every expense.
    func expense(id: UUID) throws -> Expense? {
        var descriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try fetch(descriptor).first
    }
}
