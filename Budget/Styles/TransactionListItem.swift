import SwiftUI
import SwiftData

// MARK: - Reusable Transaction List Item Component (UPDATED)
struct TransactionListItem: View {
    let transaction: Transaction
    
    var body: some View {
        AppListItem(
            content: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        // UPDATED: Use fallback icons based on transaction amount if no category emoji
                        categoryIconView
                        
                        Text(transaction.category?.name ?? "Uncategorized")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 8) {
                        Text(dateFormatter.string(from: transaction.date))
                            .foregroundColor(Color.appText.opacity(0.6))
                            .font(.caption)
                        
                        if let pm = transaction.paymentMethod?.name {
                            Text("• \(pm)")
                                .foregroundColor(Color.appText.opacity(0.6))
                                .font(.caption)
                        }
                        
                        if let note = transaction.note, !note.isEmpty {
                            Text("• \(note)")
                                .foregroundColor(Color.appText.opacity(0.6))
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
            },
            trailing: {
                Text(transaction.amount as NSNumber, formatter: currencyFormatter)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(transaction.amount >= 0 ? Color(red: 0.5, green: 1.0, blue: 0.5) : .white)  // Light green for income, white for expenses
            }
        )
    }
    
    // UPDATED: Category icon view with fallback icons for local transactions
    @ViewBuilder private var categoryIconView: some View {
        if let categoryEmoji = transaction.category?.emoji, !categoryEmoji.isEmpty, isValidEmoji(categoryEmoji) {
            // Use the category emoji if available
            Text(categoryEmoji)
                .font(.system(size: 20))
        } else {
            // Fallback for uncategorized/empty emoji: colored icons based on amount
            if transaction.amount >= 0 {
                // Income: light green plus
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.5, green: 1.0, blue: 0.5)) // Light green
            } else {
                // Expense: light red minus
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.5)) // Light red
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }
    
    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        return f
    }
}

// MARK: - Helper function for emoji validation
private func isValidEmoji(_ s: String) -> Bool {
    guard !s.isEmpty else { return false }
    let chars = Array(s)
    if chars.count != 1 { return false }
    if let scalar = s.unicodeScalars.first {
        if CharacterSet.alphanumerics.contains(scalar) { return false }
        if CharacterSet.punctuationCharacters.contains(scalar) { return false }
        if CharacterSet.whitespacesAndNewlines.contains(scalar) { return false }
    }
    return true
}
