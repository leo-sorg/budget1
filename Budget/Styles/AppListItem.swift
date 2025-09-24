import SwiftUI

// MARK: - Unified List Item Component (Used Everywhere)
struct AppListItem<Content: View, TrailingContent: View>: View {
    let content: Content
    let trailingContent: TrailingContent
    let onDelete: (() -> Void)?
    
    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailing: () -> TrailingContent,
        onDelete: (() -> Void)? = nil
    ) {
        self.content = content()
        self.trailingContent = trailing()
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: 12) {
            content
            
            Spacer()
            
            trailingContent
            
            // Simple delete button (only visible if onDelete is provided)
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Convenience initializer for simple cases
extension AppListItem where TrailingContent == EmptyView {
    init(
        @ViewBuilder content: () -> Content,
        onDelete: (() -> Void)? = nil
    ) {
        self.content = content()
        self.trailingContent = EmptyView()
        self.onDelete = onDelete
    }
}

// MARK: - Category List Items (Used in Both ManageView and SummaryView)
struct APICategoryListItem: View {
    let category: APICategory
    let onDelete: (() -> Void)?
    
    init(category: APICategory, onDelete: (() -> Void)? = nil) {
        self.category = category
        self.onDelete = onDelete
    }
    
    var body: some View {
        AppListItem(
            content: {
                HStack(spacing: 12) {
                    // Category emoji or fallback icon
                    if isValidEmoji(category.emoji) {
                        Text(category.emoji)
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    
                    // Category name
                    Text(category.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            },
            trailing: {
                CategoryTypeTag(isIncome: category.isIncome)
            },
            onDelete: onDelete
        )
    }
}

// MARK: - Payment Method List Items (Used in Both ManageView and SummaryView)
struct APIPaymentMethodListItem: View {
    let paymentMethod: APIPaymentMethod
    let onDelete: (() -> Void)?
    
    init(paymentMethod: APIPaymentMethod, onDelete: (() -> Void)? = nil) {
        self.paymentMethod = paymentMethod
        self.onDelete = onDelete
    }
    
    var body: some View {
        AppListItem(
            content: {
                HStack(spacing: 12) {
                    // Payment method emoji or fallback icon
                    if isValidEmoji(paymentMethod.emoji) {
                        Text(paymentMethod.emoji)
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    
                    // Payment method name
                    Text(paymentMethod.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            },
            trailing: {
                EmptyView()
            },
            onDelete: onDelete
        )
    }
}

// MARK: - Transaction List Item (Used in SummaryView)
struct APITransactionListItem: View {
    let transaction: APITransaction
    let onDelete: (() -> Void)?
    
    init(transaction: APITransaction, onDelete: (() -> Void)? = nil) {
        self.transaction = transaction
        self.onDelete = onDelete
    }
    
    var body: some View {
        AppListItem(
            content: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        // Category icon with emoji support and fallback icons
                        categoryIconView
                        
                        Text(transaction.categoryName.isEmpty ? "Uncategorized" : transaction.categoryName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    HStack(spacing: 8) {
                        Text(formatDisplayDate(transaction.dateISO))
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        if !transaction.paymentMethod.isEmpty {
                            Text("• \(transaction.paymentMethod)")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            },
            trailing: {
                Text(formatCurrency(Decimal(transaction.amount)))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(transaction.amount >= 0 ? .green : .primary)
            },
            onDelete: onDelete
        )
    }
    
    // Category icon view with emoji support and fallback icons
    @ViewBuilder private var categoryIconView: some View {
        if !transaction.categoryEmoji.isEmpty && isValidEmoji(transaction.categoryEmoji) {
            // Use the category emoji from the API
            Text(transaction.categoryEmoji)
                .font(.system(size: 20))
        } else {
            // Fallback for uncategorized/empty emoji: colored icons
            if transaction.amount >= 0 {
                // Income: green plus
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            } else {
                // Expense: red minus
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Summary List Items (Used in SummaryView for category/payment summaries)
struct SummaryCategoryItem: View {
    let name: String
    let amount: Decimal
    let onDelete: (() -> Void)?
    
    init(name: String, amount: Decimal, onDelete: (() -> Void)? = nil) {
        self.name = name
        self.amount = amount
        self.onDelete = onDelete
    }
    
    var body: some View {
        AppListItem(
            content: {
                Text(name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            },
            trailing: {
                Text(formatCurrency(amount))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(amount >= 0 ? .green : .primary)
            },
            onDelete: onDelete
        )
    }
}

struct SummaryPaymentItem: View {
    let name: String
    let amount: Decimal
    let onDelete: (() -> Void)?
    
    init(name: String, amount: Decimal, onDelete: (() -> Void)? = nil) {
        self.name = name
        self.amount = amount
        self.onDelete = onDelete
    }
    
    var body: some View {
        AppListItem(
            content: {
                HStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    Text(name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            },
            trailing: {
                Text(formatCurrency(amount))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(amount >= 0 ? .green : .primary)
            },
            onDelete: onDelete
        )
    }
}

// MARK: - Glass Card Components (for Summary View totals)
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct GlassCardRow: View {
    let label: String
    let value: String
    let valueColor: Color
    var isEmphasized: Bool = false
    
    init(label: String, value: String, valueColor: Color = .primary, isEmphasized: Bool = false) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.isEmphasized = isEmphasized
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: isEmphasized ? .semibold : .regular))
                .foregroundColor(isEmphasized ? .primary : .secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: isEmphasized ? .semibold : .medium))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Income/Expense Tag Component
struct CategoryTypeTag: View {
    let isIncome: Bool
    
    var body: some View {
        Text(isIncome ? "Income" : "Expense")
            .font(.caption.weight(.medium))
            .foregroundColor(isIncome ? .green : .red)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isIncome ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
            )
    }
}

// MARK: - Shared Helper Functions
private func formatCurrency(_ value: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "pt_BR")
    return formatter.string(for: NSDecimalNumber(decimal: value)) ?? "R$ 0,00"
}

private func formatDisplayDate(_ dateString: String) -> String {
    let outputFormatter = DateFormatter()
    outputFormatter.dateFormat = "dd/MM"
    
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
    guard !string.isEmpty else { return false }
    return string.unicodeScalars.allSatisfy { scalar in
        scalar.properties.isEmoji
    }
}
