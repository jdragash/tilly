#if DEBUG
import Foundation
import SwiftData

/// A state the app can be put in for testing on a phone, from the Developer section in
/// Settings. Every sample scenario seeds its own in-memory store; `yourData` is the person's
/// own store and is never seeded. Debug builds only.
enum DeveloperScenario: String, CaseIterable, Identifiable, Sendable {
    case yourData, empty, oneExpense, typicalYear, longHistory, nothingChargedYet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yourData: "Your data"
        case .empty: "Empty"
        case .oneExpense: "One expense"
        case .typicalYear: "Typical year"
        case .longHistory: "Long history"
        case .nothingChargedYet: "Nothing charged yet"
        }
    }

    var isSample: Bool { self != .yourData }

    /// Inserts this scenario's data and saves. `.yourData` and `.empty` insert nothing.
    func seed(into context: ModelContext, today: Date, calendar: Calendar) throws {
        switch self {
        case .yourData, .empty:
            return
        case .oneExpense:
            let subscriptions = ExpenseCategory(name: "Subscriptions", emoji: "📺")
            context.insert(subscriptions)
            context.insert(Expense(name: "Music", amount: 15, anchorDate: calendar.startOfDay(for: today), category: subscriptions))
        case .typicalYear:
            try PreviewData.insert(into: context, today: today, calendar: calendar)
        case .longHistory:
            try PreviewData.insert(into: context, today: today, calendar: calendar, historyMonths: 36)
        case .nothingChargedYet:
            let home = ExpenseCategory(name: "Home", emoji: "🏠")
            context.insert(home)
            let start = calendar.startOfDay(for: today)
            let internet = calendar.date(byAdding: .day, value: 2, to: start)!
            let water = calendar.date(byAdding: .day, value: 5, to: start)!
            context.insert(Expense(name: "Internet", amount: 30, anchorDate: internet, category: home))
            context.insert(Expense(name: "Water", amount: 45, anchorDate: water, category: home))
        }
        try context.save()
    }
}
#endif
