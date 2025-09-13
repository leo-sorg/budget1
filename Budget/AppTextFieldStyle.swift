import SwiftUI

extension View {
    func appTextField() -> some View {
        self
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appTabBar)
            )
    }
}
