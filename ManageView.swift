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
    @State private var newCategoryIsIncome: Bool? = nil
    @State private var newPayment = ""
    @State private var alertMessage: String?

    @State private var showingCategories = true
    @State private var showCategoryForm = false
    @State private var showPaymentForm = false

    var body: some View {
        NavigationStack {
            VStack {
                Picker("", selection: $showingCategories) {
                    Text("Categories").tag(true)
                    Text("Payment Types").tag(false)
                }
                .pickerStyle(.segmented)
                .padding()

                Form {
                    if showingCategories {
                        categorySection
                    } else {
                        paymentSection
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.appBackground)
                .listRowBackground(Color.appSecondaryBackground)
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle("Manage")
            .toolbar { EditButton() }
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
        .background(Color.appBackground)
        .foregroundColor(.appText)
        .tint(.appAccent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
    }

    // MARK: - Sections
    @ViewBuilder private var categorySection: some View {
        Section {
            if categories.isEmpty {
                Text("No categories yet. Add one below.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(categories) { c in
                    HStack {
                        Text(c.emoji ?? "🏷️")
                        Text(c.name)
                        Spacer()
                        Text(c.isIncome ? "+" : "-")
                            .foregroundStyle(c.isIncome ? .green : .red)
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

            if showCategoryForm {
                VStack(alignment: .leading, spacing: 12) {
                    AccessoryTextField(
                        text: $newCategory,
                        placeholder: "Name (e.g. Food)",
                        onCancel: { newCategory = "" },
                        onDone: { },
                        autocapitalization: .words
                    )
                    AccessoryTextField(
                        text: $newCategoryEmoji,
                        placeholder: "Emoji (optional)",
                        onCancel: { newCategoryEmoji = "" },
                        onDone: { },
                        prefersEmoji: true
                    )
                    Picker("Type", selection: $newCategoryIsIncome) {
                        Text("Choose…").tag(Bool?.none)
                        ForEach([false, true], id: \.self) { isIncome in
                            Text(isIncome ? "Income" : "Expense")
                                .tag(Bool?.some(isIncome))
                        }
                    }
                    .onChange(of: newCategoryIsIncome) { _ in dismissKeyboard() }
                    Button("Add category", action: addCategory)
                        .buttonStyle(.borderedProminent)
                        .tint(.gray.opacity(0.3))
                        .foregroundStyle(Color.appAccent)
                        .disabled(trimmed(newCategory).isEmpty || newCategoryIsIncome == nil)
                }
                .transition(.opacity)
                .padding(.top, 8)
            }
        } header: {
            HStack {
                Text("Categories (drag to reorder)")
                Spacer()
                Button {
                    withAnimation { showCategoryForm.toggle() }
                } label: {
                    Image(systemName: showCategoryForm ? "xmark" : "plus")
                }
            }
        }
    }

    @ViewBuilder private var paymentSection: some View {
        Section {
            if methods.isEmpty {
                Text("No payment methods yet. Add one below.")
                    .foregroundStyle(.secondary)
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

            if showPaymentForm {
                VStack(alignment: .leading, spacing: 12) {
                    AccessoryTextField(
                        text: $newPayment,
                        placeholder: "Name (e.g. Credit Card, Pix)",
                        onCancel: { newPayment = "" },
                        onDone: { },
                        autocapitalization: .words
                    )
                    Button("Add", action: addPayment)
                        .buttonStyle(.borderedProminent)
                        .tint(.gray.opacity(0.3))
                        .foregroundStyle(Color.appAccent)
                        .disabled(trimmed(newPayment).isEmpty)
                }
                .transition(.opacity)
                .padding(.top, 8)
            }
        } header: {
            HStack {
                Text("Payment Methods (drag to reorder)")
                Spacer()
                Button {
                    withAnimation { showPaymentForm.toggle() }
                } label: {
                    Image(systemName: showPaymentForm ? "xmark" : "plus")
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

        guard let isIncome = newCategoryIsIncome else { return }

        let next = (categories.map { $0.sortIndex }.max() ?? -1) + 1
        let newCat = Category(
            name: name,
            emoji: emoji.isEmpty ? nil : emoji,
            sortIndex: next,
            isIncome: isIncome
        )

        do {
            try withAnimation {
                context.insert(newCat)
                try context.save()
            }

            SHEETS.postCategory(
                remoteID: newCat.remoteID,
                name: newCat.name,
                emoji: newCat.emoji,
                sortIndex: newCat.sortIndex,
                isIncome: newCat.isIncome
            )

            newCategory = ""; newCategoryEmoji = ""; newCategoryIsIncome = nil
            withAnimation { showCategoryForm = false }
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

            newPayment = ""
            withAnimation { showPaymentForm = false }
        } catch {
            alertMessage = "Could not save payment method: \(error.localizedDescription)"
            print("SAVE ERROR (Payment):", error)
        }
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

