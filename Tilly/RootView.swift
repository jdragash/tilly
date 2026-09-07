import SwiftData
import SwiftUI

struct RootView: View {
    @Query private var expenses: [Expense]
    @Environment(\.calendar) private var calendar

    @State private var today = Date()
    @State private var section: MonthSection?

    var body: some View {
        Group {
            if expenses.isEmpty {
                TimelineEmptyState()
            } else if let section {
                ScrollView {
                    MonthSectionView(section: section, today: today, showsFirstWeekLine: !section.hasChargedEntry)
                }
            }
        }
        .background(Tokens.Surface.base)
        .onAppear(perform: rebuildSection)
        .onChange(of: expenses.count) { _, _ in rebuildSection() }
    }

    private func rebuildSection() {
        today = Date()
        let month = MonthKey(containing: today, calendar: calendar)
        section = TimelineBuilder.month(month, expenses: expenses.map(\.timelineExpense), today: today, calendar: calendar)
    }
}

#Preview("Seeded current month") {
    let container = try! TillyStore.container(inMemory: true)
    try! SampleData.insert(into: container.mainContext, today: Date(), calendar: .current)
    return RootView()
        .modelContainer(container)
}

#Preview("Empty state") {
    RootView()
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
    return RootView()
        .modelContainer(container)
}
