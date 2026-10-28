import Foundation
import Observation

/// One clock for every boiling picture: it counts in steps of `Motion.boilStep`, and a picture reads
/// the step to choose which of its three drawings to show. One timer for all of them, not one for each,
/// so a screenful of pictures costs one tick, not dozens of timelines.
@MainActor @Observable
final class BoilClock {
    static let shared = BoilClock()

    private(set) var step = 0
    /// The step the lists' pictures read: it stops while `listsHeld`, so they keep the drawing they
    /// have and redraw nothing, rather than redrawing all at once to hold still.
    private(set) var listStep = 0
    /// The lists are covered, as by the editor's sheet: boiling them cost the sheet its frames.
    @ObservationIgnored var listsHeld = false
    @ObservationIgnored private var timer: Timer?

    private init() {
        let timer = Timer(timeInterval: Tokens.Motion.boilStep, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.step &+= 1
                if !self.listsHeld { self.listStep &+= 1 }
            }
        }
        // In the common modes, so the boil goes on while a list scrolls.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}
