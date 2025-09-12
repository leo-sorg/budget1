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
                .padding(.vertical, 12)
                .background(Color.appTabBar)
                .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1.0) : 0.5)
        }
    }
}
