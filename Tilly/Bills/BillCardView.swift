import SwiftUI

/// One category's bills in All bills: its emoji, name and total on a line, then a row for each
/// bill. A row is a button that opens the bill's next charge.
struct BillCardView: View {
    let card: BillCard
    let period: BillPeriod
    let onOpen: (BillRow) -> Void

    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        BillCardFrame {
            header
            ForEach(card.rows) { row in
                BillRowView(row: row, period: period, trailing: .figure, onOpen: onOpen)
            }
        }
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // Stacked: the name and the total each want the whole width at this size.
                VStack(alignment: .leading, spacing: Tokens.Space.tight) {
                    HStack(spacing: Tokens.Space.gap) {
                        emoji
                        nameText
                    }
                    totalText
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: Tokens.Space.gap) {
                    emoji
                    nameText
                        .frame(maxWidth: .infinity, alignment: .leading)
                    totalText
                        .layoutPriority(1)
                }
            }
        }
        .padding(.bottom, Tokens.Space.cardHeaderBottom)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(card.category?.name ?? BillsFormatting.uncategorisedName), "
                + "\(TimelineFormatting.spokenAmount(card.total, locale: locale)) a \(period.rawValue)"
        )
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder private var emoji: some View {
        if let emoji = card.category?.emoji {
            Text(emoji)
                .font(Tokens.Text.billCardEmoji)
                .accessibilityHidden(true)
        }
    }

    private var nameText: some View {
        Text(card.category?.name ?? BillsFormatting.uncategorisedName)
            .font(Tokens.Text.billCardName)
            .foregroundStyle(Tokens.Ink.primary)
    }

    private var totalText: some View {
        Text(TimelineFormatting.amount(card.total, locale: locale))
            .font(Tokens.Text.billCardTotal)
            .monospacedDigit()
            .foregroundStyle(Tokens.Ink.primary)
    }
}

/// The bills that have ended, in a card of their own: each its name, when it ended, and what it
/// cost in all.
struct EndedBillsCard: View {
    let rows: [BillRow]
    let period: BillPeriod
    let emoji: (BillRow) -> String?
    let onOpen: (BillRow) -> Void

    var body: some View {
        BillCardFrame {
            ForEach(rows) { row in
                BillRowView(
                    row: row, period: period, trailing: .paidInAll, emoji: emoji(row),
                    showsRule: row.id != rows.first?.id, onOpen: onOpen
                )
            }
        }
    }
}

/// The rounded ground a card's content sits on, inset from the screen as the prototype's is.
private struct BillCardFrame<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(.top, Tokens.Space.cardTop)
        .padding(.horizontal, Tokens.Space.cardSides)
        .padding(.bottom, Tokens.Space.cardBottom)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Tokens.Surface.card, in: RoundedRectangle(cornerRadius: Tokens.Radius.card))
        .padding(.horizontal, Tokens.Space.cardInset)
    }
}

/// A bill: its name, a note on its rhythm and state, and what it comes to in the period. Stacks
/// at the accessibility sizes, filling the width as `OccurrenceRow` does.
struct BillRowView: View {
    enum Trailing { case figure, paidInAll }

    let row: BillRow
    let period: BillPeriod
    let trailing: Trailing
    var emoji: String?
    var showsRule = true
    let onOpen: (BillRow) -> Void

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var note: String {
        BillsFormatting.note(for: row, period: period, calendar: calendar, locale: locale)
    }

    private var value: Decimal? {
        trailing == .figure ? row.figure : row.paidInAll
    }

    private var valueText: String {
        TimelineFormatting.amount(value, locale: locale)
    }

    var body: some View {
        Button { onOpen(row) } label: {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: Tokens.Space.tight) {
                        nameText
                        noteText(lines: nil)
                        valueView
                    }
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: Tokens.Space.billRowGap) {
                        nameText
                            .layoutPriority(1)
                        noteText(lines: 1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        valueView
                            .layoutPriority(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, Tokens.Space.billRowVertical)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            if showsRule {
                Rectangle()
                    .fill(Tokens.Surface.rule)
                    .frame(height: Tokens.Size.hairline)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
        .accessibilityHint(trailing == .paidInAll ? "Opens its last charge" : "Opens its next charge")
    }

    private var nameText: some View {
        Text(emoji.map { "\($0) \(row.name)" } ?? row.name)
            .font(Tokens.Text.billName)
            .foregroundStyle(Tokens.Ink.primary)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
    }

    private func noteText(lines: Int?) -> some View {
        Text(note)
            .font(Tokens.Text.billNote)
            .foregroundStyle(Tokens.Ink.secondary)
            .lineLimit(lines)
            .truncationMode(.tail)
    }

    private var valueView: some View {
        Text(valueText)
            .font(Tokens.Text.billFigure)
            .monospacedDigit()
            .foregroundStyle(trailing == .paidInAll ? Tokens.Ink.secondary : Tokens.Ink.primary)
    }

    private var spokenLabel: String {
        let amount = value.map { TimelineFormatting.spokenAmount($0, locale: locale) }
        switch trailing {
        case .figure:
            return "\(row.name), \(note), " + (amount.map { "\($0) a \(period.rawValue)" } ?? "amount not yet known")
        case .paidInAll:
            return "\(row.name), \(note), " + (amount.map { "\($0) in all" } ?? "nothing paid")
        }
    }
}
