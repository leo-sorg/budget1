import SwiftUI
import SwiftData

struct SummaryView: View {
    @Query(sort: \Transaction.date, order: .reverse)
    private var txs: [Transaction]

    // Month/Year selection (defaults to current)
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int  = Calendar.current.component(.year,  from: Date())

    var body: some View {
        VStack(spacing: 0) {
            // Header using reusable component
            AppHeader(title: "SUMMARY")
            
            // Month navigation chips (right-aligned, newest first)
            VStack(alignment: .leading, spacing: 12) {
                Color.clear
                    .frame(height: 50)
                    .singleRowChipScrollRight {
                        ForEach(Array(monthsArray.enumerated()), id: \.offset) { index, monthData in
                            MonthChipView(
                                month: monthData.month,
                                year: monthData.year,
                                isSelected: selectedMonth == monthData.month && selectedYear == monthData.year,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedMonth = monthData.month
                                        selectedYear = monthData.year
                                    }
                                }
                            )
                            .environment(\.layoutDirection, .leftToRight) // Reset text direction inside chips
                        }
                    }
            }
            .padding() // Same padding as InputView and ManageView sections
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    // Totals Section with liquid glass
                    totalsSection
                    
                    // By Category Section with list component
                    byCategorySection
                    
                    // By Payment Method Section with list component
                    byPaymentSection
                    
                    // Extra padding at bottom for tab bar
                    Spacer()
                        .frame(height: 100)
                }
                .padding()
            }
            .background(Color.clear)
        }
    }
    
    // MARK: - Month navigation data
    
    private var monthsArray: [(month: Int, year: Int)] {
        var months: [(month: Int, year: Int)] = []
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Generate last 12 months
        for monthsAgo in 0..<12 {
            if let date = calendar.date(byAdding: .month, value: -monthsAgo, to: currentDate) {
                let month = calendar.component(.month, from: date)
                let year = calendar.component(.year, from: date)
                months.append((month: month, year: year))
            }
        }
        
        return months
    }
    
    // MARK: - Sections
    
    @ViewBuilder private var totalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Totals")
                .font(.headline)
                .foregroundColor(.appText)
            
            // Using the liquid glass GlassCard component
            GlassCard {
                VStack(spacing: 12) {
                    GlassCardRow(
                        label: "Income",
                        value: formatCurrency(totalIncome),
                        valueColor: .green
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    GlassCardRow(
                        label: "Expenses",
                        value: formatCurrency(totalExpenses),
                        valueColor: .red
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    GlassCardRow(
                        label: "Net",
                        value: formatCurrency(netTotal),
                        valueColor: netTotal >= 0 ? .green : .red,
                        isEmphasized: true
                    )
                }
            }
        }
    }
    
    @ViewBuilder private var byCategorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By category")
                .font(.headline)
                .foregroundColor(.appText)
            
            if byCategory.isEmpty {
                Text("No data for this month")
                    .foregroundColor(.appText.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 8) {
                    ForEach(byCategoryKeys, id: \.self) { key in
                        SummaryCategoryItem(
                            name: key,
                            amount: byCategory[key] ?? 0
                        )
                    }
                }
            }
        }
    }
    
    @ViewBuilder private var byPaymentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By payment method")
                .font(.headline)
                .foregroundColor(.appText)
            
            if byPayment.isEmpty {
                Text("No data for this month")
                    .foregroundColor(.appText.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 8) {
                    ForEach(byPaymentKeys, id: \.self) { key in
                        SummaryPaymentItem(
                            name: key,
                            amount: byPayment[key] ?? 0
                        )
                    }
                }
            }
        }
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
}

// MARK: - Month Chip Component with Glass Background
struct MonthChipView: View {
    let month: Int
    let year: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(monthYearString)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        // Using the public GlassChipBackground from ChipScrollStyles.swift
        .background(GlassChipBackground(isSelected: isSelected))
        .buttonStyle(PlainButtonStyle())
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        
        var components = DateComponents()
        components.month = month
        components.year = year
        components.day = 1
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(month)/\(year)"
    }
}

// MARK: - Summary List Item Components

struct SummaryCategoryItem: View {
    let name: String
    let amount: Decimal
    
    var body: some View {
        AppListItem(
            content: {
                Text(name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            },
            trailing: {
                Text(formatCurrency(amount))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(amount >= 0 ? .green : .white)
            }
        )
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "pt_BR")
        return f.string(for: NSDecimalNumber(decimal: value)) ?? "R$ 0,00"
    }
}

struct SummaryPaymentItem: View {
    let name: String
    let amount: Decimal
    
    var body: some View {
        AppListItem(
            content: {
                HStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                    Text(name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            },
            trailing: {
                Text(formatCurrency(amount))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(amount >= 0 ? .green : .white)
            }
        )
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "pt_BR")
        return f.string(for: NSDecimalNumber(decimal: value)) ?? "R$ 0,00"
    }
}
