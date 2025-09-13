import SwiftUI

struct AppButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        AppButton(configuration: configuration)
    }

    private struct AppButton: View {
        @Environment(\.isEnabled) private var isEnabled
        let configuration: Configuration

        var body: some View {
            configuration.label
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(isEnabled ? Color.white : Color.appText.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    ZStack {
                        // Base glass layer
                        Capsule()
                            .fill(.thinMaterial)
                        
                        // White overlay for glow effect
                        Capsule()
                            .fill(Color.white.opacity(isEnabled ? 0.3 : 0.1))
                        
                        // Subtle border
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    }
                )
                .shadow(
                    color: Color.white.opacity(isEnabled ? 0.2 : 0.1),
                    radius: configuration.isPressed ? 4 : 8,
                    x: 0,
                    y: configuration.isPressed ? 2 : 4
                )
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .opacity(isEnabled ? (configuration.isPressed ? 0.9 : 1.0) : 0.5)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
}
