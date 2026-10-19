import SwiftUI

/// What the editor is open for.
enum EditorRequest: Identifiable, Equatable {
    case add
    case edit(EditSession)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let session): "edit-\(session.id)"
        }
    }
}

/// How the editor closed. A drag down closes the sheet without the editor's say, and reads as
/// `.cancelled` to whoever holds the request.
enum EditorClose: Equatable {
    /// ✕, or a drag down.
    case cancelled
    /// The charge to land on: the saved bill's charge at `date`.
    case saved(expenseID: UUID, date: Date)
    case deleted
}

/// The sheet's own coordinate space, which moves with it.
enum EditorSheetSpace {
    static let name = "editorSheet"
}

/// The editor's card reports its frame in the sheet's own space, which moves with the sheet, so
/// the frame is the same wherever the sheet is in its travel.
struct EditorCardFrameKey: PreferenceKey {
    static let defaultValue: CGRect? = nil
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

extension EnvironmentValues {
    /// Everything in the sheet but the card fades by this as the sheet closes, so what drops is a
    /// plain sheet carrying the card.
    @Entry var editorSheetContents: Double = 1
}

/// The editor's sheet, drawn by the timeline: a scrim, then the sheet rising from the bottom with
/// the system sheet's corner radius and grabber, dragged down to close. Drawn by the app rather
/// than presented, so the card can fly between it and the list (DECISIONS.md, "Views switch in
/// place…").
///
/// It rises over `sheetRise` with `sheetRiseBounce`. Closing, its contents fade over
/// `sheetContentsFade` while it drops over `sheetExit` (the prototype's soft exit). Reduce Motion
/// fades it both ways. The scrim takes taps and does nothing with them, as a sheet's does.
struct EditorSheet<Content: View>: View {
    @Binding var request: EditorRequest?
    /// Where the editor's card rests when the sheet is up, in `CardFlightLayer.space`, with the
    /// sheet's own travel taken out: a flight can aim at it before the sheet has arrived.
    let onCardRest: (CGRect) -> Void
    /// How far a drag had pulled the sheet down as it let go to close: a card landing back from it
    /// starts where it was, not at its rest.
    var onDragClose: (CGFloat) -> Void = { _ in }
    @ViewBuilder let content: (EditorRequest) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// What the sheet shows: the request, kept while the sheet leaves after it has gone.
    @State private var shown: EditorRequest?
    /// How far below its rest the sheet sits.
    @State private var travel: CGFloat = 0
    /// Everything but the card, fading first as the sheet closes.
    @State private var contents: Double = 1
    /// The whole sheet and scrim: Reduce Motion fades instead of moving.
    @State private var opacity: Double = 1
    /// Bumped by every open and close, so a close finishing after a fresh open leaves it alone.
    @State private var generation = 0
    @State private var isDragging = false
    /// The sheet's rest, in the flight space, measured where the travel doesn't reach.
    @State private var rest: CGRect = .zero
    /// The sheet's drawn height, its top to the screen's bottom, behind the keyboard too.
    @State private var sheetHeight: CGFloat = 0
    @State private var cardInSheet: CGRect?
    @State private var reportedCardRest: CGRect?

    /// From its rest to fully below the screen. Its rest is shorter than the sheet while a
    /// keyboard is up, and the sheet hasn't been measured before it first opens.
    private var offDistance: CGFloat {
        max(sheetHeight, rest.height + Tokens.Space.sheetOffMargin)
    }

    /// 1 at rest, 0 off the screen: the scrim darkens as the sheet rises.
    private var raised: Double {
        guard shown != nil else { return 0 }
        guard offDistance > 0 else { return 1 }
        return Double(min(1, max(0, 1 - travel / offDistance)))
    }

    var body: some View {
        ZStack {
            scrim
            // Where the sheet rests, never moved, so the card's rest can be read from it.
            Color.clear
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(CardFlightLayer.space)) } action: {
                    rest = $0
                    reportCardRest()
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            if let shown {
                sheet(shown)
            }
        }
        .onChange(of: request, initial: true) { _, new in
            if let new { present(new) } else if shown != nil { close() }
        }
    }

    // MARK: Pieces

    private var scrim: some View {
        Tokens.Surface.scrim
            .opacity(raised * opacity)
            .ignoresSafeArea()
            // A sheet's dimming takes taps and does nothing with them.
            .contentShape(Rectangle())
            .onTapGesture {}
            .allowsHitTesting(shown != nil)
            .accessibilityHidden(true)
    }

