import SwiftUI

struct AppButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        AppButton(configuration: configuration)
    }

    private struct AppButton: View {
        let configuration: Configuration

        var body: some View {
            configuration.label
                .fontWeight(.semibold)
                .foregroundColor(.appAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.appTabBar)
                )
                .opacity(configuration.isPressed ? 0.8 : 1.0)
        }
    }
}
