import SwiftUI

import SwiftUI

// MARK: - Shared Glass Background Component for Text Fields
private struct GlassTextFieldBackground: View {
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

// MARK: - Glass Text Field Style with Toolbar
struct GlassTextFieldStyle: TextFieldStyle {
    @FocusState private var isFocused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .focused($isFocused)
            .foregroundColor(.white)
            .padding(12)
            .background(GlassTextFieldBackground(isFocused: isFocused))
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Cancel") {
                        isFocused = false
                        hideKeyboard()
                    }
                    Spacer()
                    Button("Done") {
                        isFocused = false
                        hideKeyboard()
                    }
                }
            }
    }
}

// MARK: - Custom Glass Text Field with Focus Callback
struct GlassTextFieldWithCallback: View {
    @Binding var text: String
    let placeholder: String
    let onFocusChange: (Bool) -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField(placeholder, text: $text)
            .focused($isFocused)
            .foregroundColor(.white)
            .padding(12)
            .background(GlassTextFieldBackground(isFocused: isFocused))
            .onChange(of: isFocused) { _, newValue in
                onFocusChange(newValue)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Cancel") {
                        isFocused = false
                        hideKeyboard()
                    }
                    Spacer()
                    Button("Done") {
                        isFocused = false
                        hideKeyboard()
                    }
                }
            }
    }
}

// MARK: - Currency Text Field with Proper Formatting - Updated with Focus Binding
struct CurrencyTextField: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    @State private var displayText: String = ""
    
    // Callback to notify parent about focus changes
    let onFocusChange: ((Bool) -> Void)?
    
    // NEW: Initializer that accepts focus change callback
    init(text: Binding<String>, placeholder: String, onFocusChange: @escaping (Bool) -> Void) {
        self._text = text
        self.placeholder = placeholder
        self.onFocusChange = onFocusChange
    }
    
    // LEGACY: Initializer for backward compatibility (without focus tracking)
    init(text: Binding<String>, placeholder: String) {
        self._text = text
        self.placeholder = placeholder
        self.onFocusChange = nil
    }
    
    var body: some View {
        TextField(placeholder, text: $displayText)
            .focused($isFocused)
            .foregroundColor(.white)
            .keyboardType(.numberPad)
            .padding(12)
            .background(GlassTextFieldBackground(isFocused: isFocused))
            .onChange(of: displayText) { _, newValue in
                formatCurrency(newValue)
            }
            .onChange(of: text) { _, newValue in
                if newValue.isEmpty {
                    displayText = ""
                }
            }
            .onChange(of: isFocused) { _, newValue in
                onFocusChange?(newValue)
            }
            .onAppear {
                displayText = text
            }
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

// MARK: - Glass Date Picker Container
struct GlassDatePicker: View {
    @Binding var selection: Date
    @State private var isFocused: Bool = false
    
    var body: some View {
        DatePicker("", selection: $selection, displayedComponents: .date)
            .labelsHidden()
            .datePickerStyle(.compact)
            .padding(12)
            .background(GlassTextFieldBackground(isFocused: isFocused))
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isFocused.toggle()
                }
            }
    }
}

// MARK: - Helper function
private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
