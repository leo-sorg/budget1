import SwiftUI
import SwiftData
import PhotosUI
import Foundation
#if canImport(UIKit)
import UIKit
#endif

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

    // NEW: Delete confirmation states
    @State private var showDeleteCategoryConfirmation = false
    @State private var showDeletePaymentConfirmation = false
    @State private var categoryToDelete: APICategory?
    @State private var paymentMethodToDelete: APIPaymentMethod?
    @State private var deletingCategoryID: String?
    @State private var deletingPaymentID: String?

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
    
    // Namespace for morphing effects
    @Namespace private var manageSectionNamespace
    @Namespace private var categoryTypeNamespace

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
                                },
                                namespace: manageSectionNamespace
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
            .refreshable {
                await refreshCurrentSection()
            }
        }
        .background {
            AppAppearance.shared.appBackgroundColor
                .ignoresSafeArea(.all)
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
        // NEW: Delete confirmation dialogs
        .confirmationDialog(
            "Delete Category",
            isPresented: $showDeleteCategoryConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let category = categoryToDelete {
                    deleteCategory(category)
                }
            }
            Button("Cancel", role: .cancel) {
                categoryToDelete = nil
            }
        } message: {
            if let category = categoryToDelete {
                Text("Are you sure you want to delete \"\(category.name)\"? This action cannot be undone.")
            }
        }
        .confirmationDialog(
            "Delete Payment Method",
            isPresented: $showDeletePaymentConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let method = paymentMethodToDelete {
                    deletePaymentMethod(method)
                }
            }
            Button("Cancel", role: .cancel) {
                paymentMethodToDelete = nil
            }
        } message: {
            if let method = paymentMethodToDelete {
                Text("Are you sure you want to delete \"\(method.name)\"? This action cannot be undone.")
            }
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

    // MARK: - Delete Functions

    private func deleteCategory(_ category: APICategory) {
            deletingCategoryID = category.remoteID
            
            if useMockData {
                // Simulate API delay for mock
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Remove from local array
                    if let index = self.categories.firstIndex(where: { $0.remoteID == category.remoteID }) {
                        withAnimation {
                            self.categories.remove(at: index)
                        }
                    }
                    self.deletingCategoryID = nil
                    self.categoryToDelete = nil
                }
            } else {
                SHEETS.deleteCategory(remoteID: category.remoteID) { response in
                    DispatchQueue.main.async {
                        self.deletingCategoryID = nil
                        self.categoryToDelete = nil
                        
                        if response.status == 200 {
                            // Remove from local array immediately for fast UI update (no full reload)
                            if let index = self.categories.firstIndex(where: { $0.remoteID == category.remoteID }) {
                                withAnimation {
                                    self.categories.remove(at: index)
                                }
                            }
                            
                            // NO FULL RELOAD: Removed self.fetchCategories() call
                            // The item is already removed from the UI for fast feedback
                        } else {
                            // Show error
                            self.alertMessage = "Failed to delete category: \(response.body)"
                        }
                    }
                }
            }
        }
        
        private func deletePaymentMethod(_ method: APIPaymentMethod) {
            deletingPaymentID = method.remoteID
            
            if useMockData {
                // Simulate API delay for mock
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Remove from local array
                    if let index = self.methods.firstIndex(where: { $0.remoteID == method.remoteID }) {
                        withAnimation {
                            self.methods.remove(at: index)
                        }
                    }
                    self.deletingPaymentID = nil
                    self.paymentMethodToDelete = nil
                }
            } else {
                SHEETS.deletePaymentMethod(remoteID: method.remoteID) { response in
                    DispatchQueue.main.async {
                        self.deletingPaymentID = nil
                        self.paymentMethodToDelete = nil
                        
                        if response.status == 200 {
                            // Remove from local array immediately for fast UI update (no full reload)
                            if let index = self.methods.firstIndex(where: { $0.remoteID == method.remoteID }) {
                                withAnimation {
                                    self.methods.remove(at: index)
                                }
                            }
                            
                            // NO FULL RELOAD: Removed self.fetchPaymentMethods() call
                            // The item is already removed from the UI for fast feedback
                        } else {
                            // Show error
                            self.alertMessage = "Failed to delete payment method: \(response.body)"
                        }
                    }
                }
            }
        }
    
    // MARK: - Data Loading Functions (unchanged)
    
    private func loadDataForCurrentSection() {
        switch selectedSection {
        case .categories:
            fetchCategories()
        case .payments:
            fetchPaymentMethods()
        case .background:
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
                    } else {
                        self.categoriesError = response.message
                    }
                    
                case .failure(let error):
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
                    } else {
                        self.paymentMethodsError = response.message
                    }
                    
                case .failure(let error):
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

    // MARK: - Category Section with DELETE functionality
    @ViewBuilder private var categorySection: some View {
        VStack(spacing: 24) {
            // Add/Edit form (keep this part exactly the same)
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
                                hideKeyboard()
                            }
                        }
                    }
                    .appSmallButtonStyle()
                }
                
                if showCategoryForm {
                    // Keep all your existing form code here
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
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Type")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            ChipGroup {  // ← Add this wrapper from ChipScrollStyles.swift
                                HStack(spacing: 12) {
                                    LiquidGlassChip(
                                        title: "Expense",
                                        isSelected: !newCategoryIsIncome,
                                        onTap: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                newCategoryIsIncome = false
                                            }
                                            hideKeyboard()
                                        },
                                        namespace: categoryTypeNamespace
                                    )
                                    
                                    LiquidGlassChip(
                                        title: "Income",
                                        isSelected: newCategoryIsIncome,
                                        onTap: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                newCategoryIsIncome = true
                                            }
                                            hideKeyboard()
                                        },
                                        namespace: categoryTypeNamespace
                                    )
                                }
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
                                    
                                    // UPDATED: Category list with DELETE functionality
            if isLoadingCategories {
                        loadingView
                    } else if let error = categoriesError {
                        errorView(message: error, retryAction: fetchCategories)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Category List")
                                .font(.headline)
                                .foregroundColor(.appText)
                            
                            if categories.isEmpty {
                                Text("No categories found. Add one above or pull to refresh.")
                                    .foregroundColor(.appText.opacity(0.6))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                List {
                                    ForEach(categories, id: \.remoteID) { category in
                                        APICategoryListItem(category: category)
                                            .opacity(deletingCategoryID == category.remoteID ? 0.6 : 1.0)
                                            .listRowBackground(Color.clear)
                                            .listRowSeparator(.hidden)
                                            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                                    }
                                    .onDelete { indexSet in
                                        for index in indexSet {
                                            let category = categories[index]
                                            categoryToDelete = category
                                            showDeleteCategoryConfirmation = true
                                        }
                                    }
                                }
                                .listStyle(.plain)
                                .scrollContentBackground(.hidden)
                                .frame(height: CGFloat(categories.count * 80))
                            }
                        }
                    }
                }
            }

                            // MARK: - Payment Section with DELETE functionality
                            @ViewBuilder private var paymentSection: some View {
                                VStack(spacing: 24) {
                                    // Add/Edit form (keep this part exactly the same)
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
                                                        hideKeyboard()
                                                    }
                                                }
                                            }
                                            .appSmallButtonStyle()
                                        }
                                        
                                        if showPaymentForm {
                                            // Keep all your existing form code here
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
                                    
                                    // UPDATED: Payment method list with DELETE functionality
                                    if isLoadingPaymentMethods {
                                        loadingView
                                    } else if let error = paymentMethodsError {
                                        errorView(message: error, retryAction: fetchPaymentMethods)
                                    } else {
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text("Payment Type List")
                                                .font(.headline)
                                                .foregroundColor(.appText)
                                            
                                            if methods.isEmpty {
                                                Text("No payment methods found. Add one above or pull to refresh.")
                                                    .foregroundColor(.appText.opacity(0.6))
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            } else {
                                                VStack(spacing: 8) {
                                                    ForEach(methods, id: \.remoteID) { method in
                                                        // NEW: Enhanced payment method list item with delete functionality
                                                        EnhancedAPIPaymentMethodListItem(
                                                            paymentMethod: method,
                                                            isDeleting: deletingPaymentID == method.remoteID,
                                                            onDelete: {
                                                                paymentMethodToDelete = method
                                                                showDeletePaymentConfirmation = true
                                                            }
                                                        )
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // MARK: - Background section (unchanged)
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
                                            ForEach(Array(presetColors.enumerated()), id: \.offset) { _, colorTuple in
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
                                        .appButtonStyle()
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
                                            .appButtonStyle()
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
                                    .appSmallButtonStyle()
                                }
                                .frame(maxWidth: .infinity, minHeight: 200)
                            }

                            // MARK: - Async Add Functions (unchanged)
                            @MainActor
                            private func performAddCategory() async -> Bool {
                                hideKeyboard()
                                let name = trimmed(newCategory)
                                let emoji = trimmed(newCategoryEmoji)
                                guard !name.isEmpty else { return false }

                                if categories.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                                    alertMessage = "A category named \"\(name)\" already exists."
                                    return false
                                }

                                if useMockData {
                                    await mockAddDelay()
                                    self.newCategory = ""
                                    self.newCategoryEmoji = ""
                                    self.newCategoryIsIncome = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        withAnimation { self.showCategoryForm = false }
                                    }
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

                                if methods.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
                                    alertMessage = "A payment method named \"\(name)\" already exists."
                                    return false
                                }

                                if useMockData {
                                    await mockAddDelay()
                                    self.newPayment = ""
                                    self.newPaymentEmoji = ""
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        withAnimation { self.showPaymentForm = false }
                                    }
                                    self.methods = self.getMockPaymentMethods()
                                    return true
                                } else {
                                    return await performRealAddPayment(name: name, emoji: emoji)
                                }
                            }
                            
                            @MainActor
                            private func performRealAddCategory(name: String, emoji: String) async -> Bool {
                                let next = (categories.map { $0.sortIndex }.max() ?? -1) + 1
                                let remoteID = UUID().uuidString

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
                                                self.newCategory = ""
                                                self.newCategoryEmoji = ""
                                                self.newCategoryIsIncome = false
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                    withAnimation { self.showCategoryForm = false }
                                                }
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

                                return await withCheckedContinuation { continuation in
                                    SHEETS.postPayment(
                                        remoteID: remoteID,
                                        name: name,
                                        emoji: emoji.isEmpty ? nil : emoji,
                                        sortIndex: next
                                    ) { response in
                                        DispatchQueue.main.async {
                                            if response.status == 200 {
                                                self.newPayment = ""
                                                self.newPaymentEmoji = ""
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                                    withAnimation { self.showPaymentForm = false }
                                                }
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
                            
                            // MARK: - Mock Data Functions (unchanged)
                            private func getMockCategories() -> [APICategory] {
                                let mockJSON = """
                                [
                                    {
                                        "remoteID": "mock-cat-1",
                                        "name": "Food",
                                        "emoji": "🍕",
                                        "sortIndex": 0,
                                        "isIncome": false,
                                        "timestamp": "2025-09-17T12:00:00.000Z"
                                    },
                                    {
                                        "remoteID": "mock-cat-2",
                                        "name": "Transport",
                                        "emoji": "🚗",
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
                                        "remoteID": "mock-cat-7",
                                        "name": "Salary",
                                        "emoji": "💼",
                                        "sortIndex": 6,
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
                                        "name": "Pix",
                                        "emoji": "📱",
                                        "sortIndex": 1,
                                        "timestamp": "2025-09-17T12:00:00.000Z"
                                    },
                                    {
                                        "remoteID": "mock-pm-3",
                                        "name": "Cash",
                                        "emoji": "💵",
                                        "sortIndex": 2,
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
                            
                            private func mockAddDelay() async {
                                try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
                            }

                            // MARK: - Helper Functions (unchanged)
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
                                if let color = Color.fromHex(cleanHex) {
                                    store.setColor(color)
                                    showHexInput = false
                                    hexColorInput = ""
                                }
                            }
                            
                            private func hideKeyboard() {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }

                        // MARK: - NEW Enhanced List Item Components with Delete Animation

                        struct EnhancedAPICategoryListItem: View {
                            let category: APICategory
                            let isDeleting: Bool
                            let onDelete: () -> Void
                            
                            var body: some View {
                                HStack(spacing: 12) {
                                    // Category emoji or fallback icon
                                    if isValidEmoji(category.emoji) {
                                        Text(category.emoji)
                                            .font(.system(size: 20))
                                    } else {
                                        Image(systemName: "tag.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    // Category name
                                    Text(category.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    // Type tag
                                    CategoryTypeTag(isIncome: category.isIncome)
                                    
                                    // Delete button with loading state
                                    if isDeleting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.6)
                                    } else {
                                        Button(action: onDelete) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.clear)
                                .glassEffect(.regular, in: .rect(cornerRadius: 10))
                                .opacity(isDeleting ? 0.6 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isDeleting)
                            }
                        }

                        struct EnhancedAPIPaymentMethodListItem: View {
                            let paymentMethod: APIPaymentMethod
                            let isDeleting: Bool
                            let onDelete: () -> Void
                            
                            var body: some View {
                                HStack(spacing: 12) {
                                    // Payment method emoji or fallback icon
                                    if isValidEmoji(paymentMethod.emoji) {
                                        Text(paymentMethod.emoji)
                                            .font(.system(size: 20))
                                    } else {
                                        Image(systemName: "creditcard.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    // Payment method name
                                    Text(paymentMethod.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    // Delete button with loading state
                                    if isDeleting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.6)
                                    } else {
                                        Button(action: onDelete) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.clear)
                                .glassEffect(.regular, in: .rect(cornerRadius: 10))
                                .opacity(isDeleting ? 0.6 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isDeleting)
                            }
                        }

                        // MARK: - Helper Components (unchanged)
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

                        // Helper function for emoji validation
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
