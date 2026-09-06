# App scaffolding — implementation plan

**Brief:** `docs/briefs/timeline/brief.md` — its "Technical" constraint and the three
scaffolding items listed under **In**. This plan carves those out so the timeline's own plan
covers only the screen.

**Decisions:** "Core is a Swift package, not a folder in the app target"; "Stock SwiftUI in
v1, behind a token layer from day one"; "Occurrences are computed, never stored"; "The
occurrence window means effective dates" — all in `docs/DECISIONS.md`.

Creates the Xcode project, the app and test targets, the SwiftData model layer and its
mapping to `TillyCore`, and `DesignSystem/Tokens.swift`. No timeline, no editor, no
categories.

---

## Environment, confirmed 2026-09-06

Checked on this machine rather than assumed:

- Xcode 26.6 (build 17F113), iOS SDK 26.5, simulator SDK 26.5
- Swift 6.3.3
- `iPhone 17` simulator exists, so the brief's verify command is valid as written
- **No `xcodegen`, no `tuist`**, and no Xcode CLI creates a project

---

## Already decided — do not reopen

- **`Core/` stays a separate package.** The app links `TillyCore` as a *local* package
  reference. Nothing from `Core/Sources/` is copied into the app target.
- **`TillyCore` never learns about SwiftData.** Mapping goes one way: app model → engine
  value type, at the app-side boundary. No step adds an import to `Core/`.
- **Views reference `Tokens` only.** Enforced per step, not deferred to review — see Step 2.
- **Models are CloudKit-shaped even though sync is off.** Every stored property is optional
  or has a default, no `@Attribute(.unique)` anywhere, every relationship optional.
- **Dates through `Calendar` components.** Applies to the app layer too, including tests.
- **Swift Testing**, not XCTest, in the app test target as well as the engine's.

---

## Decisions this plan makes

These were open. Each is settled here so no step has to stop and ask; each is reversible if
Jake disagrees, and the first one should be recorded in `DECISIONS.md` by `tilly-ship`.

### The project file is authored by hand, once

`CLAUDE.md` says "Don't hand-edit `.pbxproj`". That rule exists so **routine file additions**
never require project-file surgery — and authoring the project once, correctly, with
file-system synchronized groups is precisely what makes that rule true forever after.
Nothing in the plan edits the `.pbxproj` again.

What makes this tractable rather than reckless: with `PBXFileSystemSynchronizedRootGroup`,
the project file contains **no per-file references at all**. It is a fixed ~380-line skeleton
of targets, phases and build settings, and it does not grow as the app does.

**Verified, not assumed.** Two complete probes of this exact structure were built and run in a
scratch directory before this plan was finished, then deleted. Between them they established:

- The local package resolves as `TillyCore @ local`, and
  `xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test`
  returns `** TEST SUCCEEDED **`.
- A new `.swift` file in a **newly created nested directory** compiles into both targets with
  the `.pbxproj` **byte-identical** before and after — the synchronized-groups guarantee,
  tested rather than trusted.
- The real model layer of Step 3 builds and passes all its named tests under
  `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, including the end-to-end case that drives
  `RecurrenceEngine` from stored rows.
- The app **installs, launches and renders** in the iPhone 17 simulator, with a live on-disk
  SwiftData store behind a real `@Query`, drawn entirely through `Tokens`.
- The Debug build emits `Tilly.app/Tilly.debug.dylib`, so Xcode's preview machinery has what
  it needs.

**One thing that remains unverified, stated plainly:** the SwiftUI canvas actually rendering.
That needs Xcode.app open and cannot be driven from the command line. Everything previews
*depend* on is confirmed — `ENABLE_PREVIEWS`, the debug dylib, a building scheme, and a
preview that supplies its own container. If the canvas still misbehaves, that is a finding to
report, not to work around.

The traps both probes hit are written into the steps below.

*Rejected — create it in Xcode's GUI.* Produces a guaranteed-canonical file, but costs Jake a
wizard run that can't be specified or verified in advance, and the template emits extras
(asset catalog, sample content, sometimes an XCTest target) that then need removing. The
probe removes the only real argument for it, which was risk.

*Rejected — XcodeGen or Tuist.* Neither is installed, both are third-party build tooling in a
project whose stated point is learning iOS properly, and both introduce a second source of
truth for the project — a `project.yml` that has to stay in step with the thing it generates.

### The model layer is `Expense` and `OverrideRecord`, and nothing else

No `Category` model. Categories are their own roadmap item with their own brief still to
come, and the timeline brief puts them explicitly out of scope. Adding the model now is
guessing at a shape nothing consumes. Nothing is lost by waiting: v1 has not shipped, so
there is no store to migrate, and CloudKit compatibility already forces the relationship to
be optional whenever it does arrive.

### The persisted override type is named `OverrideRecord`

`TillyCore` already exports `OccurrenceOverride`. Two types with the same name in one file,
separated only by module qualification, is a footgun for no gain. `OverrideRecord` says "the
stored one" and never collides — in the compiler or in a reader's head.

### The recurrence unit is stored as its raw `String`

`recurrenceUnitRaw: String`, with a computed `recurrenceUnit: RecurrenceUnit` reading it. A
plain `String` attribute is trivially CloudKit-safe, readable in the store, and usable in a
`#Predicate` later. Storing the enum directly would go through `Codable` into an opaque blob.

