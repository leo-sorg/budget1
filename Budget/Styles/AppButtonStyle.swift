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

// MARK: - Enhanced App Button Style with Liquid Glass
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
        .allowsHitTesting(!stateManager.isLoading)
        .animation(.easeInOut(duration: 0.2), value: stateManager.isLoading)
        .animation(.easeInOut(duration: 0.2), value: stateManager.showSuccess)
        .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        .preference(key: ButtonStatePreferenceKey.self, value: stateManager)
    }
}

// MARK: - Small Button Style with Glass Effect
struct AppSmallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Glass Button Style (Custom implementation)
struct GlassButtonStyle: ButtonStyle {
    let isProminent: Bool
    
    init(isProminent: Bool = false) {
        self.isProminent = isProminent
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                isProminent ? .thickMaterial : .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Glass Button Style Extensions
extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { 
        GlassButtonStyle(isProminent: false) 
    }
    
    static var glassProminent: GlassButtonStyle { 
        GlassButtonStyle(isProminent: true) 
    }
}

// MARK: - Custom Glass Container for Multiple Buttons
struct GlassButtonContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: spacing) {
            content
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Preference Key for State Management
struct ButtonStatePreferenceKey: PreferenceKey {
    static var defaultValue: ButtonStateManager? = nil
    
    static func reduce(value: inout ButtonStateManager?, nextValue: () -> ButtonStateManager?) {
        value = nextValue()
    }
}

// MARK: - Enhanced Button View Wrapper
struct EnhancedButton: View {
    let title: String
    let action: () async -> Bool // Returns true if successful
    @State private var stateManager: ButtonStateManager?
    
    var body: some View {
        Button(title) {
            Task {
                guard let stateManager = stateManager else { return }
                
                // Start loading with haptic feedback
                await MainActor.run {
                    stateManager.startLoading()
                    // Light haptic feedback when starting
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
                
                // Perform action
                let success = await action()
                
                // Show result with appropriate haptic feedback
                await MainActor.run {
                    if success {
                        stateManager.showSuccessAndReset()
                        // Success haptic feedback
                        let notification = UINotificationFeedbackGenerator()
                        notification.notificationOccurred(.success)
                    } else {
                        stateManager.reset()
                        // Error haptic feedback
                        let notification = UINotificationFeedbackGenerator()
                        notification.notificationOccurred(.error)
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

// MARK: - Liquid Glass Tab Bar Enhancements
struct GlassTabViewModifier: ViewModifier {
    let selectedTab: Binding<Int>
    
    func body(content: Content) -> some View {
        content
            .onChange(of: selectedTab.wrappedValue) { _, newValue in
                // Haptic feedback on tab change
                let selection = UISelectionFeedbackGenerator()
                selection.selectionChanged()
            }
    }
}

extension View {
    func glassTabBar(selectedTab: Binding<Int>) -> some View {
        modifier(GlassTabViewModifier(selectedTab: selectedTab))
    }
}

// MARK: - View Extension for Interactive Glass Effects
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
    
    // Add glass effect with automatic interaction support
    func interactiveGlass(
        tint: Color? = nil,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
    }
}
