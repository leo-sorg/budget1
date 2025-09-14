import SwiftUI

// MARK: - Exact same glass background as chips
private struct GlassButtonBackground: View {
    let isPressed: Bool
    
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
    }
}

// MARK: - Updated App Button Style - IDENTICAL to chips
struct AppButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(GlassButtonBackground(isPressed: configuration.isPressed))
            .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Small Button Style - Same as main button but smaller
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
