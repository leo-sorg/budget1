import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context

    // Fetch all transactions, newest first
    @Query(sort: \Transaction.date, order: .reverse)
    private var txs: [Transaction]

    var body: some View {
        NavigationStack {
            List {
                if txs.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No transactions yet")
                                .font(.headline)
                            Text("Add one in the Input tab. It will appear here.")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    // Monthly total section (current month)
                    Section("This month") {
                        HStack {
                            Text("Income")
                            Spacer()
                            Text(incomeThisMonth as NSNumber, formatter: currencyFormatter)
                        }
                        HStack {
                            Text("Expenses")
                            Spacer()
                            Text(expensesThisMonth as NSNumber, formatter: currencyFormatter)
                        }
                        HStack {
                            Text("Net")
                            Spacer()
                            Text(netThisMonth as NSNumber, formatter: currencyFormatter)
                                .fontWeight(.semibold)
                        }
                    }

                    // All transactions
                    Section("All transactions") {
                        ForEach(txs) { tx in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(tx.category?.emoji ?? "💸")
                                    Text(tx.category?.name ?? "Uncategorized")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(tx.amount as NSNumber, formatter: currencyFormatter)
                                }
                                .font(.body)

                                HStack(spacing: 8) {
                                    Text(dateFormatter.string(from: tx.date))
                                    if let pm = tx.paymentMethod?.name {
                                        Text("• \(pm)")
                                    }
                                    if let note = tx.note, !note.isEmpty {
                                        Text("• \(note)")
                                    }
                                }
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .listRowBackground(Color.appSecondaryBackground)
            .navigationTitle("History")
            .toolbar { EditButton() } // enables swipe-to-delete / Edit
        }
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .background(Color.appBackground)
        .foregroundColor(.appText)
        .tint(.appAccent)
    }

    // MARK: - Helpers

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(txs[index])
        }
        try? context.save()
    }

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

    // Currency & date formatters
    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        // If you want BRL explicitly, uncomment:
        // f.locale = Locale(identifier: "pt_BR")
        return f
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }
}