    private func sheet(_ shown: EditorRequest) -> some View {
        content(shown)
            .id(shown.id)
            .environment(\.editorSheetContents, contents)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .coordinateSpace(name: EditorSheetSpace.name)
            .onPreferenceChange(EditorCardFrameKey.self) { frame in
                cardInSheet = frame
                reportCardRest()
            }
            .background {
                // Down to the screen's bottom and behind the keyboard, as a system sheet's ground is.
                Color.clear
                    .drawnPaper()
                    .clipShape(UnevenRoundedRectangle(
                        topLeadingRadius: Tokens.Radius.sheet, topTrailingRadius: Tokens.Radius.sheet,
                        style: .circular
                    ))
                    .ignoresSafeArea(.all, edges: .bottom)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { sheetHeight = $0 }
            }
            .overlay(alignment: .top) { grabber }
            .offset(y: travel)
            .opacity(opacity)
            .gesture(drag)
            .accessibilityAddTraits(.isModal)
            .accessibilityAction(.escape) { request = nil }
    }

    private var grabber: some View {
        Capsule()
            .fill(Tokens.Surface.grabber)
            .frame(width: Tokens.Size.grabber.width, height: Tokens.Size.grabber.height)
            .padding(.top, Tokens.Space.grabberTop)
            .opacity(contents)
            .accessibilityHidden(true)
    }

    /// Down closes it once past a quarter of its height or flung past half; short of that it springs
    /// back. Up, it gives a little. Global, because the sheet moves under the finger.
    private var drag: some Gesture {
        DragGesture(minimumDistance: Tokens.Space.sheetDragSlop, coordinateSpace: .global)
            .onChanged { value in
                guard request != nil else { return }
                isDragging = true
                let down = value.translation.height
                travel = down >= 0 ? down : down * Tokens.Motion.sheetDragResistance
            }
            .onEnded { value in
                guard isDragging else { return }
                isDragging = false
                let height = max(1, offDistance)
                let closes = value.translation.height > height * Tokens.Motion.sheetDragCloses
                    || value.predictedEndTranslation.height > height * Tokens.Motion.sheetFlingCloses
                if closes {
                    onDragClose(travel)
                    request = nil
                } else {
                    withAnimation(riseAnimation) { travel = 0 }
                }
            }
    }

    // MARK: Opening and closing

    private var riseAnimation: Animation {
        .spring(duration: Tokens.Motion.Card.sheetRise, bounce: Tokens.Motion.Card.sheetRiseBounce)
    }

    private func present(_ new: EditorRequest) {
        generation &+= 1
        let isFresh = shown == nil
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
            shown = new
            contents = 1
            // Reported afresh for every open: one opened while the last was still leaving would
            // otherwise match the old report and never be sent.
            reportedCardRest = nil
            if isFresh {
                if reduceMotion {
                    travel = 0
                    opacity = 0
                } else {
                    travel = offDistance
                    opacity = 1
                }
            }
        }
        reportCardRest()
        // A turn later, so the sheet is drawn where it starts before it moves. A sheet still
        // leaving rises again from wherever it has got to.
        DispatchQueue.main.async {
            if reduceMotion {
                withAnimation(.linear(duration: Tokens.Motion.reducedFade)) { opacity = 1 }
            } else {
                withAnimation(riseAnimation) { travel = 0 }
            }
        }
    }

    private func close() {
        generation &+= 1
        let closing = generation
        let finish = {
            guard generation == closing else { return }
            var instant = Transaction()
            instant.disablesAnimations = true
            withTransaction(instant) {
                shown = nil
                cardInSheet = nil
                reportedCardRest = nil
                contents = 1
                opacity = 1
                travel = 0
            }
        }
        if reduceMotion {
            withAnimation(.linear(duration: Tokens.Motion.reducedFade)) { opacity = 0 } completion: { finish() }
            return
        }
        withAnimation(.easeOut(duration: Tokens.Motion.Card.sheetContentsFade)) { contents = 0 }
        withAnimation(.spring(duration: Tokens.Motion.Card.sheetExit, bounce: 0)) {
            travel = offDistance
        } completion: {
            finish()
        }
    }

    /// Only a real change: the frame wobbles by hundredths of a point while the sheet moves.
    private func reportCardRest() {
        guard let cardInSheet, rest != .zero else { return }
        let frame = cardInSheet.offsetBy(dx: rest.minX, dy: rest.minY)
        if let reported = reportedCardRest,
           abs(reported.minX - frame.minX) < Tokens.Space.frameTolerance,
           abs(reported.minY - frame.minY) < Tokens.Space.frameTolerance,
           abs(reported.width - frame.width) < Tokens.Space.frameTolerance,
           abs(reported.height - frame.height) < Tokens.Space.frameTolerance {
            return
        }
        reportedCardRest = frame
        onCardRest(frame)
    }
}
