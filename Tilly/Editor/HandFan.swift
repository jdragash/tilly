import CoreGraphics
import Foundation

/// Where each card of the fan sits: on an arc, `handArc` degrees per step, the step tightening from
/// `handStepMax` to fit `width`, never below `handStepMin`; past that the fan is wider than `width`
/// and scrolls. Pure, so it's tested without views. Offsets are from the hand's centre, to the
/// card's centre; the arc is the prototype's `fanPose`.
struct HandFan: Equatable {
    struct Pose: Equatable {
        var offset: CGSize
        var angle: Double // degrees, clockwise
    }

    let count: Int
    let width: CGFloat

    /// What the step would be if nothing stopped it shrinking.
    private var fittedStep: CGFloat {
        (width - Tokens.Size.handCard.width - Tokens.Space.handSideClearance) / CGFloat(max(1, count - 1))
    }

    var step: CGFloat {
        min(Tokens.Space.handStepMax, max(Tokens.Space.handStepMin, fittedStep))
    }

    var scrolls: Bool { count > 1 && fittedStep < Tokens.Space.handStepMin }

    var contentWidth: CGFloat {
        scrolls
            ? CGFloat(count - 1) * step + Tokens.Size.handCard.width + Tokens.Space.handSideClearance
            : width
    }

    func pose(at index: Int) -> Pose {
        let arc = Tokens.Motion.handArc
        let steps = Double(index) - Double(count - 1) / 2
        let limit = Tokens.Motion.handArcMax / arc
        let curved = max(-limit, min(limit, steps))
        let theta = curved * arc
        let radians = theta * .pi / 180
        let radius = Double(step) / sin(arc * .pi / 180)
        // Past the limit the cards carry on in a line at the same height and angle.
        let beyond = steps - curved
        let x = radius * sin(radians) + beyond * Double(step)
        let y = radius * (1 - cos(radians))
        return Pose(offset: CGSize(width: x, height: y), angle: theta)
    }
}
