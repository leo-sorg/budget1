import SwiftUI

// MARK: - Reusable Glass List Item Component
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
            
            if let onDelete = onDelete {
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.clear)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .opacity(0.3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
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

// MARK: - Glass Card Background (Liquid Glass Style - Same as buttons/chips)
private struct GlassCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.clear)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(0.6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .opacity(0.7)
            )
    }
}

// MARK: - Glass Card Component (Liquid Glass Style)
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(GlassCardBackground())
    }
}

// MARK: - Glass Card Row (for stats/summaries)
struct GlassCardRow: View {
    let label: String
    let value: String
    let valueColor: Color
    var isEmphasized: Bool = false
    
    init(label: String, value: String, valueColor: Color = .white, isEmphasized: Bool = false) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.isEmphasized = isEmphasized
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: isEmphasized ? .semibold : .regular))
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: isEmphasized ? .semibold : .regular))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Income/Expense Tag Component (NEW)
struct CategoryTypeTag: View {
    let isIncome: Bool
    
    var body: some View {
        Text(isIncome ? "Income" : "Expense")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(isIncome ?
                Color(red: 0.5, green: 1.0, blue: 0.5) :  // Light green
                Color(red: 1.0, green: 0.5, blue: 0.5)     // Light red
            )
    }
}

// MARK: - Category List Item - COMPLETELY REBUILT
struct CategoryListItem: View {
    let category: Category
    let onDelete: () -> Void
    
    var body: some View {
        AppListItem(
            content: {
                HStack(spacing: 12) {
                    // Emoji
                    Text(category.emoji ?? "🏷️")
                        .font(.system(size: 20))
                    
                    // Name
                    Text(category.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            },
            trailing: {
                // New Income/Expense tag
                CategoryTypeTag(isIncome: category.isIncome)
            },
            onDelete: onDelete
        )
    }
}

// MARK: - Payment Method List Item
struct PaymentMethodListItem: View {
    let paymentMethod: PaymentMethod
    let onDelete: () -> Void
    
    var body: some View {
        AppListItem(
            content: {
                HStack(spacing: 12) {
                    // Payment method icon
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                    
                    // Name
                    Text(paymentMethod.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            },
            trailing: {
                EmptyView()
            },
            onDelete: onDelete
        )
    }
}

// MARK: - List Container with Header
struct AppListSection<Items: RandomAccessCollection, ItemContent: View>: View where Items.Element: Identifiable {
    let title: String
    let emptyMessage: String
    let items: Items
    let addButtonAction: () -> Void
    let itemContent: (Items.Element) -> ItemContent
    
    init(
        title: String,
        emptyMessage: String,
        items: Items,
        onAdd: @escaping () -> Void,
        @ViewBuilder itemContent: @escaping (Items.Element) -> ItemContent
    ) {
        self.title = title
        self.emptyMessage = emptyMessage
        self.items = items
        self.addButtonAction = onAdd
        self.itemContent = itemContent
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(spacing: 16) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.appText)
                    Spacer()
                    Button("Add", action: addButtonAction)
                        .buttonStyle(AppSmallButtonStyle())
                }
                
                if items.isEmpty {
                    Text(emptyMessage)
                        .foregroundColor(.appText.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 8) {
                        ForEach(items) { item in
                            itemContent(item)
                        }
                    }
                }
            }
        }
    }
}
