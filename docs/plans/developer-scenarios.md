# Developer scenarios — implementation plan

**Brief:** none. Scoped in conversation: a debug-only panel in Settings that switches the app
between the person's own data and a set of sample scenarios, for testing on a phone.
**Settled by:** "The timeline is the only screen, and everything else is a sheet" in
`DECISIONS.md` (the panel lives in the Settings sheet); "Your place survives" in `DESIGN.md`.

## Already decided — do not reopen

- **Debug builds only.** Everything here sits inside `#if DEBUG`, as `PreviewData` does. A
  Release build contains no scenario code and no Developer section.
- **Sample data never touches the person's data.** Scenarios load into their own
  **in-memory** store. The person's persistent store is created once per launch and kept;
  switching back to "Your data" returns to it unchanged.
- **A scenario reseeds from scratch whenever it loads**: when picked, when reset, and on every
  launch while it is the active scenario. Edits made inside a scenario last until then. This is
  what keeps scenarios repeatable, and it is why an in-memory store is enough.
- **The saved scroll place is kept per side.** Your data uses `UserDefaults.standard`, as now.
  Scenarios share one place in their own suite, cleared whenever a scenario loads, so each one
  starts from first-run positioning and a relaunch restores within it.
- **The active scenario survives relaunch**, stored in `UserDefaults.standard`. An unknown
  stored value means "Your data".
- **Loading rebuilds the whole timeline** (`.id` on `TimelineView`), which also closes the
  Settings sheet. No confirmation: nothing the person owns is at risk.
- Scenario names and order: Your data, Empty, One expense, Typical year, Long history, Nothing
  charged yet. Sample content is invented, like `PreviewData`.

## Model routing

All three steps prove themselves by tests and a look at the screen, with no scroll geometry
involved: **Sonnet**.

## Steps

### Step 1 — Scenarios that seed a store

**Files:** `Tilly/Developer/DeveloperScenario.swift` (new); `Tilly/DesignSystem/PreviewData.swift`
(modified); `TillyTests/DeveloperScenarioTests.swift` (new)

**Interface:**
```swift
#if DEBUG
enum DeveloperScenario: String, CaseIterable, Identifiable, Sendable {
    case yourData, empty, oneExpense, typicalYear, longHistory, nothingChargedYet
    var id: String { rawValue }
    var title: String            // "Your data", "Empty", "One expense", "Typical year",
                                 // "Long history", "Nothing charged yet"
    var isSample: Bool { self != .yourData }
    /// Inserts this scenario's data and saves. `.yourData` and `.empty` insert nothing.
    func seed(into context: ModelContext, today: Date, calendar: Calendar) throws
}
#endif

// PreviewData gains a parameter; existing callers keep their behaviour through the default.
static func insert(into context: ModelContext, today: Date, calendar: Calendar, historyMonths: Int = 6) throws
```
- `historyMonths` replaces the literal 6 in every `monthOffset: -6`, and the car insurance's
  `-9` becomes `-(historyMonths + 3)`. Nothing else in `PreviewData` changes.
- **oneExpense:** category "Subscriptions" 📺, and "Music", 15, monthly, anchored on `today`.
- **typicalYear:** `PreviewData.insert(…)` with the default.
- **longHistory:** `PreviewData.insert(…, historyMonths: 36)`.
- **nothingChargedYet:** category "Home" 🏠, and two monthly expenses anchored on
  `today + 2 days` ("Internet", 30) and `today + 5 days` ("Water", 45), by `Calendar` date
  arithmetic. No history.

**Done when:** these pass, each against an in-memory `TillyStore.container(inMemory: true)`
with a fixed `today` (2026-09-19) and a Gregorian calendar:
- `emptyInsertsNothing`: 0 expenses, 0 categories
- `yourDataInsertsNothing`: 0 expenses, 0 categories
- `oneExpenseInsertsOneOfEach`: 1 expense, 1 category, anchored on `today`
- `typicalYearMatchesPreviewData`: 9 expenses, 6 categories, floor = `today`'s month − 9
- `longHistoryReachesBackThreeYears`: 9 expenses, floor = `today`'s month − 39
- `nothingChargedYetHasNoChargedEntryThisMonth`: the current month built by `TimelineBuilder`
  has no charged entry
- `titlesAreInOrder`: `allCases.map(\.title)` equals the list above

**Verify:** `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test`

**Out of scope:** any UI, any container switching.

### Step 2 — A session that owns the store and the saved place

Needs step 1's `DeveloperScenario`.

**Files:** `Tilly/Developer/DeveloperSession.swift` (new); `Tilly/Timeline/TimelinePlace.swift`,
`Tilly/Timeline/TimelineView.swift`, `Tilly/TillyApp.swift` (modified);
`TillyTests/DeveloperSessionTests.swift` (new)

