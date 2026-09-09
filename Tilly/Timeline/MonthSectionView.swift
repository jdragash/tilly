import SwiftUI

/// One month's days, descending so the future sits above. Draws no header of its own —
/// `TimelineView` supplies that separately, as a `Section` header, so it can pin. This view
/// only ever draws an expanded month's content.
struct MonthSectionView: View {
    let section: MonthSection
    let showsFirstWeekLine: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(section.days) { day in
                DayGroupView(group: day)
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
