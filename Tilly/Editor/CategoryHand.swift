import SwiftUI

/// The hand: a fan of one card per category, in the Settings order, and `New`. Pressing a card lifts
/// it and tilts its neighbours; letting go on the same card plays it, and a copy flies up to the
/// editor's tile. The category the bill is already in is on the card, so it isn't in the fan. See
/// "The hand is the category picker" in `docs/DESIGN.md`.
struct CategoryHand: View {
    let categories: [ExpenseCategory]   // Settings order
    let selection: UUID?
    let newBreathes: Bool
    /// The tile's frame in the editor's coordinate space (global), for a played card to fly to.
    let tileFrame: CGRect
    let onPlay: (UUID) -> Void          // called when the flying card reaches the tile
    let onNew: () -> Void

    private enum Item: Identifiable, Equatable {
        static func == (lhs: Item, rhs: Item) -> Bool { lhs.id == rhs.id }

        case category(ExpenseCategory)
        case new

        var id: String {
            switch self {
            case .category(let category): category.id.uuidString
            case .new: "new"
            }
        }
    }

    private struct Flight {
        let id: UUID
        let start: CGPoint   // the card's centre in the hand's space
        let angle: Double
        var progress: CGFloat = 0
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressed: String?
    @State private var dealt = false
    @State private var flight: Flight?
    @State private var frames: [String: CGRect] = [:]    // each card's frame, in the hand's space
    @State private var handFrame: CGRect = .zero         // the hand, global

    private var items: [Item] {
        categories.sorted { $0.sortOrder < $1.sortOrder }
            .filter { $0.id != selection }
            .map(Item.category) + [.new]
    }

    var body: some View {
        GeometryReader { geometry in
            let items = items
            let fan = HandFan(count: items.count, width: geometry.size.width)
            ScrollView(.horizontal) {
                ZStack(alignment: .top) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        card(item, at: index, of: items, fan: fan)
                    }
                }
                .frame(width: max(fan.contentWidth, geometry.size.width), height: geometry.size.height, alignment: .top)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .scrollDisabled(!fan.scrolls)
            .scrollBounceBehavior(.basedOnSize)
            .coordinateSpace(name: Self.space)
            .overlay(alignment: .topLeading) { flyer }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { handFrame = $0 }
        }
        .sensoryFeedback(.selection, trigger: pressed) { _, new in new != nil }
        .onAppear { dealt = true }
    }

    private static let space = "categoryHand"

    // MARK: One card

    private func card(_ item: Item, at index: Int, of items: [Item], fan: HandFan) -> some View {
        let pose = fan.pose(at: index)
        let pressedIndex = items.firstIndex { $0.id == pressed }
        let isPressed = pressedIndex == index
        var angle = pose.angle
        var lift: CGFloat = 0
        if isPressed {
            lift = -Tokens.Motion.Card.pressLift
        } else if let pressedIndex, abs(pressedIndex - index) == 1 {
            angle += index < pressedIndex ? -Tokens.Motion.Card.neighbourTilt : Tokens.Motion.Card.neighbourTilt
        }
        let isFlying = flight.map { item.id == $0.id.uuidString } ?? false
        let dealOffset = dealt || reduceMotion ? 0 : Tokens.Motion.Card.deal

        return Button {
            play(item, frame: frames[item.id], angle: pose.angle)
        } label: {
            face(item)
        }
        .buttonStyle(HandPressStyle { isDown in
            if isDown { pressed = item.id } else if pressed == item.id { pressed = nil }
        })
        .frame(width: Tokens.Size.handCard.width, height: Tokens.Size.handCard.height)
        .scaleEffect(isPressed ? Tokens.Motion.Card.pressScale : 1)
        .rotationEffect(.degrees(angle))
        .offset(x: pose.offset.width, y: Tokens.Space.handTop + pose.offset.height + lift + dealOffset)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { frames[item.id] = $0 }
        .opacity(isFlying ? 0 : 1)
        .zIndex(isPressed ? Double(items.count) + 1 : Double(index))
        .animation(reduceMotion ? nil : .easeOut(duration: Tokens.Motion.Card.press), value: pressed)
        .animation(
            reduceMotion ? nil : .spring(duration: Tokens.Motion.Card.sheetRise, bounce: Tokens.Motion.Card.sheetRiseBounce)
                .delay(Double(index) * Tokens.Motion.Card.dealStagger),
            value: dealt
        )
        .animation(reduceMotion ? nil : .spring(duration: Tokens.Motion.Card.sheetRise, bounce: Tokens.Motion.Card.sheetRiseBounce), value: items.map(\.id))
        .accessibilityLabel(label(of: item))
        .accessibilityHint(item == .new ? "Picks a symbol to make one" : "Puts the bill in this category")
    }

