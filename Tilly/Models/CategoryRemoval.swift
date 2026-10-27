import Foundation
import SwiftData

/// Deleting a category takes its bills with it, every record of each and their overrides, after the
/// one alert that says so. The relationship's rule stays `.nullify`, so only this deletes bills.
enum CategoryRemoval {
    /// Bills (series, by `seriesKey`) filed under `category`, for the alert's count.
    static func billCount(of category: ExpenseCategory) -> Int {
        Set((category.expenses ?? []).map(\.seriesKey)).count
    }

    /// Deletes every `Expense` filed under it (overrides cascade), then the category, then saves.
    static func delete(_ category: ExpenseCategory, context: ModelContext) throws {
        let id = category.id
        let filed = try context.fetch(FetchDescriptor<Expense>()).filter { $0.category?.id == id }
        for expense in filed { context.delete(expense) }
        context.delete(category)
        try context.save()
    }
}
