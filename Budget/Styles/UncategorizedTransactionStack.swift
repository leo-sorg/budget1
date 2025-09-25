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
                            print("🎯 Opening category picker for transaction: \(transaction.remoteID)")
                            print("🎯 Categories available: \(categories.count)")
                            // FIX: Set selectedTransaction IMMEDIATELY when tapped
                            selectedTransaction = transaction
                            // Small delay to ensure state is set before showing sheet
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showCategoryPicker = true
                            }
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
            print("🚀 UncategorizedTransactionStack appeared with \(transactions.count) transactions and \(categories.count) categories")
        }
        .sheet(isPresented: $showCategoryPicker) {
            // FIX: Always pass the first transaction if selectedTransaction is nil
            let transactionToShow = selectedTransaction ?? cardStack.first
            
            if let transaction = transactionToShow {
                BeautifulCategoryPickerSheet(
                    transaction: transaction,
                    availableCategories: categories,
                    onSelectCategory: { category in
                        print("✅ User selected category: \(category.name)")
                        // TODO: Call API to update transaction category
                        // SHEETS.updateTransactionCategory(remoteID: transaction.remoteID, categoryName: category.name) { response in
                        //     // Handle response
                        // }
                        
                        onCategorizeTransaction(transaction, category)
                        showCategoryPicker = false
                        selectedTransaction = nil
                        moveTopCardToBack()
                    }
                )
                .presentationDetents([.medium, .large])
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

// MARK: - Beautiful Category Picker Sheet (REVERTED + COLOR FIXES)
struct BeautifulCategoryPickerSheet: View {
    let transaction: APITransaction
    let availableCategories: [APICategory]
    let onSelectCategory: (APICategory) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            // Header with transaction info
            headerSection
            
            // Categories section
            categoriesSection
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.container, edges: .bottom)  // IGNORE safe area at bottom to prevent cutoff
        .onAppear {
            print("🔍 BeautifulCategoryPickerSheet opened")
            print("🔍 Available categories count: \(availableCategories.count)")
        }
    }
    
    // MARK: - Header Section (SIMPLIFIED - NO TRANSACTION INFO)
    @ViewBuilder private var headerSection: some View {
        VStack(spacing: 24) {
            // Just some top padding - no title, no transaction card
            Spacer()
                .frame(height: 16)
        }
    }
    
    // MARK: - Categories Section (FIXED SCROLLING)
    @ViewBuilder private var categoriesSection: some View {
        VStack(spacing: 16) {
            if availableCategories.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Categories Available")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Add categories in the Manage tab first")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                // Categories grid - REMOVED maxHeight to allow full scrolling
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 16) {
                        ForEach(availableCategories, id: \.remoteID) { category in
                            CategoryCard(category: category) {
                                print("📝 Selected category: \(category.name)")
                                
                                // Haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                // Call the selection handler
                                onSelectCategory(category)
                                
                                // Close the sheet
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)  // INCREASED bottom padding to prevent cutoff
                }
                // REMOVED: .frame(maxHeight: 300) - this was cutting off the categories
            }
        }
    }
}

// MARK: - Beautiful Category Card (WITH FIXED COLORS)
struct CategoryCard: View {
    let category: APICategory
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon/Emoji
                ZStack {
                    Circle()
                        .fill(category.isIncome ? Color(red: 0.5, green: 1.0, blue: 0.5).opacity(0.1) : Color(red: 1.0, green: 0.5, blue: 0.5).opacity(0.1))  // FIXED: Same colors as manage view
                        .frame(width: 50, height: 50)
                    
                    if !category.emoji.isEmpty {
                        Text(category.emoji)
                            .font(.title2)
                    } else {
                        Image(systemName: category.isIncome ? "plus.circle.fill" : "tag.fill")
                            .font(.title3)
                            .foregroundColor(category.isIncome ? Color(red: 0.5, green: 1.0, blue: 0.5) : Color(red: 1.0, green: 0.5, blue: 0.5))  // FIXED: Same colors as manage view
                    }
                }
                
                // Name (COLORED BASED ON TYPE WITH BACKGROUND)
                Text(category.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(category.isIncome ? Color(red: 0.5, green: 1.0, blue: 0.5) : Color(red: 1.0, green: 0.5, blue: 0.5))  // SAME COLORS: green for income, red for expense
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(category.isIncome ? Color(red: 0.5, green: 1.0, blue: 0.5).opacity(0.15) : Color(red: 1.0, green: 0.5, blue: 0.5).opacity(0.15))  // SAME BACKGROUND as the old badge
                    )
            }
            .frame(height: 100)  // REDUCED height since we removed the badge
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)  // REVERTED: Back to original padding
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)  // REVERTED: Back to original shadow
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
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
