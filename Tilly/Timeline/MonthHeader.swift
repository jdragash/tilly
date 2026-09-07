import SwiftUI

/// Carries the month's total, excluding skipped occurrences — the same figure a collapsed
/// bar shows for this month, from the same `MonthSection`. See "Month headers carry the
/// month's total" in `docs/DECISIONS.md`.
struct MonthHeader: View {
    let section: MonthSection
    let today: Date

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Tokens.Space.tight) {
                    nameText
                    totalText
                }
                // See the note in `OccurrenceRow`: the standard branch is held to full
                // width by its `Spacer()`, and this one has nothing to do that job.
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack {
                    nameText
                    Spacer()
                    totalText
                }
            }
        }
        .padding(.horizontal, Tokens.Space.gutter)
        .padding(.top, Tokens.Space.section)
        .padding(.bottom, Tokens.Space.tight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(TimelineFormatting.accessibilityLabel(for: section, calendar: calendar, today: today, locale: locale))
    }

    private var nameText: some View {
        Text(section.month.name(in: calendar, relativeTo: today, locale: locale))
            .font(Tokens.Text.monthName)
            .foregroundStyle(Tokens.Ink.primary)
    }

    private var totalText: some View {
        Text(TimelineFormatting.amount(section.total, locale: locale))
            .font(Tokens.Text.monthTotal)
            .monospacedDigit()
            .foregroundStyle(Tokens.Ink.secondary)
            .fixedSize()
    }
}
