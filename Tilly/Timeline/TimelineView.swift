import SwiftData
import SwiftUI

/// The timeline: next month always open above, history running continuously below down to
/// the oldest charge entered. See "The timeline is one list you scroll, bounded at both
/// ends" in `docs/DECISIONS.md`.
struct TimelineView: View {
    @Query private var expenses: [Expense]
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    @State private var today = Date()
    @State private var window: TimelineWindow?
    @State private var sections: [MonthKey: MonthSection] = [:]
    @State private var headerOffsets: [MonthKey: CGFloat] = [:]
    @State private var headerHeights: [MonthKey: CGFloat] = [:]
    @State private var viewportHeight: CGFloat = 0
    @State private var scrollProxy: ScrollViewProxy?
    @State private var hasSetRestingPosition = false
    @State private var isUnlockLatched = false
    @State private var isProgrammaticScroll = false
    @State private var scrollOffset: CGFloat = 0
    @State private var restingContentOffset: CGFloat?
    @State private var pillClearance: CGFloat = Tokens.Space.floatingClearance

    private static let scrollSpace = "timelineScroll"

    /// The last month (in top-to-bottom document order) whose header has reached the
    /// container's top edge. Derived fresh from every header's live offset rather than
    /// toggled by a paired on/off event — `LazyVStack` can recycle a header while it's off
    /// screen without ever firing a "no longer pinned" transition for it, which left a stale
    /// entry behind under a set-based, event-driven version of this. A geometry read recomputes
    /// on every layout the header is actually part of, so recycling can't leave it stuck.
    /// `.last` (rather than `.first`) matters too: a single scroll update can cross more than
    /// one month's threshold at once, and the later month in document order is the one that
    /// has actually taken over pinning.
    private var pinnedMonth: MonthKey? {
        visibleMonths.last { (headerOffsets[$0] ?? .infinity) <= 0 }
    }

    /// Months from the top of the window down to the floor, with an empty month dropped
    /// unless it's the current month, the one after, or anything unlocked beyond that — all
    /// of those always render, empty or not, because they're either the month the header
    /// speaks for or a month the reader deliberately opened. See "History stops where your
    /// oldest charge does" in `docs/DESIGN.md`.
    private var visibleMonths: [MonthKey] {
        guard let window else { return [] }
        return window.months.filter { month in
            month >= window.current || !(sections[month]?.isEmpty ?? true)
        }
    }

    /// The month under the middle of the viewport — the one actually being read, and the
    /// only anchor that survives opening or closing a month without visibly moving. The
    /// top-most visible item is wrong (it's the bar about to be tapped, so preserving it
    /// shoves the read month off screen); total content height is wrong too, because one
    /// gesture can add a month at one end and drop one at the other. See "Looking further
    /// ahead is a deliberate unlock" in `docs/DECISIONS.md`.
    private func monthUnderMiddle() -> MonthKey? {
        let middleY = viewportHeight / 2
        return visibleMonths.last { (headerOffsets[$0] ?? .infinity) <= middleY }
    }

    /// Which way `LatestButton` points, and whether it shows at all: absent within a
    /// screenful of the resting position, `.down` above it (the reader is in an unlocked
    /// month ahead), `.up` below it (the reader is back in history). See "Getting back" in
    /// `docs/DESIGN.md`.
    ///
    /// Deliberately not `headerOffsets[window.current]`, the way `updateLatch` reads it —
    /// `LazyVStack` stops laying out (and therefore stops measuring) a header once it is far
    /// enough off screen, which freezes that dictionary entry at whatever it last was.
    /// Confirmed on device: scrolling several months into history left it stuck around
    /// −110pt, well short of a screenful, so a distance check against it never tripped.
    /// `updateLatch` never meets this because an unlocked month is at most a couple of
    /// screens away; a reader can scroll arbitrarily far into history, so this needs a
    /// signal `LazyVStack` can't stop measuring. `scrollOffset` comes straight off the
    /// `ScrollView` itself, which is never recycled, and `restingContentOffset` is a cached
    /// "what `scrollOffset` would be if the current month's header were at the top" —
    /// refreshed whenever that header happens to be mounted, and stable in between because
    /// nothing but an unlock, a close, or a day change moves the current month within the
    /// content.
    private var returnDirection: LatestButton.Direction? {
        guard viewportHeight > 0, let restingContentOffset else { return nil }
        let distance = scrollOffset - restingContentOffset
        if distance > viewportHeight { return .up }
        if distance < -viewportHeight { return .down }
        return nil
    }

