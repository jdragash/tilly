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

    // MARK: arrange and restore

    static let noFigures: [UUID: (bills: Int, monthly: Decimal)] = [:]

    @Test func colourSortsAsARainbow() throws {
        let (_, made) = try Self.categories([
            (name: "None", created: 0, order: 0, colour: ""),
            (name: "Pink", created: 1, order: 1, colour: "magenta"),
            (name: "Purple", created: 2, order: 2, colour: "violet"),
            (name: "Blue", created: 3, order: 3, colour: "blue"),
            (name: "Teal", created: 4, order: 4, colour: "aqua"),
            (name: "Green", created: 5, order: 5, colour: "green"),
            (name: "Yellow", created: 6, order: 6, colour: "yellow"),
            (name: "Orange", created: 7, order: 7, colour: "orange"),
            (name: "Red", created: 8, order: 8, colour: "red"),
        ])
        CategoryOrdering.arrange(made, by: .colour, figures: Self.noFigures)
        #expect(Self.byOrder(made) == ["Red", "Orange", "Yellow", "Green", "Teal", "Blue", "Purple", "Pink", "None"])
    }

    @Test func nameSortsAToZ() throws {
        let (_, made) = try Self.categories([
            (name: "bills 10", created: 0, order: 0, colour: "blue"),
            (name: "Zoo", created: 1, order: 1, colour: "blue"),
            (name: "bills 2", created: 2, order: 2, colour: "blue"),
            (name: "Apple", created: 3, order: 3, colour: "blue"),
        ])
        CategoryOrdering.arrange(made, by: .name, figures: Self.noFigures)
        #expect(Self.byOrder(made) == ["Apple", "bills 2", "bills 10", "Zoo"])
    }

    @Test func costSortsMostFirst() throws {
        let (_, made) = try Self.categories([
            (name: "A", created: 0, order: 0, colour: "blue"),
            (name: "B", created: 1, order: 1, colour: "blue"),
            (name: "C", created: 2, order: 2, colour: "blue"),
        ])
        let figures = [made[0].id: (bills: 1, monthly: Decimal(10)), made[1].id: (bills: 1, monthly: Decimal(300))]
        CategoryOrdering.arrange(made, by: .monthlyCost, figures: figures)
        // C has no figures, so it costs nothing and goes last.
        #expect(Self.byOrder(made) == ["B", "A", "C"])
    }

    @Test func countSortsMostFirst() throws {
        let (_, made) = try Self.categories([
            (name: "A", created: 0, order: 0, colour: "blue"),
            (name: "B", created: 1, order: 1, colour: "blue"),
            (name: "C", created: 2, order: 2, colour: "blue"),
        ])
        let figures = [
            made[0].id: (bills: 1, monthly: Decimal(900)),
            made[1].id: (bills: 4, monthly: Decimal(5)),
            made[2].id: (bills: 2, monthly: Decimal(5)),
        ]
        CategoryOrdering.arrange(made, by: .billCount, figures: figures)
        #expect(Self.byOrder(made) == ["B", "C", "A"])
    }

    @Test func tiesFallBackToName() throws {
        let (_, made) = try Self.categories([
            (name: "Mango", created: 0, order: 0, colour: "red"),
            (name: "Cherry", created: 1, order: 1, colour: "red"),
            (name: "Lime", created: 2, order: 2, colour: "green"),
            (name: "Apple", created: 3, order: 3, colour: "red"),
        ])
        CategoryOrdering.arrange(made, by: .colour, figures: Self.noFigures)
        #expect(Self.byOrder(made) == ["Apple", "Cherry", "Mango", "Lime"])

        let same = Dictionary(uniqueKeysWithValues: made.map { ($0.id, (bills: 2, monthly: Decimal(50))) })
        CategoryOrdering.arrange(made, by: .billCount, figures: same)
        #expect(Self.byOrder(made) == ["Apple", "Cherry", "Lime", "Mango"])
    }

    @Test func restorePutsTheOrderBack() throws {
        let (_, made) = try Self.categories([
            (name: "C", created: 0, order: 0, colour: "blue"),
            (name: "A", created: 1, order: 1, colour: "blue"),
            (name: "B", created: 2, order: 2, colour: "blue"),
        ])
        let before = CategoryOrdering.arrange(made, by: .name, figures: Self.noFigures)
        #expect(Self.byOrder(made) == ["A", "B", "C"])
        #expect(before == [made[0].id, made[1].id, made[2].id])
        CategoryOrdering.restore(made, order: before)
        #expect(Self.byOrder(made) == ["C", "A", "B"])
        #expect(made.map(\.sortOrder).sorted() == [0, 1, 2])
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
