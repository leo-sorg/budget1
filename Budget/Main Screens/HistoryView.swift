import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context

    // Fetch all transactions, newest first
    @Query(sort: \Transaction.date, order: .reverse)
    private var txs: [Transaction]

    var body: some View {
        VStack(spacing: 0) {
            // Header using reusable component
            AppHeader(title: "HISTORY")
            
            if txs.isEmpty {
                // Show empty state
                VStack(alignment: .leading, spacing: 8) {
                    Text("No transactions yet")
                        .font(.headline)
                        .foregroundColor(.appText)
                    Text("Add one in the Input tab. It will appear here.")
                        .foregroundColor(Color.appText.opacity(0.6))
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(Color.clear)
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Monthly total section with liquid glass style
                        monthlyTotalSection
                        
                        // All transactions section using the list component
                        transactionsSection
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
    }

    // MARK: - Sections
    
    @ViewBuilder private var monthlyTotalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This month")
                .font(.headline)
                .foregroundColor(.appText)
            
            // Using the new GlassCard component with liquid glass style
            GlassCard {
                VStack(spacing: 12) {
                    GlassCardRow(
                        label: "Income",
                        value: formatCurrency(incomeThisMonth),
                        valueColor: .green
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    GlassCardRow(
                        label: "Expenses",
                        value: formatCurrency(expensesThisMonth),
                        valueColor: .red
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    GlassCardRow(
                        label: "Net",
                        value: formatCurrency(netThisMonth),
                        valueColor: netThisMonth >= 0 ? .green : .red,
                        isEmphasized: true
                    )
                }
            }
        }
    }
    
    @ViewBuilder private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All transactions")
                .font(.headline)
                .foregroundColor(.appText)
            
            if txs.isEmpty {
                Text("No transactions yet")
                    .foregroundColor(.appText.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 8) {
                    ForEach(txs) { tx in
                        TransactionListItem(
                            transaction: tx,
                            onDelete: {
                                context.delete(tx)
                                try? context.save()
                            }
                        )
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var thisMonthTransactions: [Transaction] {
        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: Date())) ?? Date()
        let startNext = cal.date(byAdding: .month, value: 1, to: startOfMonth) ?? Date()
        return txs.filter { $0.date >= startOfMonth && $0.date < startNext }
    }

    private var incomeThisMonth: Decimal {
        thisMonthTransactions.reduce(0) { $0 + max($1.amount, 0) }
    }

    private var expensesThisMonth: Decimal {
        thisMonthTransactions.reduce(0) { $0 + min($1.amount, 0) }
    }

    private var netThisMonth: Decimal { incomeThisMonth + expensesThisMonth }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        return f.string(for: NSDecimalNumber(decimal: value)) ?? "$0.00"
    }
}

// MARK: - Transaction List Item Component
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(transaction.amount >= 0 ? .green : .white)
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
