import Testing
import SwiftUI
@testable import Tilly

@Suite struct CalendarZoomTests {
    private let trigger = Tokens.Scale.pinchTrigger

    @Test func nothingInsideTheTrigger() {
        #expect(PinchTrigger.direction(magnification: 1) == nil)
        #expect(PinchTrigger.direction(magnification: 1.2) == nil)
        #expect(PinchTrigger.direction(magnification: 0.85) == nil)
    }

    @Test func spreadingPastTheTriggerIsIn() {
        #expect(PinchTrigger.direction(magnification: 1.3) == .in)
    }

    @Test func closingPastTheTriggerIsOut() {
        #expect(PinchTrigger.direction(magnification: 0.7) == .out)
    }

    @Test func exactlyAtTheTriggerCounts() {
        #expect(PinchTrigger.direction(magnification: trigger) == .in)
        #expect(PinchTrigger.direction(magnification: 1 / trigger) == .out)
    }
}
