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
    @State private var scrollProxy: ScrollViewProxy?
    @State private var hasSetRestingPosition = false

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
    /// unless it's the current month or the one after — both always render, empty or not,
    /// because the current month needs its header and its first-week line. See "History
    /// stops where your oldest charge does" in `docs/DESIGN.md`.
    private var visibleMonths: [MonthKey] {
        guard let window else { return [] }
        let nextMonth = window.current.advanced(by: 1)
        return window.months.filter { month in
            month == window.current || month == nextMonth || !(sections[month]?.isEmpty ?? true)
        }
    }

    var body: some View {
        GeometryReader { rootProxy in
            content(topInset: rootProxy.safeAreaInsets.top)
        }
        .onAppear(perform: setUpIfNeeded)
        .onChange(of: expenses) { _, _ in rebuildSections() }
        .onChange(of: sections) { _, _ in restOnCurrentMonthIfNeeded() }
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
                            CollapsedMonthBar(section: section(for: window.top.advanced(by: 1)), today: today, open: {})
                            ForEach(visibleMonths) { month in
                                let monthSection = section(for: month)
                                Section {
                                    MonthSectionView(
                                        section: monthSection,
                                        showsFirstWeekLine: monthSection.isCurrent && !monthSection.hasChargedEntry
                                    )
                                } header: {
                                    MonthHeader(section: monthSection, today: today, isPinned: pinnedMonth == month)
                                        .onGeometryChange(for: CGFloat.self) { proxy in
                                            proxy.frame(in: .named(Self.scrollSpace)).minY
                                        } action: { minY in
                                            headerOffsets[month] = minY
                                        }
                                }
                                .id(month.id)
                            }
                            floorLine(window.floor)
                        }
                        .scrollTargetLayout()
                    }
                    .onAppear { scrollProxy = proxy }
                }
                .coordinateSpace(name: Self.scrollSpace)
                .background(Tokens.Surface.base)
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
