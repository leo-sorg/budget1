import SwiftUI

// MARK: - Uncategorized Transaction Card Stack
struct UncategorizedTransactionStack: View {
    let transactions: [APITransaction]
    let categories: [APICategory]
    let onCategorizeTransaction: (APITransaction, APICategory) -> Void
    let onDismissStack: () -> Void
    
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var showCategoryPicker = false
    @State private var selectedTransaction: APITransaction?
    
    private let cardHeight: CGFloat = 140
    private let maxVisibleCards = 3
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Uncategorized Transactions")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(transactions.count) transaction\(transactions.count == 1 ? "" : "s") need categorization")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button("Dismiss") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        onDismissStack()
                    }
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            }
            
            // Card Stack
            if !transactions.isEmpty && currentIndex < transactions.count {
                ZStack {
                    ForEach(Array(visibleTransactions.enumerated()), id: \.element.remoteID) { stackIndex, transaction in
                        let actualIndex = currentIndex + stackIndex
                        let isTopCard = stackIndex == 0
                        
                        TransactionCard(
                            transaction: transaction,
                            isTopCard: isTopCard,
                            stackIndex: stackIndex,
                            dragOffset: isTopCard ? dragOffset : .zero
                        ) {
                            // Tap action - show category picker
                            selectedTransaction = transaction
                            showCategoryPicker = true
                        }
                        .scaleEffect(cardScale(for: stackIndex))
                        .offset(y: cardYOffset(for: stackIndex))
                        .zIndex(Double(maxVisibleCards - stackIndex))
                        .opacity(cardOpacity(for: stackIndex))
                        .gesture(
                            isTopCard ? cardDragGesture : nil
                        )
                    }
                }
                .frame(height: cardHeight + 60) // Extra space for card offsets
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentIndex)
                .animation(.spring(response: 0.3, dampingFraction: 0.9), value: dragOffset)
                
                // Progress indicator
                if transactions.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<min(transactions.count, 5), id: \.self) { index in
                            Circle()
                                .fill(index == min(currentIndex, 4) ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                        
                        if transactions.count > 5 {
                            Text("+\(transactions.count - 5)")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
        }
        .padding(20)
        .glassEffect(.regular.tint(Color.orange.opacity(0.1)), in: .rect(cornerRadius: 16))
        .sheet(isPresented: $showCategoryPicker) {
            if let transaction = selectedTransaction {
                CategoryPickerSheet(
                    transaction: transaction,
                    categories: categories,
                    onCategorize: { category in
                        onCategorizeTransaction(transaction, category)
                        moveToNextCard()
                    },
                    onCancel: {
                        showCategoryPicker = false
                        selectedTransaction = nil
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var visibleTransactions: [APITransaction] {
        let endIndex = min(currentIndex + maxVisibleCards, transactions.count)
        return Array(transactions[currentIndex..<endIndex])
    }
    
    private var cardDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                handleDragEnd(translation: value.translation)
            }
    }
    
    // MARK: - Helper Functions
    
    private func cardScale(for stackIndex: Int) -> CGFloat {
        return 1.0 - (CGFloat(stackIndex) * 0.05)
    }
    
    private func cardYOffset(for stackIndex: Int) -> CGFloat {
        return CGFloat(stackIndex) * 8
    }
    
    private func cardOpacity(for stackIndex: Int) -> Double {
        return stackIndex == 0 ? 1.0 : 0.8 - (Double(stackIndex) * 0.1)
    }
    
    private func handleDragEnd(translation: CGSize) {
        let threshold: CGFloat = 80
        
        if translation.x > threshold {
            // Swipe right - send to back of stack
            sendCurrentCardToBack()
        } else if translation.x < -threshold {
            // Swipe left - maybe implement "skip" functionality later
            sendCurrentCardToBack()
        } else {
            // Snap back
            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                dragOffset = .zero
            }
        }
    }
    
    private func sendCurrentCardToBack() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = CGSize(width: 400, height: 0) // Animate off screen
        }
        
        // Move the current transaction to the back and reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            moveToNextCard()
        }
    }
    
    private func moveToNextCard() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = .zero
            if currentIndex < transactions.count - 1 {
                currentIndex += 1
            } else {
                // Reached the end, cycle back to beginning
                currentIndex = 0
            }
        }
    }
}

