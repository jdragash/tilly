import SwiftUI

/// One month: its header, then each day descending so the future sits above. Step 5 adds
/// the collapsed bars either side; this view only ever draws an expanded month.
struct MonthSectionView: View {
    let section: MonthSection
    let today: Date
    let showsFirstWeekLine: Bool

    var body: some View {
        VStack(spacing: 0) {
            MonthHeader(section: section, today: today)
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
