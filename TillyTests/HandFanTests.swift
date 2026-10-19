import CoreGraphics
import Testing
@testable import Tilly

@MainActor @Suite struct HandFanTests {
    static let phone: CGFloat = 402

    @Test func oneCardSitsCentredUpright() {
        let fan = HandFan(count: 1, width: Self.phone)
        #expect(fan.pose(at: 0) == HandFan.Pose(offset: .zero, angle: 0))
        #expect(!fan.scrolls)
    }

    @Test func stepIsMaxWhenItFits() {
        let fan = HandFan(count: 3, width: Self.phone)
        #expect(fan.step == Tokens.Space.handStepMax)
        #expect(fan.contentWidth == Self.phone)
    }

    @Test func stepTightensToFitWidth() {
        let fan = HandFan(count: 9, width: Self.phone)
        let fitted = (Self.phone - Tokens.Size.handCard.width - Tokens.Space.handSideClearance) / 8
        #expect(fan.step == fitted)
        #expect(fan.step < Tokens.Space.handStepMax && fan.step > Tokens.Space.handStepMin)
        #expect(!fan.scrolls)
    }

    @Test func stepStopsAtMinAndScrolls() {
        let fan = HandFan(count: 21, width: Self.phone)
        #expect(fan.step == Tokens.Space.handStepMin)
        #expect(fan.scrolls)
        #expect(fan.contentWidth == 20 * Tokens.Space.handStepMin + Tokens.Size.handCard.width + Tokens.Space.handSideClearance)
        #expect(fan.contentWidth > Self.phone)
    }

    @Test func posesAreSymmetric() {
        for count in [2, 3, 8, 21] {
            let fan = HandFan(count: count, width: Self.phone)
            for index in 0..<count {
                let mine = fan.pose(at: index)
                let mirror = fan.pose(at: count - 1 - index)
                #expect(abs(mine.offset.width + mirror.offset.width) < 0.0001)
                #expect(abs(mine.offset.height - mirror.offset.height) < 0.0001)
                #expect(abs(mine.angle + mirror.angle) < 0.0001)
            }
        }
    }

    @Test func anglesGrowByArcPerStep() {
        let fan = HandFan(count: 5, width: Self.phone)
        for index in 1..<5 {
            #expect(abs(fan.pose(at: index).angle - fan.pose(at: index - 1).angle - Tokens.Motion.handArc) < 0.0001)
        }
        #expect(fan.pose(at: 2).angle == 0)
    }

    @Test func theCentreCardIsLowestFromItsNeighboursAtTheEnds() {
        let fan = HandFan(count: 5, width: Self.phone)
        #expect(fan.pose(at: 2).offset.height < fan.pose(at: 4).offset.height)
    }

    @Test func aWideFanStraightensPastTheLimit() {
        let fan = HandFan(count: 21, width: Self.phone)
        let last = fan.pose(at: 20), before = fan.pose(at: 19)
        #expect(last.angle == Tokens.Motion.handArcMax)
        #expect(last.offset.height == before.offset.height)
        #expect(abs(last.offset.width - before.offset.width - fan.step) < 0.0001)
    }
}
