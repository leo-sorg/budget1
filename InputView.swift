import SwiftUI
import SwiftData

struct InputView: View {
    @Environment(\.modelContext) private var context

    // Order by sortIndex for both
    @Query(sort: [
        SortDescriptor(\Category.sortIndex, order: .forward),
        SortDescriptor(\Category.name, order: .forward)
    ]) private var categories: [Category]

    @Query(sort: [
        SortDescriptor(\PaymentMethod.sortIndex, order: .forward),
        SortDescriptor(\PaymentMethod.name, order: .forward)
    ]) private var methods: [PaymentMethod]

    // Form state
    @State private var amountText = ""   // auto-formatted with R$
    @State private var date = Date()
    @State private var selectedCategory: Category?
    @State private var selectedMethod: PaymentMethod?
    @State private var note = ""
    @State private var showSavedCheck = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Value") {
                    TextField("R$ 0,00", text: $amountText)
                        .keyboardType(.numberPad)
                        // iOS 17+ uses the two-parameter version:
                        .onChange(of: amountText) { _, newValue in
                            formatAsCurrency(newValue, showCurrencySymbol: true)
                        }
                }

                Section("Date") {
                    DatePicker("When", selection: $date, displayedComponents: .date)
                }

                Section("Payment type") {
                    if methods.isEmpty {
                        Button("Add default payment types") { seedDefaults(paymentsOnly: true) }
                    } else {
                        Picker("Payment", selection: $selectedMethod) {
                            Text("Choose…").tag(PaymentMethod?.none)
                            ForEach(methods) { pm in
                                Text(pm.name).tag(PaymentMethod?.some(pm))
                            }
                        }
                    }
                }

                Section("Category") {
                    if categories.isEmpty {
                        Button("Add default categories") { seedDefaults(categoriesOnly: true) }
                    } else {
                        Picker("Category", selection: $selectedCategory) {
                            Text("Choose…").tag(Category?.none)
                            ForEach(categories) { cat in
                                Text("\(cat.emoji ?? "🏷️") \(cat.name)")
                                    .tag(Category?.some(cat))
                            }
                        }
                    }
                }

                Section("Note") { TextField("Optional", text: $note) }

                Section {
                    Button(action: save) {
                        HStack { Spacer(); Text("Save expense").fontWeight(.semibold); Spacer() }
                    }
                    .disabled(!canSave)
                }
            }
            .navigationTitle("Input")
            .task {
                if categories.isEmpty || methods.isEmpty { seedDefaults() }
            }
            .alert("Saved ✔︎", isPresented: $showSavedCheck) { Button("OK", role: .cancel) { } }
        }
    }

    // MARK: - Validation
    private var canSave: Bool { amountDecimal != nil }
    private var amountDecimal: Decimal? {
        let digits = amountText.filter(\.isNumber)
        guard !digits.isEmpty, let intVal = Decimal(string: digits) else { return nil }
        return intVal / 100
    }

    // MARK: - Actions
    private func save() {
        guard let amount = amountDecimal else { return }
        let tx = Transaction(amount: amount, date: date,
                             note: note.isEmpty ? nil : note,
                             category: selectedCategory,
                             paymentMethod: selectedMethod)
        context.insert(tx)
        try? context.save()
        amountText = ""; note = ""; date = Date()
        showSavedCheck = true
    }

    private func seedDefaults(categoriesOnly: Bool = false,
                              paymentsOnly: Bool = false) {
        if !paymentsOnly && categories.isEmpty {
            let base = (categories.map { $0.sortIndex }.max() ?? -1) + 1
            let seeds: [(String, String?)] = [
                ("Food", "🍽️"), ("Transport", "🚕"),
                ("Bills", "💡"), ("Shopping", "🛍️"),
                ("Leisure", "🎬")
            ]
            for (offset, pair) in seeds.enumerated() {
                let (name, emoji) = pair
                context.insert(Category(name: name, emoji: emoji, sortIndex: base + offset))
            }
        }
        if !categoriesOnly && methods.isEmpty {
            let base = (methods.map { $0.sortIndex }.max() ?? -1) + 1
            let seeds = ["Credit Card", "Debit Card", "Pix", "Cash"]
            for (offset, name) in seeds.enumerated() {
                context.insert(PaymentMethod(name: name, sortIndex: base + offset))
            }
        }
        try? context.save()
    }

    // MARK: - Currency formatter
    private func formatAsCurrency(_ newValue: String, showCurrencySymbol: Bool) {
        let digits = newValue.filter(\.isNumber)
        guard !digits.isEmpty else { amountText = ""; return }
        let intValue = Decimal(string: digits) ?? 0
        let value = intValue / 100
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "pt_BR")
        if !showCurrencySymbol { f.currencySymbol = "" }
        amountText = f.string(for: NSDecimalNumber(decimal: value))?
            .trimmingCharacters(in: .whitespaces) ?? ""
    }
}
