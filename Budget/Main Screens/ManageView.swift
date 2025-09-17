import SwiftUI
import SwiftData
import PhotosUI

@MainActor
struct ManageView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var store: BackgroundImageStore

    // Use @State instead of @Query to avoid migration issues
    @State private var categories: [Category] = []
    @State private var methods: [PaymentMethod] = []

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
            
            // Content based on selected section
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
            // REMOVED: .scrollDismissesKeyboard(.interactively) - this was interfering with scroll detection
        }
        .task {
            await loadData()
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

    // MARK: - Data Loading
    @MainActor
    private func loadData() async {
        do {
            // Load categories
            let categoryDescriptor = FetchDescriptor<Category>(
                sortBy: [
                    SortDescriptor(\Category.sortIndex, order: .forward),
                    SortDescriptor(\Category.name, order: .forward)
                ]
            )
            categories = try context.fetch(categoryDescriptor)
            
            // Load payment methods
            let paymentDescriptor = FetchDescriptor<PaymentMethod>(
                sortBy: [
                    SortDescriptor(\PaymentMethod.sortIndex, order: .forward),
                    SortDescriptor(\PaymentMethod.name, order: .forward)
                ]
            )
            methods = try context.fetch(paymentDescriptor)
            
            normalizeSortIndicesIfNeeded()
        } catch {
            print("Error loading data: \(error)")
            alertMessage = "Could not load data: \(error.localizedDescription)"
        }
    }

    // MARK: - Category Section with inline form
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
                        
                        // Add button
                        Button("Add Category") {
                            addCategory()
                        }
                        .buttonStyle(AppButtonStyle())
                        .disabled(newCategory.isEmpty)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
            
            // Category list with improved scrolling
            VStack(alignment: .leading, spacing: 16) {
                Text("Category List")
                    .font(.headline)
                    .foregroundColor(.appText)
                
                if categories.isEmpty {
                    Text("No categories yet. Add one above.")
                        .foregroundColor(.appText.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(categories) { category in
                            CategoryListItem(
                                category: category,
                                onDelete: {
                                    context.delete(category)
                                    try? context.save()
                                    Task { await loadData() }
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - Payment Section with inline form
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
                        
                        // Add button
                        Button("Add Payment Type") {
                            addPayment()
                        }
                        .buttonStyle(AppButtonStyle())
                        .disabled(newPayment.isEmpty)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
            
            // Payment list with improved scrolling
            VStack(alignment: .leading, spacing: 16) {
                Text("Payment Type List")
                    .font(.headline)
                    .foregroundColor(.appText)
                
                if methods.isEmpty {
                    Text("No payment methods yet. Add one above.")
                        .foregroundColor(.appText.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(methods) { method in
                            PaymentMethodListItem(
                                paymentMethod: method,
                                onDelete: {
                                    context.delete(method)
                                    try? context.save()
                                    Task { await loadData() }
                                }
                            )
                        }
                    }
                }
            }
        }
    }

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
                    
                    Button("Set Color") {
                        applyHexColor()
                    }
                    .buttonStyle(AppButtonStyle())
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

    // MARK: - Add Functions
    @MainActor
    private func addCategory() {
        hideKeyboard()
        let name = trimmed(newCategory)
        let emoji = trimmed(newCategoryEmoji)
        guard !name.isEmpty else { return }

        if categories.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            alertMessage = "A category named \"\(name)\" already exists."
            return
        }

        let next = (categories.map { $0.sortIndex }.max() ?? -1) + 1
        let newCat = Category(
            name: name,
            emoji: emoji.isEmpty ? nil : emoji,
            sortIndex: next,
            isIncome: newCategoryIsIncome
        )

        do {
            try withAnimation {
                context.insert(newCat)
                try context.save()
            }

            // Reset form
            newCategory = ""
            newCategoryEmoji = ""
            newCategoryIsIncome = false
            showCategoryForm = false
            Task { await loadData() }

            // UPDATED: Using correct API call for new script
            Task {
                SHEETS.postCategory(
                    remoteID: newCat.remoteID,
                    name: newCat.name,
                    emoji: newCat.emoji,
                    sortIndex: newCat.sortIndex,
                    isIncome: newCat.isIncome
                )
            }
        } catch {
            alertMessage = "Could not save category: \(error.localizedDescription)"
            print("SAVE ERROR (Category):", error)
        }
    }

    @MainActor
    private func addPayment() {
        hideKeyboard()
        let name = trimmed(newPayment)
        let emoji = trimmed(newPaymentEmoji)
        guard !name.isEmpty else { return }

        if methods.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            alertMessage = "A payment method named \"\(name)\" already exists."
            return
        }

        let next = (methods.map { $0.sortIndex }.max() ?? -1) + 1
        let newPM = PaymentMethod(
            name: name,
            emoji: emoji.isEmpty ? nil : emoji,
            sortIndex: next
        )

        do {
            try withAnimation {
                context.insert(newPM)
                try context.save()
            }

            // UPDATED: Using correct API call for new script
            SHEETS.postPayment(
                remoteID: newPM.remoteID,
                name: newPM.name,
                emoji: newPM.emoji,
                sortIndex: newPM.sortIndex
            )

            // Reset form
            newPayment = ""
            newPaymentEmoji = ""
            showPaymentForm = false
            Task { await loadData() }
        } catch {
            alertMessage = "Could not save payment method: \(error.localizedDescription)"
            print("SAVE ERROR (Payment):", error)
        }
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
    
    @MainActor
    private func renumberCategories() {
        for (idx, c) in categories.enumerated() { c.sortIndex = idx }
        try? context.save()
    }

    @MainActor
    private func renumberMethods() {
        for (idx, m) in methods.enumerated() { m.sortIndex = idx }
        try? context.save()
    }

    @MainActor
    private func normalizeSortIndicesIfNeeded() {
        if !categories.isEmpty, Set(categories.map { $0.sortIndex }).count == 1 {
            renumberCategories()
        }
        if !methods.isEmpty, Set(methods.map { $0.sortIndex }).count == 1 {
            renumberMethods()
        }
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

// MARK: - Custom Color Square Component using UIKit
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
        view.layer.cornerRadius = 4  // Can be adjusted via parameter if needed
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
