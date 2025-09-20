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

// MARK: - App Button Style (Uses Apple's .glass)
struct AppButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .buttonStyle(.glass)
    }
}

// MARK: - Small Button Style (Uses Apple's .glass)
struct AppSmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .buttonStyle(.glass)
    }
}

// MARK: - Enhanced Button with Loading/Success States
struct EnhancedButton: View {
    let title: String
    let action: () async -> Bool // Returns true if successful
    @StateObject private var stateManager = ButtonStateManager()
    
    var body: some View {
        Button {
            Task {
                // Start loading with haptic feedback
                await MainActor.run {
                    stateManager.startLoading()
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
                
                // Perform action
                let success = await action()
                
                // Show result with appropriate haptic feedback
                await MainActor.run {
                    if success {
                        stateManager.showSuccessAndReset()
                        let notification = UINotificationFeedbackGenerator()
                        notification.notificationOccurred(.success)
                    } else {
                        stateManager.reset()
                        let notification = UINotificationFeedbackGenerator()
                        notification.notificationOccurred(.error)
                    }
                }
            }
        } label: {
            ZStack {
                Text(title)
                    .opacity(stateManager.isLoading || stateManager.showSuccess ? 0 : 1)
                
                if stateManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                        .transition(.opacity.combined(with: .scale))
                }
                
                if stateManager.showSuccess {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.glass)
        .disabled(stateManager.isLoading)
        .animation(.easeInOut(duration: 0.2), value: stateManager.isLoading)
        .animation(.easeInOut(duration: 0.2), value: stateManager.showSuccess)
    }
}

// MARK: - Glass Button Container for Multiple Buttons
struct GlassButtonContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        GlassEffectContainer(spacing: spacing) {
            VStack(spacing: spacing) {
                content
            }
        }
    }
}

// MARK: - View Extensions for Button Feedback
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
                        .scaleEffect(0.7)
                }
                
                if showSuccess.wrappedValue {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .transition(.opacity.combined(with: .scale))
                }
            }
        )
    }
}

// MARK: - Haptic Feedback Helper
extension View {
    func withHapticFeedback() -> some View {
        self.onTapGesture {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
}