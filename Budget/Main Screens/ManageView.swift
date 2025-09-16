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
    @State private var showHexColorSheet = false
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
                                    }
                                }
                            )
                        }
                    }
            }
            .padding() // Same as InputView sections
            
            // Content based on selected section
            ScrollView {
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
        .sheet(isPresented: $showCategoryForm) {
            BottomSheet(
                buttonTitle: "Add Category",
                buttonAction: addCategory,
                onClose: closeCategorySheet,
                isButtonDisabled: newCategory.isEmpty
            ) {
                CategorySheetContent(
                    name: $newCategory,
                    emoji: $newCategoryEmoji,
                    isIncome: $newCategoryIsIncome
                )
            }
        }
        .sheet(isPresented: $showPaymentForm) {
            BottomSheet(
                buttonTitle: "Add Payment Type",
                buttonAction: addPayment,
                onClose: closePaymentSheet,
                isButtonDisabled: newPayment.isEmpty
            ) {
                PaymentSheetContent(
                    name: $newPayment,
                    emoji: $newPaymentEmoji
                )
            }
        }
        .sheet(isPresented: $showHexColorSheet) {
            BottomSheet(
                buttonTitle: "Set Color",
                buttonAction: applyHexColor,
                onClose: { showHexColorSheet = false },
                isButtonDisabled: !isValidHex(hexColorInput)
            ) {
                HexColorSheetContent(hexInput: $hexColorInput)
            }
        }
        // Removed toolbar - sheets handle their own toolbars
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

    // MARK: - Sections using new list components
    @ViewBuilder private var categorySection: some View {
        AppListSection(
            title: "Category List",
            emptyMessage: "No categories yet. Add one above.",
            items: categories,
            onAdd: {
                // Ensure payment form is closed before opening category form
                showPaymentForm = false
                showCategoryForm = true
            }
        ) { category in
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

    @ViewBuilder private var paymentSection: some View {
        AppListSection(
            title: "Payment Type List",
            emptyMessage: "No payment methods yet. Add one above.",
            items: methods,
            onAdd: {
                // Ensure category form is closed before opening payment form
                showCategoryForm = false
                showPaymentForm = true
            }
        ) { method in
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
                        showHexColorSheet = true
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

            closeCategorySheet()
            Task { await loadData() }

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

            SHEETS.postPayment(
                remoteID: newPM.remoteID,
                name: newPM.name,
                emoji: newPM.emoji,
                sortIndex: newPM.sortIndex
            )

            closePaymentSheet()
            Task { await loadData() }
        } catch {
            alertMessage = "Could not save payment method: \(error.localizedDescription)"
            print("SAVE ERROR (Payment):", error)
        }
    }

    private func closeCategorySheet() {
        hideKeyboard()
        showCategoryForm = false
        // Reset state after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            newCategory = ""
            newCategoryEmoji = ""
            newCategoryIsIncome = false
        }
    }

    private func closePaymentSheet() {
        hideKeyboard()
        showPaymentForm = false
        // Reset state after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            newPayment = ""
            newPaymentEmoji = ""
        }
    }

    // MARK: - Reorder handlers
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
            showHexColorSheet = false
            hexColorInput = ""
        }
    }
    
    // MARK: - Helper function
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