### Mapping to the engine is total — it never returns `nil`

Every stored `Expense` yields an `ExpenseSnapshot`. An unrecognised `recurrenceUnitRaw`
falls back to `.month`; a nonsense `recurrenceInterval` is already clamped by
`RecurrenceRule.init`. A bill that quietly vanishes from the timeline is a worse failure than
a bill shown with a defaulted unit, because the first is invisible and the second is
obvious. Step 3 names a test for exactly this.

### iPhone only, portrait only

`TARGETED_DEVICE_FAMILY = 1` and portrait-only orientation. Landscape on a vertical timeline
is its own layout question and nothing needs it yet. Both are one-line reversals in the
project file if that changes.

---

## Steps

### Step 1 — Create the Xcode project, both targets, and the shared scheme

**Files:**
- `Tilly.xcodeproj/project.pbxproj` (new)
- `Tilly.xcodeproj/xcshareddata/xcschemes/Tilly.xcscheme` (new)
- `Tilly/TillyApp.swift` (new)
- `Tilly/RootView.swift` (new)
- `TillyTests/ScaffoldTests.swift` (new)
- `.gitignore` (modified)

**Layout.** Two synchronized root groups at the repo root, alongside the existing `Core/`:

```
Tilly.xcodeproj/
Tilly/          → app target sources     (synchronized root group)
TillyTests/     → test target sources    (synchronized root group)
Core/           → unchanged, linked as a local package
```

**Project file — required structure.** `objectVersion = 77`,
`preferredProjectObjectVersion = 77`. Objects needed, and no others:

| Object | Count | Notes |
|---|---|---|
| `PBXProject` | 1 | `mainGroup`, `productRefGroup`, `packageReferences`, both targets |
| `PBXNativeTarget` | 2 | app (`com.apple.product-type.application`), tests (`com.apple.product-type.bundle.unit-test`) |
| `PBXFileSystemSynchronizedRootGroup` | 2 | `path = Tilly` and `path = TillyTests`; each named in its target's `fileSystemSynchronizedGroups` |
| `PBXGroup` | 2 | root group, and `Products` |
| `PBXFileReference` | 2 | `Tilly.app`, `TillyTests.xctest`, both `sourceTree = BUILT_PRODUCTS_DIR` |
| `PBXSourcesBuildPhase` | 2 | **`files = ()` in both** — synchronized groups supply the sources |
| `PBXFrameworksBuildPhase` | 2 | app's holds the one `PBXBuildFile` for `TillyCore` |
| `PBXResourcesBuildPhase` | 2 | empty |
| `PBXTargetDependency` + `PBXContainerItemProxy` | 1 each | tests depend on app |
| `XCLocalSwiftPackageReference` | 1 | `relativePath = Core` |
| `XCSwiftPackageProductDependency` | 1 | `productName = TillyCore`, in the app target's `packageProductDependencies` |
| `XCConfigurationList` + `XCBuildConfiguration` | 3 + 6 | Debug/Release at project level and per target |

Object IDs are 24 uppercase hex characters and must be unique; a fixed
`1A` + zero-padded counter scheme is fine and keeps the file readable.

