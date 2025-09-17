import SwiftUI

// MARK: - Reusable Glass List Item Component with Swipe to Delete
struct AppListItem<Content: View, TrailingContent: View>: View {
    let content: Content
    let trailingContent: TrailingContent
    let onDelete: (() -> Void)?
    
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    
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
        ZStack(alignment: .trailing) {
            // Delete button background (revealed on swipe) - BEHIND the main content
            if onDelete != nil && (offset < 0 || isSwiped) {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            offset = -UIScreen.main.bounds.width
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDelete?()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.5))
                            Text("Delete")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .frame(width: 80)
                        .frame(maxHeight: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .transition(.opacity)
            }
            
            // Main content - SOLID BACKGROUND to cover the delete button
            HStack(spacing: 12) {
                content
                
                Spacer()
                
                trailingContent
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.13)) // Solid dark background first
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .opacity(0.3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .offset(x: offset)
            .modifier(SwipeToDeleteModifier(
                onDelete: onDelete,
                offset: $offset,
                isSwiped: $isSwiped
            ))
            .onTapGesture {
                if isSwiped {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = 0
                        isSwiped = false
                    }
                }
            }
        }
        .clipped() // Ensure delete button doesn't show outside bounds
    }
}

// MARK: - Swipe to Delete Modifier (Only applied when needed)
private struct SwipeToDeleteModifier: ViewModifier {
    let onDelete: (() -> Void)?
    @Binding var offset: CGFloat
    @Binding var isSwiped: Bool
    
    func body(content: Content) -> some View {
        if onDelete != nil {
            content
                .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onChanged { value in
                            let horizontalAmount = value.translation.width
                            let verticalAmount = value.translation.height
                            
                            // Much more strict: only handle clearly horizontal gestures
                            // If vertical movement is more than 30% of horizontal, ignore
                            if abs(verticalAmount) > abs(horizontalAmount) * 0.3 {
                                return
                            }
                            
                            // Only handle left swipes for delete
                            if horizontalAmount < 0 {
                                offset = max(-100, horizontalAmount)
                            } else if isSwiped {
                                offset = min(0, -80 + horizontalAmount)
                            }
                        }
                        .onEnded { value in
                            let horizontalAmount = value.translation.width
                            let verticalAmount = value.translation.height
                            
                            // Same strict check for vertical gestures
                            if abs(verticalAmount) > abs(horizontalAmount) * 0.3 {
                                withAnimation(.spring(response: 0.15, dampingFraction: 0.9)) {
                                    offset = 0
                                    isSwiped = false
                                }
                                return
                            }
                            
                            // Handle horizontal swipe completion
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                let threshold: CGFloat = -40
                                if offset < threshold {
                                    offset = -80
                                    isSwiped = true
                                } else {
                                    offset = 0
                                    isSwiped = false
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    // Add a tap gesture to close swipe if tapped
                    TapGesture()
                        .onEnded { _ in
                            if isSwiped {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    offset = 0
                                    isSwiped = false
                                }
                            }
                        }
                )
        } else {
            content
        }
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

// MARK: - Payment Method List Item (Updated to show emoji)
struct PaymentMethodListItem: View {
    let paymentMethod: PaymentMethod
    let onDelete: () -> Void
    
    var body: some View {
        AppListItem(
            content: {
                HStack(spacing: 12) {
                    // Payment method emoji (fallback to card icon)
                    if let emoji = paymentMethod.emoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.system(size: 20))
                    } else {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
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
