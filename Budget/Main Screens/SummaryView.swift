import SwiftUI
import SwiftData

struct SummaryView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var bgStore: BackgroundImageStore

    // Month/Year selection (defaults to current)
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int  = Calendar.current.component(.year,  from: Date())
    
    // API state management
    @State private var apiTransactions: [APITransaction] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    // Segmented control state
    @State private var selectedSegment = 0 // 0: History, 1: By Category, 2: By Payment
    @Namespace private var segmentedControlNamespace
    
    // Namespace for month chip morphing
    @Namespace private var monthChipNamespace
    
    // Set this to false to use real API, true to use mock data
    private let useMockData = false

    var body: some View {
        VStack(spacing: 0) {
            // Header using reusable component
            AppHeader(title: "RADIO")
            
            // Month navigation chips (right-aligned, newest first)
            VStack(alignment: .leading, spacing: 12) {
                Color.clear
                    .frame(height: 50)
                    .singleRowChipScrollRight {
                        ForEach(Array(monthsArray.enumerated()), id: \.element.month) { index, monthData in
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
                                },
                                namespace: monthChipNamespace
                            )
                            .environment(\.layoutDirection, LayoutDirection.leftToRight) // Reset text direction inside chips
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
                        
                        // Segmented Control
                        segmentedControlSection
                        
                        // Content based on selected segment
                        selectedContentSection
                    }
                    
                    // Extra padding at bottom for tab bar
                    Spacer()
                        .frame(height: 100)
                }
                .padding()
            }
            .refreshable {
                await refreshData()
            }
        }
        .background {
            AppAppearance.shared.appBackgroundColor
                .ignoresSafeArea(.all)
        }
        .onAppear {
            // Fetch transactions for current month when screen appears
            fetchTransactionsForSelectedMonth()
        }
    }
    
    // MARK: - Segmented Control Section
    @ViewBuilder private var segmentedControlSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Segmented Control with inverted glass effect
            HStack(spacing: 0) {
                // History Segment
                Button("History") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedSegment = 0
                    }
                }
                .font(.system(size: 16, weight: selectedSegment == 0 ? .medium : .light))
                .foregroundStyle(selectedSegment == 0 ? .white : Color(white: 0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    if selectedSegment == 0 {
                        RoundedRectangle(cornerRadius: 22)
                            .glassEffect(.regular)
                            .matchedGeometryEffect(id: "selectedSegment", in: segmentedControlNamespace)
                    }
                }
                
                // By Category Segment
                Button("By Category") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedSegment = 1
                    }
                }
                .font(.system(size: 16, weight: selectedSegment == 1 ? .medium : .light))
                .foregroundStyle(selectedSegment == 1 ? .white : Color(white: 0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    if selectedSegment == 1 {
                        RoundedRectangle(cornerRadius: 22)
                            .glassEffect(.regular)
                            .matchedGeometryEffect(id: "selectedSegment", in: segmentedControlNamespace)
                    }
                }
                
                // By Payment Segment
                Button("By Payment") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedSegment = 2
                    }
                }
                .font(.system(size: 16, weight: selectedSegment == 2 ? .medium : .light))
                .foregroundStyle(selectedSegment == 2 ? .white : Color(white: 0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    if selectedSegment == 2 {
                        RoundedRectangle(cornerRadius: 22)
                            .glassEffect(.regular)
                            .matchedGeometryEffect(id: "selectedSegment", in: segmentedControlNamespace)
                    }
                }
            }
            .padding(4)
            .background {
                RoundedRectangle(cornerRadius: 22)
                    .glassEffect(.clear, in: .rect(cornerRadius: 22))
            }
        }
    }
    
    // MARK: - Selected Content Section
    @ViewBuilder private var selectedContentSection: some View {
        switch selectedSegment {
        case 0:
            allTransactionsSection
        case 1:
            byCategorySection
        case 2:
            byPaymentSection
        default:
            allTransactionsSection
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
                            } else {
                                self.errorMessage = apiResponse.message
                            }
                            
                        case .failure(let error):
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
                        // Use the data in the exact order returned by the API
                        // The API should be returning them in the correct order already
                        self.apiTransactions = apiResponse.data
                        self.errorMessage = nil
                    } else {
                        self.errorMessage = apiResponse.message
                    }
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Mock Data Generator (UPDATED with categoryEmoji)
    private func getMockTransactionsForMonth() -> [APITransaction] {
        let (startDate, _) = selectedDateRange
        let calendar = Calendar.current
        
        // Categories for expenses and income with emojis
        let expenseCategories = [
            ("Food", "🍽️"), ("Transport", "🚕"), ("Shopping", "🛍️"),
            ("Bills", "💡"), ("Leisure", "🎬"), ("Healthcare", "🏥"),
            ("Groceries", "🛒"), ("Coffee", "☕"), ("Rent", "🏠"), ("Gym", "💪")
        ]
        let incomeCategories = [
            ("Salary", "💼"), ("Freelance", "💻"), ("Bonus", "🎁"),
            ("Gifts", "🎊"), ("Investments", "📈")
        ]
        
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
            
            let categoryData: (String, String)
            let merchantName: String
            let amount: Double
            let transactionType: String
            let note: String
            
            if isIncome {
                categoryData = incomeCategories.randomElement()!
                merchantName = ["Company ABC", "Freelance Client", "Investment Return", "Gift from Family", "Bonus Payment"].randomElement()!
                amount = Double.random(in: 500...5000)
                transactionType = "income"
                note = ["Monthly salary", "Project payment", "Bonus", "Gift", "Investment return", ""].randomElement()!
            } else {
                categoryData = expenseCategories.randomElement()!
                
                switch categoryData.0 {
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
            
            // Create transaction with categoryEmoji
            let transaction = APITransaction(
                remoteID: "mock-\(selectedMonth)-\(selectedYear)-\(i)",
                amount: amount,
                categoryName: categoryData.0,
                categoryEmoji: categoryData.1, // NEW: Include emoji in mock data
                paymentMethod: paymentMethods.randomElement()!,
                merchantName: merchantName,
                note: note,
                dateISO: formatDateForAPI(transactionDate),
                transactionType: transactionType
            )
            
            transactions.append(transaction)
        }
        
        // Add a few uncategorized transactions to test fallback icons
        for i in transactionCount..<(transactionCount + 2) {
            let dayRange = calendar.range(of: .day, in: .month, for: startDate)!
            let randomDay = Int.random(in: 1...dayRange.count)
            
            var dateComponents = calendar.dateComponents([.year, .month], from: startDate)
            dateComponents.day = randomDay
            let transactionDate = calendar.date(from: dateComponents) ?? startDate
            
            let uncategorizedTransaction = APITransaction(
                remoteID: "mock-uncategorized-\(i)",
                amount: -Double.random(in: 10...50),
                categoryName: "", // Empty category name
                categoryEmoji: "", // Empty category emoji
                paymentMethod: paymentMethods.randomElement()!,
                merchantName: "Unknown Store",
                note: "Uncategorized expense",
                dateISO: formatDateForAPI(transactionDate),
                transactionType: "expense"
            )
            
            transactions.append(uncategorizedTransaction)
        }
        
        return transactions
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
            let amount = Decimal(transaction.amount)
            return result + max(amount, 0)
        }
    }

    private var totalExpenses: Decimal {
        apiTransactions.reduce(0) { result, transaction in
            let amount = Decimal(transaction.amount)
            return result + min(amount, 0)
        }
    }

    private var netTotal: Decimal { totalIncome + totalExpenses }

    private var byCategory: [String: Decimal] {
        var dict: [String: Decimal] = [:]
        for transaction in apiTransactions {
            let name = transaction.categoryName.isEmpty ? "Uncategorized" : transaction.categoryName
            let amount = Decimal(transaction.amount)
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
            let amount = Decimal(transaction.amount)
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

// MARK: - UPDATED API Transaction List Item with categoryEmoji support

struct APITransactionListItem: View {
    let transaction: APITransaction
    
    var body: some View {
        AppListItem(
            content: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        // UPDATED: Use categoryEmoji if available, fallback to colored minus icons
                        categoryIconView
                        
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
    
    // UPDATED: Category icon view with emoji support and fallback icons
    @ViewBuilder private var categoryIconView: some View {
        if !transaction.categoryEmoji.isEmpty && isValidEmoji(transaction.categoryEmoji) {
            // Use the category emoji from the API
            Text(transaction.categoryEmoji)
                .font(.system(size: 20))
        } else {
            // Fallback for uncategorized/empty emoji: colored minus icon
            if transaction.amount >= 0 {
                // Income: light green plus or up arrow
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
    
    private func formatDisplayDate(_ dateString: String) -> String {
        // Output formatter for DD/MM format
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd/MM"
        
        // Use ISO8601DateFormatter which handles various ISO formats automatically
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try with fractional seconds first
        if let date = isoFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        
        // Try without fractional seconds (for format like "2025-09-17T00:30:41-03:00")
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        
        // Try simple date format: "2025-08-16"
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd"
        if let date = simpleFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        
        // If nothing works, try to extract just the date part
        if dateString.count >= 10 {
            let datePart = String(dateString.prefix(10))
            if let date = simpleFormatter.date(from: datePart) {
                return outputFormatter.string(from: date)
            }
        }
        
        // If all else fails, return the original string
        return dateString
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "pt_BR")
        return f.string(for: NSDecimalNumber(decimal: value)) ?? "R$ 0,00"
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
