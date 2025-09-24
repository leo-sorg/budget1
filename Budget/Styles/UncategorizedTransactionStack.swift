import SwiftUI

// MARK: - Uncategorized Transaction Card Stack (Clean Version)
struct UncategorizedTransactionStack: View {
    let transactions: [APITransaction]
    let categories: [APICategory]
    let onCategorizeTransaction: (APITransaction, APICategory) -> Void
    let onDismissStack: () -> Void
    
    @State private var cardStack: [APITransaction] = []
    @State private var dragOffset: CGSize = .zero
    @State private var showCategoryPicker = false
    @State private var selectedTransaction: APITransaction?
    @State private var hasSwipedSignificantly = false
    
    private let cardHeight: CGFloat = 140
    private let maxVisibleCards = 3
    
    var body: some View {
        // ONLY the card stack - no background, no titles, no dismiss button
        ZStack {
            if !cardStack.isEmpty {
                ForEach(Array(visibleTransactions.enumerated()), id: \.element.remoteID) { stackIndex, transaction in
                    let isTopCard = stackIndex == 0
                    
                    TransactionCard(
                        transaction: transaction,
                        isTopCard: isTopCard,
                        stackIndex: stackIndex,
                        dragOffset: isTopCard ? dragOffset : .zero,
                        hasSwipedSignificantly: $hasSwipedSignificantly
                    ) {
                        // Only show category picker if we haven't swiped significantly
                        if !hasSwipedSignificantly {
                            selectedTransaction = transaction
                            showCategoryPicker = true
                        }
                    }
                    .scaleEffect(cardScale(for: stackIndex))
                    .offset(y: cardYOffset(for: stackIndex))
                    .zIndex(Double(maxVisibleCards - stackIndex))
                    .opacity(cardOpacity(for: stackIndex))
                    .gesture(
                        isTopCard ?
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                dragOffset = value.translation
                                
                                // Mark as significantly swiped if moved more than 30 points
                                if abs(value.translation.width) > 30 {
                                    hasSwipedSignificantly = true
                                }
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 80
                                if abs(value.translation.width) > threshold {
                                    // Mark as swiped to prevent tap action
                                    hasSwipedSignificantly = true
                                    
                                    // Move top card to back of stack
                                    moveTopCardToBack()
                                } else {
                                    // Snap back
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                        dragOffset = .zero
                                    }
                                    
                                    // Reset swipe flag after a short delay if it was a small movement
                                    if abs(value.translation.width) < 30 {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            hasSwipedSignificantly = false
                                        }
                                    }
                                }
                            } : nil
                    )
                }
            }
        }
        .frame(height: cardHeight + 60)
        .onAppear {
            // Initialize the card stack
            cardStack = transactions
        }
        .sheet(isPresented: $showCategoryPicker) {
            if let transaction = selectedTransaction {
                CategoryPickerSheet(
                    transaction: transaction,
                    categories: categories,
                    onCategorize: { category in
                        onCategorizeTransaction(transaction, category)
                        moveTopCardToBack()
                    },
                    onDismiss: {
                        showCategoryPicker = false
                        selectedTransaction = nil
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private var visibleTransactions: [APITransaction] {
        let endIndex = min(maxVisibleCards, cardStack.count)
        return Array(cardStack[0..<endIndex])
    }
    
    private func cardScale(for stackIndex: Int) -> CGFloat {
        return 1.0 - (CGFloat(stackIndex) * 0.05)
    }
    
    private func cardYOffset(for stackIndex: Int) -> CGFloat {
        return CGFloat(stackIndex) * 8
    }
    
    private func cardOpacity(for stackIndex: Int) -> Double {
        return stackIndex == 0 ? 1.0 : 0.8 - (Double(stackIndex) * 0.1)
    }
    
    private func moveTopCardToBack() {
        guard !cardStack.isEmpty else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = .zero
            
            // Move the first card to the end
            let topCard = cardStack.removeFirst()
            cardStack.append(topCard)
        }
        
        // Reset swipe flag for next card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            hasSwipedSignificantly = false
        }
    }
}

// MARK: - Transaction Card Component (Updated - Harmonious Layout)
struct TransactionCard: View {
    let transaction: APITransaction
    let isTopCard: Bool
    let stackIndex: Int
    let dragOffset: CGSize
    @Binding var hasSwipedSignificantly: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row - Amount and Date/Time
            HStack(alignment: .top) {
                // Amount (prominent)
                Text(formatCurrency(Decimal(transaction.amount)))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(transaction.amount >= 0 ? Color(red: 0.5, green: 1.0, blue: 0.5) : Color(red: 1.0, green: 0.6, blue: 0.6))
                
                Spacer()
                
                // Date and Time
                VStack(alignment: .trailing, spacing: 1) {
                    Text(formatDisplayDate(transaction.dateISO))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(formatDisplayTime(transaction.dateISO))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Transaction details section
            VStack(alignment: .leading, spacing: 8) {
                // Payment method
                HStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 16) // Fixed width for alignment
                    
                    Text(transaction.paymentMethod.isEmpty ? "Unknown Payment" : transaction.paymentMethod)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Merchant name (if available)
                if !transaction.merchantName.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "storefront.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(width: 16) // Same fixed width for alignment
                        
                        Text(transaction.merchantName)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
            
            // Note section (if available)
            if !transaction.note.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(width: 16) // Same fixed width for alignment
                        
                        Text(transaction.note)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
        .padding(18)
        .frame(height: 140)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.clear)
        .glassEffect(
            isTopCard ?
            .regular.tint(Color.black.opacity(0.6)).interactive() :
            .regular.interactive(),
            in: .rect(cornerRadius: 14)
        )
        .contentShape(Rectangle())
        .offset(dragOffset)
        .onTapGesture {
            if !hasSwipedSignificantly {
                onTap()
            }
        }
        .onChange(of: dragOffset) { _, newValue in
            if newValue == .zero {
                hasSwipedSignificantly = false
            }
        }
    }
}

// MARK: - Category Picker Sheet
struct CategoryPickerSheet: View {
    let transaction: APITransaction
    let categories: [APICategory]
    let onCategorize: (APICategory) -> Void
    let onDismiss: () -> Void
    
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
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatDisplayDate(transaction.dateISO))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(formatDisplayTime(transaction.dateISO))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
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
                    onDismiss()
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

// NEW: Function to extract and format time from dateISO string
private func formatDisplayTime(_ dateString: String) -> String {
    let timeFormatter = DateFormatter()
    timeFormatter.dateFormat = "HH:mm"
    
    // Try parsing with fractional seconds
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    if let date = isoFormatter.date(from: dateString) {
        return timeFormatter.string(from: date)
    }
    
    // Try parsing without fractional seconds
    isoFormatter.formatOptions = [.withInternetDateTime]
    if let date = isoFormatter.date(from: dateString) {
        return timeFormatter.string(from: date)
    }
    
    // Try to extract time from ISO string manually if it contains 'T'
    if let tRange = dateString.range(of: "T") {
        let timePart = String(dateString[tRange.upperBound...])
        if let colonRange = timePart.range(of: ":") {
            let hour = String(timePart[..<colonRange.lowerBound])
            let afterColon = String(timePart[colonRange.upperBound...])
            if let secondColonRange = afterColon.range(of: ":") {
                let minute = String(afterColon[..<secondColonRange.lowerBound])
                return "\(hour):\(minute)"
            }
        }
    }
    
    // Fallback to a default time if we can't parse
    return "00:00"
}

private func isValidEmoji(_ string: String) -> Bool {
    return !string.isEmpty
}
