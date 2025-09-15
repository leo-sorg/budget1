import SwiftUI
import SwiftData

// MARK: - Reusable Transaction List Item Component
struct TransactionListItem: View {
    let transaction: Transaction
    let onDelete: () -> Void
    
    var body: some View {
        AppListItem(
            content: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(transaction.category?.emoji ?? "💸")
                            .font(.system(size: 20))
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
            },
            onDelete: onDelete
        )
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
