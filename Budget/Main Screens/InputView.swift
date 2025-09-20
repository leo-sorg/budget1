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
    @State private var showDatePicker = false
    @State private var showSavedToast = false
    @State private var alertMessage: String?
    
    // Focus state for auto-scroll
    @StateObject private var keyboardScroll = KeyboardScrollCoordinator()

    var body: some View {
        VStack(spacing: 0) {
            // Date at the top
            topDateSection
            
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Payment Type section
                    paymentTypeSection
                    
                    // 2. Category section
                    categorySection
                    
                    // 3. Value section
                    valueSection
                    
                    // 4. Description section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.appText)
                        
                        AppTextField(
                            text: $descriptionText,
                            placeholder: "Optional description"
                        ) { isFocused in
                            keyboardScroll.focusChanged(
                                field: "input_description",
                                isFocused: isFocused,
                                accessoryHeight: KeyboardScrollCoordinator.standardAccessoryHeight
                            )
                        }
                    }
                    
                    // Save button - UPDATED TO USE ENHANCED BUTTON
                    saveSection
                    
                    // Extra padding at bottom
                    Spacer()
                        .frame(height: 300)
                }
                .padding()
                .offset(y: keyboardScroll.scrollOffset)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .scrollDismissesKeyboard(.interactively)
        }
        .overlay(alignment: .top) { toastOverlay }
        .animation(.default, value: showSavedToast)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardScroll.keyboardWillShow(height: keyboardFrame.height)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardScroll.keyboardWillHide()
        }
        .alert("Oops", isPresented: alertBinding) {
            Button("OK") { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
        .task {
            categories = (try? ctx.fetch(FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)]))) ?? []
            paymentMethods = (try? ctx.fetch(FetchDescriptor<PaymentMethod>(sortBy: [SortDescriptor(\.name)]))) ?? []
            if categories.isEmpty || paymentMethods.isEmpty {
                seedDefaults()
                // Reload after seeding defaults
                categories = (try? ctx.fetch(FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)]))) ?? []
                paymentMethods = (try? ctx.fetch(FetchDescriptor<PaymentMethod>(sortBy: [SortDescriptor(\.name)]))) ?? []
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("Cancel") {
                    hideKeyboard()
                }
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
    }
    
    // MARK: - Helper function
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Date Section with inline calendar
    @ViewBuilder private var topDateSection: some View {
        VStack(spacing: 0) {
            // Top spacing
            Spacer()
                .frame(height: 40)
            
            VStack(spacing: 16) {
                // Date header with dropdown arrow
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showDatePicker.toggle()
                    }
                    dismissKeyboard()
                }) {
                    HStack(spacing: 8) {
                        Text(formatFullDate(date))
                            .font(.headline)
                            .foregroundColor(.appText)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.appText.opacity(0.7))
                            .rotationEffect(.degrees(showDatePicker ? 180 : 0))
                            .animation(.easeInOut(duration: 0.2), value: showDatePicker)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Calendar appears directly here when showDatePicker is true
                if showDatePicker {
                    CalendarView(selectedDate: $date)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9)),
                            removal: .opacity.combined(with: .scale(scale: 0.9))
                        ))
                }
            }
            .padding(.horizontal, 16)
            
            // Bottom spacing
            Spacer()
                .frame(height: 40)
        }
    }
    
    // MARK: - Rest of the sections
    @ViewBuilder private var paymentTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Type")
                .font(.headline)
                .foregroundColor(.appText)
            
            if paymentMethods.isEmpty {
                Button("Add default payment types") {
                    seedDefaults(paymentsOnly: true)
                    // Refresh the payment methods after seeding
                    paymentMethods = (try? ctx.fetch(FetchDescriptor<PaymentMethod>(sortBy: [SortDescriptor(\.name)]))) ?? []
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
                    // Refresh the categories after seeding
                    categories = (try? ctx.fetch(FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)]))) ?? []
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
    
    @ViewBuilder private var valueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Value")
                .font(.headline)
                .foregroundColor(.appText)
            
            AppCurrencyField(
                text: $amountText,
                placeholder: "R$ 0,00"
            ) { isFocused in
                keyboardScroll.focusChanged(
                    field: "input_amount",
                    isFocused: isFocused,
                    accessoryHeight: KeyboardScrollCoordinator.standardAccessoryHeight
                )
            }
        }
    }
    
    // MARK: - UPDATED SAVE SECTION WITH ENHANCED BUTTON
    @ViewBuilder private var saveSection: some View {
        EnhancedButton(title: "Save Entry") {
            return await performSave()
        }
        .disabled(!canSave)
        .opacity(canSave ? 1.0 : 0.5)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        keyboardScroll.registerButtonFrame(geometry.frame(in: .global))
                    }
                    .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                        keyboardScroll.registerButtonFrame(newFrame)
                    }
            }
        )
    }
    
    // MARK: - NEW ASYNC SAVE FUNCTION
    @MainActor
    private func performSave() async -> Bool {
        guard let amount = amountDecimal else { return false }

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

            // Post to sheets in background - fire and forget
            SHEETS.postTransaction(
                remoteID: tx.remoteID,
                amount: signedAmount,
                date: date,
                categoryName: selectedCategory?.name,
                paymentName: selectedMethod?.name,
                note: descriptionText.isEmpty ? nil : descriptionText
            )

            // Clear form
            amountText = ""
            descriptionText = ""
            date = Date()
            selectedCategory = nil
            selectedMethod = nil
            showDatePicker = false
            
            dismissKeyboard()
            
            // Return success
            return true
        } catch {
            alertMessage = "Could not save entry: \(error.localizedDescription)"
            print("SAVE ERROR (Transaction):", error)
            return false
        }
    }

    @ViewBuilder private var toastOverlay: some View {
        if showSavedToast {
            Text("Saved ✔︎")
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundColor(Color.appText)
                .padding(.top, 60)
                .glassEffect(.regular, in: .rect(cornerRadius: 8))
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )
    }

    // MARK: - Validation and actions
    private var canSave: Bool {
        amountDecimal != nil
    }
    
    private var amountDecimal: Decimal? {
        var cleanString = amountText
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanString.contains(",") {
            let parts = cleanString.components(separatedBy: ",")
            if parts.count == 2 {
                let integerPart = parts[0].replacingOccurrences(of: ".", with: "")
                let decimalPart = parts[1]
                cleanString = integerPart + "." + decimalPart
            }
        }
        
        return Decimal(string: cleanString)
    }

    private func seedDefaults(categoriesOnly: Bool = false, paymentsOnly: Bool = false) {
        if !paymentsOnly && categories.isEmpty {
            let base = (categories.map { $0.sortIndex }.max() ?? -1) + 1
            let seeds: [(String, String?, Bool)] = [
                // Expenses (14 categories)
                ("Food", "🍽️", false),
                ("Transport", "🚕", false),
                ("Bills", "💡", false),
                ("Shopping", "🛍️", false),
                ("Leisure", "🎬", false),
                ("Groceries", "🛒", false),
                ("Healthcare", "🏥", false),
                ("Education", "📚", false),
                ("Rent", "🏠", false),
                ("Insurance", "🛡️", false),
                ("Pets", "🐾", false),
                ("Gym", "💪", false),
                ("Subscriptions", "📱", false),
                ("Coffee", "☕", false),
                
                // Income (6 categories)
                ("Salary", "💼", true),
                ("Gifts", "🎁", true),
                ("Freelance", "💻", true),
                ("Investments", "📈", true),
                ("Bonus", "💰", true),
                ("Refunds", "💵", true)
            ]
            for (offset, seed) in seeds.enumerated() {
                let (name, emoji, isIncome) = seed
                ctx.insert(Category(name: name, emoji: emoji, sortIndex: base + offset, isIncome: isIncome))
            }
        }
        if !categoriesOnly && paymentMethods.isEmpty {
            let base = (paymentMethods.map { $0.sortIndex }.max() ?? -1) + 1
            let seeds: [(String, String?)] = [
                ("Credit Card", "💳"),
                ("Debit Card", "💳"),
                ("Pix", "📱"),
                ("Cash", "💵")
            ]
            for (offset, seed) in seeds.enumerated() {
                let (name, emoji) = seed
                ctx.insert(PaymentMethod(name: name, emoji: emoji, sortIndex: base + offset))
            }
        }
        try? ctx.save()
    }
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Custom Calendar View
struct CalendarView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 12) {
            // Month/Year header
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.appText)
                        .font(.title3.weight(.medium))
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: currentMonth))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.appText)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.appText)
                        .font(.title3.weight(.medium))
                }
            }
            .padding(.horizontal, 4)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Days of week headers
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.appText.opacity(0.6))
                        .frame(height: 20)
                }
                
                // Calendar days
                ForEach(calendarDays, id: \.self) { date in
                    if let date = date {
                        Button(action: {
                            selectedDate = date
                        }) {
                            Text("\(calendar.component(.day, from: date))")
                                .font(.system(size: 16, weight: calendar.isDate(date, inSameDayAs: selectedDate) ? .bold : .regular))
                                .foregroundColor(
                                    calendar.isDate(date, inSameDayAs: selectedDate) ? .black :
                                    calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) ? .appText : .appText.opacity(0.3)
                                )
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(calendar.isDate(date, inSameDayAs: selectedDate) ? Color.appAccent : Color.clear)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Color.clear
                            .frame(width: 36, height: 36)
                    }
                }
            }
        }
        .padding(16)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .onAppear {
            currentMonth = selectedDate
        }
    }
    
    private var calendarDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        
        var days: [Date?] = []
        
        // Add empty slots for days before the first day of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add all days of the current month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
}