// MARK: - Transaction Card Component
struct TransactionCard: View {
    let transaction: APITransaction
    let isTopCard: Bool
    let stackIndex: Int
    let dragOffset: CGSize
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header row
                HStack {
                    // Amount (prominent)
                    Text(formatCurrency(Decimal(transaction.amount)))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(transaction.amount >= 0 ? Color(red: 0.5, green: 1.0, blue: 0.5) : Color(red: 1.0, green: 0.6, blue: 0.6))
                    
                    Spacer()
                    
                    // Date
                    Text(formatDisplayDate(transaction.dateISO))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // Transaction details
                HStack(spacing: 8) {
                    // Payment method icon
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(transaction.paymentMethod.isEmpty ? "Unknown" : transaction.paymentMethod)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    
                    if !transaction.merchantName.isEmpty {
                        Text("•")
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text(transaction.merchantName)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                
                // Note if available
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
                
                // Call to action
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Tap to categorize")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Spacer()
                    
                    if isTopCard {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.3))
                        Text("Swipe to skip")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }
            .padding(16)
        }
        .buttonStyle(.plain)
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
        .offset(dragOffset)
        .scaleEffect(isTopCard && abs(dragOffset.x) > 50 ? 0.95 : 1.0)
        .rotationEffect(.degrees(Double(dragOffset.x / 20)))
    }
}

// MARK: - Category Picker Sheet
struct CategoryPickerSheet: View {
    let transaction: APITransaction
    let categories: [APICategory]
    let onCategorize: (APICategory) -> Void
    let onCancel: () -> Void
    
    @Namespace private var categoryNamespace
    @State private var selectedCategoryID: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                // Handle bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray3))
                    .frame(width: 36, height: 4)
                    .padding(.top, 8)
                
                // Title and transaction info
                VStack(spacing: 12) {
                    Text("Categorize Transaction")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    // Transaction preview
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatCurrency(Decimal(transaction.amount)))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(transaction.amount >= 0 ? .green : .primary)
                            
                            if !transaction.merchantName.isEmpty {
                                Text(transaction.merchantName)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text(formatDisplayDate(transaction.dateISO))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 20)
            }
            
            Divider()
                .padding(.vertical, 8)
            
            // Categories
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(categories, id: \.remoteID) { category in
                        CategoryPickerCard(
                            category: category,
                            isSelected: selectedCategoryID == category.remoteID,
                            onTap: {
                                selectedCategoryID = category.remoteID
                            },
                            namespace: categoryNamespace
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                Button("Categorize") {
                    if let categoryID = selectedCategoryID,
                       let category = categories.first(where: { $0.remoteID == categoryID }) {
                        onCategorize(category)
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedCategoryID != nil ? Color.blue : Color.gray)
                .cornerRadius(12)
                .disabled(selectedCategoryID == nil)
                
                Button("Cancel") {
                    onCancel()
                }
                .font(.system(size: 16))
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Category Picker Card
struct CategoryPickerCard: View {
    let category: APICategory
    let isSelected: Bool
    let onTap: () -> Void
    let namespace: Namespace.ID
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Emoji or icon
                if isValidEmoji(category.emoji) {
                    Text(category.emoji)
                        .font(.system(size: 24))
                } else {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                
                // Category name
                Text(category.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Type indicator
                Text(category.isIncome ? "Income" : "Expense")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        .matchedGeometryEffect(id: "selectedCategory", in: namespace)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helper Functions
private func formatCurrency(_ value: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "pt_BR")
    return formatter.string(for: NSDecimalNumber(decimal: value)) ?? "R$ 0,00"
}

private func formatDisplayDate(_ dateString: String) -> String {
    let outputFormatter = DateFormatter()
    outputFormatter.dateFormat = "MMM dd"
    
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    if let date = isoFormatter.date(from: dateString) {
        return outputFormatter.string(from: date)
    }
    
    isoFormatter.formatOptions = [.withInternetDateTime]
    if let date = isoFormatter.date(from: dateString) {
        return outputFormatter.string(from: date)
    }
    
    let simpleFormatter = DateFormatter()
    simpleFormatter.dateFormat = "yyyy-MM-dd"
    if let date = simpleFormatter.date(from: dateString) {
        return outputFormatter.string(from: date)
    }
    
    if dateString.count >= 10 {
        let datePart = String(dateString.prefix(10))
        if let date = simpleFormatter.date(from: datePart) {
            return outputFormatter.string(from: date)
        }
    }
    
    return dateString
}

private func isValidEmoji(_ string: String) -> Bool {
    return !string.isEmpty
}
