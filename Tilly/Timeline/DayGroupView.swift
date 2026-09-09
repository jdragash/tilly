import SwiftUI

/// Two or more charges on one day collapse under a heading with a day total; one charge is
/// an ordinary row carrying its own date. See "A day is grouped only when it holds more
/// than one charge" in `docs/DECISIONS.md`.
struct DayGroupView: View {
    let group: DayGroup

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    private var headingInk: Color {
        group.state == .charged ? Tokens.Ink.secondary : Tokens.Ink.tertiary
    }

    var body: some View {
        if group.isGrouped {
            groupedBody
        } else if let entry = group.entries.first {
            OccurrenceRow(entry: entry)
        }
    }

    private var groupedBody: some View {
        VStack(spacing: 0) {
            heading
                .padding(.top, Tokens.Space.gap)
            hairline
                .padding(.top, Tokens.Space.hairlineGap)
            ForEach(group.entries) { entry in
                OccurrenceRow(entry: entry, showsDate: false)
            }
            hairline
                .padding(.bottom, Tokens.Space.tight)
        }
    }

    private var heading: some View {
        HStack {
            Text(TimelineFormatting.dayLine(group.date, calendar: calendar, locale: locale))
                .font(Tokens.Text.dayHeading)
                .tracking(Tokens.Tracking.dayHeading)
                .foregroundStyle(headingInk)
            Spacer()
            Text(TimelineFormatting.amount(group.total, locale: locale))
                .font(Tokens.Text.dayTotal)
                .monospacedDigit()
                .foregroundStyle(headingInk)
                .fixedSize()
        }
        .padding(.horizontal, Tokens.Space.gutter)
        .accessibilityElement(children: .combine)
    }

    private var hairline: some View {
        Rectangle()
            .fill(Tokens.Surface.rule)
            .frame(height: Tokens.Size.hairline)
            .padding(.horizontal, Tokens.Space.gutter)
    }
}
