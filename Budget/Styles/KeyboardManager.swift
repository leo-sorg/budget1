import SwiftUI
import UIKit

// MARK: - UIKit Emoji Text Field
final class EmojiTextField: UITextField {
    override var textInputContextIdentifier: String? {
        ""
    }

    override var textInputMode: UITextInputMode? {
        if let emojiMode = UITextInputMode.activeInputModes.first(where: { $0.primaryLanguage == "emoji" }) {
            return emojiMode
        }
        return super.textInputMode
    }
}

// MARK: - SwiftUI Wrapper
struct EmojiTextFieldRepresentable: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    var isFirstResponder: FocusState<Bool>.Binding

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> EmojiTextField {
        let textField = EmojiTextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.backgroundColor = .clear
        textField.textColor = .white
        textField.tintColor = .white
        textField.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.returnKeyType = .done
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: 0))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 4, height: 0))
        textField.rightViewMode = .always
        applyPlaceholder(placeholder, to: textField)
        textField.inputAccessoryView = makeAccessoryToolbar(for: context.coordinator)
        context.coordinator.textField = textField
        return textField
    }

    func updateUIView(_ uiView: EmojiTextField, context: Context) {
        context.coordinator.parent = self
        context.coordinator.textField = uiView

        if uiView.text != text {
            uiView.text = text
        }

        applyPlaceholder(placeholder, to: uiView)

        if isFirstResponder.wrappedValue {
            if !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            }
        } else if uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    private func makeAccessoryToolbar(for coordinator: Coordinator) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.barStyle = .black
        toolbar.isTranslucent = true
        toolbar.tintColor = .white
        toolbar.sizeToFit()

        let cancelItem = UIBarButtonItem(title: "Cancel", style: .plain, target: coordinator, action: #selector(Coordinator.cancelTapped))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneItem = UIBarButtonItem(title: "Done", style: .done, target: coordinator, action: #selector(Coordinator.doneTapped))
        toolbar.items = [cancelItem, flexible, doneItem]

        return toolbar
    }

    private static func applyPlaceholder(_ placeholder: String, to textField: UITextField) {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white.withAlphaComponent(0.4)
        ]
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attributes)
    }

    private func applyPlaceholder(_ placeholder: String, to textField: UITextField) {
        Self.applyPlaceholder(placeholder, to: textField)
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: EmojiTextFieldRepresentable
        weak var textField: EmojiTextField?

        init(parent: EmojiTextFieldRepresentable) {
            self.parent = parent
        }

        @objc func textDidChange(_ textField: UITextField) {
            let newText = textField.text ?? ""
            if parent.text != newText {
                parent.text = newText
            }
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            if !parent.isFirstResponder.wrappedValue {
                parent.isFirstResponder.wrappedValue = true
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if parent.isFirstResponder.wrappedValue {
                parent.isFirstResponder.wrappedValue = false
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        @objc func cancelTapped() {
            textField?.resignFirstResponder()
        }

        @objc func doneTapped() {
            parent.text = textField?.text ?? parent.text
            textField?.resignFirstResponder()
        }
    }
}

// MARK: - Shared Glass Background (System Glass)
struct GlassBackground: View {
    let isFocused: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(.clear)
            .glassEffect(isFocused ? .regular.interactive() : .regular, in: .rect(cornerRadius: 12))
    }
}

// MARK: - 1. CURRENCY FIELD (Number Pad) - NO TOOLBAR
struct AppCurrencyField: View {
    @Binding var text: String
    let placeholder: String
    let onFocusChange: ((Bool) -> Void)?
    @FocusState private var isFocused: Bool
    @State private var displayText: String = ""
    
    init(text: Binding<String>, placeholder: String, onFocusChange: ((Bool) -> Void)? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.onFocusChange = onFocusChange
    }
    
    var body: some View {
        TextField(placeholder, text: $displayText)
            .focused($isFocused)
            .foregroundColor(.white)
            .keyboardType(.numberPad)
            .padding(12)
            .background(GlassBackground(isFocused: isFocused))
            .onChange(of: displayText) { _, newValue in
                formatCurrency(newValue)
            }
            .onChange(of: text) { _, newValue in
                if newValue.isEmpty { displayText = "" }
            }
            .onChange(of: isFocused) { _, newValue in
                onFocusChange?(newValue)
            }
            .onAppear { displayText = text }
    }
    
    private func formatCurrency(_ value: String) {
        let digits = value.filter { $0.isNumber }
        guard !digits.isEmpty else {
            text = ""
            return
        }
        
        if let intValue = Int(digits) {
            let decimalValue = Decimal(intValue) / 100
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: "pt_BR")
            
            if let formatted = formatter.string(for: NSDecimalNumber(decimal: decimalValue)) {
                displayText = formatted
                text = formatted
            }
        }
    }
}

// MARK: - 2. TEXT FIELD (Standard Keyboard) - NO TOOLBAR
struct AppTextField: View {
    @Binding var text: String
    let placeholder: String
    let onFocusChange: ((Bool) -> Void)?
    @FocusState private var isFocused: Bool
    
    init(text: Binding<String>, placeholder: String, onFocusChange: ((Bool) -> Void)? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.onFocusChange = onFocusChange
    }
    
    var body: some View {
        TextField(placeholder, text: $text)
            .focused($isFocused)
            .foregroundColor(.white)
            .keyboardType(.default)
            .padding(12)
            .background(GlassBackground(isFocused: isFocused))
            .onChange(of: isFocused) { _, newValue in
                onFocusChange?(newValue)
            }
    }
}

// MARK: - 3. EMOJI FIELD (Default Keyboard) - FIXED HEIGHT
struct AppEmojiField: View {
    @Binding var text: String
    let placeholder: String
    let onFocusChange: ((Bool) -> Void)?
    @FocusState private var isFocused: Bool

    init(text: Binding<String>, placeholder: String, onFocusChange: ((Bool) -> Void)? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.onFocusChange = onFocusChange
    }

    var body: some View {
        EmojiTextFieldRepresentable(text: $text, placeholder: placeholder, isFirstResponder: $isFocused)
            .focused($isFocused)
            .frame(height: 20)
            .frame(maxWidth: .infinity)
            .onChange(of: text) { _, newValue in
                if newValue.count > 10 {
                    text = String(newValue.prefix(10))
                }
            }
            .onChange(of: isFocused) { _, newValue in
                onFocusChange?(newValue)
            }
            .padding(12)
            .background(GlassBackground(isFocused: isFocused))
    }
}

// MARK: - Helper Function
private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
