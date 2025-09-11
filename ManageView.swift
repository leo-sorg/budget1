import SwiftUI
import SwiftData

struct ManageView: View {
    @Environment(\.modelContext) private var context

    // Order by sortIndex, then name as tie-breaker
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
    @State private var newPayment = ""
    @State private var alertMessage: String?
    @FocusState private var focusedField: Field?

    enum Field { case catName, catEmoji, payment }

    var body: some View {
        NavigationStack {
            Form {
                // CATEGORIES
                Section("Categories (drag to reorder)") {
                    if categories.isEmpty {
                        Text("No categories yet. Add one below.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(categories) { c in
                            HStack {
                                Text(c.emoji ?? "🏷️")
                                Text(c.name)
                                Spacer()
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

                    // Add category
                    VStack(spacing: 8) {
                        HStack {
                            TextField("Name (e.g. Food)", text: $newCategory)
                                .textInputAutocapitalization(.words)
                                .focused($focusedField, equals: .catName)
                            TextField("Emoji (optional)", text: $newCategoryEmoji)
                                .frame(maxWidth: 120)
                                .focused($focusedField, equals: .catEmoji)
                        }
                        Button("Add category", action: addCategory)
                            .disabled(trimmed(newCategory).isEmpty)
                    }
                }

                // PAYMENT METHODS
                Section("Payment Methods (drag to reorder)") {
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

                    // Add payment method
                    HStack {
                        TextField("Name (e.g. Credit Card, Pix)", text: $newPayment)
                            .textInputAutocapitalization(.words)
                            .focused($focusedField, equals: .payment)
                        Button("Add", action: addPayment)
                            .disabled(trimmed(newPayment).isEmpty)
                    }
                }
            }
            .navigationTitle("Manage")
            .toolbar { EditButton() } // enables drag handles
            .task {
                normalizeSortIndicesIfNeeded()
            }
            .alert("Oops", isPresented: .constant(alertMessage != nil)) {
                Button("OK") { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    // MARK: - Add

    private func addCategory() {
        let name = trimmed(newCategory)
        let emoji = trimmed(newCategoryEmoji)
        guard !name.isEmpty else { return }

        if categories.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            alertMessage = "A category named “\(name)” already exists."
            return
        }

        let next = (categories.map { $0.sortIndex }.max() ?? -1) + 1
        context.insert(Category(name: name, emoji: emoji.isEmpty ? nil : emoji, sortIndex: next))
        do {
            try context.save()
            newCategory = ""; newCategoryEmoji = ""
            focusedField = .catName
        } catch {
            alertMessage = "Could not save category: \(error.localizedDescription)"
            print("SAVE ERROR (Category):", error)
        }
    }

    private func addPayment() {
        let name = trimmed(newPayment)
        guard !name.isEmpty else { return }

        if methods.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            alertMessage = "A payment method named “\(name)” already exists."
            return
        }

        let next = (methods.map { $0.sortIndex }.max() ?? -1) + 1
        context.insert(PaymentMethod(name: name, sortIndex: next))
        do {
            try context.save()
            newPayment = ""
            focusedField = .payment
        } catch {
            alertMessage = "Could not save payment method: \(error.localizedDescription)"
            print("SAVE ERROR (Payment):", error)
        }
    }

    // MARK: - Reorder handlers

    private func moveCategory(from source: IndexSet, to destination: Int) {
        var reordered = categories
        reordered.move(fromOffsets: source, toOffset: destination)
        for (idx, cat) in reordered.enumerated() { cat.sortIndex = idx }
        try? context.save()
    }

    private func moveMethod(from source: IndexSet, to destination: Int) {
        var reordered = methods
        reordered.move(fromOffsets: source, toOffset: destination)
        for (idx, m) in reordered.enumerated() { m.sortIndex = idx }
        try? context.save()
    }

    private func renumberCategories() {
        for (idx, c) in categories.enumerated() { c.sortIndex = idx }
        try? context.save()
    }

    private func renumberMethods() {
        for (idx, m) in methods.enumerated() { m.sortIndex = idx }
        try? context.save()
    }

    // Normalize after migrations (if all are 0)
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
