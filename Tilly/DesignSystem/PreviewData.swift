#if DEBUG
import Foundation
import SwiftData
import TillyCore

/// Invented expenses for SwiftUI previews and developer scenarios. Compiled out of release
/// builds; nothing seeds the person's own store. Anchored relative to `today` so the current month always
/// shows upcoming and charged rows, wherever a preview is opened.
enum PreviewData {
    /// `historyMonths` is how far back the monthly bills begin; developer scenarios use it to
    /// make a longer history from the same bills.
    static func insert(into context: ModelContext, today: Date, calendar: Calendar, historyMonths: Int = 6) throws {
        let components = calendar.dateComponents([.year, .month], from: today)
        let year = components.year ?? 2026
        let month = components.month ?? 1

        func anchor(day: Int, monthOffset: Int = 0) -> Date {
            calendar.date(from: DateComponents(year: year, month: month + monthOffset, day: day))!
        }

        let home = ExpenseCategory(name: "Home", emoji: "🏠")
        let subscriptions = ExpenseCategory(name: "Subscriptions", emoji: "📺")
        let phone = ExpenseCategory(name: "Phone", emoji: "📱")
        let car = ExpenseCategory(name: "Car", emoji: "🚗")
        let health = ExpenseCategory(name: "Health", emoji: "🏋️")
        let loans = ExpenseCategory(name: "Loans", emoji: "💳")
        [home, subscriptions, phone, car, health, loans].forEach(context.insert)

        let rent = Expense(name: "Rent", amount: 950, anchorDate: anchor(day: 1, monthOffset: -historyMonths), category: home)
        // Skipped this month, on the same day as the rent: two charges on one day.
        let streaming = Expense(
            name: "Streaming", amount: 13, anchorDate: anchor(day: 1, monthOffset: -historyMonths), category: subscriptions
        )
        let cloudStorage = Expense(
            name: "Cloud storage", amount: 3, anchorDate: anchor(day: 5, monthOffset: -historyMonths), category: subscriptions
        )
        let electricity = Expense(
            name: "Electricity", amount: 68, anchorDate: anchor(day: 8, monthOffset: -historyMonths), category: home
        )
        let phonePlan = Expense(
            name: "Phone plan", amount: 25, anchorDate: anchor(day: 8, monthOffset: -historyMonths), category: phone
        )
        // A yearly bill anchored three months before the rest: it doesn't recur into the current month.
        let carInsurance = Expense(
            name: "Car insurance",
            amount: 1240,
            recurrenceUnit: .year,
            anchorDate: anchor(day: 14, monthOffset: -(historyMonths + 3)),
            category: car
        )
        // A bill that ends: twelve payments, the first one last month.
        let sofaAnchor = anchor(day: 18, monthOffset: -1)
        let sofaRule = RecurrenceRule(interval: 1, unit: .month, anchorDate: sofaAnchor)
        let sofa = Expense(
            name: "Sofa",
            amount: 67,
            anchorDate: sofaAnchor,
            endDate: RecurrenceEngine.date(ofPayment: 11, for: sofaRule, calendar: calendar),
            category: loans
        )
        let water = Expense(
            name: "Water",
            amount: 45,
            recurrenceInterval: 3,
            recurrenceUnit: .month,
            anchorDate: anchor(day: 22, monthOffset: -historyMonths),
            category: home
        )
        let gym = Expense(name: "Gym", amount: 40, anchorDate: anchor(day: 28, monthOffset: -historyMonths), category: health)

        [rent, streaming, cloudStorage, electricity, phonePlan, carInsurance, sofa, water, gym]
            .forEach(context.insert)

        context.insert(OverrideRecord(scheduledDate: anchor(day: 1), isSkipped: true, expense: streaming))
        // Last month's 28th, moved into this month: the neighbouring-month trap made visible.
        context.insert(OverrideRecord(
            scheduledDate: anchor(day: 28, monthOffset: -1), movedDate: anchor(day: 3), expense: gym
        ))

        try context.save()
    }
}
#endif
