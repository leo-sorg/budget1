import SwiftUI
import SwiftData

struct HistoryView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header using reusable component
            AppHeader(title: "HISTORY")
            
            // Work in Progress content
            VStack(spacing: 20) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("Work in Progress")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("This feature is under development")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
        }
    }
}
