import SwiftUI

// MARK: - Reusable Bottom Sheet Component
struct BottomSheet<SheetContent: View>: View {
    let sheetContent: SheetContent
    let buttonTitle: String
    let buttonAction: () -> Void
    let onClose: () -> Void
    let isButtonDisabled: Bool
    @State private var keyboardShowing = false
    
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
            
            // Content that sizes itself - NO SCROLL VIEW
            VStack(spacing: 0) {
                // Dynamic content
                sheetContent
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                
                // Fixed button at bottom
                Button(buttonTitle, action: buttonAction)
                    .buttonStyle(AppButtonStyle())
                    .disabled(isButtonDisabled)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50) // Simple fixed bottom padding
            }
            
            Spacer(minLength: 0) // Push content to top
        }
        .background(Color(white: 0.15))
        .ignoresSafeArea(.keyboard) // Let SwiftUI handle keyboard automatically
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
        // Use medium detent only
        .presentationDetents([.medium])
        .presentationBackground(Color(white: 0.15))
        .presentationDragIndicator(.hidden) // We have our own custom indicator
        .interactiveDismissDisabled(false)
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
    @FocusState private var nameFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                AppTextField(text: $name, placeholder: "e.g. Food")
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
                
                AppEmojiField(text: $emoji, placeholder: "e.g. 🍕")
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
        .onAppear {
            // Don't auto-focus to prevent unexpected scrolling
            nameFieldFocused = false
        }
    }
}

// MARK: - Payment Bottom Sheet Content
struct PaymentSheetContent: View {
    @Binding var name: String
    @Binding var emoji: String
    @FocusState private var nameFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text("Payment Type")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                AppTextField(text: $name, placeholder: "e.g. Credit Card, Pix")
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
                
                AppEmojiField(text: $emoji, placeholder: "e.g. 💳")
            }
        }
        .onAppear {
            // Don't auto-focus to prevent unexpected scrolling
            nameFieldFocused = false
        }
    }
}

// MARK: - Hex Color Input Sheet Content
struct HexColorSheetContent: View {
    @Binding var hexInput: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hex Color Code")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
            
            HStack(spacing: 8) {
                Text("#")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                
                AppTextField(text: $hexInput, placeholder: "000000")
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
        .onAppear {
            isFocused = true
        }
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