    private func label(of item: Item) -> String {
        switch item {
        case .category(let category): category.name
        case .new: "New category"
        }
    }

    /// What a card looks like, as the prototype draws it: a paper card with its colour as a bar along
    /// the bottom, the category's picture in its colour and its name beneath; `New` is an outline and a
    /// plus.
    @ViewBuilder
    private func face(_ item: Item) -> some View {
        let shape = RoundedRectangle(cornerRadius: Tokens.Radius.handCard, style: .continuous)
        switch item {
        case .category(let category):
            let colour = category.colour.map(Tokens.CategoryColour.color) ?? Tokens.Chart.uncoloured
            shape.fill(Tokens.Drawn.paperCard)
                .overlay {
                    VStack(spacing: Tokens.Space.handCardGap) {
                        CategoryPictureView(
                            picture: CategoryPicture(category), colour: category.colour,
                            size: Tokens.Size.handPicture, place: .editor
                        )
                        Text(category.name)
                            .font(Tokens.Text.handName)
                            .foregroundStyle(Tokens.Drawn.ink2)
                            .lineLimit(1)
                            .minimumScaleFactor(Tokens.Scale.headerMin)
                            .padding(.horizontal, Tokens.Space.tight)
                    }
                    .padding(.bottom, Tokens.Size.handBar)
                }
                .overlay(alignment: .bottom) {
                    Rectangle().fill(colour).frame(height: Tokens.Size.handBar)
                }
                .clipShape(shape)
                .overlay { shape.strokeBorder(Tokens.Shadow.handHairline, lineWidth: Tokens.Size.hairline) }
                .shadow(color: Tokens.Shadow.handColour, radius: Tokens.Shadow.handRadius, y: Tokens.Shadow.handY)
        case .new:
            shape.strokeBorder(Tokens.Ink.tertiary, lineWidth: Tokens.Stroke.handNew)
                .overlay {
                    VStack(spacing: Tokens.Space.handCardGap) {
                        Image(systemName: "plus").font(Tokens.Text.handPlus)
                        Text("New").font(Tokens.Text.handName)
                    }
                    .foregroundStyle(Tokens.Ink.secondary)
                }
                .phaseAnimator(newBreathes ? [1, Tokens.Motion.breatheOpacity] : [1]) { view, opacity in
                    view.opacity(opacity)
                } animation: { _ in
                    .easeInOut(duration: Tokens.Motion.breathe / 2)
                }
        }
    }

    // MARK: Playing

    /// Letting go on a card plays it: a copy flies to the tile, shrinking and turning upright, then
    /// the category is picked. `New` doesn't fly. Reduce Motion picks at once.
    private func play(_ item: Item, frame: CGRect?, angle: Double) {
        guard case .category(let category) = item else {
            onNew()
            return
        }
        guard !reduceMotion, let frame, flight == nil, tileFrame != .zero else {
            onPlay(category.id)
            return
        }
        flight = Flight(id: category.id, start: CGPoint(x: frame.midX, y: frame.midY), angle: angle)
        withAnimation(.timingCurve(0.3, 0.7, 0.3, 1, duration: Tokens.Motion.Card.play)) {
            flight?.progress = 1
        } completion: {
            onPlay(category.id)
            flight = nil
        }
    }

    /// The card in flight, in the hand's space, from where it was to the tile.
    @ViewBuilder
    private var flyer: some View {
        if let flight, let category = categories.first(where: { $0.id == flight.id }) {
            let target = CGPoint(x: tileFrame.midX - handFrame.minX, y: tileFrame.midY - handFrame.minY)
            let progress = flight.progress
            let scale = 1 + (tileFrame.height / Tokens.Size.handCard.height - 1) * progress
            face(.category(category))
                .frame(width: Tokens.Size.handCard.width, height: Tokens.Size.handCard.height)
                .scaleEffect(scale)
                .rotationEffect(.degrees(flight.angle * (1 - progress)))
                .opacity(1 - 0.25 * progress)
                .position(
                    x: flight.start.x + (target.x - flight.start.x) * progress,
                    y: flight.start.y + (target.y - flight.start.y) * progress
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

/// Reports a press to the hand, which lifts the card and tilts its neighbours, and draws the card
/// itself unchanged.
private struct HandPressStyle: ButtonStyle {
    let onPressChange: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(Rectangle())
            .onChange(of: configuration.isPressed) { _, isDown in onPressChange(isDown) }
    }
}
