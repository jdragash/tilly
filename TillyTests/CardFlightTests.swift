import CoreGraphics
import Foundation
import SwiftUI
import Testing
@testable import Tilly

@MainActor @Suite struct CardFlightTests {
    typealias Builder = TimelineBuilderTests

    static let card = CGRect(x: 16, y: 70, width: 370, height: 233)
    static let row = CGRect(x: 0, y: 420, width: 402, height: 64)

    static func flight(_ kind: CardFlight.Kind) -> CardFlight {
        let bill = Builder.expense(name: "Rent", anchoredOn: Builder.date(2026, 10, 31))
        let entry = Builder.month([bill], key: Builder.thisMonth).entries[0]
        return CardFlight(kind: kind, entry: entry, isLast: true, cardFrame: card, rowFrame: row, turn: 0, travel: 0)
    }

    static func faces(_ faces: (front: Double, back: Double), _ front: Double, _ back: Double) -> Bool {
        abs(faces.front - front) < 1e-9 && abs(faces.back - back) < 1e-9
    }

    @Test func frameStartsAtTheCardAndEndsAtTheRow() {
        let flight = Self.flight(.landing(flips: true))
        #expect(flight.frame(at: 0) == Self.card)
        #expect(flight.frame(at: 1) == Self.row)
    }

    @Test func frameMovesAndResizesTogether() {
        let half = Self.flight(.landing(flips: true)).frame(at: 0.5)
        #expect(half == CGRect(x: 8, y: 245, width: 386, height: 148.5))
    }

    @Test func frameOvershootsPastTheRowWithTheSpring() {
        let past = Self.flight(.landing(flips: true)).frame(at: 1.05)
        #expect(past.minY > Self.row.minY)
        #expect(past.height < Self.row.height)
    }

    @Test func morphIsClampedToTheRow() {
        #expect(CardFlight.morph(at: -0.1) == 0)
        #expect(CardFlight.morph(at: 0.4) == 0.4)
        #expect(CardFlight.morph(at: 1.04) == 1)
    }

    @Test func chargedLandingCrossfadesOverTheFirstPartOfTravel() {
        let flight = Self.flight(.landing(flips: false))
        #expect(Self.faces(flight.faceOpacities(at: 0), 1, 0))
        let midway = flight.faceOpacities(at: CardFlight.landingFade / 2)
        #expect(abs(midway.front - 0.5) < 1e-9 && abs(midway.back - 0.5) < 1e-9)
        #expect(Self.faces(flight.faceOpacities(at: CardFlight.landingFade), 0, 1))
        #expect(Self.faces(flight.faceOpacities(at: 1), 0, 1))
    }

    @Test func chargedOpeningFadesTheCardInAsItArrives() {
        let flight = Self.flight(.opening(flips: false))
        #expect(Self.faces(flight.faceOpacities(at: 1), 0, 1))
        #expect(Self.faces(flight.faceOpacities(at: CardFlight.openingFade.upperBound), 0, 1))
        #expect(Self.faces(flight.faceOpacities(at: CardFlight.openingFade.lowerBound), 1, 1))
        #expect(Self.faces(flight.faceOpacities(at: 0), 1, 1))
    }

    @Test func frontScalesAsOnePictureToFitTheFrame() {
        let flight = Self.flight(.landing(flips: false))
        #expect(flight.frontScale(in: Self.card.size) == 1)
        // The row is wide and short: the height decides, so the card is never stretched.
        #expect(flight.frontScale(in: Self.row.size) == Self.row.height / Self.card.height)
    }

    @Test func faceSwapsAtNinetyDegrees() {
        #expect(!CardTurn.showsBack(0.49))
        #expect(CardTurn.showsBack(0.5))
        #expect(CardTurn.angle(0) == 0)
        #expect(CardTurn.angle(0.25) == 45)
        // The back comes up from −90°, so it's never drawn mirrored.
        #expect(CardTurn.angle(0.5) == -90)
        #expect(CardTurn.angle(1) == 0)
    }

    @Test func liftIsMostAtNinetyDegreesAndNoneAtRest() {
        #expect(CardTurn.lift(0, by: 0.06) == 1)
        #expect(abs(CardTurn.lift(0.5, by: 0.06) - 1.06) < 1e-9)
        #expect(abs(CardTurn.lift(1, by: 0.06) - 1) < 1e-9)
    }

    @Test func openingTurnsAsTheSpringReachesItsPlace() {
        let duration = 0.4, bounce = 0.3
        let time = CardFlight.time(toReach: CardFlight.openingTurnsAt, duration: duration, bounce: bounce)
        let spring = Spring(duration: duration, bounce: bounce)
        // The first moment it's that far: just before, it isn't yet.
        #expect(spring.value(target: 1.0, time: time) >= CardFlight.openingTurnsAt)
        #expect(spring.value(target: 1.0, time: time - 1.0 / 240) < CardFlight.openingTurnsAt)
        // Well before the spring settles, and within its own duration.
        #expect(time > 0 && time < duration)
    }

    @Test func aSlowerSpringTurnsLater() {
        let quick = CardFlight.time(toReach: CardFlight.openingTurnsAt, duration: 0.4, bounce: 0.3)
        let slow = CardFlight.time(toReach: CardFlight.openingTurnsAt, duration: 0.8, bounce: 0.3)
        #expect(slow > quick)
    }

    @Test func chargedOpeningIsOnlyBackUntilItsFadeBegins() {
        let flight = Self.flight(.opening(flips: false))
        // At the row the flyer is the row; the card comes up through it from 0.45 to 0.05.
        #expect(flight.frame(at: 1) == Self.row)
        let midway = flight.faceOpacities(at: 0.25)
        #expect(abs(midway.front - 0.5) < 1e-9 && midway.back == 1)
    }
}
