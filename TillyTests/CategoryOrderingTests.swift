import Foundation
import SwiftData
import Testing
@testable import Tilly

@MainActor
@Suite struct CategoryOrderingTests {
    static func date(_ day: Int) -> Date {
        Date(timeIntervalSinceReferenceDate: 0).addingTimeInterval(Double(day) * 86_400)
    }

    /// Categories inserted into a fresh in-memory store, so they behave as the app's do.
    static func categories(_ specs: [(name: String, created: Int, order: Int, colour: String)]) throws
        -> (ModelContext, [ExpenseCategory]) {
        let context = ModelContext(try TillyStore.container(inMemory: true))
        let made = specs.map { spec in
            let category = ExpenseCategory(name: spec.name, emoji: "🏠", sortOrder: spec.order, createdAt: date(spec.created))
            category.colourRaw = spec.colour
            context.insert(category)
            return category
        }
        return (context, made)
    }

    static func byOrder(_ categories: [ExpenseCategory]) -> [String] {
        categories.sorted { $0.sortOrder < $1.sortOrder }.map(\.name)
    }

    // MARK: nextColour

    @Test func nextColourWithNoneUsedIsBlue() {
        #expect(CategoryOrdering.nextColour(after: []) == .blue)
    }

    @Test func nextColourSkipsUsedOnesInOrder() {
        #expect(CategoryOrdering.nextColour(after: [.blue]) == .orange)
        #expect(CategoryOrdering.nextColour(after: [.blue, .aqua]) == .orange)
        #expect(CategoryOrdering.nextColour(after: [.orange, .blue]) == .aqua)
    }

    @Test func nextColourWhenAllEightUsedPicksLeastUsedEarliestFirst() {
        let all = CategoryColour.allCases
        #expect(CategoryOrdering.nextColour(after: all) == .blue)
        #expect(CategoryOrdering.nextColour(after: all + [.blue]) == .orange)
        #expect(CategoryOrdering.nextColour(after: all + [.blue, .orange, .red]) == .aqua)
    }

    // MARK: nextSortOrder

    @Test func nextSortOrderOfNoneIsZero() {
        #expect(CategoryOrdering.nextSortOrder(after: []) == 0)
    }

    @Test func nextSortOrderIsOnePastTheLargest() {
        #expect(CategoryOrdering.nextSortOrder(after: [0, 3, 1]) == 4)
    }

    // MARK: backfill

    @Test func backfillOrdersAMigratedStoreByCreation() throws {
        let (_, made) = try Self.categories([
            ("Car", 3, 0, ""), ("Home", 1, 0, ""), ("Phone", 2, 0, ""),
        ])
        CategoryOrdering.backfill(made)
        #expect(Self.byOrder(made) == ["Home", "Phone", "Car"])
        #expect(made.map(\.sortOrder).sorted() == [0, 1, 2])
    }

    @Test func backfillBreaksCreationTiesByName() throws {
        let (_, made) = try Self.categories([
            ("Home", 1, 0, ""), ("Bills", 1, 0, ""), ("Car", 1, 0, ""),
        ])
        CategoryOrdering.backfill(made)
        #expect(Self.byOrder(made) == ["Bills", "Car", "Home"])
    }

    @Test func backfillRenumbersDuplicatesContiguously() throws {
        let (_, made) = try Self.categories([
            ("A", 1, 0, ""), ("C", 3, 2, ""), ("B", 2, 2, ""), ("D", 4, 5, ""),
        ])
        CategoryOrdering.backfill(made)
        #expect(Self.byOrder(made) == ["A", "B", "C", "D"])
        #expect(made.map(\.sortOrder).sorted() == [0, 1, 2, 3])
    }

    @Test func backfillColoursInOrderAroundOnesAlreadyTaken() throws {
        let (_, made) = try Self.categories([
            ("First", 1, 0, ""), ("Second", 2, 1, "blue"), ("Third", 3, 2, ""),
        ])
        CategoryOrdering.backfill(made)
        #expect(made.map(\.colour) == [.orange, .blue, .aqua])
    }

    @Test func backfillReadsAnUnknownColourAsUnset() throws {
        let (_, made) = try Self.categories([("Home", 1, 0, "chartreuse")])
        #expect(made[0].colour == nil)
        CategoryOrdering.backfill(made)
        #expect(made[0].colour == .blue)
        #expect(made[0].colourRaw == "blue")
    }

    @Test func backfillIsIdempotent() throws {
        let (_, made) = try Self.categories([
            ("Car", 3, 0, ""), ("Home", 1, 0, "violet"), ("Phone", 2, 4, ""), ("Bills", 2, 4, ""),
        ])
        CategoryOrdering.backfill(made)
        let once = made.map { "\($0.name) \($0.sortOrder) \($0.colourRaw)" }
        CategoryOrdering.backfill(made)
        #expect(made.map { "\($0.name) \($0.sortOrder) \($0.colourRaw)" } == once)
    }

    // MARK: move

    @Test func moveRenumbersContiguously() throws {
        let (_, made) = try Self.categories([
            ("A", 1, 0, ""), ("B", 2, 1, ""), ("C", 3, 2, ""), ("D", 4, 3, ""),
        ])
        CategoryOrdering.move(made, from: IndexSet(integer: 0), to: 3)
        #expect(Self.byOrder(made) == ["B", "C", "A", "D"])
        #expect(made.map(\.sortOrder).sorted() == [0, 1, 2, 3])

        CategoryOrdering.move(made.sorted { $0.sortOrder < $1.sortOrder }, from: IndexSet(integer: 3), to: 0)
        #expect(Self.byOrder(made) == ["D", "B", "C", "A"])
    }

    /// What Settings does on a drag and a colour pick, then a relaunch: a fresh container on the
    /// same file. The sample scenarios reseed on launch, so the Simulator can't show this.
    @Test func aMoveAndAColourSurviveReopeningTheStore() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("CategoryOrderingTests-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }
        func open() throws -> ModelContext {
            ModelContext(try ModelContainer(for: TillyStore.schema, configurations: [ModelConfiguration(url: url)]))
        }

        let first = try open()
        let made = ["A", "B", "C"].enumerated().map { index, name in
            ExpenseCategory(name: name, emoji: "🏠", colour: .blue, sortOrder: index)
        }
        made.forEach(first.insert)
        CategoryOrdering.move(made, from: IndexSet(integer: 2), to: 0)
        made[0].colour = .violet
        try first.save()

        let reopened = try open().fetch(FetchDescriptor<ExpenseCategory>(sortBy: [SortDescriptor(\.sortOrder)]))
        #expect(reopened.map(\.name) == ["C", "A", "B"])
        #expect(reopened.first { $0.name == "A" }?.colour == .violet)
    }
}
