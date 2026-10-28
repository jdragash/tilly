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
    /// Stops the list's glide where it is, for the month button and All / Extras.
    @State private var glideStopper = GlideStopper()
    /// How many times the month button's return has had to start again, overtaken by a fling.
    @State private var returnRestarts = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var restingContentOffset: CGFloat?
    @State private var bottomClearance: CGFloat = Tokens.Space.floatingClearance
    @State private var containerHeight: CGFloat = 0
    @State private var currentContentTop: CGFloat?
    @State private var floorLineBottom: CGFloat?
    @State private var floorSpacer: CGFloat = 0
    @State private var isSettingsPresented = false
    @State private var isBillsPresented = false
    /// What the editor's sheet is open for; nil while it's closed.
    @State private var editor: EditorRequest?
    /// The day a calendar tap opened, its rows marked until the mark fades.
    @State private var markedDay: Date?
    /// The row a save just put in place, marked until the mark fades.
    @State private var markedEntryID: String?
    /// The rows on screen, for a save to tell whether its row is in view. State, not a plain
    /// `let`: the view is rebuilt whenever its parent redraws, and a `let` would start empty each time.
    @State private var rowFrames = RowFrames()
    /// Bumped by every mark, so steps still waiting from one left behind do nothing.
    @State private var markGeneration = 0
    /// The day a charge was just saved on over the calendar's month or year, while it arrives.
    @State private var arrivingDay: Date?

    /// How long an arrival waits, for the editor's sheet to have mostly left.
    private var arrivalDelay: TimeInterval { Tokens.Motion.Card.sheetExit * Tokens.Motion.dayArrivalAfter }

    /// A save's close refreshes the months itself, before the sheet goes, to find its row.
    @State private var refreshedOnClose = false
    /// Which view shows. The app opens on the one it was left on, as Calendar does.
    /// The category view is set aside for now: the timeline is the only view, and a stored choice
    /// of categories is left in place for when it returns.
    private let mode: ViewMode = .timeline
    /// The month the category view shows. Set properly once the window is.
    @State private var categoryMonth = MonthKey(containing: Date(), calendar: .current)
    /// How far the Calendar is zoomed, and the month its grid shows (a `MonthKey.id`; negative until
    /// one has been chosen). Both are kept across launches. Change the level through `setLevel`.
    @AppStorage("calendarLevel") private var level: CalendarLevel = .month
    @AppStorage("calendarMonthID") private var calendarMonthID = -1
    /// All charges, or only the extras: one setting for every level, kept across launches.
    @AppStorage("showsExtrasOnly") private var extrasOnly = false
    /// The All / Extras toggle's width, which the titles beneath it keep clear.
    @State private var extrasToggleWidth: CGFloat = 0
    /// Where the last change of level zoomed about.
    @State private var levelZoom = CalendarZoom.centre
    /// While the levels change, the two drawn, and how far in it is: 0 shows the further, 1 the
    /// closer. Every level draws from these, so a pinch can hold the zoom anywhere between; nil at rest.
    @State private var zoomPair: ZoomPair?
    @State private var zoomProgress: CGFloat = 0
    /// Bumped by every zoom, so the end of one overtaken does nothing.
    @State private var zoomGeneration = 0
    /// The frames a zoom grows from, reported by the year's and the month's cells.
    @State private var zoomFrames = CalendarZoomFrames()
    /// A pinch is under way, and what it is doing: each pinch moves one level at most.
    @GestureState private var isPinching = false
    @State private var pinch: Pinch?
    /// The pinch as state, for taps to read: a level leaving keeps the closures it was drawn
    /// with, and reads a `@GestureState` from them as it was then.
    @State private var pinchUnderway = false
    @State private var pinchEnded = Date.distantPast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    private static let logger = Logger(subsystem: "com.jdragash.Tilly", category: "TimelineView")
    private static let scrollSpace = "timelineScroll"
    /// The list's own content, which scrolling doesn't move: distances measured here hold
    /// still while the list scrolls.
    private static let contentSpace = TimelineSpace.content

    /// The last month (in top-to-bottom document order) whose header has reached the
    /// container's top edge. Derived fresh from every header's live offset rather than
    /// toggled by a paired on/off event — `LazyVStack` can recycle a header while it's off
    /// screen without ever firing a "no longer pinned" transition for it, which left a stale
    /// entry behind under a set-based, event-driven version of this. A geometry read recomputes
    /// on every layout the header is actually part of, so recycling can't leave it stuck.
    /// `.last` (rather than `.first`) matters too: a single scroll update can cross more than
    /// one month's threshold at once, and the later month in document order is the one that
    /// has actually taken over pinning.
    private func pinnedMonth(in months: [MonthKey]) -> MonthKey? {
        months.last { (headerOffsets[$0] ?? .infinity) <= 0 }
    }

    /// Months from the ceiling down to the floor, with an empty month dropped unless it's the
    /// current month or the one after, which always render, empty or not. See "One list, from
    /// your oldest charge to five years on" in `docs/DESIGN.md`.
    private var visibleMonths: [MonthKey] {
        guard let window else { return [] }
        let nextMonth = window.current.advanced(by: 1)
        return window.months.filter { month in
            month == window.current || month == nextMonth || !(sections[month]?.isEmpty ?? true)
        }
    }

    /// The list's own height: the viewport less the top row the back button sits in. Derived
    /// from the viewport and the row's fixed height rather than read from the scroll view, so
    /// it can't arrive a callback apart from the offsets it's compared with.
    private var listHeight: CGFloat {
        viewportHeight - Tokens.Size.headerRow
    }

    /// The month under the middle of the list — the one actually being read, and the
    /// only anchor that survives a month being added or dropped without visibly moving. The
    /// top-most visible item is wrong (preserving it can shove the read month off screen);
    /// total content height is wrong too, because one change can add a month at one end and
    /// drop one at the other. See `.claude/rules/swiftui-scrolling.md`.
    private func monthUnderMiddle() -> MonthKey? {
        let middleY = listHeight / 2
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
        // The editor's keyboard shrinks the screen behind it too, and the bottom row rode up
        // behind the editor to sit on the keyboard (measured: y 772 → 418). The timeline has
        // no text field of its own, so it ignores the keyboard whole: ignoring it on the row
        // alone isn't enough, because the row follows the bottom of what it sits in.
        .ignoresSafeArea(.keyboard)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { viewportHeight = $0 }
        // Above the levels, the glass controls and the bottom row.
        .overlay {
            EditorSheet(request: $editor) { request in
                switch request {
                case .add:
                    ExpenseEditor(today: today, onClose: closeEditor)
                case .edit(let session):
                    ExpenseEditor(today: today, session: session, onClose: closeEditor)
                }
            }
        }
        .coordinateSpace(name: TimelineSpace.name)
        // Every close refreshes, a drag down included: a save writes an `OverrideRecord` or edits
        // fields on the same `Expense` instances this view already holds, and `@Query`'s own
        // change notification doesn't reliably fire for a relationship-only edit, while
        // `.onChange(of: expenses)` compares the array by model identity, not by the fields
        // within it. Without this a saved amount left the row showing what it read before the
        // edit, and deleting future charges, which only ends a record, left the months ahead.
        .onChange(of: editor) { _, new in
            guard new == nil else { return }
            // Once the sheet has dropped away, unless it has opened again by then.
            DispatchQueue.main.asyncAfter(deadline: .now() + Tokens.Motion.Card.sheetExit) {
                if editor == nil { BoilClock.shared.listsHeld = false }
            }
            if refreshedOnClose {
                refreshedOnClose = false
            } else {
                refreshWindow()
            }
        }
        .onAppear { setUpIfNeeded() }
        .onChange(of: expenses) { _, _ in refreshWindow() }
        .onChange(of: extrasOnly) { _, _ in showExtrasChange() }
        .onChange(of: sections) { _, _ in restorePlaceIfNeeded() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active, hasRestoredPlace { saveCurrentPlace() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            handleDayChange()
        }
    }

    /// The category view lies over the timeline, which stays mounted beneath it, hidden, so its
    /// place survives a switch: rebuilt, the list would restore only to the month, and pay
    /// for laying itself out again. With no expenses both views are the empty state.
    private func content(topInset: CGFloat, bottomInset: CGFloat) -> some View {
        let showsCategories = mode == .categories && !expenses.isEmpty && window != nil
        let hasLevels = mode == .timeline && !expenses.isEmpty && window != nil
        // The levels' controls follow `level`; the levels themselves are drawn while they show or zoom.
        let showsCalendarMonth = hasLevels && level == .month
        let drawsMonth = hasLevels && draws(.month)
        let drawsYear = hasLevels && draws(.year)
        let coversTimeline = showsCategories || (hasLevels && level != .day)
        let timelineLook = hasLevels ? look(of: .day) : (scale: 1, opacity: 1)
        return ZStack {
            timeline(topInset: topInset)
                .scaleEffect(reduceMotion ? 1 : timelineLook.scale, anchor: levelZoom.anchor)
                .opacity(showsCategories ? 0 : timelineLook.opacity)
                .allowsHitTesting(!coversTimeline)
                .accessibilityHidden(coversTimeline)
            if showsCategories, let window {
                CategoryView(
                    month: $categoryMonth, window: window, expenses: expenses, today: today,
                    bottomClearance: bottomClearance, onOpen: openEntry
                )
            }
            // The month above the year: its paper covers the year's large end, as the transitions
            // this replaced drew it.
            if drawsYear, let window {
                let yearLook = look(of: .year)
                YearView(
                    overview: yearOverview(in: window), extrasOnly: extrasOnly, today: today,
                    titleTrailingClearance: toggleClearance,
                    onOpenMonth: { month in ifNotPinching { openMonth(month, in: window) } },
                    arrivingDay: arrivingDay, arrivalDelay: arrivalDelay,
                    onMonthFrame: { if level == .year { zoomFrames.report(month: $0, frame: $1) } }
                )
                .scaleEffect(reduceMotion ? 1 : yearLook.scale, anchor: levelZoom.anchor)
                .opacity(yearLook.opacity)
                .allowsHitTesting(level == .year)
                .accessibilityHidden(level != .year)
            }
            if drawsMonth, let window {
                let monthLook = look(of: .month)
                CalendarMonthView(
                    month: calendarMonthBinding(in: window), window: window,
                    calendarMonth: calendarMonthModel(in: window), today: today,
                    onOpenDay: { day in ifNotPinching { openDay(day) } },
                    arrivingDay: arrivingDay, arrivalDelay: arrivalDelay,
                    // Only while the month shows: leaving, it reports scaled frames past the zoom's end.
                    onDayFrame: { if level == .month { zoomFrames.report(day: $0, frame: $1) } },
                    onBack: { ifNotPinching { backToYear(in: window) } },
                    isPinching: isPinching,
                    titleTrailingClearance: toggleClearance
                )
                .scaleEffect(reduceMotion ? 1 : monthLook.scale, anchor: levelZoom.anchor)
                .opacity(monthLook.opacity)
                .allowsHitTesting(level == .month)
                .accessibilityHidden(level != .month)
            }
        }
        // Alongside the levels' own gestures, so one finger still scrolls and pages.
        .simultaneousGesture(
            MagnifyGesture()
                .updating($isPinching) { _, pinching, _ in pinching = true }
                .onChanged(followPinch)
        )
        // Ended or cancelled alike: the gesture's state resets either way.
        .onChange(of: isPinching) { _, pinching in
            pinchUnderway = pinching
            if !pinching {
                endPinch()
                pinchEnded = Date()
            }
        }
        .coordinateSpace(name: CalendarZoom.space)
        .onGeometryChange(for: CGSize.self) { $0.size } action: { zoomFrames.size = $0 }
        // Settings never moves: it sits in the `headerRow` band where headers pin, and each
        // header hands off beneath it. Over the empty state too.
        // While a finger drags across the lanes the controls step aside with the month's name,
        // and the readout takes the row alone. The bottom row stays: hiding it felt wrong.
        .overlayPreferenceValue(CategoryReadoutKey.self, alignment: .topTrailing) { readout in
            HStack(spacing: Tokens.Space.groupGap) {
                if showsCategories, let window {
                    MonthArrows(
                        canGoBack: categoryMonth > window.floor,
                        canGoForward: categoryMonth < window.ceiling,
                        step: { categoryMonth = categoryMonth.advanced(by: $0) }
                    )
                }
                if showsCalendarMonth, let window {
                    let shown = shownCalendarMonth(in: window)
                    MonthArrows(
                        canGoBack: shown > window.floor,
                        canGoForward: shown < window.ceiling,
                        step: { calendarMonthID = shown.advanced(by: $0).id }
                    )
                }
                HeaderControls { isSettingsPresented = true }
            }
            .frame(height: Tokens.Size.headerRow)
            .padding(.trailing, Tokens.Space.gutter)
            .opacity(readout == nil ? 1 : 0)
            .allowsHitTesting(readout == nil)
            .animation(Tokens.Motion.aside(hiding: readout != nil), value: readout == nil)
        }
        // Under the top row's trailing end at every Calendar level, where the month's and the
        // year's titles begin, and over the pinned header on the timeline. It doesn't zoom with
        // the levels: like the settings button, it stays put while they change beneath it.
        .overlay(alignment: .topTrailing) {
            if mode == .timeline && !expenses.isEmpty && window != nil {
                ExtrasToggle(extrasOnly: $extrasOnly)
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { extrasToggleWidth = $0 }
                    .padding(.top, Tokens.Size.headerRow + Tokens.Space.titleTop)
                    .padding(.trailing, Tokens.Space.gutter)
            }
        }
        .overlay(alignment: .bottom) { bottomRow(bottomInset: bottomInset) }
        // Above the glass controls, which fade while it shows: the readout takes the header row.
        .overlayPreferenceValue(CategoryReadoutKey.self) { CategoryReadoutLayer(placement: $0) }
        .sheet(isPresented: $isSettingsPresented) { SettingsSheet(today: today) }
        .sheet(isPresented: $isBillsPresented) { AllBillsSheet(today: today) }
    }

    @ViewBuilder
    private func timeline(topInset: CGFloat) -> some View {
        Group {
            if expenses.isEmpty {
                TimelineEmptyState()
            } else if let window {
                // The days' top row holds the way back to the month; the settings button floats over
                // its trailing end from `content`. Months pin beneath the row, not in it.
                VStack(spacing: 0) {
                    dayTopRow(window)
                    list(window)
                }
                .drawnPaper()
                .overlay(alignment: .top) {
                    // A `GeometryReader` nested inside this `.overlay` reports a zero top
                    // inset here — confirmed on device — so the inset is measured once, by
                    // the `GeometryReader` wrapping the whole screen in `body`, and passed
                    // down instead. See "The month header" in `docs/DESIGN.md`.
                    Color.clear
                        .drawnPaper()
                        .frame(height: topInset)
                        .frame(maxWidth: .infinity)
                        .ignoresSafeArea(edges: .top)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    /// "‹ October": the month under the middle of the list, live, which the back button returns
    /// to as the calendar's month.
    private func dayTopRow(_ window: TimelineWindow) -> some View {
        let month = monthUnderMiddle() ?? window.current
        return HStack {
            BackButton(title: month.name(in: calendar, relativeTo: today, locale: locale)) {
                ifNotPinching { backToMonth(in: window) }
            }
            Spacer()
        }
        .padding(.horizontal, Tokens.Space.gutter)
        .frame(height: Tokens.Size.headerRow)
    }

    private func list(_ window: TimelineWindow) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    if isLastPayment { ceilingLine(window.ceiling) }
                    // Once per update, not once per month: each was a filter of every month in the
                    // window, run again for every header on every scroll frame.
                    let months = visibleMonths
                    let pinned = pinnedMonth(in: months)
                    ForEach(months) { month in
                        let monthSection = section(for: month)
                        Section {
                            MonthSectionView(
                                section: monthSection,
                                today: today,
                                showsFirstWeekLine: monthSection.isCurrent && !monthSection.hasChargedEntry,
                                markedDay: markedDay,
                                markedEntryID: markedEntryID,
                                onRowFrame: { rowFrames.report($0, frame: $1) },
                                onOpen: { entry in ifNotPinching { openEntry(entry) } }
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
                            // Pinned beneath the top row, where only the All / Extras toggle
                            // floats over its trailing end.
                            MonthHeader(
                                section: monthSection, today: today, isPinned: pinned == month,
                                trailingClearance: toggleClearance
                            )
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
                                // A header the list stops drawing keeps its last offset, which
                                // then lies: a jump to a far month left June's behind at the
                                // top, and the month under the middle read June. Its height
                                // stays, as every header's is the same.
                                .onDisappear { headerOffsets[month] = nil }
                        }
                        .id(month.id)
                    }
                    // Where a day below every listed month falls.
                    Color.clear
                        .frame(height: Tokens.Size.scrollMarker)
                        .id(TimelineFloor.scrollID)
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
                .background { GlideStopperAnchor(stopper: glideStopper) }
                .scrollTargetLayout()
            }
            .contentMargins(.bottom, bottomClearance, for: .scrollContent)
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, newValue in
                scrollOffset = newValue
            }
            .onScrollGeometryChange(for: CGFloat.self) { $0.containerSize.height } action: { _, newValue in
                containerHeight = newValue
                updateFloorSpacer()
            }
            .onScrollPhaseChange { oldPhase, newPhase in
                // The return was overtaken: the fling the tap cut short got its momentum back
                // (its finger lifted a moment after the tap, or the halt didn't hold). Stop it again
                // and start the return over, a couple of times at most.
                if isProgrammaticScroll, oldPhase == .animating, newPhase == .decelerating,
                   level == .day, returnRestarts < Self.returnRestartLimit {
                    returnRestarts += 1
                    returnToResting(restarting: true)
                }
            if newPhase == .idle && !isProgrammaticScroll && hasRestoredPlace { saveCurrentPlace() }
            }
            .onAppear { scrollProxy = proxy }
        }
        .coordinateSpace(name: Self.scrollSpace)
    }

    // MARK: The calendar's month

    private static func monthKey(id: Int) -> MonthKey {
        MonthKey(year: id / 12, month: id % 12 + 1)
    }

    /// The month the grid shows, held inside the window.
    private func shownCalendarMonth(in window: TimelineWindow) -> MonthKey {
        guard calendarMonthID >= 0 else { return window.current }
        return min(max(Self.monthKey(id: calendarMonthID), window.floor), window.ceiling)
    }

    private func calendarMonthBinding(in window: TimelineWindow) -> Binding<MonthKey> {
        Binding(
            get: { shownCalendarMonth(in: window) },
            set: { calendarMonthID = $0.id }
        )
    }

    /// Built on every change rather than cached, as the lanes are: a saved edit changes the
    /// instances this view holds, which `.onChange(of:)` can't see.
    private func calendarMonthModel(in window: TimelineWindow) -> CalendarMonth {
        let month = shownCalendarMonth(in: window)
        let built = TimelineBuilder.month(
            month, expenses: Expense.timelineExpenses(expenses), today: today, calendar: calendar,
            extrasOnly: extrasOnly
        )
        let section = MonthSection(
            month: built.month, entries: built.entries, total: built.total, remaining: built.remaining,
            isCurrent: month == window.current, showsExtrasOnly: built.showsExtrasOnly
        )
        return CalendarMonthBuilder.month(section, today: today, calendar: calendar)
    }

    /// The twelve months from this one, as the year shows them. Built on every change, as the
    /// month is. Months past the window's ceiling are built too, and are simply empty.
    private func yearOverview(in window: TimelineWindow) -> YearOverview {
        let timelineExpenses = Expense.timelineExpenses(expenses)
        let sections = (0..<12).map { offset -> MonthSection in
            let key = window.current.advanced(by: offset)
            // Every charge: the year's marks and totals need the usual ones even with extras only.
            let built = TimelineBuilder.month(
                key, expenses: timelineExpenses, today: today, calendar: calendar, extrasOnly: false
            )
            return MonthSection(
                month: built.month, entries: built.entries, total: built.total, remaining: built.remaining,
                isCurrent: key == window.current, showsExtrasOnly: built.showsExtrasOnly
            )
        }
        return YearBuilder.overview(
            sections: sections, categoryOf: Expense.categoryMap(expenses),
            categories: categories.map(CategoryInfo.init), extrasOnly: extrasOnly, today: today, calendar: calendar
        )
    }

    /// The days' back button: out to the month under the middle of the list, shrinking into `day`
    /// when it's in that month and the grid has shown it, or else into the day last opened from the
    /// grid if the list is still in its month.
    private func backToMonth(in window: TimelineWindow) {
        setLevel(.month, zoom: monthTarget(in: window))
    }

    /// Where the way out of the days goes: sets the grid's month and returns the zoom to shrink by.
    private func monthTarget(in window: TimelineWindow, shrinkingInto day: Date? = nil) -> CalendarZoom {
        let target = min(max(monthUnderMiddle() ?? window.current, window.floor), window.ceiling)
        calendarMonthID = target.id
        let inTarget: (Date) -> Date? = { MonthKey(containing: $0, calendar: calendar) == target ? $0 : nil }
        let shrinksInto = day.flatMap(inTarget).flatMap { zoomFrames.days[$0] == nil ? nil : $0 }
            ?? zoomFrames.openedDay.flatMap(inTarget)
        return shrinksInto.map(zoomFrames.zoom(forDay:)) ?? .centre
    }

    /// The month's back button: out to the year, shrinking into the month's cell.
    private func backToYear(in window: TimelineWindow) {
        setLevel(.year, zoom: zoomFrames.zoom(forMonth: shownCalendarMonth(in: window)))
    }

    /// One pinch, once it has a direction: the level it zooms to (nil past the year or the days,
    /// where it does nothing), how far along it is and how fast, and how to undo what it prepared.
    private struct Pinch {
        let direction: PinchDirection
        let target: CalendarLevel?
        var progress: CGFloat = 0
        var speed: CGFloat = 0
        /// When the fingers last moved: fingers held still send no changes, so a speed this old is 0.
        var moved = Date()
        /// A day it lands on in the days, marked once it finishes.
        var day: Date?
        var undo: () -> Void = {}
    }

    /// The zoom follows the fingers: on the first change past the dead zone the pinch chooses what
    /// to zoom to, as the matching tap or back button would, then holds the zoom where the fingers
    /// are. See the prototype's `pMove`.
    private func followPinch(_ value: MagnifyGesture.Value) {
        if pinch == nil {
            guard let direction = PinchProgress.direction(magnification: value.magnification) else { return }
            pinch = beginPinch(direction, at: value.startLocation)
        }
        guard var pinch, pinch.target != nil else { return }
        pinch.progress = PinchProgress.progress(magnification: value.magnification, direction: pinch.direction)
        pinch.speed = PinchProgress.speed(
            magnification: value.magnification, velocity: value.velocity, direction: pinch.direction
        )
        pinch.moved = Date()
        self.pinch = pinch
        var still = Transaction()
        still.disablesAnimations = true
        withTransaction(still) {
            zoomProgress = pinch.direction == .in ? pinch.progress : 1 - pinch.progress
        }
    }

    /// Chooses what the pinch zooms to and draws the pair at its start, preparing what the tap or
    /// back button would: the month the year opens, the day the list lands on, the month it backs to.
    private func beginPinch(_ direction: PinchDirection, at location: CGPoint) -> Pinch {
        let dead = Pinch(direction: direction, target: nil)
        guard let window, mode == .timeline, !expenses.isEmpty else { return dead }
        endZoom(settled: false)
        switch (level, direction) {
        case (.year, .in):
            guard let month = nearest(to: location, in: zoomFrames.months) else { return dead }
            let old = calendarMonthID
            calendarMonthID = min(max(month, window.floor), window.ceiling).id
            _ = beginZoom(to: .month, zoom: zoomFrames.zoom(forMonth: month))
            return Pinch(direction: direction, target: .month) { calendarMonthID = old }
        case (.month, .in):
            let shown = shownCalendarMonth(in: window)
            let days = zoomFrames.days.filter { MonthKey(containing: $0.key, calendar: calendar) == shown }
            guard let day = nearest(to: location, in: days) else { return dead }
            let place = glideStopper.offset
            let opened = zoomFrames.openedDay
            zoomFrames.openedDay = day
            land(on: day)
            _ = beginZoom(to: .day, zoom: zoomFrames.zoom(forDay: day))
            return Pinch(direction: direction, target: .day, day: day) {
                zoomFrames.openedDay = opened
                if let place { glideStopper.putBack(place) }
            }
        case (.day, .out):
            let old = calendarMonthID
            let zoom = monthTarget(in: window, shrinkingInto: day(under: location))
            _ = beginZoom(to: .month, zoom: zoom)
            return Pinch(direction: direction, target: .month) { calendarMonthID = old }
        case (.month, .out):
            _ = beginZoom(to: .year, zoom: zoomFrames.zoom(forMonth: shownCalendarMonth(in: window)))
            return Pinch(direction: direction, target: .year)
        case (.year, .out), (.day, .in):
            return dead
        }
    }

    /// The fingers lifted: past `pinchFinish`, or flicked, the zoom runs on to the level it was
    /// heading for; otherwise it springs back and what it prepared is undone. See `pEnd`.
    private func endPinch() {
        guard let pinch else { return }
        self.pinch = nil
        guard let target = pinch.target, zoomPair != nil else { return }
        let held = Date().timeIntervalSince(pinch.moved) > Tokens.Motion.pinchStill
        let finishes = PinchProgress.finishes(progress: pinch.progress, speed: held ? 0 : pinch.speed)
        let now = pinch.direction == .in ? pinch.progress : 1 - pinch.progress
        // Going in finishes at 1, going out at 0; springing back, the other way.
        let end: CGFloat = (pinch.direction == .in) == finishes ? 1 : 0
        let duration = PinchProgress.settleDuration(from: now, to: end)
        let settle = Tokens.Motion.zoom(duration: duration)
        if finishes {
            runZoom(to: end, level: target, animation: settle, duration: duration)
            if target == .day, let day = pinch.day {
                markOpened(day)
            }
        } else {
            runZoom(to: end, level: level, animation: settle, duration: duration)
            pinch.undo()
        }
    }

    /// Runs a tap's action unless a pinch is under way or has just ended: the fingers lifting off a
    /// pinch land as taps on whatever is under them, which opened two days at once.
    private func ifNotPinching(_ action: () -> Void) {
        guard !pinchUnderway, Date().timeIntervalSince(pinchEnded) > Tokens.Motion.pinchQuiet else { return }
        action()
    }

    /// The key whose frame's centre is nearest `point`.
    private func nearest<Key>(to point: CGPoint, in frames: [Key: CGRect]) -> Key? {
        frames.min { hypot($0.value.midX - point.x, $0.value.midY - point.y) < hypot($1.value.midX - point.x, $1.value.midY - point.y) }?.key
    }

    /// The day of the row under `point` in the list, if a row is there.
    private func day(under point: CGPoint) -> Date? {
        let ids = rowFrames.frames.filter { $0.value.minY <= point.y && point.y < $0.value.maxY }.keys
        for section in sections.values {
            if let entry = section.entries.first(where: { ids.contains($0.id) }) { return entry.date }
        }
        return nil
    }

    /// A month in the year opens as the month level.
    private func openMonth(_ month: MonthKey, in window: TimelineWindow) {
        calendarMonthID = min(max(month, window.floor), window.ceiling).id
        setLevel(.month, zoom: zoomFrames.zoom(forMonth: month))
    }

    /// What a title or a header beneath the All / Extras toggle keeps clear at its trailing end.
    private var toggleClearance: CGFloat {
        extrasToggleWidth + Tokens.Space.gap + Tokens.Space.gutter
    }

    /// All / Extras changed: the months are rebuilt, and the month under the middle of the list
    /// is held where it is, as a window change holds it. See "Nothing under the reader's eyes
    /// moves" in `docs/DESIGN.md`. A month left with nothing drops out as any empty month does;
    /// if it was the one being read, the nearest month left takes its place.
    ///
    /// A switch made while the list still glides stops the glide first, as the month button does:
    /// left to run, the glide carried on past the anchoring scroll, which was dropped, and once
    /// the list had shrunk under it, it ran off the end and showed nothing at all (measured).
    private func showExtrasChange() {
        guard window != nil else { return }
        glideStopper.stop()
        let anchorMonth = monthUnderMiddle()
        let desiredOffset = anchorMonth.flatMap { headerOffsets[$0] } ?? 0
        rebuildSections()
        let target = anchorMonth.flatMap { anchor in
            visibleMonths.contains(anchor)
                ? anchor
                : visibleMonths.min { abs($0.id - anchor.id) < abs($1.id - anchor.id) }
        }
        isProgrammaticScroll = true
        DispatchQueue.main.async {
            if let target { restoreAnchor(target, to: max(0, desiredOffset)) }
            DispatchQueue.main.async { isProgrammaticScroll = false }
        }
    }

    /// The two levels a change of level zooms between: the year and a month, or a month and the days.
    private struct ZoomPair: Equatable {
        let further: CalendarLevel
        let closer: CalendarLevel

        init(between one: CalendarLevel, and other: CalendarLevel) {
            if one == .year || other == .year {
                (further, closer) = (.year, .month)
            } else {
                (further, closer) = (.month, .day)
            }
        }
    }

    /// Whether `level` is drawn: the one that shows, and both of a zoom's pair while it runs.
    private func draws(_ level: CalendarLevel) -> Bool {
        level == self.level || zoomPair?.further == level || zoomPair?.closer == level
    }

    /// A level's size and fade: from the zoom while it is in one, otherwise full or hidden.
    private func look(of level: CalendarLevel) -> (scale: CGFloat, opacity: Double) {
        if let zoomPair {
            if level == zoomPair.closer { return levelZoom.closer(at: zoomProgress) }
            if level == zoomPair.further { return levelZoom.further(at: zoomProgress) }
        }
        return (1, level == self.level ? 1 : 0)
    }

    /// Moves between the year, a month and the days, zooming about `zoom`: going in, the closer
    /// level grows out of the cell that was tapped while the further one grows past and fades;
    /// going out, the reverse, back into that cell. Both are drawn from one progress value, so a
    /// pinch can hold the zoom anywhere between. The timeline is always mounted, so its place
    /// survives. Nothing here touches a scroll.
    ///
    /// The pair is drawn at its start a turn before the progress moves, so the level arriving is
    /// in place, unseen, before it starts to grow. A zoom still running ends at once.
    private func setLevel(_ new: CalendarLevel, zoom: CalendarZoom) {
        endZoom(settled: false)
        guard new != level else { return }
        let from = beginZoom(to: new, zoom: zoom)
        let generation = zoomGeneration
        DispatchQueue.main.async {
            guard generation == zoomGeneration else { return }
            runZoom(to: 1 - from, level: new, animation: Tokens.Motion.zoom, duration: Tokens.Motion.zoomDuration)
        }
    }

    /// Draws the pair for a change from `level` to `new` at where `level` is now, unseen, and
    /// returns that progress.
    private func beginZoom(to new: CalendarLevel, zoom: CalendarZoom) -> CGFloat {
        let pair = ZoomPair(between: level, and: new)
        let from: CGFloat = level == pair.closer ? 1 : 0
        levelZoom = zoom
        zoomFrames.isZooming = true
        zoomPair = pair
        zoomProgress = from
        zoomGeneration &+= 1
        return from
    }

    /// Animates the running zoom's progress to `end`, setting `level` with it so the controls
    /// answer at once, and ends the zoom when the animation has had its time.
    private func runZoom(to end: CGFloat, level new: CalendarLevel, animation: Animation, duration: TimeInterval) {
        let generation = zoomGeneration
        withAnimation(animation) {
            level = new
            zoomProgress = end
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            guard generation == zoomGeneration else { return }
            endZoom(settled: true)
        }
    }

    /// The zoom running, if any, is over: only `level` stays drawn, at full size, at once.
    private func endZoom(settled: Bool) {
        guard zoomPair != nil else { return }
        zoomGeneration &+= 1
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            zoomPair = nil
        }
        zoomFrames.zoomEnded(settled: settled, showing: level)
    }

    /// Any day of the month opens the days: the timeline, with that day's first row just under its
    /// month's pinned header, the day's rows marked and then fading. A day with nothing on it lands
    /// where it would fall, in the middle of what shows, with nothing marking it; today with nothing
    /// on it lands the Today line there, as the month button does. The timeline stays mounted
    /// beneath the grid, so its proxy is there to scroll.
    ///
    /// Two scrolls, a turn apart, neither animated. The month first, because a lazy list resolves
    /// only ids it has laid out: asked straight for a day in a month it hadn't built, it didn't
    /// move. Then the day's marker, zero high, so placing it needs only the header's height:
    /// `scrollTo` lands a target's point at fraction `f` on the container's point at `f`, and with
    /// no height of its own the marker's top lands at `f × (listHeight − bottomClearance)`.
    /// Measured: 59.86 under a 60pt header, from the current month and from three months back.
    private func openDay(_ date: Date) {
        guard scrollProxy != nil else { return }
        let day = calendar.startOfDay(for: date)
        let hasRows = sections[MonthKey(containing: day, calendar: calendar)]?.entries.contains { $0.date == day } ?? false
        markedDay = hasRows ? day : nil
        zoomFrames.openedDay = day
        setLevel(.day, zoom: zoomFrames.zoom(forDay: day))
        land(on: day) {
            if hasRestoredPlace { saveCurrentPlace() }
            withAnimation(.easeOut(duration: Tokens.Motion.dayMark)) { markedDay = nil }
        }
    }

    /// A day a pinch has opened, already landed on: marked as a tap marks it, then fading, and the
    /// place saved.
    private func markOpened(_ day: Date) {
        let hasRows = sections[MonthKey(containing: day, calendar: calendar)]?.entries.contains { $0.date == day } ?? false
        markedDay = hasRows ? day : nil
        DispatchQueue.main.async {
            if hasRestoredPlace { saveCurrentPlace() }
            withAnimation(.easeOut(duration: Tokens.Motion.dayMark)) { markedDay = nil }
        }
    }

    /// What a day lands on in the list, and how.
    private enum DayLanding {
        /// A day with rows: its marker just under the header.
        case rows(MonthKey)
        /// Today with nothing on it, while the divider shows.
        case divider(MonthKey)
        /// A zero-high marker, where a day without a charge would fall, centred.
        case marker(AnyHashable, MonthKey)
    }

    private func landing(for day: Date) -> DayLanding {
        let month = MonthKey(containing: day, calendar: calendar)
        let months = visibleMonths
        if months.contains(month) {
            let section = section(for: month)
            if section.entries.contains(where: { $0.date == day }) { return .rows(month) }
            if day == calendar.startOfDay(for: today), section.isCurrent, section.hasChargedEntry {
                return .divider(month)
            }
            return .marker(AnyHashable(OccurrenceRow.dayScrollID(day)), month)
        }
        // Not listed, as an empty month isn't: where it would be, at the top of the nearest month below.
        guard let below = months.first(where: { $0 < month }) else {
            return .marker(AnyHashable(TimelineFloor.scrollID), months.last ?? month)
        }
        let section = section(for: below)
        let seams = DaySeams.seams(for: section, today: today, calendar: calendar)
        let first = seams[0]?.first ?? section.entries.first?.date ?? seams[section.entries.count]?.first
        return .marker(first.map { AnyHashable(OccurrenceRow.dayScrollID($0)) } ?? AnyHashable(below.id), below)
    }

    /// Lands `day` as `openDay` describes, unanimated, then calls `done` once the list is still.
    private func land(on day: Date, then done: @escaping () -> Void = {}) {
        guard let scrollProxy else { return }
        let landing = landing(for: day)
        let month: MonthKey
        switch landing {
        case .rows(let key), .divider(let key), .marker(_, let key): month = key
        }
        isProgrammaticScroll = true
        // The month first: a lazy list resolves only ids it has laid out, and a month far from
        // where the list rests hasn't been. Landing on it lays it out and measures its header.
        scrollProxy.scrollTo(month.id, anchor: .top)
        DispatchQueue.main.async {
            let headerHeight = headerHeights[month] ?? 0
            switch landing {
            case .rows:
                let room = listHeight - bottomClearance
                let fraction = room > 0 ? min(1, headerHeight / room) : 0
                scrollProxy.scrollTo(OccurrenceRow.dayScrollID(day), anchor: UnitPoint(x: 0.5, y: fraction))
            case .divider:
                // Its own height, not its frame's, which the zoom is scaling; until it has laid out
                // it is centred as a zero-high marker would be.
                let height = rowFrames.frames[TodayDivider.sizeID]?.height ?? 0
                scrollProxy.scrollTo(TodayDivider.scrollID, anchor: dividerAnchor(height: height, in: month))
            case .marker(let id, _):
                scrollProxy.scrollTo(id, anchor: dividerAnchor(height: 0, in: month))
            }
            DispatchQueue.main.async {
                isProgrammaticScroll = false
                done()
            }
        }
    }

    /// Puts the row's top `landingRowOffset` under its month's pinned header, unanimated, so a saved
    /// row that was off screen is in view as the sheet leaves: the jump happens behind it.
    ///
    /// Two scrolls a turn apart, as `openDay`'s: the month first, which lays it out, then the row's
    /// own target once it has laid out. `scrollTo` lands a target's point at fraction `f` on the
    /// container's point at `f`, so a target `h` high has its top at `f × (room − h)`.
    private func jump(to entry: TimelineEntry, then done: @escaping () -> Void = {}) {
        guard let scrollProxy else {
            done()
            return
        }
        let month = MonthKey(containing: entry.date, calendar: calendar)
        isProgrammaticScroll = true
        scrollProxy.scrollTo(month.id, anchor: .top)
        // The row's own scroll needs the row laid out, both to resolve its id and for its height:
        // a turn after the month's scroll it sometimes hasn't been, and the scroll did nothing.
        func scrollToRow(tries: Int) {
            DispatchQueue.main.async {
                guard let rowHeight = rowFrames.frames[entry.id]?.height else {
                    if tries > 0 {
                        scrollToRow(tries: tries - 1)
                    } else {
                        Self.logger.error("A saved row never laid out")
                        isProgrammaticScroll = false
                        done()
                    }
                    return
                }
                let headerHeight = headerHeights[month] ?? 0
                let room = listHeight - bottomClearance - rowHeight
                let top = headerHeight + Tokens.Motion.Card.landingRowOffset
                let fraction = room > 0 ? min(1, max(0, top / room)) : 0
                scrollProxy.scrollTo(OccurrenceRow.rowScrollID(entry.id), anchor: UnitPoint(x: 0.5, y: fraction))
                DispatchQueue.main.async {
                    isProgrammaticScroll = false
                    if hasRestoredPlace { saveCurrentPlace() }
                    done()
                }
            }
        }
        scrollToRow(tries: Self.frameTries)
    }

    /// Times the month button's return starts over when a fling overtakes it.
    private static let returnRestartLimit = 2

    /// Turns a jump waits for its row to lay out before it gives up.
    private static let frameTries = 10

    /// Whether the entry's row is wholly on screen, under the pinned header and above the bottom
    /// row. The list starts under the days' top row; `TimelineSpace` starts at the safe area's top,
    /// as the list's own frame does.
    private func isInView(_ entry: TimelineEntry) -> Bool {
        guard let frame = rowFrames.frames[entry.id] else { return false }
        let month = MonthKey(containing: entry.date, calendar: calendar)
        let listTop = Tokens.Size.headerRow
        return TimelineLanding.isInView(
            frame, listTop: listTop, headerHeight: headerHeights[month] ?? 0,
            listBottom: listTop + listHeight - bottomClearance
        )
    }

    /// A row tap builds the session fresh from the store, keyed on what the entry itself
    /// carries — never from `sections`, which is a snapshot rebuilt on every change. See
    /// "Opening a charge edits it" in `docs/DESIGN.md`.
    private func openEntry(_ entry: TimelineEntry) {
        do {
            guard let session = try EditSession.make(
                expenseID: entry.expenseID, scheduledDate: entry.scheduledDate,
                context: modelContext, calendar: calendar
            ) else { return }
            open(.edit(session))
        } catch {
            Self.logger.error("Opening a charge failed: \(error)")
        }
    }

    /// Opens the editor's sheet. Covered by it and its scrim, the levels' pictures hold the drawing
    /// they have from this moment, so none redraws in the frames the sheet takes to rise.
    private func open(_ request: EditorRequest) {
        BoilClock.shared.listsHeld = true
        editor = request
    }

    /// The editor closed. A save over the days refreshes the months now, so its row is there, lets
    /// the sheet go, then brings the row into view behind it and marks it. Anything else closes the
    /// sheet alone; a save over the calendar's month or year drops the charge into its day.
    private func closeEditor(_ close: EditorClose) {
        guard case .saved(let expenseID, let date) = close,
              mode == .timeline, level == .day, window != nil, !expenses.isEmpty
        else {
            if case .saved(_, let date) = close, mode == .timeline, level != .day {
                arrive(on: date)
            }
            editor = nil
            return
        }
        refreshWindow()
        refreshedOnClose = true
        let entry = TimelineLanding.target(expenseID: expenseID, date: date, in: sections, calendar: calendar)
        editor = nil
        // Outside the window, or hidden by Extras: nothing to show.
        guard let entry else { return }
        markGeneration &+= 1
        let generation = markGeneration
        bringIntoView(entry, generation: generation) { mark(entry, generation: generation) }
    }

    /// Over the calendar's month or year the saved charge drops into its day: the day is marked
    /// arriving from now (its picture held back), the drop begins once the sheet has mostly left, and
    /// the mark is cleared when it is over.
    private func arrive(on date: Date) {
        let day = calendar.startOfDay(for: date)
        arrivingDay = day
        let over = arrivalDelay + Tokens.Motion.Card.dayDropDuration + Tokens.Motion.dayFade + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + over) {
            if arrivingDay == day { arrivingDay = nil }
        }
    }

    /// Two turns for the rebuilt rows to lay out and any anchoring scroll to land, then a `jump` if
    /// the row isn't wholly in view, then `done`.
    private func bringIntoView(_ entry: TimelineEntry, generation: Int, then done: @escaping () -> Void) {
        DispatchQueue.main.async {
            DispatchQueue.main.async {
                guard generation == markGeneration else { return }
                if isInView(entry) {
                    done()
                } else {
                    jump(to: entry, then: done)
                }
            }
        }
    }

    /// Marks the row, then fades the mark a turn later, as a calendar tap's mark fades.
    private func mark(_ entry: TimelineEntry, generation: Int) {
        guard generation == markGeneration else { return }
        markedEntryID = entry.id
        DispatchQueue.main.async {
            guard generation == markGeneration else { return }
            withAnimation(.easeOut(duration: Tokens.Motion.dayMark)) { markedEntryID = nil }
        }
    }

    /// The month button bottom left and All bills and + bottom right, always visible, placed as
    /// Calendar's bottom row is. How far it reaches above the home indicator's safe area, which
    /// grows with Dynamic Type, sets the list's bottom inset so the floor line clears it. See "Getting back" in `docs/DESIGN.md`.
    private func bottomRow(bottomInset: CGFloat) -> some View {
        HStack {
            MonthButton(
                // The year has no month to go back to.
                action: mode == .timeline && level == .year ? nil : {
                    if mode == .categories, let window {
                        categoryMonth = window.current
                    } else if level == .day {
                        returnToResting()
                    } else if let window {
                        calendarMonthID = window.current.id
                    }
                }
            )
            Spacer()
            BottomTrailingControls(onBills: { isBillsPresented = true }, onAdd: { open(.add) })
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
        if let newWindow {
            // The category view starts on the current month, and stays inside the window when
            // a bill's change moves its floor or ceiling past the month it shows.
            let month = window == nil ? newWindow.current : categoryMonth
            categoryMonth = min(max(month, newWindow.floor), newWindow.ceiling)
            // The calendar's month is kept across launches: a stored one outside the window, or
            // none, starts on the current month; after that it's clamped in as the lanes' is.
            if window == nil {
                let stored = Self.monthKey(id: calendarMonthID)
                let inside = calendarMonthID >= 0 && stored >= newWindow.floor && stored <= newWindow.ceiling
                calendarMonthID = (inside ? stored : newWindow.current).id
            } else {
                calendarMonthID = min(max(shownCalendarMonth(in: window ?? newWindow), newWindow.floor), newWindow.ceiling).id
            }
        }
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
        sections[month] ?? MonthSection(
            month: month, entries: [], total: 0, remaining: 0, isCurrent: false, showsExtrasOnly: false
        )
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
    ///
    /// A window that stays as it was is rebuilt without anchoring, a saved row's included: the list
    /// keeps what's on screen still by itself, and re-anchoring to a pinned header (which reads 0
    /// however deep into its month the reader is) would scroll that month's top into view.
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
    private func returnToResting(restarting: Bool = false) {
        guard let window, let scrollProxy else { return }
        if !restarting { returnRestarts = 0 }
        let duration = returnDuration
        let hasDivider = section(for: window.current).hasChargedEntry
        isProgrammaticScroll = true
        // A tap lands while the list is still flying, and an animated `scrollTo` issued then
        // loses to the deceleration already in flight — measured on device: the phase stayed
        // `decelerating`, never became `animating`, and the list carried on to where the fling
        // was going. `scrollDisabled` for a turn didn't stop it on an iPhone; the scroll view's
        // own offset, set to where it is, does, so the return is issued a turn later into a list
        // that is standing still.
        glideStopper.stop()
        DispatchQueue.main.async {
            // Near enough that the divider is laid out: one glide to it. Otherwise the month first,
            // since a lazy list resolves only ids it has laid out, and then on to the divider once
            // the month's glide is over: two animated scrolls a turn apart fight.
            if hasDivider, let divider = rowFrames.frames[TodayDivider.scrollID] {
                withAnimation(.easeInOut(duration: duration)) {
                    scrollProxy.scrollTo(TodayDivider.scrollID, anchor: dividerAnchor(height: divider.height, in: window.current))
                }
                settleReturn(after: duration, atMonthTop: false)
                return
            }
            // Further off, one glide to the month, anchored so the divider lands in the middle as the
            // month arrives. Gliding to the month's top and then on to the divider overshot the line
            // from above and came back (284pt, logged).
            if hasDivider, let top = dividerHeaderTop(in: window.current) {
                let room = containerHeight - (headerHeights[window.current] ?? 0)
                withAnimation(.easeInOut(duration: duration)) {
                    scrollProxy.scrollTo(window.current.id, anchor: UnitPoint(x: 0.5, y: top / room))
                }
                settleReturn(after: duration, atMonthTop: false)
                return
            }
            withAnimation(.easeInOut(duration: duration)) {
                scrollProxy.scrollTo(window.current.id, anchor: .top)
            }
            guard hasDivider else {
                settleReturn(after: duration, atMonthTop: true)
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + Tokens.Motion.returnSettle) {
                guard let divider = rowFrames.frames[TodayDivider.scrollID] else {
                    settleReturn(after: 0, atMonthTop: true)
                    return
                }
                let onward = Tokens.Motion.returnDurationMin
                withAnimation(.easeInOut(duration: onward)) {
                    scrollProxy.scrollTo(TodayDivider.scrollID, anchor: dividerAnchor(height: divider.height, in: window.current))
                }
                settleReturn(after: onward, atMonthTop: false)
            }
        }
    }

    /// The anchor that puts the divider's centre in the middle of what shows of the list: between
    /// the pinned header's bottom and the top of the bottom row's clearance. `scrollTo` lands a
    /// target's point at fraction `f` on the container's point at `f`, the container net of its
    /// bottom margin, so a target `h` high centred at `m` needs `f = (m − h/2) / (C − h)`.
    private func dividerAnchor(height: CGFloat, in month: MonthKey) -> UnitPoint {
        let container = containerHeight
        let middle = ((headerHeights[month] ?? 0) + container) / 2
        let room = container - height
        let fraction = room > 0 ? min(1, max(0, (middle - height / 2) / room)) : 0
        return UnitPoint(x: 0.5, y: fraction)
    }

    /// Where `month`'s header must sit, from the container's top, for the divider to land centred as
    /// `dividerAnchor` puts it: from where the divider sat in its month when last laid out, both
    /// measured in the list's content, which scrolling doesn't move. Nil before it has been laid
    /// out, or when the header would have to sit above the top, which `scrollTo` can't express.
    private func dividerHeaderTop(in month: MonthKey) -> CGFloat? {
        guard let divider = rowFrames.frames[TodayDivider.contentID], let currentContentTop,
              let header = headerHeights[month], containerHeight > header
        else { return nil }
        let fromHeaderTop = divider.midY - (currentContentTop - header)
        let top = (header + containerHeight) / 2 - fromHeaderTop
        guard top >= 0, top <= containerHeight - header else { return nil }
        return top
    }

    /// Once the return's glide is over: the app's own scroll ends, and the place is saved.
    private func settleReturn(after delay: TimeInterval, atMonthTop: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + Tokens.Motion.returnSettle) {
            isProgrammaticScroll = false
            // At the month's top the reader is at the resting position by construction, so
            // `scrollOffset` *is* `restingContentOffset`. Saying so is not belt-and-braces: the
            // cache is normally written as `scrollOffset + frame.minY` from two geometry callbacks
            // that arrive independently, and during an animated scroll they are sampled at
            // different instants — measured on device leaving the cache 702, 493 and 0.2 points
            // wrong across three otherwise identical returns, and the next return's duration is
            // read from it. At the divider it isn't, so the cache is left to the header.
            if atMonthTop { restingContentOffset = scrollOffset }
            // And save it. The scroll-idle save is suppressed while this view's own scroll is
            // in flight, and a fling cut short by this tap never settled to save either — so
            // without this the saved place is wherever the fling was heading, and a relaunch
            // returns there rather than to the place just landed on.
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
    /// `desiredOffset = f × (listHeight − targetHeight)` for `f` reuses that same
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
    /// **The list is shorter than the viewport by the top row,** whose height is fixed, and
    /// **its content area shorter again by `bottomClearance`.** The bottom row gives
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
        let denominator = (listHeight - bottomClearance) - headerHeight
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
            let built = TimelineBuilder.month(
                key, expenses: timelineExpenses, today: today, calendar: calendar, extrasOnly: extrasOnly
            )
            result[key] = MonthSection(
                month: built.month, entries: built.entries, total: built.total,
                remaining: built.remaining, isCurrent: key == window.current,
                showsExtrasOnly: built.showsExtrasOnly
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
