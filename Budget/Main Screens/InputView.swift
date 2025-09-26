import SwiftUI
import SwiftData

// MARK: - Main InputView with Card Stack
@MainActor
struct InputView: View {
    @Environment(\.modelContext) private var ctx
    @EnvironmentObject private var bgStore: BackgroundImageStore
    
    // UPDATED: Use @State for API data instead of @Query for local data
    @State private var apiCategories: [APICategory] = []
    @State private var apiPaymentMethods: [APIPaymentMethod] = []
    
    // UPDATED: Changed from banner to full card stack implementation
    @State private var uncategorizedTransactions: [APITransaction] = []
    
    // API loading states - UPDATED: Added uncategorized loading state
    @State private var isLoadingCategories = false
    @State private var isLoadingPaymentMethods = false
    @State private var isLoadingUncategorized = false // NEW: Track uncategorized loading
    @State private var categoriesError: String?
    @State private var paymentMethodsError: String?
    @State private var isFirstLoad = true
    
    // Form state
    @State private var amountText = ""
    @State private var date = Date()
    @State private var selectedCategoryID: String?
    @State private var selectedMethodID: String?
    @State private var descriptionText = ""
    @State private var showDatePicker = false
    @State private var showSavedToast = false
    @State private var alertMessage: String?
    
    // Focus state for auto-scroll
    @StateObject private var keyboardScroll = KeyboardScrollCoordinator()
    
    // Namespaces for morphing effects
    @Namespace private var paymentChipNamespace
    @Namespace private var categoryChipNamespace

    // Set this to false to use real API, true to use mock data
    private let useMockData = false

    // Computed properties to get selected models from API data
    private var selectedCategory: APICategory? {
        guard let id = selectedCategoryID else { return nil }
        return apiCategories.first { $0.remoteID == id }
    }
    
    private var selectedMethod: APIPaymentMethod? {
        guard let id = selectedMethodID else { return nil }
        return apiPaymentMethods.first { $0.remoteID == id }
    }

