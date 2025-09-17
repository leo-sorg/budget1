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

// MARK: - Glass Button Background (Shared by both styles)
private struct GlassButtonBackground: View {
    let isPressed: Bool
    let isLoading: Bool
    let showSuccess: Bool
    
    init(isPressed: Bool) {
        self.isPressed = isPressed
        self.isLoading = false
        self.showSuccess = false
    }
    
    init(isPressed: Bool, isLoading: Bool, showSuccess: Bool) {
        self.isPressed = isPressed
        self.isLoading = isLoading
        self.showSuccess = showSuccess
    }
    
    var body: some View {
        Capsule()
            .fill(.clear)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)
            )
            .overlay(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isPressed ? 0.35 : 0.25),
                                Color.white.opacity(isPressed ? 0.25 : 0.15),
                                Color.white.opacity(isPressed ? 0.25 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(isPressed ? 1.0 : 0.6)
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isPressed ? 0.7 : 0.6),
                                Color.white.opacity(isPressed ? 0.3 : 0.2),
                                Color.white.opacity(isPressed ? 0.5 : 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .opacity(isPressed ? 1.0 : 0.7)
            )
            .overlay(
                // Success overlay (only for main buttons)
                Group {
                    if showSuccess {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.green.opacity(0.4),
                                        Color.green.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .transition(.opacity)
                    }
                }
            )
            .scaleEffect(isPressed && (isLoading || showSuccess) ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Enhanced App Button Style with States
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
        .background(
            GlassButtonBackground(
                isPressed: configuration.isPressed,
                isLoading: stateManager.isLoading,
                showSuccess: stateManager.showSuccess
            )
        )
        .buttonStyle(PlainButtonStyle())
        .allowsHitTesting(!stateManager.isLoading)
        .animation(.easeInOut(duration: 0.2), value: stateManager.isLoading)
        .animation(.easeInOut(duration: 0.2), value: stateManager.showSuccess)
        .preference(key: ButtonStatePreferenceKey.self, value: stateManager)
    }
}

// MARK: - Small Button Style - Same as original, no changes
struct AppSmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(GlassButtonBackground(isPressed: configuration.isPressed))
            .buttonStyle(PlainButtonStyle())
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
