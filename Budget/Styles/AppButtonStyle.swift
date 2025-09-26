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

// MARK: - App Button Style (Fixed - Clickable everywhere)
struct AppButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: isDisabled ? .medium : .semibold))
            .foregroundStyle(isDisabled ? Color(white: 0.9) : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .contentShape(Rectangle()) // ✅ This makes the entire area clickable
            .background {
                if !isDisabled {
                    Capsule()
                        .fill(.thinMaterial)
                }
            }
    }
}

// MARK: - Small Button Style (Fixed - Clickable everywhere)
struct AppSmallButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: isDisabled ? .medium : .semibold))
            .foregroundStyle(isDisabled ? Color(white: 0.9) : .white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle()) // ✅ This makes the entire area clickable
            .background {
                if isDisabled {
                    Capsule()
                        .fill(.thinMaterial)
                } else {
                    Capsule()
                        .glassEffect(.regular.interactive())
                }
            }
    }
}

// MARK: - View Extensions for Button Styles
extension View {
    func appButtonStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(AppButtonStyle(isDisabled: isDisabled))
    }
    
    func appSmallButtonStyle() -> some View {
        self.buttonStyle(AppSmallButtonStyle())
    }
}

// MARK: - Enhanced Button with Loading States (Fixed - Clickable everywhere)
struct EnhancedButton: View {
    let title: String
    let action: () async -> Bool
    let isDisabled: Bool
    @StateObject private var stateManager = ButtonStateManager()
    
    init(title: String, isDisabled: Bool = false, action: @escaping () async -> Bool) {
        self.title = title
        self.isDisabled = isDisabled
        self.action = action
    }
    
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
                    .font(.system(size: 16, weight: isDisabled ? .medium : .semibold))
                    .foregroundStyle(isDisabled ? Color(white: 0.9) : .white)
                    .opacity(stateManager.isLoading || stateManager.showSuccess ? 0 : 1)
                
                if stateManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                }
                
                if stateManager.showSuccess {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .contentShape(Rectangle()) // ✅ This makes the entire area clickable
        }
        .buttonStyle(.plain)
        .background {
                    if isDisabled && !stateManager.isLoading && !stateManager.showSuccess {
                        Capsule()
                            .fill(.thinMaterial)
                    } else {
                        Capsule()
                            .glassEffect(.regular.interactive())
                    }
                }
        .disabled(isDisabled)
        .animation(.easeInOut(duration: 0.2), value: stateManager.isLoading)
        .animation(.easeInOut(duration: 0.2), value: stateManager.showSuccess)
    }
}
