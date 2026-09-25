import SwiftUI

/// Floats above the lanes while a finger drags across them, centred on the line and clamped to
/// the gutters: the day, then each of that day's charges as emoji, name and amount, the ones
/// still to come at secondary weight. Nothing else: no running total. Glass, because it floats
/// over content. See "The category view" in `docs/DESIGN.md`.
struct CategoryReadout: View {
    let date: Date
    let charges: [TimelineEntry]
    let emojiOf: (TimelineEntry) -> String?

    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(CategoryFormatting.readoutDate(date, calendar: calendar, locale: locale))
                .font(Tokens.Text.readoutDate)
                .foregroundStyle(Tokens.Ink.primary)
                .padding(.bottom, Tokens.Space.readoutDateBottom)
            ForEach(charges) { charge in
                HStack(spacing: Tokens.Space.readoutGap) {
                    Text(emojiOf(charge) ?? "")
                    Text(charge.name)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(TimelineFormatting.amount(charge.amount, locale: locale))
                        .monospacedDigit()
                }
                .font(Tokens.Text.readoutRow)
                .foregroundStyle(charge.state == .upcoming ? Tokens.Ink.secondary : Tokens.Ink.primary)
                .padding(.vertical, Tokens.Space.readoutRowVertical)
            }
        }
        .padding(.horizontal, Tokens.Space.readoutHorizontal)
        .padding(.vertical, Tokens.Space.readoutVertical)
        .frame(minWidth: Tokens.Size.readoutMinWidth, maxWidth: Tokens.Size.readoutMaxWidth, alignment: .leading)
        .fixedSize()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Tokens.Radius.readout))
        // VoiceOver reads each dot's own label; this follows a finger it can't see.
        .accessibilityHidden(true)
    }
}

/// What the readout shows and where its line is, handed up from the category view to the shell,
/// which draws it above the header's glass controls; drawn inside the category view it sat
/// beneath them.
struct CategoryReadoutPlacement: Equatable {
    let date: Date
    let charges: [TimelineEntry]
    /// Each charge's emoji, by `TimelineEntry.id`.
    let emojis: [String: String]
    /// The line's x, and the top of the lanes' axis, in the category view, which fills the shell.
    let lineX: CGFloat
    let lanesTop: CGFloat
}

struct CategoryReadoutKey: PreferenceKey {
    static let defaultValue: CategoryReadoutPlacement? = nil
    static func reduce(value: inout CategoryReadoutPlacement?, nextValue: () -> CategoryReadoutPlacement?) {
        value = nextValue() ?? value
    }
}

/// Places the readout: centred on the line and clamped to the gutters, `readoutClearance` above
/// the lanes' axis, over the header when it has to be, never above the top of the screen.
struct CategoryReadoutLayer: View {
    let placement: CategoryReadoutPlacement?

    @State private var size: CGSize = .zero

    var body: some View {
        GeometryReader { proxy in
            if let placement {
                let x = min(max(placement.lineX - size.width / 2, Tokens.Space.gutter),
                            proxy.size.width - Tokens.Space.gutter - size.width)
                let y = max(placement.lanesTop - Tokens.Space.readoutClearance - size.height, Tokens.Space.headerRowInset)
                CategoryReadout(date: placement.date, charges: placement.charges, emojiOf: { placement.emojis[$0.id] })
                    .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
                    // Unplaced until it has been measured once, rather than a frame in the wrong place.
                    .opacity(size == .zero ? 0 : 1)
                    .offset(x: x, y: y)
            }
        }
        .allowsHitTesting(false)
    }
}
