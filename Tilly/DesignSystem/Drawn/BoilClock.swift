import Foundation
import Observation

/// One clock for every boiling picture: it counts in steps of `Motion.boilStep`, and a picture reads
/// the step to choose which of its three drawings to show. One timer for all of them, not one for each,
/// so a screenful of pictures costs one tick, not dozens of timelines.
@MainActor @Observable
final class BoilClock {
    static let shared = BoilClock()

    private(set) var step = 0
    @ObservationIgnored private var timer: Timer?

    private init() {
        let timer = Timer(timeInterval: Tokens.Motion.boilStep, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.step &+= 1 }
        }
        // In the common modes, so the boil goes on while a list scrolls.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}
