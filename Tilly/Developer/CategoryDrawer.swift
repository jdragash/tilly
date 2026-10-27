#if DEBUG && !targetEnvironment(simulator)
import Combine
import DialKit
import SwiftUI
import UIKit

/// The category screens' dials on a phone, in DialKit's in-app drawer: shake the phone to open it,
/// shake again or drag it down to close it. It lives in its own window above the app, so it opens
/// over any sheet; while it's closed the window lets every touch through. The values feed
/// `LayoutTuning`, as the Mac inspector's do in the Simulator, and are kept across launches. The
/// drawer's Copy hands them over as JSON. Debug builds on a device only.
@MainActor
final class CategoryDrawer {
    static let shared = CategoryDrawer()

    private let panel: DialPanelState<CategoryLayout>
    private let presentation = DrawerPresentation()
    private var window: DrawerWindow?
    private var watching: Set<AnyCancellable> = []

    private static let storageKey = "tilly.dials.categories"

    private init() {
        let stored = Self.load()
        LayoutTuning.shared.layout = stored
        panel = DialPanelState(
            id: UUID(uuidString: "6E0B2C5A-3F4D-4E8B-9A71-2C1D5B7E9F30")!,
            name: CategoryDialSpecs.panelName,
            initial: stored,
            controls: CategoryDialSpecs.groups.map { group in
                .group(group.title, children: group.dials.map(Self.control))
            }
        )
        panel.$values
            .sink { values in
                MainActor.assumeIsolated {
                    LayoutTuning.shared.layout = values
                    Self.save(values)
                }
            }
            .store(in: &watching)
        NotificationCenter.default.publisher(for: .deviceDidShake)
            .sink { [weak self] _ in MainActor.assumeIsolated { self?.toggle() } }
            .store(in: &watching)
    }

    private static func control(_ dial: CategoryDialSpec) -> DialControl<CategoryLayout> {
        switch dial.kind {
        case .points(let path, let range, let step, let unit):
            .slider(dial.key, keyPath: path, label: dial.label, range: range, step: step, unit: unit ? "pt" : nil)
        case .count(let path, let range):
            .slider(dial.key, keyPath: path, label: dial.label, range: range, step: 1)
        }
    }

    /// Sets the drawer up; it opens on the first shake.
    func start() {}

    private func toggle() {
        if window == nil { makeWindow() }
        presentation.isPresented.toggle()
    }

    private func makeWindow() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }
        let window = DrawerWindow(windowScene: scene)
        window.presentation = presentation
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear
        let host = UIHostingController(rootView: DrawerRoot(presentation: presentation))
        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false
        self.window = window
    }

    // MARK: Keeping the values

    /// What was set last time, laid over today's defaults: a field added since keeps its default,
    /// and one removed is dropped, so a change to the model never throws the rest away.
    private static func load() -> CategoryLayout {
        let defaults = CategoryLayout()
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stored = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let base = try? JSONSerialization.jsonObject(with: JSONEncoder().encode(defaults)) as? [String: Any]
        else { return defaults }
        let merged = base.merging(stored.filter { base[$0.key] != nil }) { _, kept in kept }
        guard let mergedData = try? JSONSerialization.data(withJSONObject: merged),
              let layout = try? JSONDecoder().decode(CategoryLayout.self, from: mergedData) else { return defaults }
        return layout
    }

    private static func save(_ layout: CategoryLayout) {
        if let data = try? JSONEncoder().encode(layout) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

/// Whether the drawer is open; DialKit writes `false` back when it's dragged closed.
@MainActor
private final class DrawerPresentation: ObservableObject {
    @Published var isPresented = false
}

private struct DrawerRoot: View {
    @ObservedObject var presentation: DrawerPresentation

    var body: some View {
        DialRoot(position: .bottomRight, storageID: "tilly", showsFAB: false, isPresented: $presentation.isPresented)
    }
}

/// Above everything, and invisible to touches while the drawer is closed.
private final class DrawerWindow: UIWindow {
    weak var presentation: DrawerPresentation?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard presentation?.isPresented == true else { return nil }
        return super.hitTest(point, with: event)
    }
}

extension Notification.Name {
    static let deviceDidShake = Notification.Name("TillyDeviceDidShake")
}

/// A shake arrives at the key window; every window passes it on as a notification.
extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}
#endif
