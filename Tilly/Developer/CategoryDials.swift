#if DEBUG && targetEnvironment(simulator)
import Combine
import DialkitmacOS
import DialkitmacOSAgent
import Foundation

/// The category screens' dials, in DialKit's Mac inspector: run `swift run dialkit-macos` from a
/// checkout of github.com/mikelikesdesign/dialkit-macos, then the app in the Simulator, and a
/// "Categories" panel appears. Each change lands in `LayoutTuning` and redraws what reads it. Debug
/// builds in the Simulator only; on a phone `CategoryDrawer` shows the same dials in the app.
/// A value worth keeping is copied into `CategoryLayout`'s defaults.
@MainActor
final class CategoryDials {
    static let shared = CategoryDials()

    private let panel: DialPanelState<CategoryLayout>
    private var watching: AnyCancellable?

    private init() {
        panel = DialPanelState(
            // Fixed, so a relaunch or a preview edits the same panel.
            id: UUID(uuidString: "6E0B2C5A-3F4D-4E8B-9A71-2C1D5B7E9F30")!,
            name: CategoryDialSpecs.panelName,
            initial: LayoutTuning.shared.layout,
            controls: CategoryDialSpecs.groups.map { group in
                .group(group.title, children: group.dials.map(Self.control))
            },
            persistKey: "tilly.categories"
        )
        watching = panel.$values.sink { values in
            MainActor.assumeIsolated { LayoutTuning.shared.layout = values }
        }
    }

    private static func control(_ dial: CategoryDialSpec) -> DialControl<CategoryLayout> {
        switch dial.kind {
        case .points(let path, let range, let step, let unit):
            .slider(dial.key, keyPath: path, label: dial.label, range: range, step: step, unit: unit ? "pt" : nil)
        case .count(let path, let range):
            .slider(dial.key, keyPath: path, label: dial.label, range: range, step: 1)
        }
    }

    /// Connects to the inspector, retrying until it's running. Safe to call more than once.
    func start() {
        DialKitAgent.shared.start(appName: "Tilly")
    }
}
#endif