**Build settings that carry meaning** (the rest are Xcode's ordinary defaults):

| Setting | Value | Why |
|---|---|---|
| `IPHONEOS_DEPLOYMENT_TARGET` | `26.0` | `CLAUDE.md` |
| `SWIFT_VERSION` | `6.0` | `CLAUDE.md` |
| `SDKROOT` | `iphoneos` | |
| `TARGETED_DEVICE_FAMILY` | `1` | iPhone only — decided above |
| `INFOPLIST_KEY_UISupportedInterfaceOrientations` | `UIInterfaceOrientationPortrait` | portrait only — decided above |
| `GENERATE_INFOPLIST_FILE` | `YES` | no `Info.plist` file to maintain |
| `INFOPLIST_KEY_UIApplicationSceneManifest_Generation` | `YES` | SwiftUI lifecycle |
| `PRODUCT_BUNDLE_IDENTIFIER` | `com.jdragash.Tilly` / `com.jdragash.TillyTests` | matches the already-public GitHub handle; discloses nothing new |
| `TEST_HOST` | `$(BUILT_PRODUCTS_DIR)/Tilly.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Tilly` | test target only |
| `BUNDLE_LOADER` | `$(TEST_HOST)` | test target only |
| `ENABLE_TESTABILITY` | `YES` (Debug) | `@testable import Tilly` |
| **`ENABLE_PREVIEWS`** | **`YES`** (app target) | **Xcode canvas previews. Easy to omit and the omission is silent** |
| **`SWIFT_DEFAULT_ACTOR_ISOLATION`** | **`MainActor`** (both targets) | **what Xcode 26's own App template sets; without it Swift 6 concurrency behaves differently from every tutorial and sample Jake will read** |
| `SWIFT_APPROACHABLE_CONCURRENCY` | `YES` (project) | template default; softens Swift 6 concurrency diagnostics |
| `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` | `YES` (project) | template default |
| `LOCALIZATION_PREFERS_STRING_CATALOGS` | `YES` (project) | template default |
| `STRING_CATALOG_GENERATE_SYMBOLS` | `NO` (test target) | template default |

**These were taken from Xcode 26.6's own templates, not from memory** — read out of
`Templates/Project Templates/Base/{App Base, SwiftUI App Base, Base_ProjectSettings,
Unit Testing Bundle Base}.xctemplate/TemplateInfo.plist` inside the Xcode bundle. The point
of a hand-authored project is that it behaves like an ordinary one; taking the settings from
the source Xcode itself uses is what makes that true rather than hoped for.

`ENABLE_DEBUG_DYLIB` needs no entry — it defaults to `YES` for app targets. Confirmed
resolved and confirmed working: the Debug build emits `Tilly.app/Tilly.debug.dylib`, which is
the mechanism Xcode 16+ previews actually execute against.

Do **not** set `ASSETCATALOG_COMPILER_APPICON_NAME` or
`ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME`. There is no asset catalog yet and a
setting pointing at a catalog that doesn't exist is a dangling reference. The app icon and
accent colour belong to the v2 design pass.

**Three traps, all hit during the probe:**

1. **An empty `<TestPlans></TestPlans>` element in the scheme breaks the test action.** It
   puts the scheme into test-plan mode with zero plans, and `xcodebuild` fails with
   `Scheme Tilly is not currently configured for the test action` — which reads like a
   missing `Testables` entry and isn't. Omit the element entirely and list the test target
   under `<Testables>`.
2. **The scheme must be in `xcshareddata`, not `xcuserdata`.** `xcuserdata` is gitignored, so
   a scheme written there works on this machine and fails everywhere else, including CI.
   `BlueprintIdentifier` in each `BuildableReference` must be the target's 24-character
   object ID from the project file.
3. **`.gitignore` does not currently cover the workspace Xcode will create inside the
   project.** `*.xcworkspace/xcuserdata/` is anchored to the repo root and does not match
   `Tilly.xcodeproj/project.xcworkspace/xcuserdata/`. On a public repo that means Jake's
   local editor state gets published. Add:

   ```
   **/xcuserdata/
   Tilly.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist
   ```

   `xcodebuild` alone creates neither; opening the project in Xcode.app creates both.

**Source files — deliberately bare at this step.** `TillyApp.swift` is an `@main` `App` with
a `WindowGroup` containing `RootView()`, and **no** `modelContainer` yet (Step 3 adds it).
`RootView` is `Text("Tilly")` with no modifiers at all — not styled, not padded. This is not
laziness: `Tokens` does not exist until Step 2, and a view carrying raw values, even for one
step, is the exact seam the token rule exists to protect. A view with no modifiers contains
no values to be raw.

`ScaffoldTests.swift` holds one test proving the harness runs and the package is linked.

**Done when:**
- `xcodebuild -list -project Tilly.xcodeproj` lists targets `Tilly` and `TillyTests`, and
  reports `TillyCore: <repo>/Core @ local` under resolved source packages
- `tillyCoreIsLinked` — constructs a `RecurrenceRule(interval: 0, unit: .month, anchorDate:)`
  and expects `interval == 1`. Trivial, but it fails to compile unless `import TillyCore`
  resolves, which is the thing being proved
- The full test command reports `** TEST SUCCEEDED **`
- `git status --porcelain` shows no `xcuserdata` path

**Verify:**
```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test
```
Report the actual tail of the output, including the test count.

**Out of scope:** every model type, `Tokens`, the model container, any styling, asset
catalogs, app icons, launch screens, UI tests, CI configuration.

---

### Step 2 — `DesignSystem/Tokens.swift`, and the root view using it

**Depends on:** Step 1.

**Files:**
- `Tilly/DesignSystem/Tokens.swift` (new)
- `Tilly/RootView.swift` (modified — replaces the bare `Text` from Step 1)

**Interface:**
```swift
import SwiftUI

enum Tokens {
    enum Text {
        static let amount: Font
        static let body: Font
        static let caption: Font
    }
    enum Ink {
        static let primary: Color
        static let secondary: Color
    }
    enum Surface {
        static let base: Color
    }
}
```

Every value aliases a system one — `.largeTitle`, `.body`, `.footnote`, `.primary`,
`.secondary`, `Color(.systemBackground)`. That is the whole point of v1's token layer: the
system supplies Liquid Glass, Dynamic Type, dark mode and VoiceOver correctly, and the
indirection makes swapping it later a one-file change.

**Why this set and no more.** It is what `DESIGN.md` names, plus foreground colours, which
any view needs and which cannot live under `Text` because that holds fonts. No spacing scale,
no radii, no semantic state colours. The timeline hasn't been explored yet, so inventing
those now means inventing a design system ahead of the design — which is the thing v1
explicitly defers. Tokens get added by the step that first needs them.

`Tokens.Text` keeps the name `DESIGN.md` prints. An earlier draft of this plan warned that it
shadows SwiftUI's `Text`; **that warning was wrong and has been removed.** Because the type is
nested inside `enum Tokens`, it is only reachable as `Tokens.Text`, so a bare `Text("Tilly")`
in a view resolves to SwiftUI's — verified by compiling exactly that. The name is only
shadowed inside the body of `enum Tokens` itself, where nothing writes `Text` anyway.

`RootView` becomes app name plus a short placeholder line, styled entirely through `Tokens`,
with a `#Preview { RootView() }`. Still no data and no `@Query` — Step 3 adds both, and
changes this preview when it does.

**Done when:**
- Every value in `Tokens.swift` is a system alias; no hex literal, no numeric literal, no
  `Color(red:green:blue:)`
- `RootView` contains no font, colour or size literal — only `Tokens.*`
- The build succeeds and the Step 1 tests still pass

**Verify:**
```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test
```
and, as the seam check `tilly-ship` will repeat:
```
grep -REn '#[0-9A-Fa-f]{6}|Color\(red:|\.font\(\.(largeTitle|title|headline|subheadline|body|callout|footnote|caption)|\.font\(\.system' Tilly --include='*.swift' | grep -v 'DesignSystem/'
```
This must print nothing. A match means a raw value escaped into a view.

**Out of scope:** `DesignSystem/Gallery.swift` — it is its own roadmap line and wants real
components to render. Spacing, corner radii, animation and state-colour tokens. Anything
about how the timeline looks.

---

### Step 3 — SwiftData models, the store, and the boundary into `TillyCore`

**Depends on:** Steps 1 and 2.

**Files:**
- `Tilly/Models/Expense.swift` (new)
- `Tilly/Models/OverrideRecord.swift` (new)
- `Tilly/Models/TillyStore.swift` (new)
- `Tilly/TillyApp.swift` (modified — attaches the container)
- `Tilly/RootView.swift` (modified — shows a count, proving the container is live)
- `TillyTests/ModelLayerTests.swift` (new)

**Interface:**
```swift
@Model
final class Expense {
    var id: UUID = UUID()
    var name: String = ""
    var amount: Decimal?
    var isEstimate: Bool = false
    var isArchived: Bool = false
    var recurrenceInterval: Int = 1
    var recurrenceUnitRaw: String = RecurrenceUnit.month.rawValue
    var anchorDate: Date = Date()
    var endDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \OverrideRecord.expense)
    var overrides: [OverrideRecord]?

    init(
        id: UUID = UUID(),
        name: String = "",
        amount: Decimal? = nil,
        isEstimate: Bool = false,
        isArchived: Bool = false,
        recurrenceInterval: Int = 1,
        recurrenceUnit: RecurrenceUnit = .month,
        anchorDate: Date = Date(),
        endDate: Date? = nil
    )
}

extension Expense {
    var recurrenceUnit: RecurrenceUnit { get }   // falls back to .month
    var rule: RecurrenceRule { get }
    var snapshot: ExpenseSnapshot { get }
    var overrideSnapshots: [OccurrenceOverride] { get }
}

@Model
final class OverrideRecord {
    var scheduledDate: Date = Date()
    var actualAmount: Decimal?
    var movedDate: Date?
    var isSkipped: Bool = false
    var expense: Expense?

    init(
        scheduledDate: Date = Date(),
        actualAmount: Decimal? = nil,
        movedDate: Date? = nil,
        isSkipped: Bool = false,
        expense: Expense? = nil
    )
}

extension OverrideRecord {
    var snapshot: OccurrenceOverride { get }
}

enum TillyStore {
    static let schema: Schema                                  // [Expense, OverrideRecord]
    static func container(inMemory: Bool = false) throws -> ModelContainer
}
```

**Why `anchorDate` defaults to `Date()`.** CloudKit forces a default on every non-optional
property, and a new expense anchored today is harmless. `.distantPast` would be the obvious
alternative and is a trap: the month generator walks forward from the anchor one index at a
time, so a distant-past anchor means hundreds of thousands of iterations before it reaches
this year.

**`overrideSnapshots` returns every override, unfiltered by date, always.** This is not
incidental — it is the caller obligation recorded under "The occurrence window means
effective dates" in `docs/DECISIONS.md`. An override whose `scheduledDate` sits outside the
queried window is exactly the one that moves a bill *into* it, so filtering here would drop
precisely the records that matter, and the resulting month would still look plausible. The
property exists so no call site has to remember this.

**`TillyApp`** builds one `ModelContainer` from `TillyStore.container()` and attaches it with
`.modelContainer(_:)`. A container that cannot be created is unrecoverable — there is no app
without a store — so failing loudly with `fatalError` carrying the underlying error is right
here, and matches what Xcode's own SwiftData template does.

**`RootView`** gains `@Query private var expenses: [Expense]` and renders the count. It is
scaffolding, styled through `Tokens`, and the timeline replaces it.

**The preview must gain a container in the same step, and this is the trap.** `@Query` reads
its `modelContext` from the environment, so the moment `RootView` gains a query, the bare
`#Preview { RootView() }` written in Step 2 stops working — the canvas fails where the app
still runs fine, which makes it look like a preview bug rather than a missing container.
Update it in the same edit:

```swift
#Preview {
    RootView()
        .modelContainer(try! TillyStore.container(inMemory: true))
}
```

The `try!` is deliberate and confined to a preview: a container that cannot be built should
fail the canvas immediately and visibly. `inMemory: true` keeps previews off the real store,
which is also what lets a later preview seed sample rows without touching Jake's data.

**Done when — named cases in `ModelLayerTests`,** using a gregorian calendar pinned to UTC to
match `Core/Tests/TillyCoreTests/OccurrenceTests.swift`, and
`TillyStore.container(inMemory: true)` throughout:

- `defaultInitialisedExpenseInsertsAndFetches` — `Expense()` with no arguments saves and
  reads back. Proves every stored property really has a default, which is the CloudKit shape.
- `expenseRoundTripsEveryField` — name, amount, `isEstimate`, `isArchived`, interval, unit,
  anchor and end date all survive a save/fetch.
- `amountOfNilStaysNil` — a variable bill with no amount does not become zero.
- `snapshotCarriesTheStoredRule` — interval 3, `.month`, a known anchor and end date map onto
  `snapshot.rule` unchanged.
- `unrecognisedUnitFallsBackToMonthRatherThanVanishing` — `recurrenceUnitRaw = "fortnight"`
  yields a snapshot with unit `.month`, and the expense is still returned by a fetch.
- `zeroIntervalClampsThroughToTheRule` — `recurrenceInterval = 0` produces
  `snapshot.rule.interval == 1`, inherited from `RecurrenceRule.init`.
- `overrideSnapshotsIncludeOnesScheduledOutsideAnyWindow` — three overrides on one expense
  with `scheduledDate`s months apart; `overrideSnapshots` returns all three. This is the
  guard for the decision above.
- `expenseWithNoOverridesGivesAnEmptyArrayNotNil` — the optional relationship does not leak.
- `deletingAnExpenseDeletesItsOverrides` — cascade delete leaves no `OverrideRecord` behind.
- `storedDataDrivesTheEngineEndToEnd` — the real proof the boundary works. Store an expense
  anchored 31 Jan 2027, monthly, plus an `OverrideRecord` moving 31 Jan to 2 Feb. Feed
  `snapshot` and `overrideSnapshots` to
  `RecurrenceEngine.occurrences(for:overrides:in:calendar:)` for a 1–28 Feb window. Expect
  the moved occurrence present with `scheduledDate` 31 Jan and `effectiveDate` 2 Feb, and the
  28 Feb occurrence alongside it.

**On CloudKit compatibility, stated honestly:** these tests prove the schema is *valid*, not
that it is CloudKit-valid. That is only checked when a CloudKit container is configured, which
needs entitlements and is v1.1 work. What holds the line until then is the declaration shape —
every property optional or defaulted, no unique constraints, the relationship optional — which
is reviewable by reading the two model files and is what `tilly-ship` should check.

**Verify:**
```
xcodebuild -scheme Tilly -destination 'platform=iOS Simulator,name=iPhone 17' test
```
Report the actual test count and output. Then confirm the engine is untouched:
```
cd Core && swift test
```
This must still report its existing 54 tests passing. Any change to that number means
something in this plan reached into `Core/`, which nothing here should.

Then confirm the app actually runs, since a passing test suite does not prove a launchable
app:

```
xcrun simctl boot 'iPhone 17'; xcrun simctl install 'iPhone 17' "$(find ~/Library/Developer/Xcode/DerivedData/Tilly-*/Build/Products/Debug-iphonesimulator -maxdepth 1 -name Tilly.app | head -1)" && xcrun simctl launch 'iPhone 17' com.jdragash.Tilly
```

Expect the placeholder view rendering the expense count. Screenshot it. Open the project in
Xcode.app once and confirm the `RootView` canvas renders — the one thing the command line
cannot check.

**Out of scope:** a `Category` model. Seed or sample data — the timeline brief puts that with
the timeline. Any query helper that groups occurrences by month, fetches a window, or paginates:
that is the timeline's plan. Migrations. Turning on CloudKit. The expense editor.

---

## What this leaves for the timeline

Stated so its plan doesn't re-derive it: the timeline gets a working app target, a live
`ModelContainer`, `Expense`/`OverrideRecord` with a total mapping into `TillyCore`'s value
types, and a `Tokens` file to extend. It still needs its own seeded sample data, its month
windowing and paging, `DesignSystem/Gallery.swift`, and the design questions its brief lists
as open — the state grammar, the moved-occurrence trace, the reserved look-ahead slot, and the
resting position on first open. None of those are settled here.

## If a step is wrong

These specs were written before the code existed. If a step turns out to be ambiguous,
impossible, or wrong, **stop and say so** — don't improvise a fix and don't silently widen
the scope. A wrong spec caught in one message costs far less than a wrong spec followed to
completion.

The project file in Step 1 is the most likely place for this. It was verified end to end on
this machine on 2026-09-06, but it is a large fixed structure specified in prose, and a
mismatch will surface as an `xcodebuild` error that names something other than the real
cause — trap 1 above is exactly that shape. Report the actual error rather than adjusting
settings until it builds; a project that builds for an unknown reason is worse than one that
doesn't build yet.

The same applies to anything not covered here. A gap is a signal to ask, not licence to decide.
