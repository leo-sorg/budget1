import SwiftUI
import SwiftData
import PhotosUI
import Foundation  // Add this
import UIKit 

@MainActor
struct ManageView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var store: BackgroundImageStore

    // UPDATED: Use @State for API data instead of local database
    @State private var categories: [APICategory] = []
    @State private var methods: [APIPaymentMethod] = []
    
    // UPDATED: Add API state management like SummaryView
    @State private var isLoadingCategories = false
    @State private var isLoadingPaymentMethods = false
    @State private var categoriesError: String?
    @State private var paymentMethodsError: String?

    // Set this to false to use real API, true to use mock data
    private let useMockData = false

    @State private var newCategory = ""
    @State private var newCategoryEmoji = ""
    @State private var newCategoryIsIncome = false
    @State private var newPayment = ""
    @State private var newPaymentEmoji = ""
    @State private var alertMessage: String?
    @State private var hexColorInput = ""

    // Preset colors for background picker - Using explicit Color values (11 colors + 1 custom slot)
    let presetColors: [(Color, String)] = [
        (Color(red: 0.1, green: 0.1, blue: 0.2), "Dark Blue"),
        (Color(red: 0.0, green: 0.0, blue: 0.0), "Black"),
        (Color(red: 0.15, green: 0.15, blue: 0.15), "Dark Gray"),
        (Color(red: 0.2, green: 0.05, blue: 0.05), "Dark Red"),
        (Color(red: 0.05, green: 0.2, blue: 0.05), "Dark Green"),
        (Color(red: 0.2, green: 0.15, blue: 0.05), "Dark Brown"),
        (Color(red: 0.15, green: 0.05, blue: 0.2), "Dark Purple"),
        (Color(red: 0.05, green: 0.1, blue: 0.2), "Navy"),
        (Color(red: 0.2, green: 0.2, blue: 0.05), "Dark Yellow"),
        (Color(red: 0.05, green: 0.15, blue: 0.15), "Dark Cyan"),
        (Color(red: 0.2, green: 0.05, blue: 0.15), "Dark Magenta"),
    ]

    // Updated to support 3 sections
    enum ManageSection: String, CaseIterable {
        case categories = "Categories"
        case payments = "Payment Types"
        case background = "Background"
    }
    
    @State private var selectedSection: ManageSection = .categories
    @State private var showCategoryForm = false
    @State private var showPaymentForm = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var showHexInput = false

    var body: some View {
        VStack(spacing: 0) {
            // Header using reusable component
            AppHeader(title: "MANAGE")
            
            // Chip navigation with InputView-style padding
            VStack(alignment: .leading, spacing: 12) {
                Color.clear
                    .frame(height: 50)
                    .singleRowChipScroll {
                        ForEach(ManageSection.allCases, id: \.self) { section in
                            ManageSectionChip(
                                section: section,
                                isSelected: selectedSection == section,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedSection = section
                                        // Reset forms when switching sections
                                        showCategoryForm = false
                                        showPaymentForm = false
                                        // Dismiss keyboard to avoid scroll interference
                                        hideKeyboard()
                                    }
                                }
                            )
                        }
                    }
            }
            .padding() // Same as InputView sections
            
            // Content based on selected section with pull-to-refresh
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    switch selectedSection {
                    case .categories:
                        categorySection
                    case .payments:
                        paymentSection
                    case .background:
                        backgroundSection
                    }
                    
                    // Extra padding at bottom to ensure scrollability
                    Spacer()
                        .frame(height: 150)
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .refreshable {
                await refreshCurrentSection()
            }
        }
        .onAppear {
            // Load data when view appears
            loadDataForCurrentSection()
        }
        .onChange(of: selectedSection) { _, _ in
            // Load data when section changes
            loadDataForCurrentSection()
        }
        .alert("Oops", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
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

    // MARK: - Data Loading Functions
    
    private func loadDataForCurrentSection() {
        switch selectedSection {
        case .categories:
            fetchCategories()
        case .payments:
            fetchPaymentMethods()
        case .background:
            // Background section doesn't need API data
            break
        }
    }
    
    @MainActor
    private func refreshCurrentSection() async {
        switch selectedSection {
        case .categories:
            await refreshCategories()
        case .payments:
            await refreshPaymentMethods()
        case .background:
            // Background section doesn't need refresh
            break
        }
    }
    
    private func fetchCategories() {
        isLoadingCategories = true
        categoriesError = nil
        
        if useMockData {
            // Mock API delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isLoadingCategories = false
                self.categories = self.getMockCategories()
                self.categoriesError = nil
            }
        } else {
            fetchRealAPICategories()
        }
    }
    
    private func fetchPaymentMethods() {
        isLoadingPaymentMethods = true
        paymentMethodsError = nil
        
        if useMockData {
            // Mock API delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isLoadingPaymentMethods = false
                self.methods = self.getMockPaymentMethods()
                self.paymentMethodsError = nil
            }
        } else {
            fetchRealAPIPaymentMethods()
        }
    }
    
    // MARK: - Real API Functions
    private func fetchRealAPICategories() {
        SHEETS.getCategories { result in
            DispatchQueue.main.async {
                self.isLoadingCategories = false
                
                switch result {
                case .success(let response):
                    if response.success {
                        self.categories = response.data.sorted { $0.sortIndex < $1.sortIndex }
                        print("✅ Successfully loaded \(self.categories.count) categories")
                    } else {
                        self.categoriesError = response.message
                        print("❌ Categories API Error: \(response.message)")
                    }
                    
                case .failure(let error):
                    print("❌ Categories Error: \(error)")
                    self.categoriesError = error.localizedDescription
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
                        self.methods = response.data.sorted { $0.sortIndex < $1.sortIndex }
                        print("✅ Successfully loaded \(self.methods.count) payment methods")
                    } else {
                        self.paymentMethodsError = response.message
                        print("❌ Payment Methods API Error: \(response.message)")
                    }
                    
                case .failure(let error):
                    print("❌ Payment Methods Error: \(error)")
                    self.paymentMethodsError = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Pull to Refresh Functions
    
    @MainActor
    private func refreshCategories() async {
        if useMockData {
            // Simulate network delay for mock data
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            self.categories = self.getMockCategories()
            self.categoriesError = nil
        } else {
            await refreshRealAPICategories()
        }
    }
    
    @MainActor
    private func refreshPaymentMethods() async {
        if useMockData {
            // Simulate network delay for mock data
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            self.methods = self.getMockPaymentMethods()
            self.paymentMethodsError = nil
        } else {
            await refreshRealAPIPaymentMethods()
        }
    }
    
    @MainActor
    private func refreshRealAPICategories() async {
        await withCheckedContinuation { continuation in
            SHEETS.getCategories { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        if response.success {
                            self.categories = response.data.sorted { $0.sortIndex < $1.sortIndex }
                            self.categoriesError = nil
                            print("✅ Refreshed \(self.categories.count) categories")
                        } else {
                            self.categoriesError = response.message
                            print("❌ Refresh Categories Error: \(response.message)")
                        }
                        
                    case .failure(let error):
                        print("❌ Refresh Categories Error: \(error)")
                        self.categoriesError = error.localizedDescription
                    }
                    
                    continuation.resume()
                }
            }
        }
    }
    
    @MainActor
    private func refreshRealAPIPaymentMethods() async {
        await withCheckedContinuation { continuation in
            SHEETS.getPaymentMethods { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        if response.success {
                            self.methods = response.data.sorted { $0.sortIndex < $1.sortIndex }
                            self.paymentMethodsError = nil
                            print("✅ Refreshed \(self.methods.count) payment methods")
                        } else {
                            self.paymentMethodsError = response.message
                            print("❌ Refresh Payment Methods Error: \(response.message)")
                        }
                        
                    case .failure(let error):
                        print("❌ Refresh Payment Methods Error: \(error)")
                        self.paymentMethodsError = error.localizedDescription
                    }
                    
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Category Section with inline form and loading states
    @ViewBuilder private var categorySection: some View {
        VStack(spacing: 24) {
            // Add/Edit form
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Add Category")
                        .font(.headline)
                        .foregroundColor(.appText)
                    Spacer()
                    Button(showCategoryForm ? "Cancel" : "Add New") {
                        withAnimation {
                            showCategoryForm.toggle()
                            if showCategoryForm {
                                newCategory = ""
                                newCategoryEmoji = ""
                                newCategoryIsIncome = false
                            } else {
                                // Dismiss keyboard when canceling
                                hideKeyboard()
                            }
                        }
                    }
                    .buttonStyle(AppSmallButtonStyle())
                }
                
                if showCategoryForm {
                    VStack(spacing: 20) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            AppTextField(text: $newCategory, placeholder: "e.g. Food")
                        }
                        
                        // Emoji field with picker button
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Emoji (optional)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                EmojiHelperButton { selectedEmoji in
                                    newCategoryEmoji = selectedEmoji
                                }
                            }
                            AppEmojiField(text: $newCategoryEmoji, placeholder: "e.g. 🍕")
                        }
                        
                        // Type selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Type")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    newCategoryIsIncome = false
                                    hideKeyboard()
                                }) {
                                    Text("Expense")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                }
                                .background(GlassChipBackground(isSelected: !newCategoryIsIncome))
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    newCategoryIsIncome = true
                                    hideKeyboard()
                                }) {
                                    Text("Income")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                }
                                .background(GlassChipBackground(isSelected: newCategoryIsIncome))
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // Add button using EnhancedButton
                        EnhancedButton(title: "Add Category") {
                            return await performAddCategory()
                        }
                        .disabled(newCategory.isEmpty)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
            
            // Category list with loading states
            VStack(alignment: .leading, spacing: 16) {
                Text("Category List")
                    .font(.headline)
                    .foregroundColor(.appText)
                
                if isLoadingCategories {
                    // Loading state
                    loadingView
                } else if let error = categoriesError {
                    // Error state
                    errorView(message: error, retryAction: fetchCategories)
                } else if categories.isEmpty {
                    Text("No categories found. Add one above or pull to refresh.")
                        .foregroundColor(.appText.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(categories, id: \.remoteID) { category in
                            APICategoryListItem(
                                category: category,
                                onDelete: {
                                    // TODO: Implement API delete if needed
                                    // For now, just show that deletion is not available
                                    alertMessage = "Deleting from API not yet implemented"
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Payment Section with inline form and loading states
    @ViewBuilder private var paymentSection: some View {
        VStack(spacing: 24) {
            // Add/Edit form
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Add Payment Type")
                        .font(.headline)
                        .foregroundColor(.appText)
                    Spacer()
                    Button(showPaymentForm ? "Cancel" : "Add New") {
                        withAnimation {
                            showPaymentForm.toggle()
                            if showPaymentForm {
                                newPayment = ""
                                newPaymentEmoji = ""
                            } else {
                                // Dismiss keyboard when canceling
                                hideKeyboard()
                            }
                        }
                    }
                    .buttonStyle(AppSmallButtonStyle())
                }
                
                if showPaymentForm {
                    VStack(spacing: 20) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Payment Type")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                            AppTextField(text: $newPayment, placeholder: "e.g. Credit Card, Pix")
                        }
                        
                        // Emoji field with picker button
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Emoji (optional)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                Spacer()
                                EmojiHelperButton { selectedEmoji in
                                    newPaymentEmoji = selectedEmoji
                                }
                            }
                            AppEmojiField(text: $newPaymentEmoji, placeholder: "e.g. 💳")
                        }
                        
                        // Add button using EnhancedButton
                        EnhancedButton(title: "Add Payment Type") {
                            return await performAddPayment()
                        }
                        .disabled(newPayment.isEmpty)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
            
            // Payment list with loading states
            VStack(alignment: .leading, spacing: 16) {
                Text("Payment Type List")
                    .font(.headline)
                    .foregroundColor(.appText)
                
                if isLoadingPaymentMethods {
                    // Loading state
                    loadingView
                } else if let error = paymentMethodsError {
                    // Error state
                    errorView(message: error, retryAction: fetchPaymentMethods)
                } else if methods.isEmpty {
                    Text("No payment methods found. Add one above or pull to refresh.")
                        .foregroundColor(.appText.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(methods, id: \.remoteID) { method in
                            APIPaymentMethodListItem(
                                paymentMethod: method,
                                onDelete: {
                                    // TODO: Implement API delete if needed
                                    // For now, just show that deletion is not available
                                    alertMessage = "Deleting from API not yet implemented"
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Background section
    @ViewBuilder private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Background Options")
                .font(.headline)
                .foregroundColor(.appText)
            
            // Color grid directly on screen
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose Color")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    // Show the 11 preset colors
                    ForEach(Array(presetColors.enumerated()), id: \.offset) { index, colorTuple in
                        let (color, _) = colorTuple
                        ColorSquare(
                            color: color,
                            isSelected: store.useCustomColor && store.backgroundColor == color,
                            action: {
                                store.setColor(color)
                            }
                        )
                    }
                    
                    // Custom hex color button (12th square)
                    Button(action: {
                        hexColorInput = ""
                        showHexInput.toggle()
                        hideKeyboard()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 50)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Hex input inline
            if showHexInput {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hex Color Code")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    HStack(spacing: 8) {
                        Text("#")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        
                        AppTextField(text: $hexColorInput, placeholder: "000000")
                            .onChange(of: hexColorInput) { _, newValue in
                                var cleaned = newValue.replacingOccurrences(of: "#", with: "")
                                if cleaned.count > 6 {
                                    cleaned = String(cleaned.prefix(6))
                                }
                                cleaned = cleaned.filter { $0.isHexDigit }
                                hexColorInput = cleaned.uppercased()
                            }
                    }
                    
                    // Set Color button using EnhancedButton
                    EnhancedButton(title: "Set Color") {
                        if isValidHex(hexColorInput) {
                            applyHexColor()
                            return true
                        }
                        return false
                    }
                    .disabled(!isValidHex(hexColorInput))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
            }
            
            // Buttons below the color grid
            VStack(spacing: 12) {
                // Image picker
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    Text("Choose Image")
                }
                .buttonStyle(AppButtonStyle())
                .onChange(of: pickerItem) { oldValue, newValue in
                    Task { await loadSelection(newValue) }
                }
                .task(id: pickerItem) {
                    await loadSelection(pickerItem)
                }

                // Reset to default button
                if store.image != nil || store.useCustomColor {
                    Button("Reset to Default") {
                        store.resetToDefault()
                    }
                    .buttonStyle(AppButtonStyle())
                }
                
                // Current status indicator
                HStack {
                    Text("Current:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(
                        store.image != nil ? "Custom Image" :
                        store.useCustomColor ? "Custom Color" :
                        "Default Color"
                    )
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Loading View
    @ViewBuilder private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    // MARK: - Error View
    @ViewBuilder private func errorView(message: String, retryAction: @escaping () -> Void) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Couldn't load data")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                retryAction()
            }
            .buttonStyle(AppSmallButtonStyle())
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    // MARK: - NEW ASYNC ADD FUNCTIONS
    @MainActor
    private func performAddCategory() async -> Bool {
        hideKeyboard()
        let name = trimmed(newCategory)
        let emoji = trimmed(newCategoryEmoji)
        guard !name.isEmpty else { return false }

        // Check if category already exists
        if categories.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            alertMessage = "A category named \"\(name)\" already exists."
            return false
        }

        if useMockData {
            // Mock success for testing
            await mockAddDelay()
            
            // Clear form fields
            self.newCategory = ""
            self.newCategoryEmoji = ""
            self.newCategoryIsIncome = false
            
            // Wait for success animation to show before collapsing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    self.showCategoryForm = false
                }
            }
            
            // Refresh categories from mock
            self.categories = self.getMockCategories()
            
            return true
        } else {
            return await performRealAddCategory(name: name, emoji: emoji)
        }
    }

    @MainActor
    private func performAddPayment() async -> Bool {
        hideKeyboard()
        let name = trimmed(newPayment)
        let emoji = trimmed(newPaymentEmoji)
        guard !name.isEmpty else { return false }

        // Check if payment method already exists
        if methods.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            alertMessage = "A payment method named \"\(name)\" already exists."
            return false
        }

        if useMockData {
            // Mock success for testing
            await mockAddDelay()
            
            // Clear form fields
            self.newPayment = ""
            self.newPaymentEmoji = ""
            
            // Wait for success animation to show before collapsing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    self.showPaymentForm = false
                }
            }
            
            // Refresh payment methods from mock
            self.methods = self.getMockPaymentMethods()
            
            return true
        } else {
            return await performRealAddPayment(name: name, emoji: emoji)
        }
    }
    
    // MARK: - Real API Add Functions
    @MainActor
    private func performRealAddCategory(name: String, emoji: String) async -> Bool {
        let next = (categories.map { $0.sortIndex }.max() ?? -1) + 1
        let remoteID = UUID().uuidString

        // Post to sheets
        return await withCheckedContinuation { continuation in
            SHEETS.postCategory(
                remoteID: remoteID,
                name: name,
                emoji: emoji.isEmpty ? nil : emoji,
                sortIndex: next,
                isIncome: newCategoryIsIncome
            ) { response in
                DispatchQueue.main.async {
                    if response.status == 200 {
                        // Clear form fields
                        self.newCategory = ""
                        self.newCategoryEmoji = ""
                        self.newCategoryIsIncome = false
                        
                        // Wait for success animation to show before collapsing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                self.showCategoryForm = false
                            }
                        }
                        
                        // Refresh categories from API
                        self.fetchRealAPICategories()
                        
                        continuation.resume(returning: true)
                    } else {
                        self.alertMessage = "Could not save category: \(response.body)"
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    @MainActor
    private func performRealAddPayment(name: String, emoji: String) async -> Bool {
        let next = (methods.map { $0.sortIndex }.max() ?? -1) + 1
        let remoteID = UUID().uuidString

        // Post to sheets
        return await withCheckedContinuation { continuation in
            SHEETS.postPayment(
                remoteID: remoteID,
                name: name,
                emoji: emoji.isEmpty ? nil : emoji,
                sortIndex: next
            ) { response in
                DispatchQueue.main.async {
                    if response.status == 200 {
                        // Clear form fields
                        self.newPayment = ""
                        self.newPaymentEmoji = ""
                        
                        // Wait for success animation to show before collapsing
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                self.showPaymentForm = false
                            }
                        }
                        
                        // Refresh payment methods from API
                        self.fetchRealAPIPaymentMethods()
                        
                        continuation.resume(returning: true)
                    } else {
                        self.alertMessage = "Could not save payment method: \(response.body)"
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    // MARK: - Mock Data Functions
    private func getMockCategories() -> [APICategory] {
        // Use simple JSON decoding to create mock data
        let mockJSON = """
        [
            {
                "Remote ID": "mock-cat-1",
                "Name": "Food",
                "Emoji": "🍕",
                "Sort Index": 0,
                "Is Income": false,
                "Timestamp": "2025-09-17T12:00:00.000Z"
            },
            {
                "Remote ID": "mock-cat-2",
                "Name": "Transport",
                "Emoji": "🚗",
                "Sort Index": 1,
                "Is Income": false,
                "Timestamp": "2025-09-17T12:00:00.000Z"
            },
            {
                "Remote ID": "mock-cat-3",
                "Name": "Shopping",
                "Emoji": "🛍️",
                "Sort Index": 2,
                "Is Income": false,
                "Timestamp": "2025-09-17T12:00:00.000Z"
            },
            {
                "Remote ID": "mock-cat-7",
                "Name": "Salary",
                "Emoji": "💼",
                "Sort Index": 6,
                "Is Income": true,
                "Timestamp": "2025-09-17T12:00:00.000Z"
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
        // For now, return empty array since APIPaymentMethod has complex decoding
        // This can be implemented later if needed
        return []
    }
    
    private func mockAddDelay() async {
        // Simulate API call delay
        try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
    }

    // MARK: - Helpers
    private func loadSelection(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let ui = UIImage(data: data) {
                await MainActor.run { store.setImage(ui) }
            }
        } catch {
            // Ignore; keep previous background
        }
    }

    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func isValidHex(_ hex: String) -> Bool {
        let cleanHex = hex.replacingOccurrences(of: "#", with: "")
        return cleanHex.count == 6 && cleanHex.allSatisfy { $0.isHexDigit }
    }
    
    private func applyHexColor() {
        let cleanHex = hexColorInput.replacingOccurrences(of: "#", with: "")
        if let color = Color(hex: cleanHex) {
            store.setColor(color)
            showHexInput = false
            hexColorInput = ""
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - API List Item Components

struct APICategoryListItem: View {
    let category: APICategory
    let onDelete: () -> Void
    
    var body: some View {
        AppListItem(
            content: {
                HStack(spacing: 12) {
                    // Emoji
                    Text(category.emoji.isEmpty ? "🏷️" : category.emoji)
                        .font(.system(size: 20))
                    
                    // Name
                    Text(category.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            },
            trailing: {
                // Income/Expense tag
                CategoryTypeTag(isIncome: category.isIncome)
            },
            onDelete: onDelete
        )
    }
}

struct APIPaymentMethodListItem: View {
    let paymentMethod: APIPaymentMethod
    let onDelete: () -> Void
    
    var body: some View {
        AppListItem(
            content: {
                HStack(spacing: 12) {
                    // Payment method emoji (fallback to card icon)
                    if !paymentMethod.emoji.isEmpty {
                        Text(paymentMethod.emoji)
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Name
                    Text(paymentMethod.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            },
            trailing: {
                EmptyView()
            },
            onDelete: onDelete
        )
    }
}

// MARK: - Custom Manage Section Chip
struct ManageSectionChip: View {
    let section: ManageView.ManageSection
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(section.rawValue)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        // Using the public GlassChipBackground from ChipScrollStyles.swift
        .background(GlassChipBackground(isSelected: isSelected))
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Color Square Component
struct ColorSquare: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ColorBoxView(color: color)
                .frame(height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.white : Color.white.opacity(0.3),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// UIKit-based color view to bypass SwiftUI rendering issues
struct ColorBoxView: UIViewRepresentable {
    let color: Color
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.backgroundColor = UIColor(color)
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (6 digits)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}