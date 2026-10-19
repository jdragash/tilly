import SwiftUI

/// A saved charge arriving on its day over the calendar's month or year: the picture (or the year's
/// mark) is held back, then drops from `dayDrop` above on a spring, fading in over the first
/// 0.15s, with a light tap at 40% of the drop. Reduce Motion fades it in and nothing more.
///
/// `arrives` is true from the save until the arrival is over; the drop waits `delay` so the
/// editor's sheet has mostly left first. Until then the content stays hidden, so a day that has
/// only just gained a charge doesn't show it early.
struct DayArrival: ViewModifier {
    let arrives: Bool
    let delay: TimeInterval
    /// Told when the drop reaches 40%, which is when the day's total rolls.
    var onImpact: () -> Void = {}

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dropped: Bool
    @State private var faded: Bool
    @State private var tick = 0

    init(arrives: Bool, delay: TimeInterval, onImpact: @escaping () -> Void = {}) {
        self.arrives = arrives
        self.delay = delay
        self.onImpact = onImpact
        _dropped = State(initialValue: !arrives)
        _faded = State(initialValue: !arrives)
    }

    func body(content: Content) -> some View {
        content
            .offset(y: dropped || reduceMotion ? 0 : -Tokens.Motion.Card.dayDrop)
            .opacity(faded ? 1 : 0)
            .sensoryFeedback(.impact(weight: .light), trigger: tick)
            .onChange(of: arrives, initial: true) { _, isArriving in
                guard isArriving else { return }
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) {
                    dropped = false
                    faded = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    if reduceMotion {
                        withAnimation(.easeInOut(duration: Tokens.Motion.reducedFade)) { faded = true }
                        return
                    }
                    withAnimation(.spring(duration: Tokens.Motion.Card.dayDropDuration, bounce: Tokens.Motion.Card.dayDropBounce)) {
                        dropped = true
                    }
                    withAnimation(.easeOut(duration: Tokens.Motion.dayFade)) { faded = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + Tokens.Motion.Card.dayDropDuration * Tokens.Motion.dayImpactAt) {
                        tick += 1
                        onImpact()
                    }
                }
            }
    }
}

extension View {
    func dayArrival(_ arrives: Bool, delay: TimeInterval, onImpact: @escaping () -> Void = {}) -> some View {
        modifier(DayArrival(arrives: arrives, delay: delay, onImpact: onImpact))
    }
}
