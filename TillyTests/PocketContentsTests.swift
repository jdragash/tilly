import Foundation
import SwiftData
import Testing
@testable import Tilly

@Suite struct PocketContentsTests {
    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    static let today = date(2027, 1, 15)

    static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    static func makeContext() throws -> ModelContext {
        ModelContext(try TillyStore.container(inMemory: true))
    }

    static func category(_ name: String, order: Int, in context: ModelContext) -> ExpenseCategory {
        let category = ExpenseCategory(name: name, emoji: "🏠", colour: nil, sortOrder: order)
        context.insert(category)
        return category
    }

    @discardableResult
    static func bill(
        _ name: String, in category: ExpenseCategory?, anchor: Date, end: Date? = nil,
        series: UUID? = nil, archived: Bool = false, context: ModelContext
    ) -> Expense {
        let expense = Expense(
            name: name, isArchived: archived, anchorDate: anchor, endDate: end,
            category: category, seriesID: series
        )
        context.insert(expense)
        return expense
    }

    static func make(
        _ context: ModelContext, excluding: UUID? = nil
    ) throws -> [PocketContent] {
        let categories = try context.fetch(FetchDescriptor<ExpenseCategory>())
        let expenses = try context.fetch(FetchDescriptor<Expense>())
        return PocketContents.make(
            categories: categories, expenses: expenses, excluding: excluding,
            today: today, calendar: calendar
        )
    }

    @Test func noCategoriesNoPockets() throws {
        let context = try Self.makeContext()
        #expect(try Self.make(context).isEmpty)
    }

    @Test func pocketsFollowSortOrder() throws {
        let context = try Self.makeContext()
        _ = Self.category("Third", order: 2, in: context)
        _ = Self.category("First", order: 0, in: context)
        _ = Self.category("Second", order: 1, in: context)
        #expect(try Self.make(context).map(\.name) == ["First", "Second", "Third"])
    }

    @Test func emptyCategoryPeeksNothing() throws {
        let context = try Self.makeContext()
        _ = Self.category("Home", order: 0, in: context)
        #expect(try Self.make(context).first?.peeking == [])
    }

    @Test func atMostThreePeek() throws {
        let context = try Self.makeContext()
        let home = Self.category("Home", order: 0, in: context)
        Self.bill("A", in: home, anchor: Self.date(2026, 1, 1), context: context)
        Self.bill("B", in: home, anchor: Self.date(2026, 2, 1), context: context)
        Self.bill("C", in: home, anchor: Self.date(2026, 3, 1), context: context)
        Self.bill("D", in: home, anchor: Self.date(2026, 4, 1), context: context)
        #expect(try Self.make(context).first?.peeking == ["B", "C", "D"])
    }

    @Test func latestAnchorIsInFront() throws {
        let context = try Self.makeContext()
        let home = Self.category("Home", order: 0, in: context)
        Self.bill("Newest", in: home, anchor: Self.date(2026, 9, 1), context: context)
        Self.bill("Oldest", in: home, anchor: Self.date(2026, 1, 1), context: context)
        Self.bill("Middle", in: home, anchor: Self.date(2026, 5, 1), context: context)
        #expect(try Self.make(context).first?.peeking == ["Oldest", "Middle", "Newest"])
    }

    @Test func endedBillsDontPeek() throws {
        let context = try Self.makeContext()
        let home = Self.category("Home", order: 0, in: context)
        Self.bill("Ended", in: home, anchor: Self.date(2026, 1, 1), end: Self.date(2027, 1, 14), context: context)
        Self.bill("Running", in: home, anchor: Self.date(2026, 2, 1), context: context)
        #expect(try Self.make(context).first?.peeking == ["Running"])
    }

    @Test func billEndingTodayStillPeeks() throws {
        let context = try Self.makeContext()
        let home = Self.category("Home", order: 0, in: context)
        // Ends today at a later hour; still running at day granularity.
        let endsToday = Self.calendar.date(byAdding: .hour, value: 5, to: Self.today)!
        Self.bill("Last day", in: home, anchor: Self.date(2026, 1, 1), end: endsToday, context: context)
        #expect(try Self.make(context).first?.peeking == ["Last day"])
    }

    @Test func splitSeriesPeeksOnceUnderItsLatestName() throws {
        let context = try Self.makeContext()
        let home = Self.category("Home", order: 0, in: context)
        let series = UUID()
        Self.bill("Old name", in: home, anchor: Self.date(2026, 1, 1), end: Self.date(2026, 6, 1),
                  series: series, context: context)
        Self.bill("New name", in: home, anchor: Self.date(2026, 6, 1), series: series, context: context)
        #expect(try Self.make(context).first?.peeking == ["New name"])
    }

    @Test func editedSeriesIsExcluded() throws {
        let context = try Self.makeContext()
        let home = Self.category("Home", order: 0, in: context)
        let editing = Self.bill("Editing", in: home, anchor: Self.date(2026, 3, 1), context: context)
        Self.bill("Other", in: home, anchor: Self.date(2026, 1, 1), context: context)
        #expect(try Self.make(context, excluding: editing.seriesKey).first?.peeking == ["Other"])
    }

    @Test func billWithoutCategoryIsIgnored() throws {
        let context = try Self.makeContext()
        _ = Self.category("Home", order: 0, in: context)
        Self.bill("Orphan", in: nil, anchor: Self.date(2026, 1, 1), context: context)
        #expect(try Self.make(context).first?.peeking == [])
    }

    @Test func archivedBillsDontPeek() throws {
        let context = try Self.makeContext()
        let home = Self.category("Home", order: 0, in: context)
        Self.bill("Archived", in: home, anchor: Self.date(2026, 3, 1), archived: true, context: context)
        Self.bill("Kept", in: home, anchor: Self.date(2026, 1, 1), context: context)
        #expect(try Self.make(context).first?.peeking == ["Kept"])
    }
}
