#if DEBUG
import SwiftUI
import UIKit

/// The look's and the card's motion as a few named steps each, so a feel can be tuned on the phone by
/// choosing between things a real distance apart. Three slots, A, B and C, keep a whole setup to flip
/// back to; "Copy values" puts the exact numbers on the pasteboard, for `Tokens.swift`.
struct MotionTuningSection: View {
    @State private var tuning = MotionTuning.shared
    @State private var savedSlots: Set<String> = Set(Self.slotNames.filter { UserDefaults.standard.dictionary(forKey: Self.slotKey($0)) != nil })

    private static let slotNames = ["A", "B", "C"]
    private static func slotKey(_ name: String) -> String { "motion.slot.\(name)" }

    var body: some View {
        Section {
            HStack(spacing: Tokens.Space.gap) {
                ForEach(Self.slotNames, id: \.self) { name in slot(name) }
            }
            .buttonStyle(.bordered)
            ForEach(MotionGroup.all) { group in
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
            Button("Reset everything") { tuning.reset() }
            Button("Copy values") { UIPasteboard.general.string = tuning.swiftSnippet }
        } header: {
            Text("Look and motion")
        } footer: {
            Text("Live, in this build only. A slot keeps the setup you have now; tap it to bring it back, hold to save over it. Edges update as a screen redraws.")
        }
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
