#if DEBUG
import Foundation
import Observation
import SwiftData

/// Which store the app is showing: the person's own, or a sample scenario seeded fresh into
/// memory. Owned by `TillyApp` in debug builds; see `docs/plans/developer-scenarios.md`.
///
/// The two sides keep separate saved places, so scrolling around sample data never moves the
/// person's own place. A sample's place is cleared whenever it loads, so each one starts from
/// first-run positioning, and kept across a relaunch, so a relaunch can be tested inside it.
@MainActor @Observable
final class DeveloperSession {
    private(set) var scenario: DeveloperScenario
    private(set) var container: ModelContainer
    private(set) var placeStore: TimelinePlaceStore
    /// Changes on every load, so the timeline can be rebuilt from scratch.
    private(set) var generation = 0

    private static let scenarioKey = "tillyDeveloperScenario"

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let sandboxDefaults: UserDefaults
    @ObservationIgnored private let makePersistentContainer: () throws -> ModelContainer
    @ObservationIgnored private let today: () -> Date
    @ObservationIgnored private let calendar: Calendar
    /// Created at most once, the first time "Your data" is shown, and reused after that.
    @ObservationIgnored private var persistentContainer: ModelContainer?
    /// The store being replaced, kept alive until the next load. Views still showing it (the
    /// Settings sheet, as the timeline rebuilds) read its models for a frame after a load, and
    /// SwiftData crashes on a read from a store that has been released.
    @ObservationIgnored private var outgoingContainer: ModelContainer?

    init(
        defaults: UserDefaults = .standard,
        sandboxDefaults: UserDefaults = UserDefaults(suiteName: "com.jdragash.Tilly.sandbox")!,
        persistentContainer: @escaping () throws -> ModelContainer = { try TillyStore.container() },
        today: @escaping () -> Date = Date.init,
        calendar: Calendar = .current
    ) {
        self.defaults = defaults
        self.sandboxDefaults = sandboxDefaults
        self.makePersistentContainer = persistentContainer
        self.today = today
        self.calendar = calendar

        let stored = defaults.string(forKey: Self.scenarioKey).flatMap(DeveloperScenario.init(rawValue:))
        let scenario = stored ?? .yourData
        self.scenario = scenario
        // Placeholders, replaced straight away by `build`; stored properties must all be set
        // before `self` can be used.
        self.container = try! TillyStore.container(inMemory: true)
        self.placeStore = TimelinePlaceStore(defaults: defaults)
        build(scenario)
    }

    /// Switches to `scenario`, or reseeds it if it is already active, and bumps `generation`.
    func load(_ scenario: DeveloperScenario) {
        self.scenario = scenario
        defaults.set(scenario.rawValue, forKey: Self.scenarioKey)
        if scenario.isSample { TimelinePlaceStore(defaults: sandboxDefaults).clear() }
        outgoingContainer = container
        build(scenario)
        generation += 1
    }

    /// Clears the active side's saved place and rebuilds the timeline, which lands where a first
    /// run does, without reseeding anything. The rebuild is what makes it stick: left where it
    /// was, the timeline saved that place again the moment the app was backgrounded, so a
    /// relaunch returned to it as if nothing was forgotten.
    func forgetPlace() {
        placeStore.clear()
        generation += 1
    }

    private func build(_ scenario: DeveloperScenario) {
        do {
            if scenario.isSample {
                let sample = try TillyStore.container(inMemory: true)
                try scenario.seed(into: sample.mainContext, today: today(), calendar: calendar)
                container = sample
                placeStore = TimelinePlaceStore(defaults: sandboxDefaults)
            } else {
                if persistentContainer == nil { persistentContainer = try makePersistentContainer() }
                container = persistentContainer!
                placeStore = TimelinePlaceStore(defaults: defaults)
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
#endif
