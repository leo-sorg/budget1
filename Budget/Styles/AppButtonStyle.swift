import SwiftUI

// MARK: - Button State Manager
@MainActor
final class ButtonStateManager: ObservableObject, Equatable {
    @Published var isLoading = false
    @Published var showSuccess = false
    private let id = UUID()
    
    static func == (lhs: ButtonStateManager, rhs: ButtonStateManager) -> Bool {
        lhs.id == rhs.id
    }
    
    func startLoading() {
        isLoading = true
        showSuccess = false
    }
    
    func showSuccessAndReset() {
        isLoading = false
        showSuccess = true
        
        // Reset to normal state after showing success
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.showSuccess = false
            }
        }
    }
    
    func reset() {
        isLoading = false
        showSuccess = false
    }
}

// MARK: - Enhanced App Button Style with States (System Glass)
struct AppButtonStyle: ButtonStyle {
    @StateObject private var stateManager = ButtonStateManager()
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            configuration.label
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .opacity(stateManager.isLoading || stateManager.showSuccess ? 0 : 1)
            
            // Loading indicator
            if stateManager.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                    .transition(.opacity.combined(with: .scale))
            }
            
            // Success checkmark
            if stateManager.showSuccess {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .allowsHitTesting(!stateManager.isLoading)
        .animation(.easeInOut(duration: 0.2), value: stateManager.isLoading)
        .animation(.easeInOut(duration: 0.2), value: stateManager.showSuccess)
        .preference(key: ButtonStatePreferenceKey.self, value: stateManager)
    }
}

// MARK: - Small Button Style - System Glass
struct AppSmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Preference Key for State Management
struct ButtonStatePreferenceKey: PreferenceKey {
    static var defaultValue: ButtonStateManager? = nil
    
    static func reduce(value: inout ButtonStateManager?, nextValue: () -> ButtonStateManager?) {
        value = nextValue()
    }
}

// MARK: - Enhanced Button View Wrapper (For main buttons only)
struct EnhancedButton: View {
    let title: String
    let action: () async -> Bool // Returns true if successful
    @State private var stateManager: ButtonStateManager?
    
    var body: some View {
        Button(title) {
            Task {
                guard let stateManager = stateManager else { return }
                
                // Start loading
                await MainActor.run {
                    stateManager.startLoading()
                }
                
                // Perform action
                let success = await action()
                
                // Show result
                await MainActor.run {
                    if success {
                        stateManager.showSuccessAndReset()
                    } else {
                        stateManager.reset()
                    }
                }
            }
        }
        .buttonStyle(AppButtonStyle())
        .onPreferenceChange(ButtonStatePreferenceKey.self) { manager in
            self.stateManager = manager
        }
    }
}

// MARK: - View Extension for Easy Use (Optional helper)
extension View {
    func withButtonFeedback(
        isLoading: Binding<Bool>,
        showSuccess: Binding<Bool>
    ) -> some View {
        self.overlay(
            Group {
                if isLoading.wrappedValue {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                if showSuccess.wrappedValue {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.opacity.combined(with: .scale))
                }
            }
        )
    }
}
