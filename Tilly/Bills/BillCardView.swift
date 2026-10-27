import SwiftUI

/// One category's bills in All bills, read only: a paper card with its picture, name and total in a
/// header, then a row for each bill. Nothing in it opens. See `Tokens.Bills` for the measurements.
struct BillCardView: View {
    let card: BillCard
    let period: BillPeriod
    let today: Date

    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        BillCardFrame(colour: card.category?.colour, seed: stableSeed(card.id)) {
            header
            ForEach(card.rows) { row in
                BillRowView(row: row, period: period, today: today, trailing: .figure)
            }
        }
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                // Stacked: the name and the total each want the whole width at this size.
                VStack(alignment: .leading, spacing: Tokens.Space.tight) {
                    HStack(spacing: Tokens.Bills.pictureToName) {
                        picture
                        nameText(lines: nil)
                    }
                    totalText
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Tokens.Bills.rowGrownPadding)
            } else {
                HStack(spacing: Tokens.Bills.pictureToName) {
                    picture
                    nameText(lines: 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    totalText
                        .layoutPriority(1)
                }
            }
        }
        .frame(minHeight: Tokens.Bills.headerHeight)
        .padding(.leading, Tokens.Bills.headerLeading)
        .padding(.trailing, Tokens.Bills.headerTrailing)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(card.category?.name ?? BillsFormatting.uncategorisedName), "
                + "\(TimelineFormatting.spokenAmount(card.total, locale: locale)) a \(period.rawValue)"
        )
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder private var picture: some View {
        if let picture = card.category?.picture, !picture.isNone {
            CategoryPictureView(
                picture: picture, colour: card.category?.colour, size: Tokens.Size.pictureBillCard, round: true
            )
        }
    }

    private func nameText(lines: Int?) -> some View {
        Text(card.category?.name ?? BillsFormatting.uncategorisedName)
            .font(Tokens.Bills.headerNameFont(dynamicTypeSize))
            .foregroundStyle(Tokens.Ink.primary)
            .lineLimit(lines)
            .truncationMode(.tail)
    }

    private var totalText: some View {
        Text(TimelineFormatting.amount(card.total, locale: locale))
            .font(Tokens.Bills.headerTotalFont(dynamicTypeSize))
            .monospacedDigit()
            .foregroundStyle(Tokens.Ink.primary)
    }
}

/// The bills that have ended, in a card of their own with no header: each its name, when it ended,
/// and what it cost in all.
struct EndedBillsCard: View {
    let rows: [BillRow]
    let period: BillPeriod
    let today: Date
    let picture: (BillRow) -> CategoryPicture

    var body: some View {
        BillCardFrame(colour: nil, seed: stableSeed("ended")) {
            ForEach(rows) { row in
                BillRowView(
                    row: row, period: period, today: today, trailing: .paidInAll, picture: picture(row),
                    showsRule: row.id != rows.first?.id
                )
            }
        }
    }
}

/// The paper a card's content sits on, with its colour strip along the bottom.
private struct BillCardFrame<Content: View>: View {
    let colour: CategoryColour?
    let seed: UInt64
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(.bottom, Tokens.Bills.cardBottom)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            CategoryCardBackground(
                colour: colour, seed: seed, radius: Tokens.Bills.cardRadius, strip: Tokens.Bills.cardStrip,
                wobble: Tokens.Drawn.pickerCardWobble, shadowColour: Tokens.Bills.shadowColour,
                shadowRadius: Tokens.Bills.shadowRadius, shadowY: Tokens.Bills.shadowY
            )
        }
    }
}

/// A bill: its name, a note on its rhythm and state on the same line, and what it comes to in the
/// period. Stacks at the accessibility sizes, filling the width as `OccurrenceRow` does.
struct BillRowView: View {
    enum Trailing { case figure, paidInAll }

    let row: BillRow
    let period: BillPeriod
    let today: Date
    let trailing: Trailing
    var picture: CategoryPicture = .none
    var showsRule = true

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var note: String {
        BillsFormatting.note(for: row, period: period, today: today, calendar: calendar, locale: locale)
    }

    private var value: Decimal? {
        trailing == .figure ? row.figure : row.paidInAll
    }

    private var valueText: String {
        TimelineFormatting.amount(value, locale: locale)
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Tokens.Space.tight) {
                    nameText(lines: nil)
                    if !note.isEmpty { noteText(lines: nil) }
                    valueView
                }
                .padding(.vertical, Tokens.Bills.rowGrownPadding)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    nameText(lines: 1)
                        .layoutPriority(1)
                    noteText(lines: 1)
                        .padding(.leading, Tokens.Bills.rowNameToNote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    valueView
                        .padding(.leading, Tokens.Bills.rowNoteToFigure)
                        .layoutPriority(2)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: Tokens.Bills.rowHeight, alignment: .leading)
        .overlay(alignment: .top) {
            if showsRule {
                Rectangle()
                    .fill(Tokens.Drawn.hairline)
                    .frame(height: Tokens.Size.hairline)
            }
        }
        .padding(.horizontal, Tokens.Bills.rowInset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
    }

    private func nameText(lines: Int?) -> some View {
        Text("\(picture.inline) \(row.name)")
            .font(Tokens.Bills.rowNameFont(dynamicTypeSize))
            .foregroundStyle(Tokens.Ink.primary)
            .lineLimit(lines)
            .truncationMode(.tail)
    }

    private func noteText(lines: Int?) -> some View {
        Text(note)
            .font(Tokens.Bills.rowNoteFont)
            .foregroundStyle(Tokens.Drawn.ink2)
            .lineLimit(lines)
            .truncationMode(.tail)
    }

    private var valueView: some View {
        Text(valueText)
            .font(Tokens.Bills.rowFigureFont(dynamicTypeSize))
            .monospacedDigit()
            .foregroundStyle(trailing == .paidInAll ? Tokens.Drawn.ink2 : Tokens.Ink.primary)
    }

    private var spokenLabel: String {
        let amount = value.map { TimelineFormatting.spokenAmount($0, locale: locale) }
        let spoken: String = switch trailing {
        case .figure: amount.map { "\($0) a \(period.rawValue)" } ?? "amount not yet known"
        case .paidInAll: amount.map { "\($0) in all" } ?? "nothing paid"
        }
        return ([row.name] + (note.isEmpty ? [] : [note]) + [spoken]).joined(separator: ", ")
    }
}
