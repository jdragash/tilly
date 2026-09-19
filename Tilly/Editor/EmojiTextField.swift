import SwiftUI
import UIKit

/// A text field whose keyboard opens on the system emoji keyboard. It draws nothing: the slot
/// it sits in shows the chosen emoji, and this only receives the typing. Where the person has
/// no emoji keyboard enabled it falls back to their default keyboard, and `EmojiInput` still
/// filters what arrives, so a letter never becomes a category's emoji.
struct EmojiTextField: UIViewRepresentable {
    @Binding var emoji: String?
    @Binding var isFocused: Bool

    func makeUIView(context: Context) -> EmojiUITextField {
        let field = EmojiUITextField()
        field.delegate = context.coordinator
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        field.textColor = .clear
        field.tintColor = .clear
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.autocapitalizationType = .none
        return field
    }

    func updateUIView(_ field: EmojiUITextField, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        // Act on a change of the binding, not on its state. In the emoji-to-name handoff the name
        // field has taken focus before the binding's write lands, so `isFocused` is briefly stale
        // and any update in that window would otherwise pull focus back to this field.
        guard isFocused != coordinator.lastSeenFocus else { return }
        coordinator.lastSeenFocus = isFocused
        if isFocused {
            if !field.isFirstResponder {
                // The field may not be in a window yet on the first pass.
                DispatchQueue.main.async {
                    field.becomeFirstResponder()
                    field.reloadInputViews()
                }
            }
        } else if field.isFirstResponder {
            field.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    @MainActor
    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiTextField
        /// The last `isFocused` that `updateUIView` saw; see the note there.
        var lastSeenFocus = false

        init(_ parent: EmojiTextField) { self.parent = parent }

        @objc func changed(_ field: UITextField) {
            let text = field.text ?? ""
            field.text = ""
            if let emoji = EmojiInput.emoji(from: text) {
                parent.emoji = emoji
            }
        }

        func textFieldDidBeginEditing(_ field: UITextField) { setFocused(true) }
        func textFieldDidEndEditing(_ field: UITextField) { setFocused(false) }

        /// `resignFirstResponder()` in `updateUIView` ends editing synchronously, which would write
        /// the binding in the middle of a view update. Write only a change, and a turn later.
        private func setFocused(_ focused: Bool) {
            guard parent.isFocused != focused else { return }
            Task { @MainActor in
                if parent.isFocused != focused { parent.isFocused = focused }
            }
        }
    }
}

final class EmojiUITextField: UITextField {
    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" } ?? super.textInputMode
    }
}
