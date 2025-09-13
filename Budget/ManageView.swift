import SwiftUI
import SwiftData
import UIKit

@MainActor
struct ManageView: View {
    @Environment(\.modelContext) private var context

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

    @State private var showingCategories = true
    @State private var showCategoryForm = false
    @State private var showPaymentForm = false

    var body: some View {
        NavigationStack {
            Form {
                Picker("", selection: $showingCategories) {
                    Text("Categories").tag(true)
                    Text("Payment Types").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 8)

                if showingCategories {
                    categorySection
                } else {
                    paymentSection
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .listRowBackground(Color.appSecondaryBackground)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Manage")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    EditButton()
                }
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
        }
        .background(Color.clear)
        .foregroundColor(.appText)
        .tint(.appAccent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
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

    // MARK: - Sections
    @ViewBuilder private var categorySection: some View {
        Section {
            if categories.isEmpty {
                Text("No categories yet. Add one below.")
                    .foregroundColor(Color.appText.opacity(0.6))
            } else {
                ForEach(categories) { c in
                    HStack {
                        Text(c.emoji ?? "🏷️")
                        Text(c.name)
                        Spacer()
                        Text(c.isIncome ? "+" : "-")
                            .foregroundColor(Color.appAccent)
                        Button(role: .destructive) {
                            context.delete(c)
                            try? context.save()
                            renumberCategories()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .onDelete { idx in
                    for i in idx { context.delete(categories[i]) }
                    try? context.save()
                    renumberCategories()
                }
                .onMove(perform: moveCategory)
            }
        } header: {
            HStack {
                Text("Categories (drag to reorder)")
                Spacer()
                Button {
                    showCategoryForm = true
                    showPaymentForm = false
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    @ViewBuilder private var paymentSection: some View {
        Section {
            if methods.isEmpty {
                Text("No payment methods yet. Add one below.")
                    .foregroundColor(Color.appText.opacity(0.6))
            } else {
                ForEach(methods) { m in
                    HStack {
                        Text(m.name)
                        Spacer()
                        Button(role: .destructive) {
                            context.delete(m)
                            try? context.save()
                            renumberMethods()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .onDelete { idx in
                    for i in idx { context.delete(methods[i]) }
                    try? context.save()
                    renumberMethods()
                }
                .onMove(perform: moveMethod)
            }
        } header: {
            HStack {
                Text("Payment Methods (drag to reorder)")
                Spacer()
                Button {
                    showPaymentForm = true
                    showCategoryForm = false
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    // MARK: - Add
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
    private func moveCategory(from source: IndexSet, to destination: Int) {
        var reordered = categories
        reordered.move(fromOffsets: source, toOffset: destination)
        for (idx, cat) in reordered.enumerated() { cat.sortIndex = idx }
        try? context.save()
    }

    @MainActor
    private func moveMethod(from source: IndexSet, to destination: Int) {
        var reordered = methods
        reordered.move(fromOffsets: source, toOffset: destination)
        for (idx, m) in reordered.enumerated() { m.sortIndex = idx }
        try? context.save()
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

    // MARK: - Helpers
    private func trimmed(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

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
            AccessoryTextField(
                text: $newCategory,
                placeholder: "Name (e.g. Food)",
                onCancel: { newCategory = "" },
                onDone: { },
                autocapitalization: .words
            )
            .appTextField()

            AccessoryTextField(
                text: $newCategoryEmoji,
                placeholder: "Emoji (optional)",
                onCancel: { newCategoryEmoji = "" },
                onDone: { },
                prefersEmoji: true
            )
            .appTextField()

            Picker("Type", selection: $newCategoryIsIncome) {
                Text("Expense").tag(false)
                Text("Income").tag(true)
            }
            .pickerStyle(.segmented)
            .onChange(of: newCategoryIsIncome) { _ in dismissKeyboard() }
            .appTextField()

            Button(action: onAdd) {
                Text("Add Category")
            }
            .buttonStyle(AppButtonStyle())
            .disabled(newCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
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
            AccessoryTextField(
                text: $newPayment,
                placeholder: "Name (e.g. Credit Card, Pix)",
                onCancel: { newPayment = "" },
                onDone: { },
                autocapitalization: .words
            )
            .appTextField()

            Button(action: onAdd) {
                Text("Add Payment Type")
            }
            .buttonStyle(AppButtonStyle())
            .disabled(newPayment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
}


