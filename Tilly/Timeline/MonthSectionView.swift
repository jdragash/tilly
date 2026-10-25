import SwiftUI

/// One month's charges, one row each, descending so the future sits above. Draws no header of its own —
/// `TimelineView` supplies that separately, as a `Section` header, so it can pin. This view
/// only ever draws an expanded month's content.
struct MonthSectionView: View {
    let section: MonthSection
    let today: Date
    let showsFirstWeekLine: Bool
    /// The day a calendar tap opened, its rows marked until the mark fades.
    var markedDay: Date?
    /// The row a save just put in place, marked until the mark fades.
    var markedEntryID: String?
    /// Each row's frame in `TimelineSpace` as it changes, and nil as it leaves.
    var onRowFrame: (String, CGRect?) -> Void = { _, _ in }
    let onOpen: (TimelineEntry) -> Void

    /// Where the today divider goes in the current month: before the first row on or before today,
    /// the top of its day. None while nothing is charged yet, or in any other month.
    private var todayDividerIndex: Int? {
        guard section.isCurrent, section.hasChargedEntry else { return nil }
        let start = calendar.startOfDay(for: today)
        return section.entries.firstIndex { $0.date <= start }
    }

    @Environment(\.calendar) private var calendar

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(section.entries.enumerated()), id: \.element.id) { index, entry in
                // Before the day's scroll marker, so a calendar tap on today lands on the row.
                if index == todayDividerIndex {
                    TodayDivider(today: today)
                        .id(TodayDivider.scrollID)
                        .onGeometryChange(for: CGRect.self) { proxy in
                            proxy.frame(in: .named(TimelineSpace.name))
                        } action: { frame in
                            onRowFrame(TodayDivider.scrollID, frame)
                        }
                        .onDisappear { onRowFrame(TodayDivider.scrollID, nil) }
                }
                // A day's first row carries the day's scroll target: zero high, so the
                // target's top is the row's top and landing on it needs no row height.
                if index == 0 || section.entries[index - 1].date != entry.date {
                    Color.clear
                        .frame(height: Tokens.Size.scrollMarker)
                        .id(OccurrenceRow.dayScrollID(entry.date))
                }
                Button {
                    onOpen(entry)
                } label: {
                    // On the label, not the button: a plain button hit-tests its label's
                    // shape, so outside it the gap between name and amount stays dead.
                    OccurrenceRow(
                        entry: entry, today: today,
                        isMarked: entry.date == markedDay || entry.id == markedEntryID
                    )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Edits this charge")
                .id(OccurrenceRow.rowScrollID(entry.id))
                .onGeometryChange(for: CGRect.self) { proxy in
                    proxy.frame(in: .named(TimelineSpace.name))
                } action: { frame in
                    onRowFrame(entry.id, frame)
                }
                .onDisappear { onRowFrame(entry.id, nil) }
            }
            if !section.entries.isEmpty {
                Color.clear
                    .frame(height: Tokens.Space.stackMonthBottom)
            }
            if showsFirstWeekLine {
                Text("This fills in as bills go out.")
                    .font(Tokens.Text.monthTotal)
                    .foregroundStyle(Tokens.Ink.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Tokens.Space.gutter * 2)
                    .padding(.top, Tokens.Space.section)
            }
        }
    }
}
