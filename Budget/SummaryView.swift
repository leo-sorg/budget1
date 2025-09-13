import SwiftUI
import SwiftData

struct SummaryView: View {
    @Query(sort: \Transaction.date, order: .reverse)
    private var txs: [Transaction]

    // Month/Year selection (defaults to current)
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int  = Calendar.current.component(.year,  from: Date())

    // Generate a small year range (adjust as you like)
    private var years: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 5)...(current + 1))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Period Section
                SectionContainer("Period") {
                    VStack(spacing: 12) {
                        Picker("Month", selection: $selectedMonth) {
                            ForEach(1...12, id: \.self) { m in
                                Text(shortMonthName(m)).tag(m)
                            }
                        }
                        .appPickerStyle()
                        
                        Picker("Year", selection: $selectedYear) {
                            ForEach(years, id: \.self) { y in
                                Text(String(y)).tag(y)
                            }
                        }
                        .appPickerStyle()
                    }
                }
                
                // Totals Section
                SectionContainer("Totals") {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Income")
                            Spacer()
                            Text(formatCurrency(totalIncome))
                        }
                        HStack {
                            Text("Expenses")
                            Spacer()
                            Text(formatCurrency(totalExpenses))
                        }
                        HStack {
                            Text("Net")
                            Spacer()
                            Text(formatCurrency(netTotal))
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.appText)
                }
                
                // By Category Section
                SectionContainer("By category") {
                    if byCategory.isEmpty {
                        Text("No data for this month")
                            .foregroundColor(.appText.opacity(0.6))
                    } else {
                        VStack(spacing: 8) {
                            ForEach(byCategoryKeys, id: \.self) { key in
                                HStack {
                                    Text(key)
                                    Spacer()
                                    Text(formatCurrency(byCategory[key] ?? 0))
                                }
                                .foregroundColor(.appText)
                            }
                        }
                    }
                }
                
                // By Payment Method Section
                SectionContainer("By payment method") {
                    if byPayment.isEmpty {
                        Text("No data for this month")
                            .foregroundColor(.appText.opacity(0.6))
                    } else {
                        VStack(spacing: 8) {
                            ForEach(byPaymentKeys, id: \.self) { key in
                                HStack {
                                    Text(key)
                                    Spacer()
                                    Text(formatCurrency(byPayment[key] ?? 0))
                                }
                                .foregroundColor(.appText)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    // MARK: - Filtering for selected month/year

    private var selectedRange: (start: Date, end: Date) {
        var comps = DateComponents()
        comps.year = selectedYear
        comps.month = selectedMonth
        comps.day = 1
        let cal = Calendar.current
        let start = cal.date(from: comps) ?? Date()
        let end = cal.date(byAdding: .month, value: 1, to: start) ?? start
        return (start, end)
    }

    private var filteredTxs: [Transaction] {
        let (start, end) = selectedRange
        return txs.filter { $0.date >= start && $0.date < end }
    }

    private var totalIncome: Decimal {
        filteredTxs.reduce(0) { $0 + max($1.amount, 0) }
    }

    private var totalExpenses: Decimal {
        filteredTxs.reduce(0) { $0 + min($1.amount, 0) }
    }

    private var netTotal: Decimal { totalIncome + totalExpenses }

    private var byCategory: [String: Decimal] {
        var dict: [String: Decimal] = [:]
        for tx in filteredTxs {
            let name = tx.category?.name ?? "Uncategorized"
            dict[name, default: 0] += tx.amount
        }
        // Sort high → low
        return dict.sorted { $0.value > $1.value }
            .reduce(into: [:]) { $0[$1.key] = $1.value }
    }
    private var byCategoryKeys: [String] { Array(byCategory.keys) }

    private var byPayment: [String: Decimal] {
        var dict: [String: Decimal] = [:]
        for tx in filteredTxs {
            let name = tx.paymentMethod?.name ?? "—"
            dict[name, default: 0] += tx.amount
        }
        return dict.sorted { $0.value > $1.value }
            .reduce(into: [:]) { $0[$1.key] = $1.value }
    }
    private var byPaymentKeys: [String] { Array(byPayment.keys) }

    // MARK: - Formatting helpers

    private func formatCurrency(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "pt_BR")
        return f.string(for: NSDecimalNumber(decimal: value)) ?? "R$ 0,00"
    }

    /// Short month name in the current locale (e.g., "Sep", "set.")
    /// Uses a real Date so we avoid optional arrays like shortMonthSymbols.
    private func shortMonthName(_ m: Int) -> String {
        guard (1...12).contains(m) else { return "Month" }
        var comps = DateComponents()
        comps.year = 2000
        comps.month = m
        comps.day = 1
        let cal = Calendar.current
        let date = cal.date(from: comps) ?? Date()

        let df = DateFormatter()
        df.locale = Locale.current
        df.setLocalizedDateFormatFromTemplate("MMM") // short month name
        return df.string(from: date).capitalized
    }
}
