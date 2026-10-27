import Testing
import SwiftUI
@testable import Tilly

@Suite struct CalendarZoomTests {
    private let zoom = CalendarZoom(anchor: .center, scale: 0.25)
    private func near(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.0001 }

    @Test func closerStartsAtCellScaleAndClear() {
        let c = zoom.closer(at: 0)
        #expect(near(c.scale, 0.25))
        #expect(c.opacity == 0)
    }

    @Test func closerEndsFullAndOpaque() {
        let c = zoom.closer(at: 1)
        #expect(near(c.scale, 1))
        #expect(c.opacity == 1)
    }

    @Test func furtherEndsAtOuterScaleAndClear() {
        let start = zoom.further(at: 0)
        #expect(near(start.scale, 1))
        #expect(start.opacity == 1)
        let end = zoom.further(at: 1)
        #expect(near(end.scale, zoom.outerScale))
        #expect(end.opacity == 0)
    }

    @Test func outerScaleCapsAtZoomMax() {
        let small = CalendarZoom(anchor: .center, scale: 0.2)
        #expect(near(small.outerScale, Tokens.Scale.zoomMax))
        #expect(near(CalendarZoom(anchor: .center, scale: 0.5).outerScale, 2))
    }

    @Test func noDirectionInsideTheDeadZone() {
        #expect(PinchProgress.direction(magnification: 1) == nil)
        #expect(PinchProgress.direction(magnification: 1.03) == nil)
        #expect(PinchProgress.direction(magnification: 0.97) == nil)
    }

    @Test func spreadingIsIn() {
        #expect(PinchProgress.direction(magnification: 1.1) == .in)
    }

    @Test func closingIsOut() {
        #expect(PinchProgress.direction(magnification: 0.9) == .out)
    }

    @Test func progressIsFullAtPinchFull() {
        let p = PinchProgress.progress(magnification: Tokens.Scale.pinchFull, direction: .in)
        #expect(near(p, 1))
    }

    @Test func progressClampsBothEnds() {
        #expect(PinchProgress.progress(magnification: 10, direction: .in) == 1)
        #expect(PinchProgress.progress(magnification: 0.5, direction: .in) == 0)
    }

    @Test func progressOutUsesTheInverse() {
        let p = PinchProgress.progress(magnification: 1 / Tokens.Scale.pinchFull, direction: .out)
        #expect(near(p, 1))
        let q = PinchProgress.progress(magnification: 1.5, direction: .in)
        #expect(near(PinchProgress.progress(magnification: 1 / 1.5, direction: .out), q))
    }

    @Test func finishesPastFortyPercent() {
        #expect(PinchProgress.finishes(progress: 0.45, speed: 0))
    }

    @Test func flickFinishesEarly() {
        #expect(PinchProgress.finishes(progress: 0.1, speed: 2))
    }

    @Test func slowShortPinchSpringsBack() {
        #expect(!PinchProgress.finishes(progress: 0.3, speed: 0.5))
    }

    @Test func settleDurationScalesWithDistance() {
        let whole = PinchProgress.settleDuration(from: 0, to: 1)
        let half = PinchProgress.settleDuration(from: 0.5, to: 1)
        #expect(abs(whole - Tokens.Motion.zoomDuration) < 0.0001)
        #expect(abs(half - Tokens.Motion.zoomDuration / 2) < 0.0001)
    }

    @Test func settleDurationHasAFloor() {
        #expect(PinchProgress.settleDuration(from: 0.99, to: 1) == Tokens.Motion.pinchSettleMin)
    }
}
