import SwiftUI

/// A flight in progress. The layer draws `front` until the turn passes 90°, then `back`.
struct CardFlight: Equatable {
    enum Kind: Equatable {
        case landing(flips: Bool)
        case opening(flips: Bool)
    }

    let kind: Kind
    /// The back is this row.
    let entry: TimelineEntry
    /// The back's corners, as in its month.
    let isLast: Bool
    /// The editor's card, in `CardFlightLayer.space`. An opening aims at where it last rested, and is
    /// corrected if the sheet's card reports another place.
    var cardFrame: CGRect
    /// The row at its full height, in `CardFlightLayer.space`.
    var rowFrame: CGRect
    /// 0 … 1: 0 the front up, 1 the back up.
    var turn: Double
    /// 0 … 1: 0 at the card, 1 at the row. A bouncing spring carries it a little past 1.
    var travel: CGFloat

    var flips: Bool {
        switch kind {
        case .landing(let flips), .opening(let flips): flips
        }
    }

    /// A charged landing crossfades the card into its back over this much of the travel.
    static let landingFade: CGFloat = 0.65
    /// A charged opening fades the card in between these points of the travel, coming up.
    static let openingFade: ClosedRange<CGFloat> = 0.05...0.45

    /// How far an opening travels before a flipping card turns over: in place, rather than after the
    /// spring's last fraction of a point.
    static let openingTurnsAt: Double = 0.985

    /// When a spring from 0 to 1 first reaches `fraction` of the way, in seconds: an animated value
    /// can't be watched, so the turn that follows an opening's travel is timed from the spring.
    nonisolated static func time(toReach fraction: Double, duration: TimeInterval, bounce: Double) -> TimeInterval {
        let spring = Spring(duration: duration, bounce: bounce)
        let step: TimeInterval = 1.0 / 240
        let limit = max(duration, spring.settlingDuration)
        var time: TimeInterval = 0
        while time < limit {
            if spring.value(target: 1.0, time: time) >= fraction { return time }
            time += step
        }
        return limit
    }

    /// Where the flyer is at `travel`: straight from the card to the row, its size with it, past
    /// the row while a spring overshoots.
    func frame(at travel: CGFloat) -> CGRect {
        func lerp(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * travel }
        return CGRect(
            x: lerp(cardFrame.minX, rowFrame.minX),
            y: lerp(cardFrame.minY, rowFrame.minY),
            width: max(0, lerp(cardFrame.width, rowFrame.width)),
            height: max(0, lerp(cardFrame.height, rowFrame.height))
        )
    }

    /// How far the back has become the row: its corners and inset, 0 the card's, 1 the row's.
    static func morph(at travel: CGFloat) -> CGFloat {
        min(1, max(0, travel))
    }

    /// The faces' opacities for a flight that doesn't turn: a landing crossfades the card into the
    /// back as it leaves; an opening fades the card in over the back as it arrives. A turning
    /// flight shows whichever face is up, whole.
    func faceOpacities(at travel: CGFloat) -> (front: Double, back: Double) {
        switch kind {
        case .landing:
            let back = Double(min(1, max(0, travel / Self.landingFade)))
            return (1 - back, back)
        case .opening:
            let span = Self.openingFade.upperBound - Self.openingFade.lowerBound
            let front = Double(min(1, max(0, (Self.openingFade.upperBound - travel) / span)))
            return (front, 1)
        }
    }

    /// The card as one picture, scaled to fit `size` whole, never re-laid out (`editor.md`).
    func frontScale(in size: CGSize) -> CGFloat {
        guard cardFrame.width > 0, cardFrame.height > 0 else { return 1 }
        return max(0, min(size.width / cardFrame.width, size.height / cardFrame.height))
    }
}

/// What the editor's card wore as it closed: the flyer's front is drawn from it.
struct EditorCardFace {
    let draft: ExpenseDraft
    let category: ExpenseCategory?
}

extension EnvironmentValues {
    /// The editor's card hides while a flyer stands in for it.
    @Entry var editorCardHidden = false
}

/// The card in flight between the editor's sheet and its row, over everything, the sheet included.
/// While a card flies the layer takes every touch, and the first finishes the flight (TASTE 12).
struct CardFlightLayer: View {
    /// The named coordinate space on `TimelineView`'s root that every frame here is in. It starts
    /// at the safe area's top, as the timeline's root does.
    static let space = "cardFlight"

    @Binding var flight: CardFlight?
    /// The live card, nothing focused, not hit-testable.
    let front: () -> EditorCard
    /// Finishes the flight at once (TASTE 12).
    let onTapDuringFlight: () -> Void

    var body: some View {
        ZStack {
            if let flight {
                Color.clear
                    .contentShape(Rectangle())
                    // A touch, not only a tap: one that would scroll the list finishes it too.
                    .gesture(DragGesture(minimumDistance: 0).onChanged { _ in onTapDuringFlight() })
                FlyingCard(flight: flight, travel: flight.travel, front: front)
                    .allowsHitTesting(false)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The flyer at one point of its travel. Animatable in `travel`, so a spring on it is drawn every
/// frame; the turn animates in `CardFlip` inside it.
private struct FlyingCard: View, Animatable {
    let flight: CardFlight
    var travel: CGFloat
    let front: () -> EditorCard

    var animatableData: CGFloat {
        get { travel }
        set { travel = newValue }
    }

    var body: some View {
        let box = flight.frame(at: travel)
        let card = flight.cardFrame
        let faces = flight.faceOpacities(at: travel)
        ZStack {
            FlightFace(isBack: false, flips: flight.flips, opacity: faces.front) {
                front()
                    .frame(width: card.width, height: card.height)
                    .scaleEffect(flight.frontScale(in: box.size))
            }
            FlightFace(isBack: true, flips: flight.flips, opacity: faces.back) {
                OccurrenceRow(
                    entry: flight.entry, isLast: flight.isLast,
                    morph: CardFlight.morph(at: travel), cardHeight: box.height
                )
                .frame(width: box.width, height: box.height, alignment: .top)
            }
        }
        .frame(width: box.width, height: box.height)
        .modifier(CardFlip(turn: flight.turn))
        .position(x: box.midX, y: box.midY)
    }
}

/// One face of the flyer: a turning flight shows the face that's up, whole; one that doesn't turn
/// crossfades by `opacity`.
private struct FlightFace<Content: View>: View {
    let isBack: Bool
    let flips: Bool
    let opacity: Double
    @ViewBuilder let content: Content

    @Environment(\.cardFlipShowsBack) private var showsBack

    var body: some View {
        content.opacity(flips ? (showsBack == isBack ? 1 : 0) : opacity)
    }
}
