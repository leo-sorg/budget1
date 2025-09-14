import SwiftUI

// MARK: - App Header Component
struct AppHeader: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Top spacing - matches InputView date spacing
            Spacer()
                .frame(height: 40)
            
            // Header content
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.appText)
            }
            .padding(.horizontal, 16)
            
            // Bottom spacing - matches InputView date spacing
            Spacer()
                .frame(height: 40)
        }
    }
}

// MARK: - Convenience Extension
extension View {
    func appHeader(_ title: String) -> some View {
        VStack(spacing: 0) {
            AppHeader(title: title)
            self
        }
    }
}
