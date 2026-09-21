import Foundation
import SwiftData
import Testing
@testable import Tilly

@MainActor @Suite struct DeveloperSessionTests {
    let defaults: UserDefaults
    let sandboxDefaults: UserDefaults
    let names: [String]
    /// Stands in for the person's own store; counts how often it's created.
    final class PersistentStandIn {
        var made = 0
        lazy var container = try! TillyStore.container(inMemory: true)
        func make() -> ModelContainer { made += 1; return container }
    }
    let persistent = PersistentStandIn()

    init() {
        let suffix = UUID().uuidString
        names = ["tilly.test.defaults.\(suffix)", "tilly.test.sandbox.\(suffix)"]
        defaults = UserDefaults(suiteName: names[0])!
        sandboxDefaults = UserDefaults(suiteName: names[1])!
    }

    func makeSession() -> DeveloperSession {
        DeveloperSession(
            defaults: defaults,
            sandboxDefaults: sandboxDefaults,
            persistentContainer: persistent.make,
            today: { Date() },
            calendar: .current
        )
    }

    func cleanUp() {
        names.forEach { UserDefaults.standard.removePersistentDomain(forName: $0) }
    }

    static let place = TimelinePlace(anchorMonthID: 24300, anchorOffset: 12)

    static func expenseCount(in container: ModelContainer) throws -> Int {
        try container.mainContext.fetchCount(FetchDescriptor<Expense>())
    }

    @Test func startsOnYourDataByDefault() {
        defer { cleanUp() }
        let session = makeSession()
        #expect(session.scenario == .yourData)
        #expect(session.container === persistent.container)
    }

    @Test func unknownStoredScenarioMeansYourData() {
        defer { cleanUp() }
        defaults.set("somethingRemoved", forKey: "tillyDeveloperScenario")
        #expect(makeSession().scenario == .yourData)
    }

    @Test func loadingASampleSeedsAFreshStoreAndPersistsTheChoice() throws {
        defer { cleanUp() }
        let session = makeSession()
        session.load(.typicalYear)
        #expect(session.scenario == .typicalYear)
        #expect(session.container !== persistent.container)
        #expect(try Self.expenseCount(in: session.container) == 9)
        #expect(try Self.expenseCount(in: persistent.container) == 0)
        #expect(defaults.string(forKey: "tillyDeveloperScenario") == "typicalYear")
    }

    @Test func returningToYourDataReusesTheSamePersistentContainer() {
        defer { cleanUp() }
        let session = makeSession()
        session.load(.oneExpense)
        session.load(.yourData)
        #expect(session.container === persistent.container)
        #expect(persistent.made == 1)
    }

    @Test func reloadingTheSameScenarioReseedsAndBumpsGeneration() throws {
        defer { cleanUp() }
        let session = makeSession()
        session.load(.oneExpense)
        let generation = session.generation
        let context = session.container.mainContext
        try context.fetch(FetchDescriptor<Expense>()).forEach(context.delete)
        try context.save()
        #expect(try Self.expenseCount(in: session.container) == 0)

        session.load(.oneExpense)
        #expect(try Self.expenseCount(in: session.container) == 1)
        #expect(session.generation == generation + 1)
    }

    @Test func loadingASampleClearsTheSandboxPlace() {
        defer { cleanUp() }
        let session = makeSession()
        session.load(.typicalYear)
        session.placeStore.save(Self.place)
        session.load(.longHistory)
        #expect(session.placeStore.load() == nil)
    }

    @Test func relaunchInASampleKeepsTheSandboxPlace() {
        defer { cleanUp() }
        let session = makeSession()
        session.load(.typicalYear)
        session.placeStore.save(Self.place)

        let relaunched = makeSession()
        #expect(relaunched.scenario == .typicalYear)
        #expect(relaunched.placeStore.load() == Self.place)
    }

    /// Forgetting has to move the timeline too. Left where it was, the place is saved again the
    /// moment the app is backgrounded, and a relaunch returns to it as if nothing was forgotten.
    @Test func forgettingAPlaceRebuildsTheTimeline() {
        defer { cleanUp() }
        let session = makeSession()
        session.load(.typicalYear)
        session.placeStore.save(Self.place)
        let generation = session.generation

        session.forgetPlace()

        #expect(session.placeStore.load() == nil)
        #expect(session.generation == generation + 1)
    }

    @Test func sandboxPlaceNeverTouchesYourPlace() {
        defer { cleanUp() }
        let session = makeSession()
        session.placeStore.save(Self.place)
        session.load(.typicalYear)
        session.placeStore.save(TimelinePlace(anchorMonthID: 24000, anchorOffset: 0))
        session.forgetPlace()
        session.load(.yourData)
        #expect(session.placeStore.load() == Self.place)
    }

    /// A view still showing the outgoing scenario reads its models for a frame after a load.
    /// Releasing that store at once made SwiftData crash on the read.
    @Test func modelsFromTheOutgoingScenarioStayReadableAfterALoad() throws {
        defer { cleanUp() }
        let session = makeSession()
        session.load(.nothingChargedYet)
        let category = try #require(try session.container.mainContext.fetch(FetchDescriptor<ExpenseCategory>()).first)
        session.load(.longHistory)
        #expect(category.name == "Home")
    }
}
