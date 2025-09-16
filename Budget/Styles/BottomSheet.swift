import SwiftUI

// MARK: - Reusable Bottom Sheet Component
struct BottomSheet<SheetContent: View>: View {
    let sheetContent: SheetContent
    let buttonTitle: String
    let buttonAction: () -> Void
    let onClose: () -> Void
    let isButtonDisabled: Bool
    @StateObject private var keyboardScroll = KeyboardScrollCoordinator()
    
    init(
        buttonTitle: String,
        buttonAction: @escaping () -> Void,
        onClose: @escaping () -> Void,
        isButtonDisabled: Bool = false,
        @ViewBuilder content: () -> SheetContent
    ) {
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.onClose = onClose
        self.isButtonDisabled = isButtonDisabled
        self.sheetContent = content()
    }
    
    private var keyboardPadding: CGFloat {
        max(0, -keyboardScroll.scrollOffset)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    sheetContent
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                buttonArea
                    .padding(.bottom, keyboardPadding)
                    .animation(.easeInOut(duration: 0.25), value: keyboardPadding)
            }
        }
        .background(Color(white: 0.15))
        .ignoresSafeArea(.keyboard)
        .environment(\.keyboardScrollCoordinator, keyboardScroll)
        .onPreferenceChange(BottomSheetButtonFramePreferenceKey.self) { frame in
            updateButtonFrame(with: frame)
        }
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
                keyboardScroll.keyboardWillShow(height: keyboardFrame.height)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardScroll.keyboardWillHide()
        }
    }

    private var header: some View {
        ZStack {
            HStack {
                Spacer()
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                Spacer()
            }

            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 12)
        .padding(.horizontal, 20)
        .frame(height: 60)
    }

    private var buttonArea: some View {
        VStack(spacing: 16) {
            Button(buttonTitle, action: buttonAction)
                .buttonStyle(AppButtonStyle())
                .disabled(isButtonDisabled)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(
            Color(white: 0.12).opacity(0.95)
                .overlay(
                    Color.white.opacity(0.12)
                        .frame(height: 1),
                    alignment: .top
                )
        )
        .background(
            GeometryReader { geometry in
                Color.clear
                    .preference(
                        key: BottomSheetButtonFramePreferenceKey.self,
                        value: geometry.frame(in: .global)
                    )
            }
        )
    }

    private func updateButtonFrame(with frame: CGRect) {
        guard frame != .zero else { return }

        keyboardScroll.registerButtonFrame(frame)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private struct BottomSheetButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Category Bottom Sheet Content
struct CategorySheetContent: View {
    @Binding var name: String
    @Binding var emoji: String
    @Binding var isIncome: Bool
    @Environment(\.keyboardScrollCoordinator) private var keyboardScrollCoordinator
    
    var body: some View {
        VStack(spacing: 24) {
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                AppTextField(text: $name, placeholder: "e.g. Food") { isFocused in
                    keyboardScrollCoordinator?.focusChanged(
                        field: "category_name",
                        isFocused: isFocused,
                        accessoryHeight: KeyboardScrollCoordinator.standardAccessoryHeight
                    )
                }
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
                
                AppEmojiField(text: $emoji, placeholder: "e.g. 🍕") { isFocused in
                    keyboardScrollCoordinator?.focusChanged(
                        field: "category_emoji",
                        isFocused: isFocused,
                        accessoryHeight: KeyboardScrollCoordinator.emojiAccessoryHeight
                    )
                }
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
    @Environment(\.keyboardScrollCoordinator) private var keyboardScrollCoordinator

    var body: some View {
        VStack(spacing: 24) {
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Payment Type")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                AppTextField(text: $name, placeholder: "e.g. Credit Card, Pix") { isFocused in
                    keyboardScrollCoordinator?.focusChanged(
                        field: "payment_name",
                        isFocused: isFocused,
                        accessoryHeight: KeyboardScrollCoordinator.standardAccessoryHeight
                    )
                }
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

                AppEmojiField(text: $emoji, placeholder: "e.g. 💳") { isFocused in
                    keyboardScrollCoordinator?.focusChanged(
                        field: "payment_emoji",
                        isFocused: isFocused,
                        accessoryHeight: KeyboardScrollCoordinator.emojiAccessoryHeight
                    )
                }
            }
        }
    }
}

// MARK: - Hex Color Input Sheet Content
struct HexColorSheetContent: View {
    @Binding var hexInput: String
    @Environment(\.keyboardScrollCoordinator) private var keyboardScrollCoordinator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hex Color Code")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 8) {
                Text("#")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                
                AppTextField(text: $hexInput, placeholder: "000000") { isFocused in
                    keyboardScrollCoordinator?.focusChanged(
                        field: "hex_input",
                        isFocused: isFocused,
                        accessoryHeight: KeyboardScrollCoordinator.standardAccessoryHeight
                    )
                }
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
