import Foundation

/// The tuning panel's controls: one per thing a person can feel, each a few named steps a real
/// distance apart, in place of a slider for every number. A step sets the values it names.
struct MotionGroup: Identifiable, Sendable {
    struct Step: Identifiable, Sendable {
        let name: String
        let values: [String: Double]
        var id: String { name }
    }

    let id: String
    let label: String
    /// What it does, in a sentence, under the control.
    let detail: String
    let steps: [Step]

    /// The step whose values are all what they are now, if there is one.
    @MainActor func current(in tuning: MotionTuning) -> Step? {
        steps.first { step in step.values.allSatisfy { abs(tuning[$0.key] - $0.value) < 0.0001 } }
    }
}

extension MotionGroup {
    /// Apple's named springs, plus a livelier one: how much a thing overshoots.
    private static func springs(_ duration: String, _ bounce: String, base: Double) -> [Step] {
        [
            Step(name: "Smooth", values: [duration: base, bounce: 0]),
            Step(name: "Snappy", values: [duration: base, bounce: 0.1]),
            Step(name: "Bouncy", values: [duration: base, bounce: 0.3]),
            Step(name: "Springy", values: [duration: base * 1.2, bounce: 0.5]),
        ]
    }

    private static func speeds(_ id: String, quick: Double, normal: Double, slow: Double) -> [Step] {
        [Step(name: "Quick", values: [id: quick]), Step(name: "Normal", values: [id: normal]), Step(name: "Slow", values: [id: slow])]
    }

    static let all: [MotionGroup] = [
        MotionGroup(id: "boil", label: "Boil", detail: "Whether pictures redraw a few times a second so they shimmer like hand-drawn lines. Off holds them still; Editor boils them on the card, the hand and the symbol picker; Everywhere also boils lists, the calendar and Settings. It costs some smoothness: if the app lags, try Editor or Off.", steps: [
            Step(name: "Off", values: ["boil": 0]),
            Step(name: "Editor", values: ["boil": 1]),
            Step(name: "Everywhere", values: ["boil": 2]),
        ]),
        MotionGroup(id: "edge", label: "Card edges", detail: "How far a card's outline wanders from a straight line. Clean is nearly ruled; Wild looks cut by hand.", steps: [
            Step(name: "Clean", values: ["edgeWobble": 0.3]),
            Step(name: "Subtle", values: ["edgeWobble": 0.6]),
            Step(name: "Rough", values: ["edgeWobble": 1.4]),
            Step(name: "Wild", values: ["edgeWobble": 3]),
        ]),
        MotionGroup(id: "symbols", label: "Symbols", detail: "How much a symbol's lines are moved so it looks hand-drawn rather than perfect.", steps: [
            Step(name: "Clean", values: ["roughAmount": 0.6]),
            Step(name: "Subtle", values: ["roughAmount": 1.8]),
            Step(name: "Rough", values: ["roughAmount": 3]),
        ]),
        MotionGroup(id: "hand", label: "Hand: a card pressed", detail: "What a hand card does while your finger is down: how high it lifts, how much it grows and how far its neighbours tilt away.", steps: [
            Step(name: "Subtle", values: ["pressLift": 10, "pressScale": 1.03, "neighbourTilt": 2]),
            Step(name: "Medium", values: ["pressLift": 18, "pressScale": 1.06, "neighbourTilt": 3]),
            Step(name: "Deep", values: ["pressLift": 28, "pressScale": 1.12, "neighbourTilt": 5]),
        ]),
        MotionGroup(id: "deal", label: "Hand: dealt in", detail: "When the hand appears, the cards deal in from below. None skips it; Big throws them from further, one after another.", steps: [
            Step(name: "None", values: ["deal": 0, "dealStagger": 0]),
            Step(name: "Short", values: ["deal": 100, "dealStagger": 0.015]),
            Step(name: "Medium", values: ["deal": 200, "dealStagger": 0.022]),
            Step(name: "Big", values: ["deal": 320, "dealStagger": 0.03]),
        ]),
        MotionGroup(id: "play", label: "Hand: a card flies to the tile", detail: "How long a card takes to fly from the hand to the tile on the card when you let go of it.",
                    steps: speeds("play", quick: 0.18, normal: 0.26, slow: 0.42)),
        MotionGroup(id: "flood", label: "Colour fills the card", detail: "How long the new colour takes to spread over the card from the tile.",
                    steps: speeds("flood", quick: 0.25, normal: 0.38, slow: 0.65)),
        MotionGroup(id: "stamp", label: "Symbol stamped on the tile", detail: "The symbol on the tile pops bigger, then settles when its category is picked. Subtle barely moves; Big really thumps.", steps: [
            Step(name: "Subtle", values: ["stampScale": 1.15, "stampUnder": 0.97]),
            Step(name: "Medium", values: ["stampScale": 1.3, "stampUnder": 0.95]),
            Step(name: "Big", values: ["stampScale": 1.5, "stampUnder": 0.9]),
        ]),
        MotionGroup(id: "sheetRise", label: "Editor rises", detail: "How the editor comes up from the bottom. Smooth glides in; Springy overshoots and settles.", steps: springs("sheetRise", "sheetRiseBounce", base: 0.45)),
        MotionGroup(id: "sheetExit", label: "Editor leaves", detail: "How long the editor takes to drop away after you save or cancel.",
                    steps: speeds("sheetExit", quick: 0.35, normal: 0.55, slow: 0.85)),
        MotionGroup(id: "flip", label: "Card turns over", detail: "How long an upcoming bill's card takes to turn over to its row side as you save. Charged bills don't turn.", steps: speeds("flip", quick: 0.28, normal: 0.4, slow: 0.65)),
        MotionGroup(id: "pause", label: "Pause after the turn", detail: "A short rest between the card finishing its turn and dropping into the list.", steps: [
            Step(name: "None", values: ["flipHold": 0]),
            Step(name: "Short", values: ["flipHold": 0.15]),
            Step(name: "Long", values: ["flipHold": 0.35]),
        ]),
        MotionGroup(id: "drop", label: "Card drops into its row", detail: "The spring the card lands in its row with. Smooth settles quietly; Springy bounces.", steps: springs("drop", "dropBounce", base: 0.45)),
        MotionGroup(id: "open", label: "A row opens into the editor", detail: "The spring a tapped row rises into the editor with.", steps: springs("open", "openBounce", base: 0.4)),
        MotionGroup(id: "jump", label: "A far row is jumped to", detail: "When a saved bill is far off screen, the list jumps so its row sits this far down from the top before the card drops in.", steps: [
            Step(name: "Near the top", values: ["landingRowOffset": 60]),
            Step(name: "Medium", values: ["landingRowOffset": 120]),
            Step(name: "Lower down", values: ["landingRowOffset": 190]),
        ]),
        MotionGroup(id: "day", label: "Charge drops into its day", detail: "Over the calendar, a saved bill drops into its day from above. Subtle is a short fall; Deep falls further and bounces more.", steps: [
            Step(name: "Subtle", values: ["dayDrop": 24, "dayDropBounce": 0.15, "dayDropDuration": 0.4]),
            Step(name: "Medium", values: ["dayDrop": 48, "dayDropBounce": 0.3, "dayDropDuration": 0.45]),
            Step(name: "Deep", values: ["dayDrop": 80, "dayDropBounce": 0.4, "dayDropDuration": 0.55]),
        ]),
    ]
}