    var body: some View {
        GeometryReader { rootProxy in
            content(topInset: rootProxy.safeAreaInsets.top)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { viewportHeight = $0 }
        .onAppear(perform: setUpIfNeeded)
        .onChange(of: expenses) { _, _ in rebuildSections() }
        .onChange(of: sections) { _, _ in restOnCurrentMonthIfNeeded() }
        .onChange(of: headerOffsets) { _, _ in updateLatch() }
    }

    @ViewBuilder
    private func content(topInset: CGFloat) -> some View {
        Group {
            if expenses.isEmpty {
                TimelineEmptyState()
            } else if let window {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            CollapsedMonthBar(section: section(for: window.top.advanced(by: 1)), today: today, open: unlockMonthAbove)
                            ForEach(visibleMonths) { month in
                                let monthSection = section(for: month)
                                Section {
                                    MonthSectionView(
                                        section: monthSection,
                                        showsFirstWeekLine: monthSection.isCurrent && !monthSection.hasChargedEntry
                                    )
                                } header: {
                                    MonthHeader(section: monthSection, today: today, isPinned: pinnedMonth == month)
                                        .onGeometryChange(for: CGRect.self) { proxy in
                                            proxy.frame(in: .named(Self.scrollSpace))
                                        } action: { frame in
                                            headerOffsets[month] = frame.minY
                                            headerHeights[month] = frame.height
                                            if month == window.current {
                                                restingContentOffset = scrollOffset + frame.minY
                                            }
                                        }
                                }
                                .id(month.id)
                            }
                            floorLine(window.floor)
                        }
                        .scrollTargetLayout()
                    }
                    .contentMargins(.bottom, pillClearance, for: .scrollContent)
                    .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, newValue in
                        scrollOffset = newValue
                    }
                    .onAppear { scrollProxy = proxy }
                }
                .coordinateSpace(name: Self.scrollSpace)
                .background(Tokens.Surface.base)
                .overlay(alignment: .bottom) {
                    // Always rendered — never conditionally removed — so its real,
                    // Dynamic-Type-aware height is always available to size
                    // `pillClearance` from, including the very first time the reader
                    // scrolls far enough for it to matter. Visibility is opacity plus
                    // explicit accessibility/hit-testing, not presence in the tree.
                    LatestButton(month: window.current, direction: returnDirection ?? .up, today: today, action: returnToResting)
                        .padding(.bottom, Tokens.Space.section)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                            pillClearance = height + Tokens.Space.section
                        }
                        .opacity(returnDirection == nil ? 0 : 1)
                        .accessibilityHidden(returnDirection == nil)
                        .allowsHitTesting(returnDirection != nil)
                }
                .animation(.easeInOut, value: returnDirection)
                .overlay(alignment: .top) {
                    // A `GeometryReader` nested inside this `.overlay` reports a zero top
                    // inset here — confirmed on device — so the inset is measured once, by
                    // the `GeometryReader` wrapping the whole screen in `body`, and passed
                    // down instead. See "The app fills the top inset; the system draws over
                    // it" in `docs/DECISIONS.md`.
                    Tokens.Surface.base
                        .frame(height: topInset)
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea(edges: .top)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func floorLine(_ month: MonthKey) -> some View {
        Text("Nothing before \(month.name(in: calendar, relativeTo: today, locale: locale)).")
            .font(Tokens.Text.monthTotal)
            .foregroundStyle(Tokens.Ink.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Tokens.Space.gutter * 2)
            .padding(.top, Tokens.Space.section)
    }

    private func section(for month: MonthKey) -> MonthSection {
        // The placeholder shown for a month `rebuildSections()` hasn't populated yet — never
        // the current month's real answer, so `isCurrent: false` here is a deliberate "not
        // known yet", not a claim.
        sections[month] ?? MonthSection(month: month, days: [], total: 0, remaining: 0, isCurrent: false)
    }

    private func setUpIfNeeded() {
        guard window == nil else { return }
        today = Date()
        let current = MonthKey(containing: today, calendar: calendar)
        guard let floor = TimelineFloor.month(for: expenses, calendar: calendar) else { return }
        window = TimelineWindow(floor: floor, current: current)
        rebuildSections()
    }

    /// The list rests flush on the current month: its header at the top of the visible
    /// area, next month above the fold. See "The list rests flush on the current month" in
    /// `docs/plans/timeline.md`.
    ///
    /// Tried and discarded: the newer `ScrollPosition`/`.scrollPosition(_:)` API, called the
    /// same way, produced no visible scroll — a `ScrollViewProxy` from `ScrollViewReader`
    /// does. Deferring with `DispatchQueue.main.async` is load-bearing, not cosmetic: at the
    /// point `sections` first gets the current month, `scrollProxy` is still nil, because
    /// `ScrollViewReader`'s own `onAppear` — which sets it — hasn't run yet. One run-loop
    /// turn is enough for both to be ready; confirmed with logging, not assumed.
    private func restOnCurrentMonthIfNeeded() {
        guard !hasSetRestingPosition, let window, sections[window.current] != nil else { return }
        hasSetRestingPosition = true
        let target = window.current.id
        DispatchQueue.main.async {
            scrollProxy?.scrollTo(target, anchor: .top)
        }
    }

    /// Opens the month named on the unlock bar. See "The anchor" in Step 7 of
    /// `docs/plans/timeline.md`: a screenful of content lands *above* the viewport, so the
    /// month under the middle — not the bar, not total content height — is what has to stay
    /// put.
    private func unlockMonthAbove() {
        guard window != nil, let anchorMonth = monthUnderMiddle() else { return }
        let desiredOffset = headerOffsets[anchorMonth] ?? 0
        window?.unlocked += 1
        rebuildSections()
        anchorAndSettle(anchorMonth, to: desiredOffset)
    }

    /// The tidy-up: unlocked months close once the reader has actually travelled up into
    /// one of them and come back. Two guards make this safe — see "The tidy-up" in Step 7.
    /// `isUnlockLatched` requires the trip up before any close can fire, so this never fires
    /// in the frame a month opens (it opens outside the viewport, which would otherwise read
    /// as "no longer visible" instantly). `isProgrammaticScroll` keeps this from firing while
    /// one of this view's own animated scrolls is still in flight.
    private func updateLatch() {
        guard let window, !isProgrammaticScroll else { return }
        let currentOffset = headerOffsets[window.current] ?? 0
        if !isUnlockLatched {
            if window.unlocked > 0 && currentOffset > viewportHeight {
                isUnlockLatched = true
            }
        } else if currentOffset <= 0 {
            closeUnlockedMonths()
        }
    }

    /// `LatestButton`'s action: animates the reader back to the resting position — the
    /// current month's header at the container's top, the same target
    /// `restOnCurrentMonthIfNeeded` uses — then runs Step 7's tidy-up once that scroll has
    /// actually settled. `isProgrammaticScroll` holds `updateLatch` off for the same reason
    /// it does during `anchorAndSettle`: closing mid-animation would fight the animated
    /// scroll rather than follow it. See "Getting back" in `docs/DESIGN.md`.
    ///
    /// **Not `withAnimation(_:completion:)`.** Tried first, and wrong: confirmed on device
    /// via logging that its completion handler runs before the scroll has visibly moved at
    /// all — `scrollProxy.scrollTo` drives a `UIScrollView` under the hood, which doesn't
    /// report into SwiftUI's animation-completion tracking, so `closeUnlockedMonths` fired
    /// against the pre-scroll geometry and anchored on the unlocked month instead of the
    /// one just settled on. A fixed delay matching `.default`'s duration is what
    /// `anchorAndSettle` already relies on elsewhere in this file for the same reason —
    /// timing-dependent, not sufficient in principle, but held in every trial here too.
    private func returnToResting() {
        guard let window, let scrollProxy else { return }
        isProgrammaticScroll = true
        withAnimation(.default) {
            scrollProxy.scrollTo(window.current.id, anchor: .top)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isProgrammaticScroll = false
            // The reader is now at the resting position by construction, so `scrollOffset`
            // *is* `restingContentOffset`. Saying so is not belt-and-braces: the cache is
            // normally written as `scrollOffset + frame.minY` from two geometry callbacks
            // that arrive independently, and during an animated scroll they are sampled at
            // different instants — measured on device leaving the cache 702, 493 and 0.2
            // points wrong across three otherwise identical returns. The pill hides within
            // one viewport of resting, so an error approaching 778 points would leave it
            // on screen at rest, pointing the wrong way.
            restingContentOffset = scrollOffset
            closeUnlockedMonths()
        }
    }

    private func closeUnlockedMonths() {
        isUnlockLatched = false
        guard let window, window.unlocked > 0 else { return }
        let anchorMonth = monthUnderMiddle() ?? window.current
        let desiredOffset = headerOffsets[anchorMonth] ?? 0
        self.window?.unlocked = 0
        rebuildSections()
        anchorAndSettle(anchorMonth, to: desiredOffset)
    }

    /// Waits a run-loop turn for the resized list to lay out, restores `month`'s position,
    /// and holds off the close-on-scroll-back latch until that restoring scroll has settled
    /// — see "No closing during a programmatic scroll" in Step 7 of
    /// `docs/plans/timeline.md`. Exercised by opening and closing a month directly, and,
    /// via `returnToResting`, by an animated jump back across several unlocked months —
    /// both verified on device in Step 8.
    private func anchorAndSettle(_ month: MonthKey, to desiredOffset: CGFloat) {
        isProgrammaticScroll = true
        DispatchQueue.main.async {
            restoreAnchor(month, to: desiredOffset)
            DispatchQueue.main.async {
                isProgrammaticScroll = false
            }
        }
    }

    /// Places `month`'s top at `desiredOffset` points from the container's top, exactly —
    /// not approximately. `scrollTo(_:anchor:)` aligns the point at fraction `f` within the
    /// target with the point at fraction `f` within the container, so asking for `f = 0`
    /// (`.top`) always lands the target's own top at the container's top, regardless of
    /// either height — that is the one exact primitive available. Solving
    /// `desiredOffset = f × (viewportHeight − targetHeight)` for `f` reuses that same
    /// primitive to place the target's top at an arbitrary offset instead of only zero.
    ///
    /// **The target here is the header, not the section** — measured on device, 2026-09-08.
    /// `.id(_:)` sits on the `Section`, but while `pinnedViews: [.sectionHeaders]` is working,
    /// `scrollTo` resolves that id to the pinned header alone, so `targetHeight` is the
    /// header's 47 points and not the section's several hundred. Passing a section height
    /// here overshoots by a proportion of the difference: the anchor landed 287 points low.
    /// The two facts are coupled, which is why they were mistaken for independent bugs — a
    /// geometry modifier on the `Section` breaks pinning *and* makes `scrollTo` resolve to
    /// the whole section, so a section height is right only while the header is broken.
    ///
    /// A pleasant consequence: `viewportHeight − headerHeight` is a large, stable number, so
    /// `f` stays inside the unit square and the denominator never approaches zero. Both were
    /// live worries while the section's height was in this expression.
    ///
    /// Every value is read live and unrounded — a cached or rounded height was the earlier
    /// version's bug, and it drifted by half a point per gesture.
    private func restoreAnchor(_ month: MonthKey, to desiredOffset: CGFloat) {
        guard let scrollProxy else { return }
        let headerHeight = headerHeights[month] ?? 0
        let denominator = viewportHeight - headerHeight
        guard headerHeight > 0, denominator > 0.5 else {
            scrollProxy.scrollTo(month.id, anchor: .top)
            return
        }
        let fraction = desiredOffset / denominator
        scrollProxy.scrollTo(month.id, anchor: UnitPoint(x: 0.5, y: fraction))
    }

    private func rebuildSections() {
        guard let window else { return }
        let timelineExpenses = expenses.map(\.timelineExpense)

        var result: [MonthKey: MonthSection] = [:]
        var key = window.top.advanced(by: 1) // includes the unlock bar's own month
        while key >= window.floor {
            let built = TimelineBuilder.month(key, expenses: timelineExpenses, today: today, calendar: calendar)
            result[key] = MonthSection(
                month: built.month, days: built.days, total: built.total,
                remaining: built.remaining, isCurrent: key == window.current
            )
            key = key.advanced(by: -1)
        }
        sections = result
    }
}

#Preview("Seeded current month") {
    let container = try! TillyStore.container(inMemory: true)
    try! SampleData.insert(into: container.mainContext, today: Date(), calendar: .current)
    return TimelineView()
        .modelContainer(container)
}

#Preview("Empty state") {
    TimelineView()
        .modelContainer(try! TillyStore.container(inMemory: true))
}

#Preview("Nothing charged yet") {
    let container = try! TillyStore.container(inMemory: true)
    let context = container.mainContext
    let calendar = Calendar.current
    let today = Date()
    let futureAnchor = calendar.date(byAdding: .day, value: 5, to: today)!
    context.insert(Expense(name: "Upcoming bill", amount: 50, anchorDate: futureAnchor))
    try! context.save()
    return TimelineView()
        .modelContainer(container)
}
