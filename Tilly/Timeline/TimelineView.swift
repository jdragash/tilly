import SwiftData
import SwiftUI

/// The expanded months, and the bars either side. `high` is the later month and sits above;
/// `low` is the earlier month and sits below. At most `maxOpen` are expanded — opening a
/// third collapses the far end, which is why the openers say which way the reader is
/// travelling. There is no `closeAbove`/`closeBelow`: nothing closes except by being pushed
/// out of the cap. See "An opened month closes by cap, not by scrolling" in
/// `docs/DECISIONS.md`.
struct ExpandedRange: Equatable, Sendable {
    static let maxOpen = 2

    private(set) var low: MonthKey
    private(set) var high: MonthKey

    init(anchor: MonthKey) {
        low = anchor
        high = anchor
    }

    /// Descending: the future sits above.
    var months: [MonthKey] {
        var result: [MonthKey] = []
        var key = high
        while key >= low {
            result.append(key)
            key = key.advanced(by: -1)
        }
        return result
    }

    var barAbove: MonthKey { high.advanced(by: 1) }
    var barBelow: MonthKey { low.advanced(by: -1) }

    mutating func openAbove() {
        high = high.advanced(by: 1)
        capFromBelow()
    }

    mutating func openBelow() {
        low = low.advanced(by: -1)
        capFromAbove()
    }

    /// Extends the range upward to include `month`, then caps it. Used when midnight rolls
    /// the calendar into a new month, so the new month opens above the reader, in space they
    /// were not occupying.
    mutating func includeCurrentMonth(_ month: MonthKey) {
        guard month > high else { return }
        high = month
        capFromBelow()
    }

    private func monthCount() -> Int { high.id - low.id + 1 }

    private mutating func capFromBelow() {
        while monthCount() > Self.maxOpen {
            low = low.advanced(by: 1)
        }
    }

    private mutating func capFromAbove() {
        while monthCount() > Self.maxOpen {
            high = high.advanced(by: -1)
        }
    }
}

/// One month expanded, its neighbours as collapsed bars. See "One month at a time, with its
/// neighbours collapsed" in `docs/DESIGN.md`.
struct TimelineView: View {
    @Query private var expenses: [Expense]
    @Environment(\.calendar) private var calendar

    @State private var today = Date()
    @State private var range: ExpandedRange?
    @State private var sections: [MonthKey: MonthSection] = [:]
    @State private var headerOffsets: [MonthKey: CGFloat] = [:]

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
        range?.months.last { (headerOffsets[$0] ?? .infinity) <= 0 }
    }

    var body: some View {
        Group {
            if expenses.isEmpty {
                TimelineEmptyState()
            } else if let range {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        CollapsedMonthBar(section: section(for: range.barAbove), direction: .above, today: today, open: openAbove)
                        ForEach(range.months) { month in
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
                        }
                        CollapsedMonthBar(section: section(for: range.barBelow), direction: .below, today: today, open: openBelow)
                    }
                    .scrollTargetLayout()
                }
                .coordinateSpace(name: Self.scrollSpace)
                .background(Tokens.Surface.base)
            }
        }
        .onAppear(perform: setUpIfNeeded)
        .onChange(of: expenses) { _, _ in rebuildSections() }
    }

    private func section(for month: MonthKey) -> MonthSection {
        // The placeholder shown for a month `rebuildSections()` hasn't populated yet — never
        // the current month's real answer, so `isCurrent: false` here is a deliberate "not
        // known yet", not a claim.
        sections[month] ?? MonthSection(month: month, days: [], total: 0, remaining: 0, isCurrent: false)
    }

    private func setUpIfNeeded() {
        guard range == nil else { return }
        today = Date()
        range = ExpandedRange(anchor: MonthKey(containing: today, calendar: calendar))
        rebuildSections()
    }

    private func openAbove() {
        range?.openAbove()
        rebuildSections()
    }

    private func openBelow() {
        range?.openBelow()
        rebuildSections()
    }

    private func rebuildSections() {
        guard let range else { return }
        let current = MonthKey(containing: today, calendar: calendar)
        let visibleMonths = [range.barAbove] + range.months + [range.barBelow]
        let timelineExpenses = expenses.map(\.timelineExpense)

        var result: [MonthKey: MonthSection] = [:]
        for month in visibleMonths {
            let built = TimelineBuilder.month(month, expenses: timelineExpenses, today: today, calendar: calendar)
            result[month] = MonthSection(
                month: built.month, days: built.days, total: built.total,
                remaining: built.remaining, isCurrent: month == current
            )
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