    // MARK: - SIMPLIFIED: Show Logic for Uncategorized Stack
    private var shouldShowUncategorizedStack: Bool {
        // Simply show if we have uncategorized transactions and not loading them
        return !isLoadingUncategorized && !uncategorizedTransactions.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Date at the top
            topDateSection
            
            ScrollView {
                VStack(spacing: 0) {
                    // UPDATED: Show card stack based on loading states and data availability
                    if shouldShowUncategorizedStack {
                        UncategorizedTransactionStack(
                            transactions: uncategorizedTransactions,
                            categories: apiCategories,
                            onCategorizeTransaction: { transaction, category in
                                categorizeTransaction(transaction, category: category)
                            },
                            onDismissStack: {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    uncategorizedTransactions = []
                                }
                            }
                        )
                        .padding(.top, -30)
                        .padding(.bottom, 8)
                    }
                    
                    // Content sections with custom spacing
                    VStack(spacing: 24) {
                        // 1. Payment Type section
                        paymentTypeSection
                    
                        // 2. Category section
                        categorySection
                    
                        // 3. Value section
                        valueSection
                    
                        // 4. Description section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.appText)
                            
                            AppTextField(
                                text: $descriptionText,
                                placeholder: "Optional description"
                            ) { isFocused in
                                keyboardScroll.focusChanged(
                                    field: "input_description",
                                    isFocused: isFocused,
                                    accessoryHeight: KeyboardScrollCoordinator.standardAccessoryHeight
                                )
                            }
                        }
                    
                        // Save button
                        saveSection
                    
                        // Extra padding at bottom
                        Spacer()
                            .frame(height: 300)
                    }
                }
                .padding()
                .offset(y: keyboardScroll.scrollOffset)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background {
            AppAppearance.shared.appBackgroundColor
                .ignoresSafeArea(.all)
        }
        .overlay(alignment: .top) { toastOverlay }
        .animation(.default, value: showSavedToast)
        .animation(.easeInOut(duration: 0.4), value: uncategorizedTransactions.count)
        .refreshable {
            await refreshAPIDataWithFullReload()
        }
        .onAppear {
            loadAPIDataForFirstTime()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                let window = (notification.object as? UIView)?.window
                keyboardScroll.keyboardWillShow(height: keyboardFrame.height, in: window)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardScroll.keyboardWillHide()
        }
        .alert("Oops", isPresented: alertBinding) {
            Button("OK") { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("Cancel") {
                    hideKeyboard()
                }
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
    }
    
    // MARK: - API Data Loading Functions
    
    // Called when app first opens - show loading states
    private func loadAPIDataForFirstTime() {
        if isFirstLoad {
            print("🚀 First load - showing loading states")
            // First time loading - use skeleton loading for chips and load uncategorized
            fetchCategoriesWithLoading()
            fetchPaymentMethodsWithLoading()
            fetchUncategorizedWithLoading()
            isFirstLoad = false
        } else {
            print("🔄 Not first load - background refresh")
            // Subsequent loads - no loading feedback, background refresh
            loadAPIDataInBackground()
        }
    }
    
    // Called when tab switching back - background refresh without loading states
    private func loadAPIDataInBackground() {
        print("🔄 Background refresh - no loading states")
        fetchCategoriesQuietly()
        fetchPaymentMethodsQuietly()
        fetchUncategorizedQuietly()
    }
    
    // Called on pull-to-refresh - full reload with loading states like first time
    @MainActor
    private func refreshAPIDataWithFullReload() async {
        print("🔄 Pull-to-refresh - full reload with loading states")
        // Reset all data and show loading states like first app open
        
        // Clear current data and show loading states like first app open
        withAnimation(.easeInOut(duration: 0.3)) {
            apiCategories = []
            apiPaymentMethods = []
            uncategorizedTransactions = []
            isLoadingCategories = true
            isLoadingPaymentMethods = true
            isLoadingUncategorized = true
            categoriesError = nil
            paymentMethodsError = nil
        }
        
        // Load all data with loading states
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.refreshCategoriesWithLoading()
            }
            group.addTask {
                await self.refreshPaymentMethodsWithLoading()
            }
            group.addTask {
                await self.refreshUncategorizedWithLoading()
            }
        }
    }
    
    // MARK: - Categories Functions
    
    private func fetchCategoriesWithLoading() {
        isLoadingCategories = true
        categoriesError = nil
        
        if useMockData {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isLoadingCategories = false
                self.apiCategories = self.getMockCategories()
                self.autoSelectFirstCategory()
            }
        } else {
            fetchRealAPICategories()
        }
    }
    
    private func fetchCategoriesQuietly() {
        // No loading state updates - silent background fetch
        if useMockData {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.apiCategories = self.getMockCategories()
                self.autoSelectFirstCategory()
            }
        } else {
            SHEETS.getCategories { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        if response.success {
                            self.apiCategories = response.data.sorted { $0.sortIndex < $1.sortIndex }
                            self.categoriesError = nil
                            self.autoSelectFirstCategory()
                        } else {
                            self.categoriesError = response.message
                        }
                        
                    case .failure(let error):
                        self.categoriesError = error.localizedDescription
                    }
                }
            }
        }
    }
    
    private func fetchRealAPICategories() {
        SHEETS.getCategories { result in
            DispatchQueue.main.async {
                self.isLoadingCategories = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        self.apiCategories = response.data.sorted { $0.sortIndex < $1.sortIndex }
                        self.categoriesError = nil
                        self.autoSelectFirstCategory()
                    } else {
                        self.categoriesError = response.message
                    }
                    
                case .failure(let error):
                    self.categoriesError = error.localizedDescription
                }
            }
        }
    }
    
    @MainActor
    private func refreshCategoriesWithLoading() async {
        if useMockData {
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.isLoadingCategories = false
            self.apiCategories = self.getMockCategories()
            self.categoriesError = nil
            self.autoSelectFirstCategory()
        } else {
            await withCheckedContinuation { continuation in
                SHEETS.getCategories { result in
                    DispatchQueue.main.async {
                        self.isLoadingCategories = false
                        
                        switch result {
                        case .success(let response):
                            if response.success {
                                self.apiCategories = response.data.sorted { $0.sortIndex < $1.sortIndex }
                                self.categoriesError = nil
                                self.autoSelectFirstCategory()
                            } else {
                                self.categoriesError = response.message
                            }
                            
                        case .failure(let error):
                            self.categoriesError = error.localizedDescription
                        }
                        
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    // MARK: - Payment Methods Functions
    
    private func fetchPaymentMethodsWithLoading() {
        isLoadingPaymentMethods = true
        paymentMethodsError = nil
        
        if useMockData {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isLoadingPaymentMethods = false
                self.apiPaymentMethods = self.getMockPaymentMethods()
                self.autoSelectFirstPaymentMethod()
            }
        } else {
            fetchRealAPIPaymentMethods()
        }
    }
    
    private func fetchPaymentMethodsQuietly() {
        // No loading state updates - silent background fetch
        if useMockData {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.apiPaymentMethods = self.getMockPaymentMethods()
                self.autoSelectFirstPaymentMethod()
            }
        } else {
            SHEETS.getPaymentMethods { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        if response.success {
                            self.apiPaymentMethods = response.data.sorted { $0.sortIndex < $1.sortIndex }
                            self.paymentMethodsError = nil
                            self.autoSelectFirstPaymentMethod()
                        } else {
                            self.paymentMethodsError = response.message
                        }
                        
                    case .failure(let error):
                        self.paymentMethodsError = error.localizedDescription
                    }
                }
            }
        }
    }
    
    private func fetchRealAPIPaymentMethods() {
        SHEETS.getPaymentMethods { result in
            DispatchQueue.main.async {
                self.isLoadingPaymentMethods = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        self.apiPaymentMethods = response.data.sorted { $0.sortIndex < $1.sortIndex }
                        self.paymentMethodsError = nil
                        self.autoSelectFirstPaymentMethod()
                    } else {
                        self.paymentMethodsError = response.message
                    }
                    
                case .failure(let error):
                    self.paymentMethodsError = error.localizedDescription
                }
            }
        }
    }
    
    @MainActor
    private func refreshPaymentMethodsWithLoading() async {
        if useMockData {
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.isLoadingPaymentMethods = false
            self.apiPaymentMethods = self.getMockPaymentMethods()
            self.paymentMethodsError = nil
            self.autoSelectFirstPaymentMethod()
        } else {
            await withCheckedContinuation { continuation in
                SHEETS.getPaymentMethods { result in
                    DispatchQueue.main.async {
                        self.isLoadingPaymentMethods = false
                        
                        switch result {
                        case .success(let response):
                            if response.success {
                                self.apiPaymentMethods = response.data.sorted { $0.sortIndex < $1.sortIndex }
                                self.paymentMethodsError = nil
                                self.autoSelectFirstPaymentMethod()
                            } else {
                                self.paymentMethodsError = response.message
                            }
                            
                        case .failure(let error):
                            self.paymentMethodsError = error.localizedDescription
                        }
                        
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    // MARK: - Uncategorized Transactions Functions
    
    private func fetchUncategorizedWithLoading() {
        isLoadingUncategorized = true
        
        if useMockData {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isLoadingUncategorized = false
                let mockTransactions = self.getMockUncategorizedTransactions()
                self.uncategorizedTransactions = mockTransactions
            }
        } else {
            fetchRealAPIUncategorizedTransactions()
        }
    }
    
    private func fetchUncategorizedQuietly() {
        // No loading state - background refresh
        if useMockData {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let mockTransactions = self.getMockUncategorizedTransactions()
                self.uncategorizedTransactions = mockTransactions
            }
        } else {
            SHEETS.getUncategorizedTransactions { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        if response.success {
                            self.uncategorizedTransactions = response.data
                        } else {
                            self.uncategorizedTransactions = []
                        }
                    case .failure(_):
                        self.uncategorizedTransactions = []
                    }
                }
            }
        }
    }
    
    private func fetchRealAPIUncategorizedTransactions() {
        SHEETS.getUncategorizedTransactions { result in
            DispatchQueue.main.async {
                self.isLoadingUncategorized = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        self.uncategorizedTransactions = response.data
                    } else {
                        self.uncategorizedTransactions = []
                    }
                case .failure(_):
                    self.uncategorizedTransactions = []
                }
            }
        }
    }
    
    @MainActor
    private func refreshUncategorizedWithLoading() async {
        if useMockData {
            try? await Task.sleep(nanoseconds: 300_000_000)
            self.isLoadingUncategorized = false
            let mockTransactions = getMockUncategorizedTransactions()
            self.uncategorizedTransactions = mockTransactions
        } else {
            await withCheckedContinuation { continuation in
                SHEETS.getUncategorizedTransactions { result in
                    DispatchQueue.main.async {
                        self.isLoadingUncategorized = false
                        
                        switch result {
                        case .success(let response):
                            if response.success {
                                self.uncategorizedTransactions = response.data
                            } else {
                                self.uncategorizedTransactions = []
                            }
                        case .failure(_):
                            self.uncategorizedTransactions = []
                        }
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    // MARK: - Auto-selection helpers
    
    private func autoSelectFirstCategory() {
        if selectedCategoryID == nil && !apiCategories.isEmpty {
            selectedCategoryID = apiCategories.first?.remoteID
        }
    }
    
    private func autoSelectFirstPaymentMethod() {
        if selectedMethodID == nil && !apiPaymentMethods.isEmpty {
            selectedMethodID = apiPaymentMethods.first?.remoteID
        }
    }
    
    // MARK: - Categorize Transaction Function
    private func categorizeTransaction(_ transaction: APITransaction, category: APICategory) {
        print("🎯 categorizeTransaction called for transaction: \(transaction.remoteID)")
        print("🎯 Selected category: \(category.name)")
        
        // Remove from uncategorized list immediately
        self.uncategorizedTransactions.removeAll { $0.remoteID == transaction.remoteID }
        
        print("🗑️ Removed transaction \(transaction.remoteID) from uncategorized list")
        print("📊 Remaining uncategorized transactions: \(self.uncategorizedTransactions.count)")
        
        // That's it! No automatic refresh - cards only update on tab switch or pull-to-refresh
        if self.uncategorizedTransactions.isEmpty {
            print("👋 No more uncategorized transactions - stack will hide")
        }
    }
    
    // MARK: - Mock Data Functions
    
    private func getMockCategories() -> [APICategory] {
        let mockJSON = """
        [
            {
                "remoteID": "mock-cat-1",
                "name": "Food",
                "emoji": "🍽️",
                "sortIndex": 0,
                "isIncome": false,
                "timestamp": "2025-09-17T12:00:00.000Z"
            },
            {
                "remoteID": "mock-cat-2",
                "name": "Transport",
                "emoji": "🚕",
                "sortIndex": 1,
                "isIncome": false,
                "timestamp": "2025-09-17T12:00:00.000Z"
            },
            {
                "remoteID": "mock-cat-3",
                "name": "Shopping",
                "emoji": "🛍️",
                "sortIndex": 2,
                "isIncome": false,
                "timestamp": "2025-09-17T12:00:00.000Z"
            },
            {
                "remoteID": "mock-cat-4",
                "name": "Bills",
                "emoji": "💡",
                "sortIndex": 3,
                "isIncome": false,
                "timestamp": "2025-09-17T12:00:00.000Z"
            },
            {
                "remoteID": "mock-cat-5",
                "name": "Salary",
                "emoji": "💼",
                "sortIndex": 4,
                "isIncome": true,
                "timestamp": "2025-09-17T12:00:00.000Z"
            },
            {
                "remoteID": "mock-cat-6",
                "name": "Freelance",
                "emoji": "💻",
                "sortIndex": 5,
                "isIncome": true,
                "timestamp": "2025-09-17T12:00:00.000Z"
            }
        ]
        """
        
        guard let data = mockJSON.data(using: .utf8),
              let categories = try? JSONDecoder().decode([APICategory].self, from: data) else {
            return []
        }
        return categories
    }
    
    private func getMockPaymentMethods() -> [APIPaymentMethod] {
        let mockJSON = """
        [
            {
                "remoteID": "mock-pm-1",
                "name": "Credit Card",
                "emoji": "💳",
                "sortIndex": 0,
                "timestamp": "2025-09-17T12:00:00.000Z"
            },
            {
                "remoteID": "mock-pm-2",
                "name": "Debit Card",
                "emoji": "💳",
                "sortIndex": 1,
                "timestamp": "2025-09-17T12:00:00.000Z"
            },
            {
                "remoteID": "mock-pm-3",
                "name": "Pix",
                "emoji": "📱",
                "sortIndex": 2,
                "timestamp": "2025-09-17T12:00:00.000Z"
            },
            {
                "remoteID": "mock-pm-4",
                "name": "Cash",
                "emoji": "💵",
                "sortIndex": 3,
                "timestamp": "2025-09-17T12:00:00.000Z"
            }
        ]
        """
        
        guard let data = mockJSON.data(using: .utf8),
              let methods = try? JSONDecoder().decode([APIPaymentMethod].self, from: data) else {
            return []
        }
        return methods
    }
    
    // Mock data for testing card stack
    private func getMockUncategorizedTransactions() -> [APITransaction] {
        return [
            APITransaction(
                remoteID: "uncat-1",
                amount: -45.50,
                categoryName: "",
                categoryEmoji: "",
                paymentMethod: "Credit Card",
                merchantName: "Supermarket ABC",
                note: "Weekly groceries",
                dateISO: "2025-01-15",
                transactionType: "expense"
            ),
            APITransaction(
                remoteID: "uncat-2",
                amount: -12.90,
                categoryName: "",
                categoryEmoji: "",
                paymentMethod: "Pix",
                merchantName: "Coffee Shop",
                note: "",
                dateISO: "2025-01-14",
                transactionType: "expense"
            ),
            APITransaction(
                remoteID: "uncat-3",
                amount: -89.00,
                categoryName: "",
                categoryEmoji: "",
                paymentMethod: "Debit Card",
                merchantName: "Gas Station",
                note: "Fuel",
                dateISO: "2025-01-13",
                transactionType: "expense"
            ),
            APITransaction(
                remoteID: "uncat-4",
                amount: 250.00,
                categoryName: "",
                categoryEmoji: "",
                paymentMethod: "Bank Transfer",
                merchantName: "Freelance Client",
                note: "Project payment",
                dateISO: "2025-01-12",
                transactionType: "income"
            )
        ]
    }
    
    // MARK: - Helper function
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Date Section with inline calendar
    @ViewBuilder private var topDateSection: some View {
        VStack(spacing: 0) {
            // Top spacing
            Spacer()
                .frame(height: 40)
            
            VStack(spacing: 16) {
                // Date header with dropdown arrow
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showDatePicker.toggle()
                    }
                    dismissKeyboard()
                }) {
                    HStack(spacing: 8) {
                        Text(formatFullDate(date))
                            .font(.headline)
                            .foregroundColor(.appText)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.appText.opacity(0.7))
                            .rotationEffect(.degrees(showDatePicker ? 180 : 0))
                            .animation(.easeInOut(duration: 0.2), value: showDatePicker)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Calendar appears directly here when showDatePicker is true
                if showDatePicker {
                    InputViewCalendarView(selectedDate: $date)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)),
                            removal: .opacity.combined(with: .scale(scale: 0.9))
                        ))
                }
            }
            .padding(.horizontal, 16)
            
            // Bottom spacing
            Spacer()
                .frame(height: 20)
        }
    }
    
    // MARK: - Payment Type Section
    @ViewBuilder private var paymentTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Type")
                .font(.headline)
                .foregroundColor(.appText)
            
            if isLoadingPaymentMethods {
                paymentMethodsSkeleton
            } else if let error = paymentMethodsError {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Failed to load payment methods")
                        .foregroundColor(.red.opacity(0.8))
                        .font(.caption)
                    
                    Button("Retry") {
                        fetchCategoriesWithLoading()
                        fetchPaymentMethodsWithLoading()
                        fetchUncategorizedWithLoading()
                    }
                    .appSmallButtonStyle()
                }
            } else if apiPaymentMethods.isEmpty && !isLoadingPaymentMethods {
                Text("No payment methods available")
                    .foregroundColor(.appText.opacity(0.6))
                    .font(.caption)
            } else {
                Color.clear
                    .frame(height: 50)
                    .singleRowChipScroll {
                        ForEach(apiPaymentMethods, id: \.remoteID) { pm in
                            APIPaymentChipView(
                                paymentMethod: pm,
                                isSelected: selectedMethodID == pm.remoteID,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedMethodID = pm.remoteID
                                    }
                                    dismissKeyboard()
                                },
                                namespace: paymentChipNamespace
                            )
                        }
                    }
            }
        }
    }
    
    @ViewBuilder private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.headline)
                .foregroundColor(.appText)
            
            if isLoadingCategories {
                categoriesSkeleton
            } else if let error = categoriesError {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Failed to load categories")
                        .foregroundColor(.red.opacity(0.8))
                        .font(.caption)
                    
                    Button("Retry") {
                        fetchCategoriesWithLoading()
                        fetchPaymentMethodsWithLoading()
                        fetchUncategorizedWithLoading()
                    }
                    .appSmallButtonStyle()
                }
            } else if apiCategories.isEmpty && !isLoadingCategories {
                Text("No categories available")
                    .foregroundColor(.appText.opacity(0.6))
                    .font(.caption)
            } else {
                Color.clear
                    .frame(height: apiCategories.count > 2 ? 158 : (apiCategories.count > 1 ? 108 : 58)) // Dynamic height based on rows needed
                    .tripleRowChipScroll(
                        firstRowNamespace: categoryChipNamespace,
                        firstRow: {
                            ForEach(Array(stride(from: 0, to: apiCategories.count, by: 3)), id: \.self) { index in
                                APICategoryChipView(
                                    category: apiCategories[index],
                                    isSelected: selectedCategoryID == apiCategories[index].remoteID,
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedCategoryID = apiCategories[index].remoteID
                                        }
                                        dismissKeyboard()
                                    },
                                    namespace: categoryChipNamespace
                                )
                            }
                        },
                        secondRow: {
                            if apiCategories.count > 1 {
                                ForEach(Array(stride(from: 1, to: apiCategories.count, by: 3)), id: \.self) { index in
                                    APICategoryChipView(
                                        category: apiCategories[index],
                                        isSelected: selectedCategoryID == apiCategories[index].remoteID,
                                        onTap: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedCategoryID = apiCategories[index].remoteID
                                            }
                                            dismissKeyboard()
                                        },
                                        namespace: categoryChipNamespace
                                    )
                                }
                            } else {
                                EmptyView()
                            }
                        },
                        thirdRow: {
                            if apiCategories.count > 2 {
                                ForEach(Array(stride(from: 2, to: apiCategories.count, by: 3)), id: \.self) { index in
                                    APICategoryChipView(
                                        category: apiCategories[index],
                                        isSelected: selectedCategoryID == apiCategories[index].remoteID,
                                        onTap: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedCategoryID = apiCategories[index].remoteID
                                            }
                                            dismissKeyboard()
                                        },
                                        namespace: categoryChipNamespace
                                    )
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    )
            }
        }
    }
    
    // MARK: - Skeleton Loading Views
    
    @ViewBuilder private var paymentMethodsSkeleton: some View {
        Color.clear
            .frame(height: 50)
            .singleRowChipScroll {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonChip()
                }
            }
    }
    
    @ViewBuilder private var categoriesSkeleton: some View {
        Color.clear
            .frame(height: 158) // Fixed height for 3 rows
            .tripleRowChipScroll(
                firstRowNamespace: categoryChipNamespace,
                firstRow: {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonChip()
                    }
                },
                secondRow: {
                    ForEach(0..<5, id: \.self) { _ in
                        SkeletonChip()
                    }
                },
                thirdRow: {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonChip()
                    }
                }
            )
    }
    
    @ViewBuilder private var valueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Value")
                .font(.headline)
                .foregroundColor(.appText)
            
            AppCurrencyField(
                text: $amountText,
                placeholder: "R$ 0,00"
            ) { isFocused in
                keyboardScroll.focusChanged(
                    field: "input_amount",
                    isFocused: isFocused,
                    accessoryHeight: KeyboardScrollCoordinator.standardAccessoryHeight
                )
            }
        }
    }
    
    // MARK: - Save Section
    @ViewBuilder private var saveSection: some View {
        EnhancedButton(title: "Save Entry", isDisabled: !canSave) {
            return await performSave()
        }
        .opacity(canSave ? 1.0 : 0.8)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        keyboardScroll.registerButtonFrame(geometry.frame(in: .global))
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                        keyboardScroll.registerButtonFrame(newFrame)
                    }
            }
        )
    }
    
    // MARK: - Save Function
    @MainActor
    private func performSave() async -> Bool {
        guard let amount = amountDecimal else { return false }

        let signedAmount = (selectedCategory?.isIncome ?? false) ? amount : -amount

        // Create local transaction for immediate feedback
        let tx = Transaction(
            amount: signedAmount,
            date: date,
            note: descriptionText.isEmpty ? nil : descriptionText,
            category: nil, // We don't link to local categories anymore
            paymentMethod: nil // We don't link to local payment methods anymore
        )

        do {
            try withAnimation {
                ctx.insert(tx)
                try ctx.save()
            }

            // Post to sheets with API category and payment method names
            SHEETS.postTransaction(
                remoteID: tx.remoteID,
                amount: signedAmount,
                date: date,
                categoryName: selectedCategory?.name,
                paymentName: selectedMethod?.name,
                note: descriptionText.isEmpty ? nil : descriptionText
            )

            // Clear form
            amountText = ""
            descriptionText = ""
            date = Date()
            selectedCategoryID = nil
            selectedMethodID = nil
            showDatePicker = false
            
            // Auto-select first options again
            autoSelectFirstCategory()
            autoSelectFirstPaymentMethod()
            
            dismissKeyboard()
            
            return true
        } catch {
            alertMessage = "Could not save entry: \(error.localizedDescription)"
            return false
        }
    }

    @ViewBuilder private var toastOverlay: some View {
        if showSavedToast {
            Text("Saved ✔︎")
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundColor(Color.appText)
                .padding(.top, 60)
                .glassEffect(.regular, in: .rect(cornerRadius: 8))
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )
    }

    // MARK: - Validation and actions
    private var canSave: Bool {
        amountDecimal != nil
    }
    
    private var amountDecimal: Decimal? {
        var cleanString = amountText
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanString.contains(",") {
            let parts = cleanString.components(separatedBy: ",")
            if parts.count == 2 {
                let integerPart = parts[0].replacingOccurrences(of: ".", with: "")
                let decimalPart = parts[1]
                cleanString = integerPart + "." + decimalPart
            }
        }
        
        return Decimal(string: cleanString)
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Custom Calendar View (Kept to avoid redeclaration)
struct InputViewCalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 12) {
            // Month/Year header
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.appText)
                        .font(.title3.weight(.medium))
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.appText)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.appText)
                        .font(.title3.weight(.medium))
                }
            }
            .padding(.horizontal, 4)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Days of week headers
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.appText.opacity(0.6))
                        .frame(height: 20)
                }
                
                // Calendar days
                ForEach(calendarDays, id: \.self) { date in
                    if let date = date {
                        Button(action: {
                            selectedDate = date
                        }) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 16, weight: calendar.isDate(date, inSameDayAs: selectedDate) ? .bold : .regular))
                                .foregroundColor(
                                    calendar.isDate(date, inSameDayAs: selectedDate) ? .black :
                                    calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) ? .appText : .appText.opacity(0.3)
                                )
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(calendar.isDate(date, inSameDayAs: selectedDate) ? Color.appAccent : Color.clear)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Color.clear
                            .frame(width: 36, height: 36)
                    }
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .onAppear {
            currentMonth = selectedDate
        }
    }
    
    private var calendarDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        
        var days: [Date?] = []
        
        // Add empty slots for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add all days of the current month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
}
