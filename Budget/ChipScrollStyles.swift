import SwiftUI

// MARK: - Shared Glass Background Component
private struct GlassChipBackground: View {
    let isSelected: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.clear)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSelected ? 0.35 : 0.25),
                                Color.white.opacity(isSelected ? 0.25 : 0.15),
                                Color.white.opacity(isSelected ? 0.25 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(isSelected ? 1.0 : 0.6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSelected ? 0.7 : 0.6),
                                Color.white.opacity(isSelected ? 0.3 : 0.2),
                                Color.white.opacity(isSelected ? 0.5 : 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .opacity(isSelected ? 1.0 : 0.7)
            )
    }
}

// MARK: - iOS 18 Style Liquid Glass Chips
struct PaymentChipView: View {
    let paymentMethod: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(paymentMethod.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .background(GlassChipBackground(isSelected: isSelected))
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryChipView: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text("\(category.emoji ?? "") \(category.name)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .background(GlassChipBackground(isSelected: isSelected))
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Single Row Chip Scroll Style
struct SingleRowChipScrollModifier<ChipContent: View>: ViewModifier {
    let chips: ChipContent
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chips
                    }
                    .padding(.horizontal, 0)
                }
                .padding(.horizontal, -16)
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .scrollContentBackground(.hidden)
                .scrollClipDisabled()
            )
    }
}

// MARK: - Double Row Chip Scroll Style
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
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            firstRowChips
                            Spacer(minLength: 0)
                        }
                        
                        if let secondRowChips = secondRowChips {
                            HStack(spacing: 8) {
                                secondRowChips
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    .padding(.horizontal, 0)
                }
                .padding(.horizontal, -16)
                .padding(.leading, 16)
                .padding(.trailing, 16)
                .scrollContentBackground(.hidden)
                .scrollClipDisabled()
            )
    }
}

// MARK: - Convenience Extensions
extension View {
    func singleRowChipScroll<ChipContent: View>(@ViewBuilder chips: () -> ChipContent) -> some View {
        self.modifier(SingleRowChipScrollModifier(chips: chips()))
    }
    
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
