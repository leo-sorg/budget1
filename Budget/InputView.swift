import SwiftUI
import SwiftData
import UIKit

// MARK: - UIKit-powered money field with a guaranteed inputAccessoryView
struct MoneyTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onCancel: () -> Void
    var onDone: () -> Void

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: MoneyTextField
        init(_ parent: MoneyTextField) { self.parent = parent }

        @objc func editingChanged(_ tf: UITextField) {
            let digits = (tf.text ?? "").filter(\.isNumber)
            let intVal = NSDecimalNumber(string: digits.isEmpty ? "0" : digits)
            let value = intVal.dividing(by: 100)
            let f = NumberFormatter()
            f.numberStyle = .currency
            f.locale = Locale(identifier: "pt_BR")
            tf.text = f.string(from: value) ?? ""
            parent.text = tf.text ?? ""
        }

        @objc func tapCancel(_ sender: UIBarButtonItem) {
            parent.text = ""
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            parent.onCancel()
        }

        @objc func tapDone(_ sender: UIBarButtonItem) {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            parent.onDone()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField(frame: .zero)
        tf.placeholder = placeholder
        tf.keyboardType = .numberPad
        tf.delegate = context.coordinator
        tf.borderStyle = .none
        tf.backgroundColor = .clear
        tf.textColor = UIColor(Color.appText)
        tf.tintColor = UIColor(Color.appAccent)
        tf.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)

        let bar = UIToolbar()
        bar.sizeToFit()
        let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: context.coordinator, action: #selector(Coordinator.tapCancel(_:)))
        let flex = UIBarButtonItem(systemItem: .flexibleSpace)
        let done = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(Coordinator.tapDone(_:)))
        bar.items = [cancel, flex, done]
        bar.barTintColor = UIColor(Color.appSecondaryBackground)
        bar.tintColor = UIColor(Color.appAccent)
        tf.inputAccessoryView = bar

        context.coordinator.editingChanged(tf)
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
    }
}

// MARK: - Generic text field with Cancel / Done toolbar
struct AccessoryTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onCancel: () -> Void
    var onDone: () -> Void
    var keyboardType: UIKeyboardType = .default
    var prefersEmoji: Bool = false
    var autocapitalization: UITextAutocapitalizationType = .sentences

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: AccessoryTextField
        init(_ parent: AccessoryTextField) { self.parent = parent }

        @objc func editingChanged(_ tf: UITextField) {
            parent.text = tf.text ?? ""
        }

        @objc func tapCancel(_ sender: UIBarButtonItem) {
            parent.text = ""
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            parent.onCancel()
        }

        @objc func tapDone(_ sender: UIBarButtonItem) {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            parent.onDone()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    private class EmojiTextField: UITextField {
        override var textInputMode: UITextInputMode? {
            for mode in UITextInputMode.activeInputModes {
                if mode.primaryLanguage == "emoji" { return mode }
            }
            return super.textInputMode
        }
    }

    func makeUIView(context: Context) -> UITextField {
        let tf: UITextField = prefersEmoji ? EmojiTextField(frame: .zero) : UITextField(frame: .zero)
        tf.placeholder = placeholder
        tf.delegate = context.coordinator
        tf.borderStyle = .none
        tf.keyboardType = keyboardType
        tf.autocapitalizationType = autocapitalization
        tf.backgroundColor = .clear
        tf.textColor = UIColor(Color.appText)
        tf.tintColor = UIColor(Color.appAccent)
        tf.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)

        let bar = UIToolbar()
        bar.sizeToFit()
        let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: context.coordinator, action: #selector(Coordinator.tapCancel(_:)))
        let flex = UIBarButtonItem(systemItem: .flexibleSpace)
        let done = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(Coordinator.tapDone(_:)))
        bar.items = [cancel, flex, done]
        bar.barTintColor = UIColor(Color.appSecondaryBackground)
        bar.tintColor = UIColor(Color.appAccent)
        tf.inputAccessoryView = bar

        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
    }
}

// MARK: - Chip views
struct PaymentChipView: View {
    let paymentMethod: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(paymentMethod.name)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundColor(isSelected ? Color.appAccent : Color.appText)
        }
        .background(isSelected ? Color.appAccent.opacity(0.2) : Color.clear)
        .background(.ultraThinMaterial, in: Capsule())
        .clipShape(Capsule())
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryChipView: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text("\(category.emoji ?? "") \(category.name)")
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .foregroundColor(isSelected ? Color.appAccent : Color.appText)
        }
        .background(isSelected ? Color.appAccent.opacity(0.3) : Color.clear)
        .background(.ultraThinMaterial, in: Capsule())
        .clipShape(Capsule())
        .buttonStyle(PlainButtonStyle())
    }
}

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
            
            MoneyTextField(
                text: $amountText,
                placeholder: "R$ 0,00",
                onCancel: { },
                onDone: { }
            )
            .materialContainer()
        }
    }
    
    @ViewBuilder private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.headline)
                .foregroundColor(.appText)
            
            AccessoryTextField(
                text: $descriptionText,
                placeholder: "Optional description",
                onCancel: { },
                onDone: { }
            )
            .materialContainer()
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
                .appMaterialButton()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
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
                    .padding(.horizontal, 0)
                }
                .padding(.horizontal, -16)
                .padding(.leading, 16)
                .padding(.trailing, 16) // Add right padding for scroll end alignment
                .scrollContentBackground(.hidden)
                .scrollClipDisabled()
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
                .appMaterialButton()
            } else {
                // Single ScrollView containing both rows so they scroll together
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
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
                            Spacer(minLength: 0) // Push to left
                        }
                        
                        if categories.count > 1 {
                            HStack(spacing: 8) {
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
                                Spacer(minLength: 0) // Push to left
                            }
                        }
                    }
                    .padding(.horizontal, 0)
                }
                .padding(.horizontal, -16)
                .padding(.leading, 16)
                .padding(.trailing, 16) // Add right padding for scroll end alignment
                .scrollContentBackground(.hidden)
                .scrollClipDisabled()
            }
        }
    }
    
    @ViewBuilder private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date")
                .font(.headline)
                .foregroundColor(.appText)
            
            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .materialContainer()
        }
    }
    
    @ViewBuilder private var saveSection: some View {
        Button("Save Entry") {
            save()
        }
        .appMaterialButton()
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
        let digits = amountText.filter(\.isNumber)
        guard !digits.isEmpty, let intVal = Decimal(string: digits) else { return nil }
        return intVal / 100
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

            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
