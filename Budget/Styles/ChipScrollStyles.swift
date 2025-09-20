import SwiftUI

// MARK: - iOS 26 Liquid Glass Chip Components (Official Apple API)

/// Payment method chip with native iOS 26 Liquid Glass design
struct PaymentChipView: View {
    let paymentMethod: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon or emoji
            Group {
                if let emoji = paymentMethod.emoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.system(size: 16))
                } else {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Payment method name
            Text(paymentMethod.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular.interactive(), in: .capsule)
        .background(
            isSelected ? Color.appAccent.opacity(0.25) : Color.clear,
            in: .capsule
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.bouncy(duration: 0.3), value: isSelected)
        .onTapGesture {
            onTap()
        }
    }
}

/// Category chip with native iOS 26 Liquid Glass design
struct CategoryChipView: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            // Emoji if available
            if let emoji = category.emoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.system(size: 16))
            }
            
            // Category name
            Text(category.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular.interactive(), in: .capsule)
        .background(
            isSelected ? Color.appAccent.opacity(0.25) : Color.clear,
            in: .capsule
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.bouncy(duration: 0.3), value: isSelected)
        .onTapGesture {
            onTap()
        }
    }
}

/// Month navigation chip with native iOS 26 Liquid Glass design
struct MonthChipView: View {
    let month: Int
    let year: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Text(monthYearString)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.regular.interactive(), in: .capsule)
            .background(
                isSelected ? Color.appAccent.opacity(0.25) : Color.clear,
                in: .capsule
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.bouncy(duration: 0.3), value: isSelected)
            .onTapGesture {
                onTap()
            }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        
        var components = DateComponents()
        components.month = month
        components.year = year
        components.day = 1
        
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(month)/\(year)"
    }
}

/// Manage section chip with native iOS 26 Liquid Glass design
struct ManageSectionChip: View {
    let section: ManageView.ManageSection
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Text(section.rawValue)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(.regular.interactive(), in: .capsule)
            .background(
                isSelected ? Color.appAccent.opacity(0.25) : Color.clear,
                in: .capsule
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.bouncy(duration: 0.3), value: isSelected)
            .onTapGesture {
                onTap()
            }
    }
}

/// Generic liquid glass chip for forms (like Expense/Income selectors)
struct LiquidGlassChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .glassEffect(.regular.interactive(), in: .capsule)
            .background(
                isSelected ? Color.appAccent.opacity(0.25) : Color.clear,
                in: .capsule
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.bouncy(duration: 0.3), value: isSelected)
            .onTapGesture {
                onTap()
            }
    }
}

// MARK: - Chip Container System

/// Single row horizontal chip scroll container
struct ChipScrollContainer<Content: View>: View {
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: Content
    
    init(
        spacing: CGFloat = 8,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.alignment = alignment
        self.content = content()
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: spacing) {
                content
                Spacer(minLength: 0)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollClipDisabled()
        .contentMargins(.horizontal, 0)
    }
}

/// Right-to-left chip scroll container (newest first)
struct ChipScrollContainerRTL<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: spacing) {
                content
                Spacer(minLength: 0)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollClipDisabled()
        .contentMargins(.horizontal, 0)
        .environment(\.layoutDirection, .rightToLeft)
    }
}

/// Double row chip container for categories - SIMPLIFIED
struct DoubleRowChipContainer<FirstRowContent: View, SecondRowContent: View>: View {
    let spacing: CGFloat
    let firstRowContent: FirstRowContent
    let secondRowContent: SecondRowContent?
    
    init(
        spacing: CGFloat = 8,
        @ViewBuilder firstRow: () -> FirstRowContent,
        @ViewBuilder secondRow: () -> SecondRowContent? = { nil }
    ) {
        self.spacing = spacing
        self.firstRowContent = firstRow()
        self.secondRowContent = secondRow()
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: spacing) {
                HStack(spacing: spacing) {
                    firstRowContent
                }
                
                if let secondRowContent = secondRowContent {
                    HStack(spacing: spacing) {
                        secondRowContent
                    }
                }
            }
        }
        .scrollClipDisabled()
    }
}

// MARK: - View Modifiers for Backwards Compatibility

struct SingleRowChipScrollModifier<ChipContent: View>: ViewModifier {
    let chips: ChipContent
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ChipScrollContainer {
                    chips
                }
            )
    }
}

struct SingleRowChipScrollRightModifier<ChipContent: View>: ViewModifier {
    let chips: ChipContent
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ChipScrollContainerRTL {
                    chips
                }
            )
    }
}

struct DoubleRowChipScrollModifier<FirstRowContent: View, SecondRowContent: View>: ViewModifier {
    let firstRowChips: FirstRowContent
    let secondRowChips: SecondRowContent?
    
    init(firstRowChips: FirstRowContent, secondRowChips: SecondRowContent? = nil) {
        self.firstRowChips = firstRowChips
        self.secondRowChips = secondRowChips
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                DoubleRowChipContainer(
                    firstRow: { firstRowChips },
                    secondRow: { secondRowChips }
                )
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Add single row chip scroll behavior (left-aligned)
    func singleRowChipScroll<ChipContent: View>(@ViewBuilder chips: () -> ChipContent) -> some View {
        self.modifier(SingleRowChipScrollModifier(chips: chips()))
    }
    
    /// Add single row chip scroll behavior (right-aligned, newest first)
    func singleRowChipScrollRight<ChipContent: View>(@ViewBuilder chips: () -> ChipContent) -> some View {
        self.modifier(SingleRowChipScrollRightModifier(chips: chips()))
    }
    
    /// Add double row chip scroll behavior
    func doubleRowChipScroll<FirstRowContent: View, SecondRowContent: View>(
        @ViewBuilder firstRow: () -> FirstRowContent,
        @ViewBuilder secondRow: () -> SecondRowContent? = { nil }
    ) -> some View {
        self.modifier(DoubleRowChipScrollModifier(
            firstRowChips: firstRow(),
            secondRowChips: secondRow()
        ))
    }
}
