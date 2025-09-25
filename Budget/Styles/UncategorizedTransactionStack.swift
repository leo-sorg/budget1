import SwiftUI

// MARK: - Uncategorized Transaction Card Stack (Clean Version)
struct UncategorizedTransactionStack: View {
    let transactions: [APITransaction]
    let categories: [APICategory]
    let onCategorizeTransaction: (APITransaction, APICategory) -> Void
    let onDismissStack: () -> Void
    
    @State private var cardStack: [APITransaction] = []
    @State private var transactionsToRemove: Set<String> = []
    @State private var dragOffset: CGSize = .zero
    @State private var showCategoryPicker = false
    @State private var selectedTransaction: APITransaction?
    @State private var hasSwipedSignificantly = false
    @State private var successfulCategoryFromSheet: APICategory? // Store successful category from sheet
    @State private var cardBeingRemoved: String? // Track which card is being animated out
    
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
                        hasSwipedSignificantly: $hasSwipedSignificantly,
                        isBeingRemoved: cardBeingRemoved == transaction.remoteID
                    ) {
                        // Only show category picker if we haven't swiped significantly
                        if !hasSwipedSignificantly {
                            print("🎯 Opening category picker for transaction: \(transaction.remoteID)")
                            print("🎯 Categories available: \(categories.count)")
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
        .onChange(of: transactions) { _, newTransactions in
            // Update card stack when transactions change from parent
            let newTransactionIDs = Set(newTransactions.map { $0.remoteID })
            let removedTransactionIDs = Set(cardStack.map { $0.remoteID }).subtracting(newTransactionIDs)
            
            print("🔄 Transactions changed. Removed IDs: \(removedTransactionIDs)")
            
            // Remove cards that are no longer in the transactions array
            if !removedTransactionIDs.isEmpty {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    cardStack.removeAll { removedTransactionIDs.contains($0.remoteID) }
                }
            }
            
            // Add any new transactions that might have been added
            let currentIDs = Set(cardStack.map { $0.remoteID })
            let newCards = newTransactions.filter { !currentIDs.contains($0.remoteID) }
            if !newCards.isEmpty {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    cardStack.append(contentsOf: newCards)
                }
            }
        }
        .sheet(isPresented: $showCategoryPicker, onDismiss: {
            // Handle successful categorization AFTER sheet is fully dismissed
            if let transaction = selectedTransaction, let successfulCategory = successfulCategoryFromSheet {
                print("🎉 Sheet dismissed - now animating card removal")
                animateCardRemovalAndCallParent(transaction: transaction, category: successfulCategory)
                // Clear the successful category
                successfulCategoryFromSheet = nil
            }
        }) {
            // Always pass the first transaction if selectedTransaction is nil
            let transactionToShow = selectedTransaction ?? cardStack.first
            
            if let transaction = transactionToShow {
                BeautifulCategoryPickerSheet(
                    transaction: transaction,
                    availableCategories: categories,
                    onSelectCategory: { category in
                        print("✅ User selected category: \(category.name)")
                    },
                    onSuccessfulCategorization: { transaction, category in
                        // Store the successful categorization for when sheet dismisses
                        print("📝 Storing successful categorization for when sheet dismisses")
                        successfulCategoryFromSheet = category
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Animate Card Removal with Diagonal Swipe Effect
    private func animateCardRemovalAndCallParent(transaction: APITransaction, category: APICategory) {
        print("🎬 Starting diagonal swipe animation for card: \(transaction.remoteID)")
        
        // Mark this card as being removed to trigger the diagonal swipe animation
        withAnimation(.easeInOut(duration: 0.5)) {
            cardBeingRemoved = transaction.remoteID
        }
        
        // After the animation completes, remove the card and call parent callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Remove the card from our local stack first with animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                if let index = self.cardStack.firstIndex(where: { $0.remoteID == transaction.remoteID }) {
                    self.cardStack.remove(at: index)
                }
            }
            
            // Reset the animation state
            self.cardBeingRemoved = nil
            
            // Call the parent callback to handle the actual removal from the data source
            // This happens after our local animation to prevent double-animation conflicts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.handleCategorySelection(transaction: transaction, category: category)
            }
            
            print("✅ Card animation completed and parent callback called")
        }
    }
    
    // MARK: - Handle Category Selection with API Call
    private func handleCategorySelection(transaction: APITransaction, category: APICategory) {
        // Clean category name - remove spaces and emojis at the end
        let cleanCategoryName = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🎯 handleCategorySelection: \(transaction.remoteID) -> \(cleanCategoryName)")
        
        // Call the parent's callback - the parent will handle the API call and then update the transactions array
        onCategorizeTransaction(transaction, category)
        
        // Reset selection
        selectedTransaction = nil
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
    
    // MARK: - Public method to remove transaction from stack
    func removeTransaction(with remoteID: String) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            cardStack.removeAll { $0.remoteID == remoteID }
        }
    }
}

// MARK: - Enhanced Category Picker Sheet with Better UX Flow
struct BeautifulCategoryPickerSheet: View {
    let transaction: APITransaction
    let availableCategories: [APICategory]
    let onSelectCategory: (APICategory) -> Void
    let onSuccessfulCategorization: (APITransaction, APICategory) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedCategoryForAPI: APICategory?
    @State private var successfulCategory: APICategory?
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
            
