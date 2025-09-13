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
            // Keep only digits, treat as cents, format as pt_BR currency
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
            parent.text = ""          // clear
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

        // Toolbar with Cancel / Done
        let bar = UIToolbar()
        bar.sizeToFit()
        let cancel = UIBarButtonItem(title: "Cancel", style: .plain, target: context.coordinator, action: #selector(Coordinator.tapCancel(_:)))
        let flex = UIBarButtonItem(systemItem: .flexibleSpace)
        let done = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(Coordinator.tapDone(_:)))
        bar.items = [cancel, flex, done]
        bar.barTintColor = UIColor(Color.appSecondaryBackground)
        bar.tintColor = UIColor(Color.appAccent)
        tf.inputAccessoryView = bar

        // Initial formatting (if any)
        context.coordinator.editingChanged(tf)
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        // Keep UIKit field in sync if SwiftUI state changes externally
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

    // UITextField that defaults to the emoji keyboard
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

// MARK: - Your main InputView
@MainActor
struct InputView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: [
        SortDescriptor(\Category.sortIndex, order: .forward),
        SortDescriptor(\Category.name, order: .forward)
    ]) private var categories: [Category]

    @Query(sort: [
        SortDescriptor(\PaymentMethod.sortIndex, order: .forward),
        SortDescriptor(\PaymentMethod.name, order: .forward)
    ]) private var methods: [PaymentMethod]

    // Form state
    @State private var amountText = ""   // formatted "R$ 0,00"
    @State private var date = Date()
    @State private var selectedCategory: Category?
    @State private var selectedMethod: PaymentMethod?
    @State private var descriptionText = ""
    @State private var showSavedToast = false
    @State private var alertMessage: String?


    private let chipHeight: CGFloat = 40

    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle("Input")
        }
        .background(Color.appBackground)
        .foregroundColor(.appText)
        .tint(.appAccent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
    }

    /// Main form broken out for easier type-checking
    @ViewBuilder
    private var formContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                fieldTitle("Value")
                valueSection
                fieldTitle("Description")
                descriptionSection
                fieldTitle("Payment Type")
                paymentSection
                fieldTitle("Category")
                categorySection
                fieldTitle("Date")
                dateSection
                saveSection
            }
            .padding()
        }
        .background(Color.appBackground)
        .scrollDismissesKeyboard(.interactively)
        .task {
            if categories.isEmpty || methods.isEmpty { seedDefaults() }
        }
        .overlay(alignment: .top) { toastOverlay }
        .animation(.default, value: showSavedToast)
        .alert("Oops", isPresented: alertBinding) {
            Button("OK") { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    @ViewBuilder private var toastOverlay: some View {
        if showSavedToast {
            Text("Saved ✔︎")
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.appSecondaryBackground.opacity(0.8))
                .foregroundColor(Color.appText)
                .cornerRadius(8)
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

    private func fieldTitle(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(Color.appText.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Form Sections
    @ViewBuilder private var valueSection: some View {
        MoneyTextField(
            text: $amountText,
            placeholder: "R$ 0,00",
            onCancel: { /* nothing else to do */ },
            onDone: { /* just collapse; formatting already applied */ }
        )
        .appTextField()
    }

    @ViewBuilder private var paymentSection: some View {
        if methods.isEmpty {
            Button("Add default payment types") { seedDefaults(paymentsOnly: true) }
            .buttonStyle(AppButtonStyle())
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(methods) { pm in
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

    @ViewBuilder private var dateSection: some View {
        DatePicker("", selection: $date, displayedComponents: .date)
            .labelsHidden()
            .datePickerStyle(.compact)
            .appTextField()
    }

    @ViewBuilder private var descriptionSection: some View {
        AccessoryTextField(
            text: $descriptionText,
            placeholder: "Optional description",
            onCancel: { /* nothing extra */ },
            onDone: { /* just collapse */ }
        )
        .appTextField()
    }

    @ViewBuilder private var saveSection: some View {
        Button(action: save) {
            Text("Save Entry")
        }
        .buttonStyle(AppButtonStyle())
        .disabled(!canSave)
    }

    // MARK: - Validation
    private var canSave: Bool { amountDecimal != nil }
    private var amountDecimal: Decimal? {
        // Parse "R$ 12,34" back to Decimal
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
                context.insert(tx)
                try context.save()
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

    private func seedDefaults(categoriesOnly: Bool = false,
                              paymentsOnly: Bool = false) {
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
                context.insert(Category(name: name, emoji: emoji, sortIndex: base + offset, isIncome: isIncome))
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
}
