import SwiftUI

// MARK: - App Header Component
struct AppHeader: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 0) {
            // Top spacing - reduced for smaller header
            Spacer()
                .frame(height: 30)
            
            // Header content
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appText)
            }
            .padding(.horizontal, 16)
            
            // Bottom spacing - reduced for smaller header
            Spacer()
                .frame(height: 20)
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