**Interface:**
```swift
// TimelinePlace.swift, not DEBUG-only: TimelineView reads its place store from the
// environment instead of constructing one.
extension EnvironmentValues {
    @Entry var timelinePlaceStore = TimelinePlaceStore()
}

#if DEBUG
@MainActor @Observable
final class DeveloperSession {
    private(set) var scenario: DeveloperScenario
    private(set) var container: ModelContainer
    private(set) var placeStore: TimelinePlaceStore
    /// Changes on every load, so the timeline can be rebuilt from scratch.
    private(set) var generation: Int

    init(
        defaults: UserDefaults = .standard,
        sandboxDefaults: UserDefaults = UserDefaults(suiteName: "com.jdragash.Tilly.sandbox")!,
        persistentContainer: @escaping () throws -> ModelContainer = { try TillyStore.container() },
        today: @escaping () -> Date = Date.init,
        calendar: Calendar = .current
    )

    /// Switches to `scenario` (or reseeds it if it is already active) and bumps `generation`.
    func load(_ scenario: DeveloperScenario)
    /// Clears the active side's saved place, without reloading.
    func forgetPlace()
}
#endif
```
- `init` reads the stored scenario (key `"tillyDeveloperScenario"`) and builds that side
  exactly as `load` does, **except** that it keeps the sandbox's saved place, so a relaunch
  restores within a scenario.
- The persistent container is created at most once per session and reused. A sample scenario
  gets a fresh `TillyStore.container(inMemory: true)`, seeded with `today()`.
- `TimelineView`: `private let placeStore = TimelinePlaceStore()` becomes
  `@Environment(\.timelinePlaceStore) private var placeStore`. Nothing else in it changes.
- `TillyApp`: in DEBUG it owns `@State private var session = DeveloperSession()` and applies
  `.id(session.generation)`, `.environment(session)`,
  `.environment(\.timelinePlaceStore, session.placeStore)` and
  `.modelContainer(session.container)` to `TimelineView`. In Release it is unchanged. Failure
  to create a container stays the existing `fatalError`.

**Done when:** these pass. Each uses throwaway `UserDefaults` suites (removed after) and an
in-memory stand-in for the persistent container:
- `startsOnYourDataByDefault`
- `unknownStoredScenarioMeansYourData`
- `loadingASampleSeedsAFreshStoreAndPersistsTheChoice`
- `returningToYourDataReusesTheSamePersistentContainer`: the same instance, created once
- `reloadingTheSameScenarioReseedsAndBumpsGeneration`: an expense deleted in the scenario
  comes back
- `loadingASampleClearsTheSandboxPlace`
- `relaunchInASampleKeepsTheSandboxPlace`: a second `DeveloperSession` on the same suites
- `sandboxPlaceNeverTouchesYourPlace`

**Verify:** the step 1 command, then launch in the simulator: still on your data, unchanged.

**Out of scope:** the Settings UI.

### Step 3 — The Developer section in Settings

Needs step 2's `DeveloperSession`.

**Files:** `Tilly/Developer/DeveloperSection.swift` (new); `Tilly/Settings/SettingsSheet.swift`
(modified)

**Interface:**
```swift
#if DEBUG
struct DeveloperSection: View {
    let session: DeveloperSession
}
#endif
```
- `SettingsSheet` reads `@Environment(DeveloperSession.self) private var session: DeveloperSession?`
  inside `#if DEBUG`, and adds `DeveloperSection` as the last section when it's non-nil. Its
  previews keep working without one.
- A stock `Section` headed "Developer":
  - an inline `Picker` over `DeveloperScenario.allCases` by `title`, whose selection calls
    `session.load(_:)`
  - "Reset scenario", shown only while a sample is active, calling `session.load(session.scenario)`
  - "Forget my place", calling `session.forgetPlace()`
  - footer: "Only in builds run from Xcode. Sample data lives in its own store; your data is
    never touched."
- Stock controls throughout, so no new tokens.

**Done when:** the suite passes; the Release build compiles
(`xcodebuild -scheme Tilly -configuration Release -destination 'generic/platform=iOS Simulator' build`)
and contains no Developer section; and in the simulator, with real taps: every scenario loads
and shows what it should; Your data comes back unchanged afterwards; an expense added inside a
scenario is gone after Reset; relaunching inside Typical year stays in it and restores its
place; and Forget my place followed by a relaunch lands on the current month.

**Verify:** the step 1 command, the Release build above, then the simulator checks.

**Out of scope:** any other setting; changing sample content beyond step 1.

## Lessons

- **Step 3:** releasing a `ModelContainer` while a view still shows its models is fatal. Switching
  from one sample to another with Settings open crashed ("This model instance was destroyed"):
  the sheet re-rendered the old scenario's categories for a frame after the old in-memory store
  had gone. `DeveloperSession` keeps the outgoing container alive until the next load, and
  `modelsFromTheOutgoingScenarioStayReadableAfterALoad` reproduces the crash without the fix.
  Empty → anything never showed it, because Empty has no categories on screen.
- **Step 3:** the simulator stopped rendering twice during checks (`captureFailed`, and
  `simctl launch` and `simctl io screenshot` hung) while every process sat at 0% CPU. A
  shutdown and boot of the device cleared it the first time.

## If a step is wrong

These specs were written before the code existed. If a step turns out to be
ambiguous, impossible, or wrong, **stop and say so** — don't improvise a fix and
don't silently widen the scope. A wrong spec caught in one message costs far less
than a wrong spec followed to completion.
