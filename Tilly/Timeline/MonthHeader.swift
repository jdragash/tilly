import SwiftUI

/// Carries what is left in the current month, and every other month's plain total —
/// excluding skipped occurrences either way. See "The month header" in
/// `docs/DESIGN.md`.
///
/// Keeps its size when it pins — condensing would save a point of height and cost three
/// points of type, landing the month you're *in* on the same shape as one you could open.
/// `isPinned` only ever changes the hairline beneath it.
///
/// The figure sits under the name on its own line. The row is shared with the glass pair, which
/// floats over the trailing end, so the trailing edge keeps `trailingClearance` clear. Its minimum
/// height is `Tokens.Size.headerRow`, the band the pair is centred in, with the text centred too.
struct MonthHeader: View {
    let section: MonthSection
    let today: Date
    let isPinned: Bool
    /// Replaces the section's own figure when set, as a picked-out category's total does.
    let figure: String?
    /// Leads the figure, as a picked-out category's emoji and name do. It gives way first: it
    /// shrinks, then truncates, and the figure after it never does.
    let figureLabel: String?
    let trailingClearance: CGFloat

    init(section: MonthSection, today: Date, isPinned: Bool = false,
         figure: String? = nil, figureLabel: String? = nil,
         trailingClearance: CGFloat = Tokens.Space.headerTrailingClearance) {
        self.section = section
        self.today = today
        self.isPinned = isPinned
        self.figure = figure
        self.figureLabel = figureLabel
        self.trailingClearance = trailingClearance
    }

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // Accessibility sizes wrap rather than shrink: the row grows here anyway.
                VStack(alignment: .leading, spacing: Tokens.Space.tight) {
                    nameText
                    figureText(label: figureLabel.map { "\($0) " })
                        .fixedSize(horizontal: false, vertical: true)
                }
                // See the note in `OccurrenceRow`: the standard branch is held to full
                // width by its `Spacer()`, and this one has nothing to do that job.
                .frame(maxWidth: .infinity, alignment: .leading)
                // Stacked, the header outgrows the row + sits in, so it takes the row's own
                // clear space above and below rather than touching the hairline.
                .padding(.vertical, Tokens.Space.headerRowInset)
            } else {
                // One line each, shrinking and then truncating before they'd wrap: a second line
                // would grow the row and move everything under it. The category view leaves the
                // header 134pt beside its arrows (iPhone 17).
                VStack(alignment: .leading, spacing: 0) {
                    nameText
                        .lineLimit(1)
                        .minimumScaleFactor(Tokens.Scale.headerMin)
                    // A gap rather than a space inside the label, which truncation would eat.
                    HStack(spacing: Tokens.Space.figureLabelGap) {
                        if let figureLabel {
                            Text(figureLabel)
                                .lineLimit(1)
                                .minimumScaleFactor(Tokens.Scale.headerMin)
                                .font(Tokens.Text.monthTotal)
                                .foregroundStyle(Tokens.Ink.secondary)
                        }
                        figureText(label: nil)
                            .fixedSize()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.leading, Tokens.Space.gutter)
        .padding(.trailing, trailingClearance)
        .frame(minHeight: Tokens.Size.headerRow)
        // Carried at rest as well as pinned. The pinned ground is the same paper as the
        // page, so drawing it unconditionally looks identical at rest — and it removes the
        // frame, right after a month opens and every header is remeasured, where `isPinned`
        // was briefly false and the header rendered with no ground at all. Deriving it from
        // measured geometry is still right; letting the *background* depend on that
        // geometry was not.
        .background(Tokens.Surface.pinned)
        .overlay(alignment: .bottom) {
            // A rule is drawn because something needs closing — at rest there is nothing to
            // close, and pinned there is content moving underneath. See "The month you're
            // reading stays named" in `docs/DESIGN.md`.
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

    /// The figure, after `label` when there is one.
    private func figureText(label: String?) -> some View {
        Text((label ?? "") + (figure ?? TimelineFormatting.headerFigure(for: section, locale: locale)))
            .font(Tokens.Text.monthTotal)
            .monospacedDigit()
            .foregroundStyle(Tokens.Ink.secondary)
    }
}
