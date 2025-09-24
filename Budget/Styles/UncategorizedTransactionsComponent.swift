import SwiftUI

// MARK: - Uncategorized Transactions Component
struct UncategorizedTransactionsComponent: View {
    let count: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.orange)
            
            // Message text
            VStack(alignment: .leading, spacing: 2) {
                Text(countText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Needs categorization")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Chevron to indicate it might be interactive in the future
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(.regular.tint(Color.white.opacity(0.0)).interactive(), in: .rect(cornerRadius: 16))
    }
    
    private var countText: String {
        if count == 1 {
            return "1 uncategorized transaction"
        } else {
            return "\(count) uncategorized transactions"
        }
    }
}
