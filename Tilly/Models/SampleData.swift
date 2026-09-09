import Foundation
import SwiftData
import TillyCore

/// Eleven expenses, each generating an occurrence on a day of the *current* month, so
/// wherever the app is first opened, the seed shows upcoming and charged rows, an estimate
/// of each temporal state, a skipped bill, and the neighbouring-month trap made visible. Most
/// anchor six months back so there is history to scroll through; the annual insurance anchors
/// nine months back, deliberately backdated, so the floor sits below two empty months. See
/// `docs/plans/timeline.md`, Step 3 for the table and Step 6 for why the anchors moved.
enum SampleData {
    private static let hasSeededKey = "tillySampleDataSeeded"
    private static let emptyStoreKey = "tillyEmptyStore"

    static func seedIfNeeded(
        into context: ModelContext,
        today: Date = Date(),
        calendar: Calendar = .current,
        defaults: UserDefaults = .standard
    ) throws {
        guard !defaults.bool(forKey: emptyStoreKey) else { return }
        guard !defaults.bool(forKey: hasSeededKey) else { return }

        let existingCount = try context.fetchCount(FetchDescriptor<Expense>())
        guard existingCount == 0 else { return }

        try insert(into: context, today: today, calendar: calendar)
        defaults.set(true, forKey: hasSeededKey)
    }

    /// The same rows without the guard, for previews and tests.
    static func insert(into context: ModelContext, today: Date, calendar: Calendar) throws {
        let components = calendar.dateComponents([.year, .month], from: today)
        let year = components.year ?? 2026
        let month = components.month ?? 1

        func anchor(day: Int, monthOffset: Int = 0, yearOffset: Int = 0) -> Date {
            calendar.date(from: DateComponents(year: year + yearOffset, month: month + monthOffset, day: day))!
        }

        let rent = Expense(name: "Rent", amount: 950, anchorDate: anchor(day: 1, monthOffset: -6))
        let streamingVideo = Expense(name: "Streaming video", amount: 18, anchorDate: anchor(day: 1, monthOffset: -6))
        let musicStreaming = Expense(name: "Music streaming", amount: 11, anchorDate: anchor(day: 2, monthOffset: -6))
        let cloudStorage = Expense(name: "Cloud storage", amount: 3, anchorDate: anchor(day: 2, monthOffset: -6))
        let gymMembership = Expense(name: "Gym membership", amount: 32, anchorDate: anchor(day: 4, monthOffset: -6))
        let electricity = Expense(
            name: "Electricity", amount: 85, isEstimate: true, anchorDate: anchor(day: 4, monthOffset: -6)
        )
        // Anchored nine months back rather than alongside the other monthlies: an annual
        // rule anchored there does not recur into the current month at all, which is the
        // deliberately backdated entry the floor rule exists for. It leaves two empty months
        // above it that the empty-month skip then has to hide.
        let insurance = Expense(
            name: "Home & contents insurance",
            amount: 240,
            recurrenceUnit: .year,
            anchorDate: anchor(day: 12, monthOffset: -9)
        )
        let water = Expense(
            name: "Water",
            amount: 38,
            isEstimate: true,
            recurrenceInterval: 3,
            recurrenceUnit: .month,
            anchorDate: anchor(day: 20, monthOffset: -6)
        )
        // A monthly rule generates every month at or after its anchor, so anchoring six
        // months back still reaches last month's 22nd — the occurrence the moved override
        // below names. The engine only pulls in an override whose scheduled date is one the
        // rule actually generates.
        let homeInternet = Expense(name: "Home internet", amount: 45, anchorDate: anchor(day: 22, monthOffset: -6))
        let councilTax = Expense(name: "Council tax", amount: 95, anchorDate: anchor(day: 25, monthOffset: -6))
        let mobilePhone = Expense(name: "Mobile phone", amount: 22, anchorDate: anchor(day: 25, monthOffset: -6))

        let expenses = [
            rent, streamingVideo, musicStreaming, cloudStorage, gymMembership, electricity,
            insurance, water, homeInternet, councilTax, mobilePhone
        ]
        expenses.forEach(context.insert)

        context.insert(OverrideRecord(
            scheduledDate: anchor(day: 1),
            isSkipped: true,
            expense: streamingVideo
        ))
        context.insert(OverrideRecord(
            scheduledDate: anchor(day: 22, monthOffset: -1),
            movedDate: anchor(day: 3),
            expense: homeInternet
        ))

        try context.save()
    }
}
