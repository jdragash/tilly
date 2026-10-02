import SwiftUI

/// One day of the month grid: its number, the emoji of its costliest charges, and its total. A
/// day with charges is a button; an empty one is its number alone.
struct CalendarDayCell: View {
    let day: CalendarDay
    let isToday: Bool
    let onOpen: () -> Void

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    var body: some View {
        if day.entries.isEmpty {
            content
        } else {
            Button(action: onOpen) {
                content
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(CalendarFormatting.dayLabel(day, calendar: calendar, locale: locale))
            .accessibilityHint("Opens the day's charges")
        }
    }

    /// Every cell lays out from the top, so a week's numbers sit on one line at every size: the
    /// number in a slot of its own, and the emoji and total share what the row has left under it.
    /// When they don't fit, as in a six-week row at the largest size the grid allows, the total
    /// shrinks; the number never moves.
    private var content: some View {
        VStack(spacing: 0) {
            number
                .layoutPriority(1)
            if !day.entries.isEmpty {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    emoji
                        .opacity(day.isUpcoming ? Tokens.Opacity.upcomingIcon : 1)
                    Spacer(minLength: 0)
                    Text(TimelineFormatting.amount(day.total, locale: locale))
                        .font(Tokens.Text.dayTotal)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(Tokens.Scale.dayTotalMin)
                        .foregroundStyle(day.isUpcoming ? Tokens.Ink.secondary : Tokens.Ink.primary)
                }
                .frame(maxHeight: .infinity)
            }
        }
        .padding(.top, Tokens.Space.cellTop)
        .padding(.bottom, Tokens.Space.cellBottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder private var number: some View {
        if isToday {
            Text("\(day.day)")
                .font(Tokens.Text.dayNumberToday)
                .foregroundStyle(Tokens.Ink.onToday)
                .frame(width: Tokens.Size.todayCircle, height: Tokens.Size.todayCircle)
                .background(Circle().fill(Tokens.Ink.today))
        } else {
            Text("\(day.day)")
                .font(Tokens.Text.dayNumber)
                .foregroundStyle(Tokens.Ink.primary)
                .frame(height: Tokens.Size.todayCircle)
        }
    }

    /// The costliest charge's emoji; two overlapped, the costliest on top, and "+N" for the rest.
    @ViewBuilder private var emoji: some View {
        let emojis = day.entries.prefix(2).map { $0.emoji ?? "" }
        if emojis.count == 1 {
            Text(emojis[0]).font(Tokens.Text.dayEmoji)
        } else {
            HStack(spacing: 0) {
                HStack(spacing: -Tokens.Space.emojiOverlap) {
                    Text(emojis[0]).zIndex(1)
                    Text(emojis[1])
                }
                .font(Tokens.Text.dayEmojiPair)
                if day.entries.count > 2 {
                    Text("+\(day.entries.count - 2)")
                        .font(Tokens.Text.dayMore)
                        .foregroundStyle(Tokens.Ink.secondary)
                        .padding(.leading, Tokens.Space.dayMoreGap)
                }
            }
        }
    }
}
