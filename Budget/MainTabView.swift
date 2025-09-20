import SwiftUI

struct MainTabView: View {
    var body: some View {
        // Just show the InputView directly without any tab bar
        InputView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}