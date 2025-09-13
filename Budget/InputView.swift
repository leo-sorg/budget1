import SwiftUI
import SwiftData

// MARK: - Main InputView
@MainActor
struct InputView: View {
    @Environment(\.modelContext) private var ctx
    @State private var categories: [Category] = []
    @State private var paymentMethods: [PaymentMethod] = []
    @State private var amountText = ""
    @State private var date = Date()
    @State private var selectedCategory: Category?
    @State private var selectedMethod: PaymentMethod?
    @State private var descriptionText = ""
    @State private var showSavedToast = false
    @State private var alertMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                valueSection
                descriptionSection
                paymentTypeSection
                categorySection
                dateSection
                saveSection
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .scrollDismissesKeyboard(.interactively)
        .overlay(alignment: .top) { toastOverlay }
        .animation(.default, value: showSavedToast)
        .alert("Oops", isPresented: alertBinding) {
            Button("OK") { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
        .task {
            categories = (try? ctx.fetch(FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)]))) ?? []
            paymentMethods = (try? ctx.fetch(FetchDescriptor<PaymentMethod>(sortBy: [SortDescriptor(\.name)]))) ?? []
            if categories.isEmpty || paymentMethods.isEmpty { seedDefaults() }
        }
    }
    
    // MARK: - Section Views
    @ViewBuilder private var valueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Value")
                .font(.headline)
                .foregroundColor(.appText)
            
            TextField("R$ 0,00", text: $amountText)
                .keyboardType(.decimalPad)
                .textFieldStyle(GlassTextFieldStyle())
                .onChange(of: amountText) { _, newValue in
                    formatCurrency(newValue)
                }
        }
    }
    
    @ViewBuilder private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.headline)
                .foregroundColor(.appText)
            
            TextField("Optional description", text: $descriptionText)
                .textFieldStyle(GlassTextFieldStyle())
        }
    }
    
    @ViewBuilder private var paymentTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Type")
                .font(.headline)
                .foregroundColor(.appText)
            
            if paymentMethods.isEmpty {
                Button("Add default payment types") {
                    seedDefaults(paymentsOnly: true)
                }
                .buttonStyle(AppButtonStyle())
            } else {
                Color.clear
                    .frame(height: 50)
                    .singleRowChipScroll {
                        ForEach(paymentMethods) { pm in
                            PaymentChipView(
                                paymentMethod: pm,
                                isSelected: selectedMethod == pm,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedMethod = pm
                                    }
                                    dismissKeyboard()
                                }
                            )
                        }
                    }
            }
        }
    }
    
    @ViewBuilder private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.headline)
                .foregroundColor(.appText)
            
            if categories.isEmpty {
                Button("Add default categories") {
                    seedDefaults(categoriesOnly: true)
                }
                .buttonStyle(AppButtonStyle())
            } else {
                Color.clear
                    .frame(height: categories.count > 1 ? 100 : 50)
                    .doubleRowChipScroll(
                        firstRow: {
                            ForEach(Array(stride(from: 0, to: categories.count, by: 2)), id: \.self) { index in
                                CategoryChipView(
                                    category: categories[index],
                                    isSelected: selectedCategory == categories[index],
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedCategory = categories[index]
                                        }
                                        dismissKeyboard()
                                    }
                                )
                            }
                        },
                        secondRow: {
                            if categories.count > 1 {
                                ForEach(Array(stride(from: 1, to: categories.count, by: 2)), id: \.self) { index in
                                    CategoryChipView(
                                        category: categories[index],
                                        isSelected: selectedCategory == categories[index],
                                        onTap: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedCategory = categories[index]
                                            }
                                            dismissKeyboard()
                                        }
                                    )
                                }
                            } else {
                                EmptyView()
                            }
                        }
                    )
            }
        }
    }
    
    @ViewBuilder private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date")
                .font(.headline)
                .foregroundColor(.appText)
            
            GlassDatePicker(selection: $date)
        }
    }
    
    @ViewBuilder private var saveSection: some View {
        Button("Save Entry") {
            save()
        }
        .buttonStyle(AppButtonStyle())
        .disabled(!canSave)
        .opacity(canSave ? 1.0 : 0.5)
    }

    @ViewBuilder private var toastOverlay: some View {
        if showSavedToast {
            Text("Saved ✔︎")
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .foregroundColor(Color.appText)
                .padding(.top)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )
    }

    // MARK: - Validation
    private var canSave: Bool { amountDecimal != nil }
    
    private var amountDecimal: Decimal? {
        let cleanString = amountText.replacingOccurrences(of: "R$", with: "").replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ",", with: ".")
        return Decimal(string: cleanString)
    }
    
    // MARK: - Currency Formatting
    private func formatCurrency(_ value: String) {
        let digits = value.filter { $0.isNumber || $0 == "." || $0 == "," }
        if let decimal = Decimal(string: digits.replacingOccurrences(of: ",", with: ".")), decimal > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: "pt_BR")
            if let formatted = formatter.string(for: NSDecimalNumber(decimal: decimal)) {
                amountText = formatted
            }
        }
    }

    // MARK: - Actions
    private func save() {
        guard let amount = amountDecimal else { return }

        let signedAmount = (selectedCategory?.isIncome ?? false) ? amount : -amount

        let tx = Transaction(
            amount: signedAmount,
            date: date,
            note: descriptionText.isEmpty ? nil : descriptionText,
            category: selectedCategory,
            paymentMethod: selectedMethod
        )

        do {
            try withAnimation {
                ctx.insert(tx)
                try ctx.save()
            }

            SHEETS.postTransaction(
                remoteID: tx.remoteID,
                amount: signedAmount,
                date: date,
                categoryName: selectedCategory?.name,
                paymentName: selectedMethod?.name,
                note: descriptionText.isEmpty ? nil : descriptionText
            )

            amountText = ""
            descriptionText = ""
            date = Date()
            withAnimation { showSavedToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showSavedToast = false }
            }

            dismissKeyboard()
        } catch {
            alertMessage = "Could not save entry: \(error.localizedDescription)"
            print("SAVE ERROR (Transaction):", error)
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
    }
}