            // Header with transaction info
            headerSection
            
            // Loading/Success/Error overlay or categories section
            ZStack {
                // Categories section (hidden during loading/success/error)
                categoriesSection
                    .opacity(isLoading || showSuccess || showError ? 0.3 : 1.0)
                    .disabled(isLoading || showSuccess || showError)
                
                // Loading overlay
                if isLoading {
                    loadingOverlay
                }
                
                // Success overlay
                if showSuccess {
                    successOverlay
                }
                
                // Error overlay
                if showError {
                    errorOverlay
                }
            }
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.container, edges: .bottom)
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
                                handleCategoryTap(category)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    // MARK: - Loading Overlay
    @ViewBuilder private var loadingOverlay: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
            
            Text("Updating category...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.9))
    }
    
    // MARK: - Success Overlay
    @ViewBuilder private var successOverlay: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
                .scaleEffect(showSuccess ? 1.0 : 0.5)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showSuccess)
            
            Text("Category updated!")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.9))
    }
    
    // MARK: - Error Overlay
    @ViewBuilder private var errorOverlay: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
                .scaleEffect(showError ? 1.0 : 0.5)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showError)
            
            Text("Failed to update")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Try Again") {
                if let category = selectedCategoryForAPI {
                    handleCategoryTap(category)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.9))
    }
    
    // MARK: - Handle Category Tap with Delayed Parent Callback
    private func handleCategoryTap(_ category: APICategory) {
        selectedCategoryForAPI = category
        
        // Show loading state
        withAnimation(.easeInOut(duration: 0.3)) {
            isLoading = true
            showError = false
            showSuccess = false
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Clean category name - remove extra spaces and emojis at the end
        let cleanCategoryName = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("📝 Making API call to update transaction \(transaction.remoteID) with category: '\(cleanCategoryName)'")
        
        // Call the edit API
        SHEETS.editTransactionCategory(
            remoteID: transaction.remoteID,
            categoryName: cleanCategoryName
        ) { response in
            DispatchQueue.main.async {
                // Hide loading
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.isLoading = false
                }
                
                if response.status == 200 {
                    print("✅ API call successful - showing success state")
                    
                    // Store the successful category and trigger callback
                    self.successfulCategory = category
                    
                    // Show success
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.showSuccess = true
                    }
                    
                    // Success haptic feedback
                    let successFeedback = UINotificationFeedbackGenerator()
                    successFeedback.notificationOccurred(.success)
                    
                    // Call parent callback and then dismiss after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        if let category = self.successfulCategory {
                            self.onSuccessfulCategorization(self.transaction, category)
                        }
                        self.dismiss()
                    }
                    
                } else {
                    print("❌ API call failed with status \(response.status): \(response.body)")
                    
                    // Show error
                    self.errorMessage = "Server error: \(response.body)"
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.showError = true
                    }
                    
                    // Error haptic feedback
                    let errorFeedback = UINotificationFeedbackGenerator()
                    errorFeedback.notificationOccurred(.error)
                }
            }
        }
    }
}

// MARK: - Beautiful Category Card
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
                        .fill(category.isIncome ? Color(red: 0.5, green: 1.0, blue: 0.5).opacity(0.1) : Color(red: 1.0, green: 0.5, blue: 0.5).opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    if !category.emoji.isEmpty {
                        Text(category.emoji)
                            .font(.title2)
                    } else {
                        Image(systemName: category.isIncome ? "plus.circle.fill" : "tag.fill")
                            .font(.title3)
                            .foregroundColor(category.isIncome ? Color(red: 0.5, green: 1.0, blue: 0.5) : Color(red: 1.0, green: 0.5, blue: 0.5))
                    }
                }
                
                // Name (COLORED BASED ON TYPE WITH BACKGROUND)
                Text(category.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(category.isIncome ? Color(red: 0.5, green: 1.0, blue: 0.5) : Color(red: 1.0, green: 0.5, blue: 0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(category.isIncome ? Color(red: 0.5, green: 1.0, blue: 0.5).opacity(0.15) : Color(red: 1.0, green: 0.5, blue: 0.5).opacity(0.15))
                    )
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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

// MARK: - Transaction Card Component (Updated - With Removal Animation)
struct TransactionCard: View {
    let transaction: APITransaction
    let isTopCard: Bool
    let stackIndex: Int
    let dragOffset: CGSize
    @Binding var hasSwipedSignificantly: Bool
    let isBeingRemoved: Bool // Whether this card is being animated out
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
        .offset(
            x: isBeingRemoved ? -UIScreen.main.bounds.width * 0.8 : dragOffset.width,
            y: isBeingRemoved ? -UIScreen.main.bounds.height * 0.3 : dragOffset.height
        ) // Animate card diagonally up-left when being removed (about 30 degrees)
        .opacity(isBeingRemoved ? 0.0 : 1.0) // Fade out while sliding
        .scaleEffect(isBeingRemoved ? 0.8 : 1.0) // Slightly shrink while disappearing
        .rotationEffect(.degrees(isBeingRemoved ? -15 : 0)) // Add slight rotation for more natural feel
        .onTapGesture {
            if !hasSwipedSignificantly && !isBeingRemoved {
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
