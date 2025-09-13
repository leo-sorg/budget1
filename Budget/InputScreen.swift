import SwiftUI
import SwiftData

struct InputScreen: View {
    @Environment(\.modelContext) private var ctx
    @State private var categories: [Category] = []
    @State private var paymentMethods: [PaymentMethod] = []

    @State private var title = ""
    @State private var amount = ""
    @State private var note = ""
    @State private var selectedCategory: Category?
    @State private var selectedMethod: PaymentMethod?

    private let chipHeight: CGFloat = 40

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // ===== KEEP YOUR EXISTING CHIPS HERE (unchanged) =====
                paymentSection
                categorySection
                // ------------------------------------------------------

                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)

                TextField("Amount", text: $amount)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)

                TextField("Note", text: $note)
                    .textFieldStyle(.roundedBorder)

                Button("Save Entry") { /* hook up your save */ }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .background(Color.clear)
        .task {
            categories = (try? ctx.fetch(FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)]))) ?? []
            paymentMethods = (try? ctx.fetch(FetchDescriptor<PaymentMethod>(sortBy: [SortDescriptor(\.name)]))) ?? []
            if categories.isEmpty || paymentMethods.isEmpty { seedDefaults() }
        }
    }

    @ViewBuilder private var paymentSection: some View {
        if paymentMethods.isEmpty {
            Button("Add default payment types") { seedDefaults(paymentsOnly: true) }
                .buttonStyle(AppButtonStyle())
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(paymentMethods) { pm in
                        Text(pm.name)
                            .appChip(isSelected: selectedMethod == pm)
                            .onTapGesture {
                                selectedMethod = pm
                                dismissKeyboard()
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.horizontal, -16)
            .frame(height: chipHeight)
        }
    }

    @ViewBuilder private var categorySection: some View {
        if categories.isEmpty {
            Button("Add default categories") { seedDefaults(categoriesOnly: true) }
                .buttonStyle(AppButtonStyle())
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    let firstRow = stride(from: 0, to: categories.count, by: 2).map { categories[$0] }
                    HStack(spacing: 8) {
                        ForEach(firstRow) { categoryChip(for: $0) }
                    }
                    let secondRow = stride(from: 1, to: categories.count, by: 2).map { categories[$0] }
                    HStack(spacing: 8) {
                        ForEach(secondRow) { categoryChip(for: $0) }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.horizontal, -16)
            .frame(height: chipHeight * 2 + 8)
        }
    }

    private func categoryChip(for cat: Category) -> some View {
        Text("\(cat.emoji ?? "") \(cat.name)")
            .appChip(isSelected: selectedCategory == cat)
            .onTapGesture {
                selectedCategory = cat
                dismissKeyboard()
            }
    }

    private func seedDefaults(categoriesOnly: Bool = false, paymentsOnly: Bool = false) {
        if !paymentsOnly && categories.isEmpty {
            let base = (categories.map { $0.sortIndex }.max() ?? -1) + 1
            let seeds: [(String, String?, Bool)] = [
                ("Food", "🍽️", false),
                ("Transport", "🚕", false),
                ("Bills", "💡", false),
                ("Shopping", "🛍️", false),
                ("Leisure", "🎬", false),
                ("Salary", "💼", true),
                ("Gifts", "🎁", true)
            ]
            for (offset, seed) in seeds.enumerated() {
                let (name, emoji, isIncome) = seed
                ctx.insert(Category(name: name, emoji: emoji, sortIndex: base + offset, isIncome: isIncome))
            }
        }
        if !categoriesOnly && paymentMethods.isEmpty {
            let base = (paymentMethods.map { $0.sortIndex }.max() ?? -1) + 1
            let seeds = ["Credit Card", "Debit Card", "Pix", "Cash"]
            for (offset, name) in seeds.enumerated() {
                ctx.insert(PaymentMethod(name: name, sortIndex: base + offset))
            }
        }
        try? ctx.save()
        categories = (try? ctx.fetch(FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)]))) ?? []
        paymentMethods = (try? ctx.fetch(FetchDescriptor<PaymentMethod>(sortBy: [SortDescriptor(\.name)]))) ?? []
    }
}
