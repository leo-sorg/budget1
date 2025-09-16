import SwiftUI

// MARK: - Reusable Bottom Sheet Component
struct BottomSheet<SheetContent: View>: View {
    let buttonTitle: String
    let buttonAction: () -> Void
    let onClose: () -> Void
    let isButtonDisabled: Bool
    let contentBuilder: (_ reportFocusChange: @escaping (String?) -> Void) -> SheetContent

    @State private var scrollOffset: CGFloat = 0
    @State private var keyboardHeight: CGFloat = 0
    @State private var buttonFrame: CGRect = .zero
    @State private var focusedFieldID: String?

    init(
        buttonTitle: String,
        buttonAction: @escaping () -> Void,
        onClose: @escaping () -> Void,
        isButtonDisabled: Bool = false,
        @ViewBuilder content: @escaping (_ reportFocusChange: @escaping (String?) -> Void) -> SheetContent
    ) {
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.onClose = onClose
        self.isButtonDisabled = isButtonDisabled
        self.contentBuilder = content
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header section
            HStack(alignment: .top) {
                // Drag indicator in center
                Spacer()
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                Spacer()
            }
            .overlay(
                // X button overlaid on right
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .offset(x: -20, y: 20)
                }
            )
            .frame(height: 60)

            ScrollView {
                VStack(spacing: 0) {
                    // Dynamic content
                    contentBuilder(handleFocusChange)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)

                    // Fixed button at bottom
                    Button(buttonTitle, action: buttonAction)
                        .buttonStyle(AppButtonStyle())
                        .disabled(isButtonDisabled)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 50)
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        updateButtonFrame(geometry.frame(in: .global))
                                    }
                                    .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                                        updateButtonFrame(newFrame)
                                    }
                            }
                        )
                }
                .offset(y: scrollOffset)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)

            Spacer(minLength: 0)
        }
        .background(Color(white: 0.15))
        .ignoresSafeArea(.keyboard)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("Cancel") {
                    hideKeyboard()
                }
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Color(white: 0.15))
        .presentationDragIndicator(.hidden)
        .interactiveDismissDisabled(false)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                updateKeyboardHeight(keyboardFrame.height)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            updateKeyboardHeight(0)
        }
    }

    private func handleFocusChange(_ fieldID: String?) {
        focusedFieldID = fieldID

        if fieldID != nil || keyboardHeight == 0 {
            adjustScrollForFocusedField()
        }
    }

    private func updateKeyboardHeight(_ height: CGFloat) {
        keyboardHeight = height
        adjustScrollForFocusedField()
    }

    private func updateButtonFrame(_ newFrame: CGRect) {
        if buttonFrame != newFrame {
            buttonFrame = newFrame

            if focusedFieldID != nil && keyboardHeight > 0 {
                adjustScrollForFocusedField(animated: false)
            }
        }
    }

    private func adjustScrollForFocusedField(animated: Bool = true) {
        guard focusedFieldID != nil, keyboardHeight > 0 else {
            setScrollOffset(0, animated: animated)
            return
        }

        let keyboardTop = UIScreen.main.bounds.height - keyboardHeight
        let padding: CGFloat = 24
        let targetPosition = keyboardTop - padding
        let buttonBottom = buttonFrame.maxY
        let overlap = max(0, buttonBottom - targetPosition)

        setScrollOffset(-overlap, animated: animated)
    }

    private func setScrollOffset(_ newValue: CGFloat, animated: Bool) {
        if animated {
            withAnimation(.easeInOut(duration: 0.25)) {
                scrollOffset = newValue
            }
        } else {
            scrollOffset = newValue
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Category Bottom Sheet Content
struct CategorySheetContent: View {
    @Binding var name: String
    @Binding var emoji: String
    @Binding var isIncome: Bool
    var onFieldFocusChange: (String?) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 24) {
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                AppTextField(
                    text: $name,
                    placeholder: "e.g. Food",
                    onFocusChange: { isFocused in
                        onFieldFocusChange(isFocused ? "categoryName" : nil)
                    }
                )
            }

            // Emoji field with picker button
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Emoji (optional)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    EmojiHelperButton { selectedEmoji in
                        emoji = selectedEmoji
                    }
                }

                AppEmojiField(
                    text: $emoji,
                    placeholder: "e.g. 🍕",
                    onFocusChange: { isFocused in
                        onFieldFocusChange(isFocused ? "categoryEmoji" : nil)
                    }
                )
            }

            // Type selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Type")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                HStack(spacing: 12) {
                    Button(action: { isIncome = false }) {
                        Text("Expense")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .background(GlassChipBackground(isSelected: !isIncome))
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { isIncome = true }) {
                        Text("Income")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .background(GlassChipBackground(isSelected: isIncome))
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Payment Bottom Sheet Content
struct PaymentSheetContent: View {
    @Binding var name: String
    @Binding var emoji: String
    var onFieldFocusChange: (String?) -> Void = { _ in }

    var body: some View {
        VStack(spacing: 24) {
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Payment Type")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                AppTextField(
                    text: $name,
                    placeholder: "e.g. Credit Card, Pix",
                    onFocusChange: { isFocused in
                        onFieldFocusChange(isFocused ? "paymentName" : nil)
                    }
                )
            }

            // Emoji field with picker button
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Emoji (optional)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                    EmojiHelperButton { selectedEmoji in
                        emoji = selectedEmoji
                    }
                }

                AppEmojiField(
                    text: $emoji,
                    placeholder: "e.g. 💳",
                    onFocusChange: { isFocused in
                        onFieldFocusChange(isFocused ? "paymentEmoji" : nil)
                    }
                )
            }
        }
    }
}

// MARK: - Hex Color Input Sheet Content
struct HexColorSheetContent: View {
    @Binding var hexInput: String
    var onFieldFocusChange: (String?) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hex Color Code")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 8) {
                Text("#")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))

                AppTextField(
                    text: $hexInput,
                    placeholder: "000000",
                    onFocusChange: { isFocused in
                        onFieldFocusChange(isFocused ? "hexCode" : nil)
                    }
                )
                    .onChange(of: hexInput) { _, newValue in
                        // Remove # if user types it
                        var cleaned = newValue.replacingOccurrences(of: "#", with: "")
                        // Limit to 6 characters
                        if cleaned.count > 6 {
                            cleaned = String(cleaned.prefix(6))
                        }
                        // Only allow hex characters
                        cleaned = cleaned.filter { $0.isHexDigit }
                        hexInput = cleaned.uppercased()
                    }
            }
            
            // Preview of the color using UIKit
            if hexInput.count == 6, let color = Color(hex: hexInput) {
                HStack {
                    Text("Preview:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    // Use UIKit-based preview
                    ColorBoxView(color: color)
                        .frame(width: 60, height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(.bottom, 30)
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (6 digits)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
