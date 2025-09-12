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
                .fontWeight(.semibold)
                .foregroundColor(.appAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.appTabBar)
                .cornerRadius(8)
                .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1.0) : 0.5)
        }
    }
}
