import SwiftUI

/// One month's charges, one row each, descending so the future sits above. Draws no header of its own —
/// `TimelineView` supplies that separately, as a `Section` header, so it can pin. This view
/// only ever draws an expanded month's content.
struct MonthSectionView: View {
    let section: MonthSection
    let showsFirstWeekLine: Bool
    let onOpen: (TimelineEntry) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(section.entries) { entry in
                Button {
                    onOpen(entry)
                } label: {
                    // On the label, not the button: a plain button hit-tests its label's
                    // shape, so outside it the gap between name and amount stays dead.
                    OccurrenceRow(entry: entry)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Edits this charge")
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
