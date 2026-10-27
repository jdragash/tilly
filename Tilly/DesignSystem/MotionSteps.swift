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
    /// The heading it sits under in Settings, named for what it changes.
    let section: String
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

    /// Only what still shows: each group's values are read where it says, in the app as it is.
    static let all: [MotionGroup] = [
        MotionGroup(id: "boil", section: "Pictures", label: "Shimmer", detail: "Whether pictures redraw a few times a second so they shimmer like hand-drawn lines. Off holds them still; Editor shimmers the bill editor and the category sheet; Everywhere also the timeline, calendar and lanes. If the app lags, try Editor or Off.", steps: [
            Step(name: "Off", values: ["boil": 0]),
            Step(name: "Editor", values: ["boil": 1]),
            Step(name: "Everywhere", values: ["boil": 2]),
        ]),
        MotionGroup(id: "edge", section: "Pictures", label: "Timeline card edges", detail: "How far a timeline row's card, and the bill card's, wanders from a straight line. Category cards have their own edge in DialKit.", steps: [
            Step(name: "Clean", values: ["edgeWobble": 0.3]),
            Step(name: "Subtle", values: ["edgeWobble": 0.6]),
            Step(name: "Rough", values: ["edgeWobble": 1.4]),
            Step(name: "Wild", values: ["edgeWobble": 3]),
        ]),
        MotionGroup(id: "symbols", section: "Pictures", label: "Calendar and lanes symbols", detail: "How hand-drawn a symbol looks in the calendar's days, the lanes and the category view's readout.", steps: [
            Step(name: "Clean", values: ["roughAmount": 0.6]),
            Step(name: "Subtle", values: ["roughAmount": 1.8]),
            Step(name: "Rough", values: ["roughAmount": 3]),
        ]),
        MotionGroup(id: "sheetRise", section: "Bill editor", label: "Opening", detail: "How the bill editor comes up from the bottom. Smooth glides in; Springy overshoots and settles.", steps: springs("sheetRise", "sheetRiseBounce", base: 0.45)),
        MotionGroup(id: "sheetExit", section: "Bill editor", label: "Closing", detail: "How long the bill editor takes to drop away after you save or cancel.",
                    steps: speeds("sheetExit", quick: 0.35, normal: 0.55, slow: 0.85)),
        MotionGroup(id: "jump", section: "After saving", label: "Timeline: jumping to the bill", detail: "When a saved bill is far off screen, the timeline jumps so its row sits this far down from the top.", steps: [
            Step(name: "Near the top", values: ["landingRowOffset": 60]),
            Step(name: "Medium", values: ["landingRowOffset": 120]),
            Step(name: "Lower down", values: ["landingRowOffset": 190]),
        ]),
        MotionGroup(id: "day", section: "After saving", label: "Calendar: the charge drops into its day", detail: "Over the calendar, a saved bill drops into its day from above. Subtle is a short fall; Deep falls further and bounces more.", steps: [
            Step(name: "Subtle", values: ["dayDrop": 24, "dayDropBounce": 0.15, "dayDropDuration": 0.4]),
            Step(name: "Medium", values: ["dayDrop": 48, "dayDropBounce": 0.3, "dayDropDuration": 0.45]),
            Step(name: "Deep", values: ["dayDrop": 80, "dayDropBounce": 0.4, "dayDropDuration": 0.55]),
        ]),
    ]

    /// The headings, in order.
    static let sections = ["Pictures", "Bill editor", "After saving"]
}
