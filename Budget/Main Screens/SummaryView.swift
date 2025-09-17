import SwiftUI
import SwiftData

struct SummaryView: View {
    @Environment(\.modelContext) private var context

    // Month/Year selection (defaults to current)
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int  = Calendar.current.component(.year,  from: Date())
    
    // API state management
    @State private var apiTransactions: [APITransaction] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Set this to false to use real API, true to use mock data
    private let useMockData = false

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
                                        // Fetch transactions for the new month
                                        fetchTransactionsForSelectedMonth()
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
                    if isLoading {
                        // Loading state
                        loadingView
                    } else if let errorMessage = errorMessage {
                        // Error state
                        errorView(message: errorMessage)
                    } else {
                        // Success state - show data
                        // Totals Section with liquid glass
                        totalsSection
                        
                        // By Category Section with list component
                        byCategorySection
                        
                        // By Payment Method Section with list component
                        byPaymentSection
                        
                        // All Transactions Section
                        allTransactionsSection
                    }
                    
                    // Extra padding at bottom for tab bar
                    Spacer()
                        .frame(height: 100)
                }
                .padding()
            }
            .background(Color.clear)
            .refreshable {
                await refreshData()
            }
        }
        .onAppear {
            // Fetch transactions for current month when screen appears
            fetchTransactionsForSelectedMonth()
        }
    }
    
    // MARK: - Loading View
    @ViewBuilder private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading transactions...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - Error View
    @ViewBuilder private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Couldn't get transactions")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                fetchTransactionsForSelectedMonth()
            }
            .buttonStyle(AppSmallButtonStyle())
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - API Fetch Function
    private func fetchTransactionsForSelectedMonth() {
        isLoading = true
        errorMessage = nil
        
        if useMockData {
            // Mock API delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isLoading = false
                self.apiTransactions = self.getMockTransactionsForMonth()
                self.errorMessage = nil
            }
        } else {
            fetchRealAPITransactions()
        }
    }
    
    // MARK: - Pull to Refresh
    @MainActor
    private func refreshData() async {
        // Don't show loading indicator during refresh (pull indicator is enough)
        errorMessage = nil
        
        if useMockData {
            // Simulate network delay for mock data
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            self.apiTransactions = self.getMockTransactionsForMonth()
            self.errorMessage = nil
        } else {
            await withCheckedContinuation { continuation in
                let (startDate, endDate) = selectedDateRange
                
                SHEETS.getTransactions(startDate: startDate, endDate: endDate, limit: 300) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let apiResponse):
                            if apiResponse.success {
                                self.apiTransactions = apiResponse.data
                                self.errorMessage = nil
                                print("✅ Refreshed \(self.apiTransactions.count) transactions")
                            } else {
                                self.errorMessage = apiResponse.message
                                print("❌ Refresh Error: \(apiResponse.message)")
                            }
                            
                        case .failure(let error):
                            print("❌ Refresh Error: \(error)")
                            self.errorMessage = error.localizedDescription
                        }
                        
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    // MARK: - Real API Call using SheetsClient
    private func fetchRealAPITransactions() {
        let (startDate, endDate) = selectedDateRange
        
        SHEETS.getTransactions(startDate: startDate, endDate: endDate, limit: 300) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let apiResponse):
                    if apiResponse.success {
                        // Just use the data as-is from the API - it's already filtered by date
                        self.apiTransactions = apiResponse.data
                        self.errorMessage = nil
                        print("✅ Successfully loaded \(self.apiTransactions.count) transactions for \(self.selectedMonth)/\(self.selectedYear)")
                    } else {
                        self.errorMessage = apiResponse.message
                        print("❌ API Error: \(apiResponse.message)")
                    }
                    
                case .failure(let error):
                    print("❌ Error: \(error)")
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Mock Data Generator
    private func getMockTransactionsForMonth() -> [APITransaction] {
        let (startDate, endDate) = selectedDateRange
        let calendar = Calendar.current
        
        // Categories for expenses and income
        let expenseCategories = ["Food", "Transport", "Shopping", "Bills", "Leisure", "Healthcare", "Groceries", "Coffee", "Rent", "Gym"]
        let incomeCategories = ["Salary", "Freelance", "Bonus", "Gifts", "Investments"]
        
        // Payment methods
        let paymentMethods = ["Credit Card", "Debit Card", "Pix", "Cash", "Bank Transfer"]
        
        // Merchants
        let foodMerchants = ["McDonald's", "Burger King", "Pizza Hut", "Subway", "Local Restaurant", "Café Central", "Padaria do Bairro"]
        let shoppingMerchants = ["Amazon", "Magazine Luiza", "Americanas", "Casas Bahia", "Zara", "C&A", "Shopping Center"]
        let transportMerchants = ["Uber", "99", "Posto Shell", "Posto Ipiranga", "Estacionamento", "Metrô"]
        let billMerchants = ["Enel", "Sabesp", "Vivo", "NET", "Nubank", "Banco do Brasil"]
        
        var transactions: [APITransaction] = []
        
        // Generate 15-20 transactions for the selected month
        let transactionCount = Int.random(in: 15...20)
        
        for i in 0..<transactionCount {
            let isIncome = Double.random(in: 0...1) < 0.15 // 15% chance of income
            
            let category: String
            let merchantName: String
            let amount: Double
            let transactionType: String
            let note: String
            
            if isIncome {
                category = incomeCategories.randomElement()!
                merchantName = ["Company ABC", "Freelance Client", "Investment Return", "Gift from Family", "Bonus Payment"].randomElement()!
                amount = Double.random(in: 500...5000)
                transactionType = "income"
                note = ["Monthly salary", "Project payment", "Bonus", "Gift", "Investment return", ""].randomElement()!
            } else {
                category = expenseCategories.randomElement()!
                
                switch category {
                case "Food", "Coffee":
                    merchantName = foodMerchants.randomElement()!
                    amount = -Double.random(in: 8...80)
                case "Transport":
                    merchantName = transportMerchants.randomElement()!
                    amount = -Double.random(in: 5...50)
                case "Shopping", "Groceries":
                    merchantName = shoppingMerchants.randomElement()!
                    amount = -Double.random(in: 20...300)
                case "Bills":
                    merchantName = billMerchants.randomElement()!
                    amount = -Double.random(in: 50...400)
                case "Rent":
                    merchantName = "Imobiliária Silva"
                    amount = -Double.random(in: 800...2000)
                case "Healthcare":
                    merchantName = "Hospital São Lucas"
                    amount = -Double.random(in: 30...200)
                case "Leisure":
                    merchantName = ["Cinema", "Netflix", "Spotify", "Game Store", "Livraria"].randomElement()!
                    amount = -Double.random(in: 15...100)
                case "Gym":
                    merchantName = "Smart Fit"
                    amount = -Double.random(in: 50...150)
                default:
                    merchantName = "Various Store"
                    amount = -Double.random(in: 10...100)
                }
                
                transactionType = "expense"
                note = ["", "Monthly payment", "Emergency", "Planned purchase", "Unexpected expense"].randomElement()!
            }
            
            // Generate random date within the month
            let dayRange = calendar.range(of: .day, in: .month, for: startDate)!
            let randomDay = Int.random(in: 1...dayRange.count)
            
            var dateComponents = calendar.dateComponents([.year, .month], from: startDate)
            dateComponents.day = randomDay
            let transactionDate = calendar.date(from: dateComponents) ?? startDate
            
            // Create transaction using struct literal
            let transaction = APITransaction(
                remoteID: "mock-\(selectedMonth)-\(selectedYear)-\(i)",
                amount: amount,
                categoryName: category,
                paymentMethod: paymentMethods.randomElement()!,
                merchantName: merchantName,
                note: note,
                dateISO: formatDateForAPI(transactionDate),
                transactionType: transactionType
            )
            
            transactions.append(transaction)
        }
        
        // Sort by date descending (most recent first)
        return transactions.sorted { $0.dateISO > $1.dateISO }
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
    
    // MARK: - Date Range Helper
    
    private var selectedDateRange: (start: Date, end: Date) {
        var comps = DateComponents()
        comps.year = selectedYear
        comps.month = selectedMonth
        comps.day = 1
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        
        let cal = Calendar.current
        let start = cal.date(from: comps) ?? Date()
        
        // Calculate the last day of the month
        var endComps = DateComponents()
        endComps.year = selectedYear
        endComps.month = selectedMonth + 1
        endComps.day = 1
        endComps.hour = 0
        endComps.minute = 0
        endComps.second = 0
        
        // Get first day of next month, then subtract 1 day
        if let firstOfNextMonth = cal.date(from: endComps) {
            let end = cal.date(byAdding: .day, value: -1, to: firstOfNextMonth) ?? start
            return (start, end)
        }
        
        // Fallback: add 1 month to start date then subtract 1 day
        let endOfMonth = cal.date(byAdding: .month, value: 1, to: start)!
        let end = cal.date(byAdding: .day, value: -1, to: endOfMonth)!
        return (start, end)
    }
    
    private func formatDateForAPI(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
    
    // MARK: - Computed Properties (now using API data)
    
    private var totalIncome: Decimal {
        apiTransactions.reduce(0) { result, transaction in
            let amount = Decimal(transaction.amount) ?? 0
            return result + max(amount, 0)
        }
    }

    private var totalExpenses: Decimal {
        apiTransactions.reduce(0) { result, transaction in
            let amount = Decimal(transaction.amount) ?? 0
            return result + min(amount, 0)
        }
    }

    private var netTotal: Decimal { totalIncome + totalExpenses }

    private var byCategory: [String: Decimal] {
        var dict: [String: Decimal] = [:]
        for transaction in apiTransactions {
            let name = transaction.categoryName.isEmpty ? "Uncategorized" : transaction.categoryName
            let amount = Decimal(transaction.amount) ?? 0
            dict[name, default: 0] += amount
        }
        // Sort high → low
        return dict.sorted { $0.value > $1.value }
            .reduce(into: [:]) { $0[$1.key] = $1.value }
    }
    private var byCategoryKeys: [String] { Array(byCategory.keys) }

    private var byPayment: [String: Decimal] {
        var dict: [String: Decimal] = [:]
        for transaction in apiTransactions {
            let name = transaction.paymentMethod.isEmpty ? "—" : transaction.paymentMethod
            let amount = Decimal(transaction.amount) ?? 0
            dict[name, default: 0] += amount
        }
        return dict.sorted { $0.value > $1.value }
            .reduce(into: [:]) { $0[$1.key] = $1.value }
    }
    private var byPaymentKeys: [String] { Array(byPayment.keys) }
    
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
                        valueColor: Color(red: 0.5, green: 1.0, blue: 0.5)  // Light green
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    GlassCardRow(
                        label: "Expenses",
                        value: formatCurrency(totalExpenses),
                        valueColor: Color(red: 1.0, green: 0.5, blue: 0.5)  // Light red
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    GlassCardRow(
                        label: "Net",
                        value: formatCurrency(netTotal),
                        valueColor: netTotal >= 0 ? Color(red: 0.5, green: 1.0, blue: 0.5) : Color(red: 1.0, green: 0.5, blue: 0.5),  // Light green or light red
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
    
    @ViewBuilder private var allTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All transactions")
                .font(.headline)
                .foregroundColor(.appText)
            
            if apiTransactions.isEmpty {
                Text("No transactions for this month")
                    .foregroundColor(.appText.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 8) {
                    // Use array index as id instead of remoteID to handle duplicates
                    ForEach(Array(apiTransactions.enumerated()), id: \.offset) { index, transaction in
                        APITransactionListItem(transaction: transaction)
                    }
                }
            }
        }
    }

    // MARK: - Formatting helpers

    private func formatCurrency(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "pt_BR")
        return f.string(for: NSDecimalNumber(decimal: value)) ?? "R$ 0,00"
    }
}

// MARK: - API Transaction List Item

struct APITransactionListItem: View {
    let transaction: APITransaction
    
    var body: some View {
        AppListItem(
            content: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        // Use amount to determine transaction type: positive = income, negative = expense
                        Text(transaction.amount >= 0 ? "💰" : "💸")
                            .font(.system(size: 20))
                        Text(transaction.categoryName.isEmpty ? "Uncategorized" : transaction.categoryName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 8) {
                        Text(formatDisplayDate(transaction.dateISO))
                            .foregroundColor(Color.appText.opacity(0.6))
                            .font(.caption)
                        
                        if !transaction.paymentMethod.isEmpty {
                            Text("• \(transaction.paymentMethod)")
                                .foregroundColor(Color.appText.opacity(0.6))
                                .font(.caption)
                        }
                        
                        if !transaction.merchantName.isEmpty {
                            Text("• \(transaction.merchantName)")
                                .foregroundColor(Color.appText.opacity(0.6))
                                .font(.caption)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                }
            },
            trailing: {
                Text(formatCurrency(Decimal(transaction.amount)))
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(transaction.amount >= 0 ? Color(red: 0.5, green: 1.0, blue: 0.5) : .white)  // Light green for income, white for expenses
            }
        )
    }
    
    private func formatDisplayDate(_ dateString: String) -> String {
        // Handle ISO date format: "2025-08-16T03:00:00.000Z"
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        isoFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        // Also try simple date format: "2025-08-16"
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd"
        
        // Output formatter for DD/MM format
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd/MM"
        
        // Try ISO format first
        if let date = isoFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        // Fall back to simple format
        else if let date = simpleFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        
        // If neither works, return the original string
        return dateString
    }
    
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
                    .foregroundColor(amount >= 0 ? Color(red: 0.5, green: 1.0, blue: 0.5) : .white)  // Light green for positive
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
                    .foregroundColor(amount >= 0 ? Color(red: 0.5, green: 1.0, blue: 0.5) : .white)  // Light green for positive
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
