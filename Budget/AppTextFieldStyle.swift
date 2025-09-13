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

// MARK: - Glass Text Field Style
struct GlassTextFieldStyle: TextFieldStyle {
    @FocusState private var isFocused: Bool
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .focused($isFocused)
            .foregroundColor(.white)
            .padding(12)
            .background(GlassTextFieldBackground(isFocused: isFocused))
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
