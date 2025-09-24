import SwiftUI

// MARK: - Unified List Item Component (Updated - No Delete Button)
struct AppListItem<Content: View, TrailingContent: View>: View {
    let content: Content
    let trailingContent: TrailingContent
    
    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailing: () -> TrailingContent
    ) {
        self.content = content()
        self.trailingContent = trailing()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            content
            
            Spacer()
            
            trailingContent
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.clear)  // Ensure no background color interferes
        .glassEffect(.regular, in: .rect(cornerRadius: 10))
    }
}

// MARK: - Convenience initializer for simple cases
extension AppListItem where TrailingContent == EmptyView {
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
        self.trailingContent = EmptyView()
    }
}

// MARK: - Category List Items (Used in Both ManageView and SummaryView)
struct APICategoryListItem: View {
    let category: APICategory
    
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
                        .foregroundColor(.white)  // UPDATED: Changed to .white for better contrast on glass
                }
            },
            trailing: {
                CategoryTypeTag(isIncome: category.isIncome)
            }
        )
    }
}

// MARK: - Payment Method List Items (Used in Both ManageView and SummaryView)
struct APIPaymentMethodListItem: View {
    let paymentMethod: APIPaymentMethod
    
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
                            .foregroundColor(.white.opacity(0.7))  // UPDATED: Changed to .white with opacity for glass
                    }
                    
                    // Payment method name
                    Text(paymentMethod.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)  // UPDATED: Changed to .white for better contrast on glass
                }
            },
            trailing: {
                EmptyView()
            }
        )
    }
}

// MARK: - Transaction List Item (Used in SummaryView)
struct APITransactionListItem: View {
    let transaction: APITransaction
    
    var body: some View {
        AppListItem(
            content: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        // Category icon with emoji support and fallback icons
                        categoryIconView
                        
                        Text(transaction.categoryName.isEmpty ? "Uncategorized" : transaction.categoryName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)  // UPDATED: Changed to .white for better contrast on glass
                    }
                    
                    HStack(spacing: 8) {
                        Text(formatDisplayDate(transaction.dateISO))
                            .foregroundColor(.white.opacity(0.6))  // UPDATED: Changed to .white with opacity for glass
                            .font(.caption)
                        
                        if !transaction.paymentMethod.isEmpty {
                            Text("• \(transaction.paymentMethod)")
                                .foregroundColor(.white.opacity(0.6))  // UPDATED: Changed to .white with opacity for glass
                                .font(.caption)
                        }
                    }
                }
            },
            trailing: {
                Text(formatCurrency(Decimal(transaction.amount)))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(transaction.amount >= 0 ? Color(red: 0.5, green: 1.0, blue: 0.5) : .white)  // UPDATED: Better colors for glass background
            }
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
                // Income: light green plus
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.5, green: 1.0, blue: 0.5))  // Light green for glass background
            } else {
                // Expense: light red minus
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.5))  // Light red for glass background
            }
        }
    }
}

// MARK: - Summary List Items (Used in SummaryView for category/payment summaries)
struct SummaryCategoryItem: View {
    let name: String
    let amount: Decimal
    
    var body: some View {
        AppListItem(
            content: {
                Text(name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)  // UPDATED: Changed to .white for better contrast on glass
            },
            trailing: {
                Text(formatCurrency(amount))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(amount >= 0 ? Color(red: 0.5, green: 1.0, blue: 0.5) : .white)  // UPDATED: Better colors for glass background
            }
        )
    }
}

struct SummaryPaymentItem: View {
    let name: String
    let amount: Decimal
    
    var body: some View {
        AppListItem(
            content: {
                HStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))  // UPDATED: Changed to .white with opacity for glass
                    Text(name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)  // UPDATED: Changed to .white for better contrast on glass
                }
            },
            trailing: {
                Text(formatCurrency(amount))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(amount >= 0 ? Color(red: 0.5, green: 1.0, blue: 0.5) : .white)  // UPDATED: Better colors for glass background
            }
        )
    }
}

// MARK: - Glass Card Components (for Summary View totals) - UPDATED with Glass Effects
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))  // UPDATED: Applied glass effect instead of background color
    }
}

struct GlassCardRow: View {
    let label: String
    let value: String
    let valueColor: Color
    var isEmphasized: Bool = false
    
    init(label: String, value: String, valueColor: Color = .white, isEmphasized: Bool = false) {  // UPDATED: Default to .white
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.isEmphasized = isEmphasized
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: isEmphasized ? .semibold : .regular))
                .foregroundColor(isEmphasized ? .white : .white.opacity(0.8))  // UPDATED: Better colors for glass background
            
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
            .foregroundColor(isIncome ? Color(red: 0.5, green: 1.0, blue: 0.5) : Color(red: 1.0, green: 0.5, blue: 0.5))  // UPDATED: Better colors for glass background
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isIncome ? Color(red: 0.5, green: 1.0, blue: 0.5).opacity(0.15) : Color(red: 1.0, green: 0.5, blue: 0.5).opacity(0.15))
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
