#if DEBUG
import SwiftUI
import UIKit

/// The live tuning in Settings: how to reach the layout dials, the motion and drawn look that only
/// tune here, as a few named steps each under a heading for what they change, and a way back to the
/// defaults. Three slots, A, B and C, keep a whole motion setup to flip back to; "Copy values" puts
/// the exact numbers on the pasteboard, for `Tokens.swift`.
struct MotionTuningSection: View {
    @State private var tuning = MotionTuning.shared
    @State private var savedSlots: Set<String> = Set(Self.slotNames.filter { UserDefaults.standard.dictionary(forKey: Self.slotKey($0)) != nil })
    @State private var confirmingReset = false

    private static let slotNames = ["A", "B", "C"]
    private static func slotKey(_ name: String) -> String { "motion.slot.\(name)" }

    var body: some View {
        Section {
            #if targetEnvironment(simulator)
            Text("Sizes and spacing on the category screens: run DialKit's Mac inspector (`swift run dialkit-macos`) and open its Categories panel.")
            #else
            Text("Sizes and spacing on the category screens: shake the phone to open DialKit's dials; shake again to close them.")
            #endif
            HStack(spacing: Tokens.Space.gap) {
                ForEach(Self.slotNames, id: \.self) { name in slot(name) }
            }
            .buttonStyle(.bordered)
            Button("Copy motion values") { UIPasteboard.general.string = tuning.swiftSnippet }
            Button("Reset tuning to defaults", role: .destructive) { confirmingReset = true }
        } header: {
            Text("Tuning")
        } footer: {
            Text("Live, in this build only. A slot keeps the motion setup you have now; tap it to bring it back, hold to save over it.")
        }
        .confirmationDialog("Reset tuning?", isPresented: $confirmingReset) {
            Button("Reset to Defaults", role: .destructive, action: resetAll)
        } message: {
            Text("Every DialKit dial and every motion step below goes back to what ships.")
        }
        ForEach(MotionGroup.sections, id: \.self) { section in
            Section(section) {
                ForEach(MotionGroup.all.filter { $0.section == section }) { group in
                    picker(group)
                }
            }
        }
    }

    private func picker(_ group: MotionGroup) -> some View {
        VStack(alignment: .leading, spacing: Tokens.Space.tight) {
            Text(group.label)
            Text(group.detail)
                .font(Tokens.Text.caption)
                .foregroundStyle(Tokens.Ink.secondary)
            Picker(group.label, selection: Binding(
                get: { group.current(in: tuning)?.name ?? "" },
                set: { name in
                    if let step = group.steps.first(where: { $0.name == name }) { tuning.apply(step.values) }
                }
            )) {
                if group.current(in: tuning) == nil { Text("Custom").tag("") }
                ForEach(group.steps) { Text($0.name).tag($0.name) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private func resetAll() {
        tuning.reset()
        #if targetEnvironment(simulator)
        CategoryDials.shared.reset()
        #else
        CategoryDrawer.shared.reset()
        #endif
    }

    /// Tap to bring the setup back, long-press to save the present one over it.
    private func slot(_ name: String) -> some View {
        let isSaved = savedSlots.contains(name)
        return Button {
            if let setup = UserDefaults.standard.dictionary(forKey: Self.slotKey(name)) as? [String: Double] {
                tuning.apply(setup)
            } else {
                save(name)
            }
        } label: {
            Text(isSaved ? name : "\(name) (empty)").frame(maxWidth: .infinity)
        }
        .simultaneousGesture(LongPressGesture(minimumDuration: 0.6).onEnded { _ in save(name) })
    }

    private func save(_ name: String) {
        UserDefaults.standard.set(tuning.snapshot(), forKey: Self.slotKey(name))
        savedSlots.insert(name)
    }
}
#endif
