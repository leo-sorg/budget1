import SwiftUI
import UIKit

// MARK: - Clean Emoji Text Field Implementation
struct EmojiOnlyTextField: View {
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
                // Limit emoji input length
                if newValue.count > 10 {
                    text = String(newValue.prefix(10))
                }
            }
            .padding(12)
            .background(
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
            )
            // IMPORTANT: No custom toolbar - this was causing conflicts
    }
}
