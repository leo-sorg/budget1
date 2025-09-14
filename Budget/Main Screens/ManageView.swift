import SwiftUI
import SwiftData
import PhotosUI

@MainActor
struct ManageView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var store: BackgroundImageStore

    // Order by sortIndex, then name
    @Query(sort: [
        SortDescriptor(\Category.sortIndex, order: .forward),
        SortDescriptor(\Category.name, order: .forward)
    ]) private var categories: [Category]

    @Query(sort: [
        SortDescriptor(\PaymentMethod.sortIndex, order: .forward),
        SortDescriptor(\PaymentMethod.name, order: .forward)
    ]) private var methods: [PaymentMethod]

    @State private var newCategory = ""
    @State private var newCategoryEmoji = ""
    @State private var newCategoryIsIncome = false
    @State private var newPayment = ""
    @State private var alertMessage: String?

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
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .task { normalizeSortIndicesIfNeeded() }
        .alert("Oops", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK") { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
        .sheet(isPresented: $showCategoryForm) {
            CategoryFormSheet(
                newCategory: $newCategory,
                newCategoryEmoji: $newCategoryEmoji,
                newCategoryIsIncome: $newCategoryIsIncome,
                onAdd: addCategory,
                onClose: closeCategorySheet
            )
            .appSheetStyle()
        }
        .sheet(isPresented: $showPaymentForm) {
            PaymentFormSheet(
                newPayment: $newPayment,
                onAdd: addPayment,
                onClose: closePaymentSheet
            )
            .appSheetStyle()
        }
    }

    // MARK: - Sections using new list components
    @ViewBuilder private var categorySection: some View {
        AppListSection(
            title: "Category List",
            emptyMessage: "No categories yet. Add one above.",
            items: categories,
            onAdd: {
                showCategoryForm = true
                showPaymentForm = false
            }
        ) { category in
            CategoryListItem(
                category: category,
                onDelete: {
                    context.delete(category)
                    try? context.save()
                    renumberCategories()
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
                showPaymentForm = true
                showCategoryForm = false
            }
        ) { method in
            PaymentMethodListItem(
                paymentMethod: method,
                onDelete: {
                    context.delete(method)
                    try? context.save()
                    renumberMethods()
                }
            )
        }
    }

    @ViewBuilder private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 12) {
                PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                    Text("Choose Background")
                }
                .buttonStyle(AppButtonStyle())
                .onChange(of: pickerItem) { oldValue, newValue in
                    Task { await loadSelection(newValue) }
                }
                .task(id: pickerItem) {
                    await loadSelection(pickerItem)
                }

                if store.image != nil {
                    Button("Remove Background") {
                        store.setImage(nil)
                    }
                    .buttonStyle(AppButtonStyle())
                }
            }
        }
    }

    // MARK: - Add Functions
    @MainActor
    private func addCategory() {
        dismissKeyboard()
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
        dismissKeyboard()
        let name = trimmed(newPayment)
        guard !name.isEmpty else { return }

        if methods.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            alertMessage = "A payment method named \"\(name)\" already exists."
            return
        }

        let next = (methods.map { $0.sortIndex }.max() ?? -1) + 1
        let newPM = PaymentMethod(name: name, sortIndex: next)

        do {
            try withAnimation {
                context.insert(newPM)
                try context.save()
            }

            SHEETS.postPayment(
                remoteID: newPM.remoteID,
                name: newPM.name,
                sortIndex: newPM.sortIndex
            )

            closePaymentSheet()
        } catch {
            alertMessage = "Could not save payment method: \(error.localizedDescription)"
            print("SAVE ERROR (Payment):", error)
        }
    }

    private func closeCategorySheet() {
        dismissKeyboard()
        newCategory = ""
        newCategoryEmoji = ""
        newCategoryIsIncome = false
        showCategoryForm = false
    }

    private func closePaymentSheet() {
        dismissKeyboard()
        newPayment = ""
        showPaymentForm = false
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

// MARK: - Form sheets with glass styling
private struct CategoryFormSheet: View {
    @Binding var newCategory: String
    @Binding var newCategoryEmoji: String
    @Binding var newCategoryIsIncome: Bool
    var onAdd: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .padding(4)
                }
            }
            
            TextField("Name (e.g. Food)", text: $newCategory)
                .textFieldStyle(GlassTextFieldStyle())

            TextField("Emoji (optional)", text: $newCategoryEmoji)
                .textFieldStyle(GlassTextFieldStyle())

            Picker("Type", selection: $newCategoryIsIncome) {
                Text("Expense").tag(false)
                Text("Income").tag(true)
            }
            .pickerStyle(.segmented)
            .onChange(of: newCategoryIsIncome) { _ in dismissKeyboard() }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )

            Button("Add Category") {
                onAdd()
            }
            .buttonStyle(AppButtonStyle())
            .disabled(newCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(Color.clear)
    }
}

private struct PaymentFormSheet: View {
    @Binding var newPayment: String
    var onAdd: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .padding(4)
                }
            }
            
            TextField("Name (e.g. Credit Card, Pix)", text: $newPayment)
                .textFieldStyle(GlassTextFieldStyle())

            Button("Add Payment Type") {
                onAdd()
            }
            .buttonStyle(AppButtonStyle())
            .disabled(newPayment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(Color.clear)
    }
}
