import SwiftUI
import UIKit

/// Stops a scroll view's glide where it is. SwiftUI has no call for it: an animated `scrollTo`
/// issued mid-glide is dropped, and `scrollDisabled` switched on for a turn never reached the
/// scroll view on an iOS 27 iPhone (off and on coalesced into one frame). UIKit's own
/// `setContentOffset(_:animated: false)`, at the offset the list is already at, ends the
/// deceleration at once, with no jump. See `.claude/rules/swiftui-scrolling.md`.
@MainActor
final class GlideStopper {
    fileprivate weak var scrollView: UIScrollView?

    /// Ends a glide in progress, holding the list where it is. A finger still down is left alone:
    /// if it lifts and the list flies on, the caller starts again (see `returnToResting`).
    func stop() {
        guard let scrollView, scrollView.isDecelerating, !scrollView.isTracking else { return }
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
    }

    /// Where the list is, exactly, for `putBack`: a pinch that springs back undoes its landing.
    var offset: CGPoint? { scrollView?.contentOffset }

    /// Puts the list back where `offset` read, unanimated.
    func putBack(_ offset: CGPoint) {
        scrollView?.setContentOffset(offset, animated: false)
    }
}

/// Placed in a scroll view's content, invisible: finds the `UIScrollView` it sits in.
struct GlideStopperAnchor: UIViewRepresentable {
    let stopper: GlideStopper

    func makeUIView(context: Context) -> Finder { Finder(stopper: stopper) }

    func updateUIView(_ view: Finder, context: Context) {
        view.stopper = stopper
        view.find()
    }

    final class Finder: UIView {
        var stopper: GlideStopper

        init(stopper: GlideStopper) {
            self.stopper = stopper
            super.init(frame: .zero)
            isUserInteractionEnabled = false
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            find()
        }

        func find() {
            var view = superview
            while let candidate = view {
                if let scrollView = candidate as? UIScrollView {
                    stopper.scrollView = scrollView
                    return
                }
                view = candidate.superview
            }
        }
    }
}
