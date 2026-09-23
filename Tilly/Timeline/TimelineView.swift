import SwiftData
import SwiftUI
import os

/// The timeline: months ahead running on above for as long as any bill does, history running
/// continuously below down to the oldest charge entered. See
/// "The timeline is one list, future above and past below, and the future runs five years on" in
/// `docs/DECISIONS.md`.
struct TimelineView: View {
    @Query private var expenses: [Expense]
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.timelinePlaceStore) private var placeStore
    @Environment(\.modelContext) private var modelContext

    @State private var today = Date()
    @State private var window: TimelineWindow?
    @State private var isLastPayment = false
    @State private var sections: [MonthKey: MonthSection] = [:]
    @State private var headerOffsets: [MonthKey: CGFloat] = [:]
    @State private var headerHeights: [MonthKey: CGFloat] = [:]
    @State private var viewportHeight: CGFloat = 0
    @State private var scrollProxy: ScrollViewProxy?
    @State private var hasRestoredPlace = false
    @State private var isProgrammaticScroll = false
    @State private var isScrollHalted = false
    @State private var scrollOffset: CGFloat = 0
    @State private var restingContentOffset: CGFloat?
    @State private var bottomClearance: CGFloat = Tokens.Space.floatingClearance
    @State private var containerHeight: CGFloat = 0
    @State private var currentContentTop: CGFloat?
    @State private var floorLineBottom: CGFloat?
    @State private var floorSpacer: CGFloat = 0
    @State private var isEditorPresented = false
    @State private var isSettingsPresented = false
    @State private var editing: EditSession?

    private static let logger = Logger(subsystem: "com.jdragash.Tilly", category: "TimelineView")
    private static let scrollSpace = "timelineScroll"
    /// The list's own content, which scrolling doesn't move: distances measured here hold
    /// still while the list scrolls.
    private static let contentSpace = "timelineContent"

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

    /// Months from the ceiling down to the floor, with an empty month dropped unless it's the
    /// current month or the one after, which always render, empty or not. See "The future runs
    /// five years ahead, or to your last payment" and "History stops where your oldest charge does" in
    /// `docs/DESIGN.md`.
    private var visibleMonths: [MonthKey] {
        guard let window else { return [] }
        let nextMonth = window.current.advanced(by: 1)
        return window.months.filter { month in
            month == window.current || month == nextMonth || !(sections[month]?.isEmpty ?? true)
        }
    }

    /// The month under the middle of the viewport — the one actually being read, and the
    /// only anchor that survives a month being added or dropped without visibly moving. The
    /// top-most visible item is wrong (preserving it can shove the read month off screen);
    /// total content height is wrong too, because one change can add a month at one end and
    /// drop one at the other. See `.claude/rules/swiftui-scrolling.md`.
    private func monthUnderMiddle() -> MonthKey? {
        let middleY = viewportHeight / 2
        return visibleMonths.last { (headerOffsets[$0] ?? .infinity) <= middleY }
    }

    /// How far the reader has travelled from the resting position: positive below it (back
    /// in history), negative above it (in a month ahead). `nil` until there is enough
    /// geometry to say. It sets how long the month button's return takes.
    ///
    /// Deliberately not `headerOffsets[window.current]` — `LazyVStack` stops laying out (and
    /// therefore stops measuring) a header once it is far enough off screen, which freezes
    /// that dictionary entry at whatever it last was. Confirmed on device: scrolling several
    /// months into history left it stuck around −110pt, well short of a screenful. A reader
    /// can scroll arbitrarily far either way, so this needs a signal `LazyVStack` can't stop
    /// measuring. `scrollOffset` comes straight off the `ScrollView` itself, which is never
    /// recycled, and `restingContentOffset` is a cached "what `scrollOffset` would be if the
    /// current month's header were at the top" — refreshed whenever that header happens to be
    /// mounted, and stable in between because nothing but a day change moves the current
    /// month within the content.
    private var returnDistance: CGFloat? {
        guard viewportHeight > 0, let restingContentOffset else { return nil }
        return scrollOffset - restingContentOffset
    }

    /// How long the return scroll should take, scaled to the distance actually travelled.
    /// `scrollTo` does animate — measured on device, not the snap it looks like — but at
    /// `.default`'s fixed duration a return from deep history covers two thousand points in
    /// under a third of a second, which reads as a jump rather than as travel.
    ///
    /// An unknown distance takes the longest duration, not the shortest. The distance is
    /// unknown exactly when the current month's header has never been laid out — which means
    /// it is far off screen, as after a relaunch two years ahead, where the shortest duration
    /// read as a jump.
    private var returnDuration: TimeInterval {
        guard let distance = returnDistance.map(abs) else { return Tokens.Motion.returnDurationMax }
        let scaled = TimeInterval(distance / Tokens.Motion.returnPointsPerSecond)
        return min(Tokens.Motion.returnDurationMax, max(Tokens.Motion.returnDurationMin, scaled))
    }

    var body: some View {
        GeometryReader { rootProxy in
            content(topInset: rootProxy.safeAreaInsets.top, bottomInset: rootProxy.safeAreaInsets.bottom)
        }
        // A sheet's keyboard shrinks the screen behind it too, and the bottom row rode up
        // behind the editor to sit on the keyboard (measured: y 772 → 418). The timeline has
        // no text field of its own, so it ignores the keyboard whole: ignoring it on the row
        // alone isn't enough, because the row follows the bottom of what it sits in.
        .ignoresSafeArea(.keyboard)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { viewportHeight = $0 }
        .onAppear(perform: setUpIfNeeded)
        .onChange(of: expenses) { _, _ in refreshWindow() }
        .onChange(of: sections) { _, _ in restorePlaceIfNeeded() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active, hasRestoredPlace { saveCurrentPlace() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            handleDayChange()
        }
    }

    @ViewBuilder
    private func content(topInset: CGFloat, bottomInset: CGFloat) -> some View {
        Group {
            if expenses.isEmpty {
                TimelineEmptyState()
            } else if let window {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                            if isLastPayment { ceilingLine(window.ceiling) }
                            ForEach(visibleMonths) { month in
                                let monthSection = section(for: month)
                                Section {
                                    MonthSectionView(
                                        section: monthSection,
                                        showsFirstWeekLine: monthSection.isCurrent && !monthSection.hasChargedEntry,
                                        onOpen: openEntry
                                    )
                                    // The content, not the `Section`: a geometry modifier there
                                    // stops headers pinning. And the content, not the header: a
                                    // pinned header reports 0 however deep into its month you are.
                                    .onGeometryChange(for: CGFloat.self) { proxy in
                                        proxy.frame(in: .named(Self.contentSpace)).minY
                                    } action: { minY in
                                        guard month == window.current else { return }
                                        currentContentTop = minY
                                        updateFloorSpacer()
                                    }
                                } header: {
                                    MonthHeader(section: monthSection, today: today, isPinned: pinnedMonth == month)
                                        .onGeometryChange(for: CGRect.self) { proxy in
                                            proxy.frame(in: .named(Self.scrollSpace))
                                        } action: { frame in
                                            headerOffsets[month] = frame.minY
                                            headerHeights[month] = frame.height
                                            if month == window.current {
                                                restingContentOffset = scrollOffset + frame.minY
                                                updateFloorSpacer()
                                            }
                                        }
                                }
                                .id(month.id)
                            }
                            floorLine(window.floor)
                                .onGeometryChange(for: CGFloat.self) { proxy in
                                    proxy.frame(in: .named(Self.contentSpace)).maxY
                                } action: { maxY in
                                    floorLineBottom = maxY
                                    updateFloorSpacer()
                                }
                            Color.clear.frame(height: floorSpacer)
                        }
                        .coordinateSpace(name: Self.contentSpace)
                        .scrollTargetLayout()
                    }
                    .scrollDisabled(isScrollHalted)
                    .contentMargins(.bottom, bottomClearance, for: .scrollContent)
                    .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, newValue in
                        scrollOffset = newValue
                    }
                    .onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.height } action: { _, newValue in
                        containerHeight = newValue
                        updateFloorSpacer()
                    }
                    .onScrollPhaseChange { _, newPhase in
                        if newPhase == .idle && !isProgrammaticScroll && hasRestoredPlace { saveCurrentPlace() }
                    }
                    .onAppear { scrollProxy = proxy }
                }
                .coordinateSpace(name: Self.scrollSpace)
                .background(Tokens.Surface.base)
                .overlay(alignment: .top) {
                    // A `GeometryReader` nested inside this `.overlay` reports a zero top
                    // inset here — confirmed on device — so the inset is measured once, by
                    // the `GeometryReader` wrapping the whole screen in `body`, and passed
                    // down instead. See "The app fills the top
                    // inset" in `docs/DESIGN.md`.
                    Tokens.Surface.base
                        .frame(height: topInset)
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea(edges: .top)
                        .allowsHitTesting(false)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            // + never moves: it sits in the `headerRow` band where headers pin, and each
            // header hands off beneath it. Over the empty state too, where it's the next step.
            GlassCircleButton(systemImage: "plus", label: "Add an expense") { isEditorPresented = true }
                .frame(height: Tokens.Size.headerRow)
                .padding(.trailing, Tokens.Space.gutter)
        }
        .overlay(alignment: .bottom) { bottomRow(bottomInset: bottomInset) }
        .sheet(isPresented: $isEditorPresented) { ExpenseEditor(today: today) }
        .sheet(isPresented: $isSettingsPresented) { SettingsSheet() }
        // `onDismiss` refreshes explicitly: a save writes an `OverrideRecord` or edits fields
        // on the same `Expense` instances this view already holds, so the in-memory objects
        // are correct the moment the sheet closes, but `@Query`'s own change notification
        // doesn't reliably fire for a relationship-only edit, and `.onChange(of: expenses)`
        // compares the array by model identity, not by the fields within it — so without
        // this, a saved amount left the row showing what it read before the edit, and
        // deleting future charges, which only ends a record, left the months ahead standing.
        .sheet(item: $editing, onDismiss: refreshWindow) { session in
            ExpenseEditor(today: today, session: session)
        }
    }

    /// A row tap builds the session fresh from the store, keyed on what the entry itself
    /// carries — never from `sections`, which is a snapshot rebuilt on every change. See
    /// "Opening a charge edits it" in `docs/DESIGN.md`.
    private func openEntry(_ entry: TimelineEntry) {
        do {
            editing = try EditSession.make(
                expenseID: entry.expenseID, scheduledDate: entry.scheduledDate,
                context: modelContext, calendar: calendar
            )
        } catch {
            Self.logger.error("Opening a charge failed: \(error)")
        }
    }

    /// The month button bottom left and settings bottom right, always visible, placed as
    /// Calendar's bottom row is. How far it reaches above the home indicator's safe area, which
    /// grows with Dynamic Type, sets the list's bottom inset so the floor line clears it. See "Getting back" in `docs/DESIGN.md`.
    private func bottomRow(bottomInset: CGFloat) -> some View {
        HStack {
            MonthButton(month: window?.current ?? MonthKey(containing: today, calendar: calendar), today: today, action: returnToResting)
            Spacer()
            GlassCircleButton(systemImage: "gearshape", label: "Settings", diameter: Tokens.Size.bottomButton) {
                isSettingsPresented = true
            }
        }
        .padding(.horizontal, Tokens.Space.bottomRowInset)
        .padding(.bottom, Tokens.Space.bottomRowInset)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
            // The list's bottom margin sits above the safe area already, so only the part of
            // the row that reaches above it counts.
            bottomClearance = max(0, height - bottomInset) + Tokens.Space.section
        }
        // Measured from the screen's edge, as Calendar's is, not from the safe area above the
        // home indicator. The row fills its container first: a view only as tall as its
        // buttons never reaches the edge it's told to ignore, and stayed 28pt above the safe
        // area (measured).
        .frame(maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    /// Replaces the months, and in the same update whether the ceiling is a real last payment, so
    /// the list says so above it. The two change together or not at all: read live from
    /// `expenses`, the line above the months went the moment a bill that runs on arrived, a turn
    /// before the window it belongs to, and everything below it jumped 60pt before the
    /// anchor was read (measured).
    private func replaceWindow(with newWindow: TimelineWindow?) {
        window = newWindow
        isLastPayment = newWindow.map {
            TimelineCeiling.isLastPayment($0.ceiling, for: expenses, current: $0.current, calendar: calendar)
        } ?? false
    }

    /// The history floor's mirror, above the last payment when every bill ends. It fills the
    /// header row, so it sits clear of + at the very top of the list.
    private func ceilingLine(_ month: MonthKey) -> some View {
        Text("Nothing after \(month.name(in: calendar, relativeTo: today, locale: locale)).")
            .font(Tokens.Text.monthTotal)
            .foregroundStyle(Tokens.Ink.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Tokens.Space.gutter * 2)
            .frame(minHeight: Tokens.Size.headerRow)
            .padding(.bottom, Tokens.Space.section)
    }

    /// Clear space after the floor line, so a list too short to fill the screen can still rest
    /// flush on the current month: what the container's height lacks of the distance from the
    /// current month's header down to the floor line's bottom. With a screenful of history it's 0.
    ///
    /// The distance is read from two unpinned things — the current month's content (less its
    /// header's height) and the floor line — in the list's own coordinate space, which
    /// scrolling doesn't move. Measured in the scroll view's space instead, the two arrived in
    /// separate callbacks either side of a scroll, and the space flickered 548 → 0.3 → 548 at
    /// launch. Changes under half a point are ignored.
    private func updateFloorSpacer() {
        guard let window, let currentContentTop, let floorLineBottom,
              let headerHeight = headerHeights[window.current], containerHeight > 0
        else { return }
        let currentHeaderTop = currentContentTop - headerHeight
        let needed = max(0, containerHeight - (floorLineBottom - currentHeaderTop))
        if abs(needed - floorSpacer) > 0.5 { floorSpacer = needed }
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
        sections[month] ?? MonthSection(month: month, entries: [], total: 0, remaining: 0, isCurrent: false)
    }

    private func setUpIfNeeded() {
        guard window == nil else { return }
        today = Date()
        let current = MonthKey(containing: today, calendar: calendar)
        guard let floor = TimelineFloor.month(for: expenses, calendar: calendar),
              let ceiling = TimelineCeiling.month(for: expenses, current: current, calendar: calendar)
        else { return }
        replaceWindow(with: TimelineWindow(floor: floor, ceiling: ceiling, current: current))
        rebuildSections()
    }

    /// Bills changed, so the floor or ceiling may have moved: ending the only bill that runs on
    /// drops every month above its last payment, and a backdated bill or a deleted old one moves
    /// the floor. The months are replaced and the month under the middle is held where it is,
    /// as a day change does. See "Nothing under the reader's eyes moves" in `docs/DESIGN.md`.
    ///
    /// The first bill arrives with no window yet, because `setUpIfNeeded` found no floor on
    /// appear; without setting up here the list would stay blank.
    private func refreshWindow() {
        guard let window else {
            setUpIfNeeded()
            return
        }
        guard let floor = TimelineFloor.month(for: expenses, calendar: calendar),
              let ceiling = TimelineCeiling.month(for: expenses, current: window.current, calendar: calendar)
        else {
            forgetWindow()
            return
        }
        let newWindow = TimelineWindow(floor: floor, ceiling: ceiling, current: window.current)
        guard newWindow != window else {
            rebuildSections()
            return
        }
        let anchorMonth = monthUnderMiddle()
        let desiredOffset = anchorMonth.flatMap { headerOffsets[$0] } ?? 0
        replaceWindow(with: newWindow)
        rebuildSections()
        if let anchorMonth, visibleMonths.contains(anchorMonth) {
            anchorAndSettle(anchorMonth, to: max(0, desiredOffset))
        }
    }

    /// The last bill is gone and the empty state shows. Everything measured from the old list
    /// goes with it, the saved place too, so the next bill sets up as a first run does and
    /// lands on the current month rather than on a place in a list that no longer exists.
    private func forgetWindow() {
        replaceWindow(with: nil)
        sections = [:]
        headerOffsets = [:]
        headerHeights = [:]
        scrollProxy = nil
        hasRestoredPlace = false
        restingContentOffset = nil
        currentContentTop = nil
        floorLineBottom = nil
        floorSpacer = 0
        placeStore.clear()
    }

    /// Restores where the reader left off, exactly once. With a saved place, scrolls so its
    /// anchor month sits at its saved offset — clamped into the current window in case the
    /// floor has moved since. With none — the first run after installing — rests flush on
    /// the current month instead, its header at the top, next month above the fold. See
    /// "Your place survives a relaunch, to the month rather than the row"
    /// in `docs/DECISIONS.md`.
    ///
    /// Tried and discarded: the newer `ScrollPosition`/`.scrollPosition(_:)` API, called the
    /// same way, produced no visible scroll — a `ScrollViewProxy` from `ScrollViewReader`
    /// does. Deferring with `DispatchQueue.main.async` is load-bearing, not cosmetic: at the
    /// point `sections` first gets the current month, `scrollProxy` is still nil, because
    /// `ScrollViewReader`'s own `onAppear` — which sets it — hasn't run yet. One run-loop
    /// turn is enough for both to be ready; confirmed with logging, not assumed.
    ///
    /// `hasRestoredPlace` is set only inside the deferred block, once a scroll has actually
    /// been issued — not before it. A nil
    /// `scrollProxy` a turn later leaves the flag false, so the next `sections` change (there
    /// will be one; `rebuildSections()` always follows) gets another attempt instead of
    /// skipping the restore forever.
    ///
    /// The same flag also gates `saveCurrentPlace` at both its call sites. Caught on device:
    /// `.onScrollPhaseChange` fires once immediately on mount, reporting `.idle` as the
    /// scroll view's default starting phase rather than a genuine settle — and it fires
    /// before this function's own deferred restore has run. Saving there overwrote the
    /// previous, correct place with the pre-restore top-of-list layout, before the restore
    /// scroll had even been issued. Nothing may save until a place has actually been
    /// restored to.
    private func restorePlaceIfNeeded() {
        guard !hasRestoredPlace, let window, sections[window.current] != nil else { return }
        DispatchQueue.main.async {
            guard let scrollProxy else { return }
            hasRestoredPlace = true
            guard let saved = placeStore.load()?.clamped(into: window),
                  let month = window.months.first(where: { $0.id == saved.anchorMonthID })
            else {
                scrollProxy.scrollTo(window.current.id, anchor: .top)
                return
            }
            // Two passes, not one. The month is unmounted at this point — nothing near the
            // top of a cold launch's list is anywhere near deep history — so `headerHeights`
            // has no entry for it and the first call takes `restoreAnchor`'s own `.top`
            // fallback, which mounts it. The second, a turn later, has real geometry and is
            // the one that lands.
            let offset = CGFloat(saved.anchorOffset)
            restoreAnchor(month, to: offset)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                restoreAnchor(month, to: offset)
            }
        }
    }

    /// The anchor to save: the month under the middle of the viewport, at its live offset —
    /// the same rule the restore and a day change both key on, so gesturing and
    /// restoring agree on what "here" means. Nothing is saved when there is no live
    /// geometry to read (nothing has laid out yet, or the screen is the empty state).
    ///
    /// **`headerOffsets` here is a deliberate limitation, not an oversight.** A pinned header
    /// reports its position as exactly `0` for as long as it is pinned, however far into the
    /// month the reader has gone — so a place saved from mid-month records the month and loses
    /// the depth, and the restore lands on that month's first row. That is the behaviour
    /// "Your place survives a relaunch, to the month rather than the row" in `docs/DECISIONS.md`
    /// signs off for v1.
    ///
    /// The honest measurement exists and is easy: the section's content is never pinned, so a
    /// month's true top is its content's top less one header height. Do not switch to it on
    /// its own. `restoreAnchor` cannot consume the negative offset that produces — asked for
    /// `-155.6` it delivered `+139.0` — so measuring better without also fixing the restore
    /// makes the landing worse, not better. `.claude/rules/swiftui-scrolling.md` records what
    /// was measured and where to start.
    private func currentPlace() -> TimelinePlace? {
        guard let month = monthUnderMiddle(), let offset = headerOffsets[month] else { return nil }
        return TimelinePlace(anchorMonthID: month.id, anchorOffset: Double(offset))
    }

    /// Fires on scroll-idle and whenever the scene leaves `.active` — deliberately both, per
    /// "Your place survives a relaunch, to the month rather than the row" in `docs/DECISIONS.md`:
    /// iOS gives no way to
    /// tell a clean background from a killed process apart, so neither may be the only
    /// writer. Suppressed during one of this view's own animated scrolls so an in-flight
    /// restore or return-to-resting doesn't overwrite the saved place with a mid-flight
    /// position, and gated on `hasRestoredPlace` at both call sites for the same reason —
    /// see the note there about the very first scroll-phase callback.
    private func saveCurrentPlace() {
        guard !isProgrammaticScroll else { return }
        // Deferred a run-loop turn: read one frame after scroll-idle or scenePhase fires,
        // not synchronously with it. `headerOffsets` is written from `onGeometryChange`,
        // which can land a beat behind the scroll settling or the scene backgrounding —
        // the same lag that once left the pinned header's ground a frame behind.
        DispatchQueue.main.async {
            guard let place = currentPlace() else { return }
            placeStore.save(place)
        }
    }

    /// `today` moves forward as the calendar day changes underneath a running app. When the
    /// month itself changes, the window is rebuilt with the new current month and a
    /// recomputed ceiling. The month the reader is now in was already listed, so nothing is
    /// inserted near them; but the ceiling rises by a month far above, and an empty month can
    /// join or leave the list, so the month under the middle is held where it is. See
    /// "Nothing under the reader's eyes moves" in `docs/DESIGN.md`.
    private func handleDayChange() {
        today = Date()
        guard let window else { return }
        let newCurrent = MonthKey(containing: today, calendar: calendar)
        guard newCurrent != window.current,
              let ceiling = TimelineCeiling.month(for: expenses, current: newCurrent, calendar: calendar)
        else {
            rebuildSections()
            return
        }
        let anchorMonth = monthUnderMiddle()
        let desiredOffset = anchorMonth.flatMap { headerOffsets[$0] } ?? 0
        replaceWindow(with: TimelineWindow(floor: window.floor, ceiling: ceiling, current: newCurrent))
        rebuildSections()
        if let anchorMonth { anchorAndSettle(anchorMonth, to: max(0, desiredOffset)) }
    }

    /// The month button's action: animates the reader back to the resting position — the
    /// current month's header at the container's top, the same target
    /// `restorePlaceIfNeeded` uses. `isProgrammaticScroll` keeps the scroll-idle save from
    /// recording a mid-flight position. See "Getting back" in `docs/DESIGN.md`.
    ///
    /// **Not `withAnimation(_:completion:)`.** Confirmed on device via logging that its
    /// completion handler runs before the scroll has visibly moved at all —
    /// `scrollProxy.scrollTo` drives a `UIScrollView` under the hood, which doesn't report
    /// into SwiftUI's animation-completion tracking. A fixed delay matching the animation's
    /// own duration is timing-dependent, not sufficient in principle, but held in every
    /// trial. That delay is derived from `returnDuration` rather than hard-coded, because the
    /// duration varies with distance and the two must not drift apart.
    private func returnToResting() {
        guard let window, let scrollProxy else { return }
        let duration = returnDuration
        isProgrammaticScroll = true
        // A tap lands while the list is still flying, and an animated `scrollTo` issued then
        // loses to the deceleration already in flight — measured: the phase stayed
        // `decelerating`, never became `animating`, and the list carried on to where the fling
        // was going. Switching scrolling off for one turn stops the momentum where it is, with
        // no jump, so the return is issued into a list that is standing still.
        isScrollHalted = true
        DispatchQueue.main.async {
            isScrollHalted = false
            withAnimation(.easeInOut(duration: duration)) {
                scrollProxy.scrollTo(window.current.id, anchor: .top)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.06) {
            isProgrammaticScroll = false
            // The reader is now at the resting position by construction, so `scrollOffset`
            // *is* `restingContentOffset`. Saying so is not belt-and-braces: the cache is
            // normally written as `scrollOffset + frame.minY` from two geometry callbacks
            // that arrive independently, and during an animated scroll they are sampled at
            // different instants — measured on device leaving the cache 702, 493 and 0.2
            // points wrong across three otherwise identical returns, and the next return's
            // duration is read from it.
            restingContentOffset = scrollOffset
            // And save it. The scroll-idle save is suppressed while this view's own scroll is
            // in flight, and a fling cut short by this tap never settled to save either — so
            // without this the saved place is wherever the fling was heading, and a relaunch
            // returns there rather than to the month just landed on.
            if hasRestoredPlace { saveCurrentPlace() }
        }
    }

    /// Waits a run-loop turn for the resized list to lay out, restores `month`'s position,
    /// and holds off the scroll-idle save until that restoring scroll has settled — see
    /// "Anchoring" in `.claude/rules/swiftui-scrolling.md`.
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
    /// header's height (47 points when measured) and not the section's several hundred. Passing a section height
    /// here overshoots by a proportion of the difference: the anchor landed 287 points low.
    /// The two facts are coupled, which is why they were mistaken for independent bugs — a
    /// geometry modifier on the `Section` breaks pinning *and* makes `scrollTo` resolve to
    /// the whole section, so a section height is right only while the header is broken.
    ///
    /// **The container is shorter than the viewport by `bottomClearance`.** The bottom row gives
    /// the list a bottom `contentMargins` so the floor line clears it, and `scrollTo`
    /// aligns within the container's *content area*, not the whole viewport. Dividing by the
    /// viewport instead lands every restore proportionally short — measured on device at
    /// 0.907x of whatever was asked, which is exactly (710 - 47) / (778 - 47). It slipped
    /// through while only small anchoring offsets used it, because the error there was a few
    /// points; restoring a saved place works from arbitrary depth, where the same ratio is tens of
    /// points and plainly visible. With the right denominator a single pass lands within a
    /// tenth of a point.
    ///
    /// **`desiredOffset` must not be negative.** `f` outside the unit square does not
    /// extrapolate: asking for -155.6 landed at +139.0 on device. So this can place a month's
    /// header anywhere from the container's top down, and cannot express "this month began
    /// above the top of the screen". See
    /// `.claude/rules/swiftui-scrolling.md`.
    ///
    /// Every value is read live and unrounded — a cached or rounded height was the earlier
    /// version's bug, and it drifted by half a point per gesture.
    private func restoreAnchor(_ month: MonthKey, to desiredOffset: CGFloat) {
        guard let scrollProxy else { return }
        let headerHeight = headerHeights[month] ?? 0
        let denominator = (viewportHeight - bottomClearance) - headerHeight
        guard headerHeight > 0, denominator > 0.5 else {
            scrollProxy.scrollTo(month.id, anchor: .top)
            return
        }
        let fraction = desiredOffset / denominator
        scrollProxy.scrollTo(month.id, anchor: UnitPoint(x: 0.5, y: fraction))
    }

    private func rebuildSections() {
        guard let window else { return }
        let timelineExpenses = Expense.timelineExpenses(expenses)

        var result: [MonthKey: MonthSection] = [:]
        for key in window.months {
            let built = TimelineBuilder.month(key, expenses: timelineExpenses, today: today, calendar: calendar)
            result[key] = MonthSection(
                month: built.month, entries: built.entries, total: built.total,
                remaining: built.remaining, isCurrent: key == window.current
            )
        }
        sections = result
    }
}

#if DEBUG
#Preview("Preview data") {
    let container = try! TillyStore.container(inMemory: true)
    try! PreviewData.insert(into: container.mainContext, today: Date(), calendar: .current)
    return TimelineView()
        .modelContainer(container)
}
#endif

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
