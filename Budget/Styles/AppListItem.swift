import SwiftUI

// MARK: - Reusable List Item with Liquid glass background and swipe-to-delete
struct AppListItem<Content: View, TrailingContent: View>: View {
    let content: Content
    let trailingContent: TrailingContent
    let onDelete: (() -> Void)?
    
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    
    private let revealWidth: CGFloat = 88
    
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
            // Delete action area revealed on swipe — pure system visuals
            if onDelete != nil && (offset < 0 || isSwiped) {
                HStack {
                    Spacer()
                    Button(role: .destructive) {
                        withAnimation(.easeOut(duration: 0.25)) {
                            offset = -UIScreen.main.bounds.width
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            onDelete?()
                        }
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: revealWidth)
                            .frame(maxHeight: .infinity)
                    }
                    .buttonStyle(.plain)
                    .tint(.red)
                }
                .background(.regularMaterial)
                .transition(.opacity)
            }
            
            // Main content — Liquid glass via helper
            HStack(spacing: 12) {
                content
                Spacer()
                trailingContent
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
            .offset(x: offset)
            .modifier(SwipeToDeleteModifier(
                onDelete: onDelete,
                offset: $offset,
                isSwiped: $isSwiped,
                revealWidth: revealWidth
            ))
            .onTapGesture {
                if isSwiped {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = 0
                        isSwiped = false
                    }
                }
            }
            .accessibilityActions {
                if onDelete != nil {
                    Button("Delete", role: .destructive) {
                        onDelete?()
                    }
                }
            }
        }
        .clipped()
    }
}

// MARK: - Swipe to Delete Modifier (system-like behavior)
private struct SwipeToDeleteModifier: ViewModifier {
    let onDelete: (() -> Void)?
    @Binding var offset: CGFloat
    @Binding var isSwiped: Bool
    let revealWidth: CGFloat
    
    // Internal gesture state
    @State private var swipeLocked: Bool = false
    @State private var startedOnThisRow: Bool = false
    @State private var initialTranslation: CGSize = .zero
    
    func body(content: Content) -> some View {
        guard onDelete != nil else { return AnyView(content) }
        
        let drag = DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                if !startedOnThisRow {
                    startedOnThisRow = true
                    initialTranslation = value.translation
                }
                
                let dx = value.translation.width
                let dy = value.translation.height
                
                if !swipeLocked {
                    let horizontalDelta = abs(dx - initialTranslation.width)
                    let verticalDelta = abs(dy - initialTranslation.height)
                    
                    if horizontalDelta > 8 && horizontalDelta > verticalDelta * 0.6 {
                        swipeLocked = true
                    } else {
                        if verticalDelta > horizontalDelta {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                                if !isSwiped { offset = 0 }
                            }
                        }
                        return
                    }
                }
                
                if dx < 0 {
                    offset = max(-revealWidth, dx)
                } else if isSwiped {
                    offset = min(0, -revealWidth + dx)
                } else {
                    offset = 0
                }
            }
            .onEnded { _ in
                defer {
                    swipeLocked = false
                    startedOnThisRow = false
                    initialTranslation = .zero
                }
                
                guard swipeLocked else {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.9)) {
                        if !isSwiped { offset = 0 }
                    }
                    return
                }
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    let threshold: CGFloat = -(revealWidth * 0.5)
                    if offset < threshold {
                        offset = -revealWidth
                        isSwiped = true
                    } else {
                        offset = 0
                        isSwiped = false
                    }
                }
            }
        
        return AnyView(
            content
                .highPriorityGesture(drag, including: .all)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        if isSwiped {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                offset = 0
                                isSwiped = false
                            }
                        }
                    }
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

// MARK: - Glass Card (Apple Liquid Glass)
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
    }
}

// MARK: - Glass Card Row (Apple Liquid Glass)
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
                .foregroundColor(.white.opacity(isEmphasized ? 1.0 : 0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: isEmphasized ? .semibold : .medium))
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Income/Expense Tag (system colors)
struct CategoryTypeTag: View {
    let isIncome: Bool
    
    var body: some View {
        Text(isIncome ? "Income" : "Expense")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isIncome ? .green : .red)
    }
}

// MARK: - Category List Item
struct CategoryListItem: View {
    let category: Category
    let onDelete: () -> Void
    
    var body: some View {
        AppListItem(
            content: {
                HStack(spacing: 12) {
                    Text(category.emoji ?? "🏷️")
                        .font(.system(size: 20))
                        .foregroundStyle(.primary)
                    Text(category.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                }
            },
            trailing: {
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
                    if let emoji = paymentMethod.emoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.system(size: 20))
                            .foregroundStyle(.primary)
                    } else {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(paymentMethod.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                }
            },
            trailing: {
                EmptyView()
            },
            onDelete: onDelete
        )
    }
}

// MARK: - List Section with standard controls and system colors
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
                        .foregroundStyle(.primary)
                    Spacer()
                    Button("Add", action: addButtonAction)
                        .buttonStyle(AppSmallButtonStyle())
                }
                
                if items.isEmpty {
                    Text(emptyMessage)
                        .foregroundStyle(.secondary)
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
