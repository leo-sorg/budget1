import SwiftUI

// MARK: - Button State Manager
@MainActor
final class ButtonStateManager: ObservableObject, @MainActor Equatable {
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

// MARK: - App Button Style (Always uses Apple's .glass)
struct AppButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

// MARK: - Small Button Style (Uses Apple's .glass)
struct AppSmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
    }
}

// MARK: - View Extensions for Button Styles
extension View {
    func appButtonStyle() -> some View {
        self.buttonStyle(.glass)
    }
    
    func appSmallButtonStyle() -> some View {
        self.buttonStyle(.glass)
    }
}

// MARK: - Enhanced Button with Loading States
struct EnhancedButton: View {
    let title: String
    let action: () async -> Bool
    @StateObject private var stateManager = ButtonStateManager()
    
    var body: some View {
        Button {
            Task {
                await MainActor.run {
                    stateManager.startLoading()
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
                
                let success = await action()
                
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
                }
                
                if stateManager.showSuccess {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
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
