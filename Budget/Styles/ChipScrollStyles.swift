import SwiftUI

// MARK: - Simple Capsule Chip Buttons

/// Payment method chip button
struct PaymentChipView: View {
    let paymentMethod: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void
    let namespace: Namespace.ID
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if let emoji = paymentMethod.emoji, !emoji.isEmpty {
                    Text(emoji)
                } else {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 14))
                }
                
                Text(paymentMethod.name)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected ? .regular.tint(.accentColor.opacity(0.2)).interactive() : .clear.interactive()
        )
        .glassEffectID(isSelected ? "selectedChip" : nil, in: namespace)
    }
}

/// Category chip button
struct CategoryChipView: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    let namespace: Namespace.ID
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if let emoji = category.emoji, !emoji.isEmpty {
                    Text(emoji)
                }
                
                Text(category.name)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected ? .regular.tint(.accentColor.opacity(0.2)).interactive() : .clear.interactive()
        )
        .glassEffectID(isSelected ? "selectedChip" : nil, in: namespace)
    }
}

/// Month navigation chip button
struct MonthChipView: View {
    let month: Int
    let year: Int
    let isSelected: Bool
    let onTap: () -> Void
    let namespace: Namespace.ID
    
    var body: some View {
        Button(action: onTap) {
            Text(monthYearString)
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected ? .regular.tint(.accentColor.opacity(0.2)).interactive() : .clear.interactive()
        )
        .glassEffectID(isSelected ? "selectedChip" : nil, in: namespace)
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

/// Manage section chip button
struct ManageSectionChip: View {
    let section: ManageView.ManageSection
    let isSelected: Bool
    let onTap: () -> Void
    let namespace: Namespace.ID
    
    var body: some View {
        Button(action: onTap) {
            Text(section.rawValue)
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected ? .regular.tint(.accentColor.opacity(0.2)).interactive() : .clear.interactive()
        )
        .glassEffectID(isSelected ? "selectedChip" : nil, in: namespace)
    }
}

/// Generic chip button
struct LiquidGlassChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    let namespace: Namespace.ID
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .glassEffect(
            isSelected ? .regular.tint(.accentColor.opacity(0.2)).interactive() : .clear.interactive()
        )
        .glassEffectID(isSelected ? "selectedChip" : nil, in: namespace)
    }
}

// MARK: - Glass Container Chip Groups

/// Container for morphing chips with glass effects
struct ChipGroup<Content: View>: View {
    @ViewBuilder let content: Content
    
    var body: some View {
        GlassEffectContainer(spacing: 8) {
            content
        }
    }
}

// MARK: - Proper Scroll Containers

/// Single row horizontal chip scroll container
struct ChipScrollContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(
        spacing: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ChipGroup {
                HStack(spacing: spacing) {
                    content
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 0)
                .padding(.vertical, 4) // Add vertical padding to prevent clipping
                .scrollTargetLayout()
            }
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollClipDisabled() // Allow content to extend beyond scroll bounds
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: 50) // Set explicit height to prevent vertical clipping
    }
}

/// Right-to-left chip scroll container
struct ChipScrollContainerRTL<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ChipGroup {
                HStack(spacing: spacing) {
                    Spacer(minLength: 0)
                    content
                }
                .padding(.horizontal, 0)
                .padding(.vertical, 4) // Add vertical padding to prevent clipping
                .scrollTargetLayout()
            }
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollClipDisabled() // Allow content to extend beyond scroll bounds
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: 50) // Set explicit height to prevent vertical clipping
        .environment(\.layoutDirection, .rightToLeft)
    }
}

/// Double row chip container
struct DoubleRowChipContainer<FirstRowContent: View, SecondRowContent: View>: View {
    let spacing: CGFloat
    let firstRowContent: FirstRowContent
    let secondRowContent: SecondRowContent?
    let firstRowNamespace: Namespace.ID
    let secondRowNamespace: Namespace.ID?
    
    init(
        spacing: CGFloat = 8,
        firstRowNamespace: Namespace.ID,
        secondRowNamespace: Namespace.ID? = nil,
        @ViewBuilder firstRow: () -> FirstRowContent,
        @ViewBuilder secondRow: () -> SecondRowContent? = { nil }
    ) {
        self.spacing = spacing
        self.firstRowNamespace = firstRowNamespace
        self.secondRowNamespace = secondRowNamespace
        self.firstRowContent = firstRow()
        self.secondRowContent = secondRow()
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 8) {
                ChipGroup {
                    HStack(spacing: spacing) {
                        firstRowContent
                        Spacer()
                    }
                }
                
                if let secondRowContent = secondRowContent {
                    ChipGroup {
                        HStack(spacing: spacing) {
                            secondRowContent
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, 0)
            .padding(.vertical, 4) // Add vertical padding to prevent clipping
        }
        .scrollClipDisabled() // Allow content to extend beyond scroll bounds
        .scrollBounceBehavior(.basedOnSize)
        .frame(height: secondRowContent != nil ? 110 : 50) // Adjust height based on content
    }
}

// MARK: - View Modifiers

struct SingleRowChipScrollModifier<ChipContent: View>: ViewModifier {
    let chips: ChipContent
    
    func body(content: Content) -> some View {
        content.overlay(ChipScrollContainer { chips })
    }
}

struct SingleRowChipScrollRightModifier<ChipContent: View>: ViewModifier {
    let chips: ChipContent
    
    func body(content: Content) -> some View {
        content.overlay(ChipScrollContainerRTL { chips })
    }
}

struct DoubleRowChipScrollModifier<FirstRowContent: View, SecondRowContent: View>: ViewModifier {
    let firstRowChips: FirstRowContent
    let secondRowChips: SecondRowContent?
    let firstRowNamespace: Namespace.ID
    let secondRowNamespace: Namespace.ID?
    
    func body(content: Content) -> some View {
        content.overlay(
            DoubleRowChipContainer(
                firstRowNamespace: firstRowNamespace,
                secondRowNamespace: secondRowNamespace,
                firstRow: { firstRowChips },
                secondRow: { secondRowChips }
            )
        )
    }
}

// MARK: - View Extensions

extension View {
    /// Add single row chip scroll behavior
    func singleRowChipScroll<ChipContent: View>(@ViewBuilder chips: () -> ChipContent) -> some View {
        self.modifier(SingleRowChipScrollModifier(chips: chips()))
    }
    
    /// Add single row chip scroll behavior (right-aligned)
    func singleRowChipScrollRight<ChipContent: View>(@ViewBuilder chips: () -> ChipContent) -> some View {
        self.modifier(SingleRowChipScrollRightModifier(chips: chips()))
    }
    
    /// Add double row chip scroll behavior
    func doubleRowChipScroll<FirstRowContent: View, SecondRowContent: View>(
        firstRowNamespace: Namespace.ID,
        secondRowNamespace: Namespace.ID? = nil,
        @ViewBuilder firstRow: () -> FirstRowContent,
        @ViewBuilder secondRow: () -> SecondRowContent? = { nil }
    ) -> some View {
        self.modifier(DoubleRowChipScrollModifier(
            firstRowChips: firstRow(),
            secondRowChips: secondRow(),
            firstRowNamespace: firstRowNamespace,
            secondRowNamespace: secondRowNamespace
        ))
    }
}
