import SwiftUI

// MARK: - KEYBOARD SYSTEM WITH NO TOOLBARS (GLOBAL TOOLBAR WILL BE ADDED ELSEWHERE)

// MARK: - Shared Glass Background
struct GlassBackground: View {
    let isFocused: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.clear)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isFocused ? 0.35 : 0.25),
                                Color.white.opacity(isFocused ? 0.25 : 0.15),
                                Color.white.opacity(isFocused ? 0.25 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(isFocused ? 1.0 : 0.6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isFocused ? 0.7 : 0.6),
                                Color.white.opacity(isFocused ? 0.3 : 0.2),
                                Color.white.opacity(isFocused ? 0.5 : 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .opacity(isFocused ? 1.0 : 0.7)
            )
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
            // NO TOOLBAR HERE
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
            // NO TOOLBAR HERE
    }
}

// MARK: - 3. EMOJI FIELD (Default Keyboard) - NO TOOLBAR
struct AppEmojiField: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField(placeholder, text: $text)
            .focused($isFocused)
            .foregroundColor(.white)
            .keyboardType(.default)
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            .onChange(of: text) { _, newValue in
                if newValue.count > 10 {
                    text = String(newValue.prefix(10))
                }
            }
            .padding(12)
            .background(GlassBackground(isFocused: isFocused))
            // NO TOOLBAR HERE
    }
}

// MARK: - Helper Function
private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
