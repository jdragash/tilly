import SwiftUI

/// The turn: rotation about y in `flipPerspective`, the face swapped at 90°, lifted by
/// `1 + flipLift × sin(π × turn)`. One view either way, so it animates (`editor.md`): the faces
/// inside read which one is up from `\.cardFlipShowsBack`, and each is drawn unmirrored.
struct CardFlip: ViewModifier, Animatable {
    /// 0 … 1: 0 the front up, 1 the back up.
    var turn: Double

    var animatableData: Double {
        get { turn }
        set { turn = newValue }
    }

    func body(content: Content) -> some View {
        let showsBack = CardTurn.showsBack(turn)
        content
            .environment(\.cardFlipShowsBack, showsBack)
            .scaleEffect(CardTurn.lift(turn, by: Tokens.Motion.Card.flipLift))
            .rotation3DEffect(
                .degrees(CardTurn.angle(turn)), axis: (x: 0, y: 1, z: 0),
                perspective: Tokens.Motion.flipPerspective
            )
            .sensoryFeedback(.selection, trigger: showsBack)
    }
}

extension EnvironmentValues {
    /// Whether a turning card's back is up: past 90° of its turn.
    @Entry var cardFlipShowsBack = false
}

/// The turn's arithmetic, apart from views so it's tested without them.
nonisolated enum CardTurn {
    /// Past 90°, the back is up.
    static func showsBack(_ turn: Double) -> Bool {
        turn >= 0.5
    }

    /// Degrees about y. The front turns 0 → 90; the back then turns −90 → 0, so neither face is
    /// ever drawn mirrored.
    static func angle(_ turn: Double) -> Double {
        let degrees = 180 * turn
        return showsBack(turn) ? degrees - 180 : degrees
    }

    /// The card rises toward the reader as it turns, most at 90°.
    static func lift(_ turn: Double, by lift: Double) -> CGFloat {
        CGFloat(1 + lift * sin(.pi * min(1, max(0, turn))))
    }
}
