import SwiftUI

/// Carries what is left in the current month, and every other month's plain total —
/// excluding skipped occurrences either way. See "The month header carries what is left,
/// and says so" in `docs/DECISIONS.md`.
///
/// Keeps its size when it pins — condensing would save a point of height and cost three
/// points of type, landing the month you're *in* on the same shape as one you could open.
/// `isPinned` only ever changes the background and the hairline beneath it.
struct MonthHeader: View {
    let section: MonthSection
    let today: Date
    let isPinned: Bool

    init(section: MonthSection, today: Date, isPinned: Bool = false) {
        self.section = section
        self.today = today
        self.isPinned = isPinned
    }

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
        .background {
            // A rule is drawn because something needs closing — at rest there is nothing
            // to close, and pinned there is content moving underneath. See "The month you
            // are reading stays named" in `docs/DESIGN.md`.
            if isPinned {
                Rectangle().fill(Tokens.Surface.pinned)
            }
        }
        .overlay(alignment: .bottom) {
            if isPinned {
                Rectangle()
                    .fill(Tokens.Surface.rule)
                    .frame(height: Tokens.Size.hairline)
                    .padding(.horizontal, Tokens.Space.gutter)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(TimelineFormatting.accessibilityLabel(for: section, calendar: calendar, today: today, locale: locale))
    }

    private var nameText: some View {
        Text(section.month.name(in: calendar, relativeTo: today, locale: locale))
            .font(Tokens.Text.monthName)
            .foregroundStyle(Tokens.Ink.primary)
    }

    private var totalText: some View {
        Text(TimelineFormatting.headerFigure(for: section, locale: locale))
            .font(Tokens.Text.monthTotal)
            .monospacedDigit()
            .foregroundStyle(Tokens.Ink.secondary)
            .fixedSize()
    }
}
