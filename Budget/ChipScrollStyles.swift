import SwiftUI

// MARK: - Liquid Glass Chip Views - Clean Apple Style
struct PaymentChipView: View {
    let paymentMethod: PaymentMethod
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(paymentMethod.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? Color.white : Color.appText)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial)
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.3))
                }
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(isSelected ? 0.4 : 0.2), lineWidth: 0.5)
            }
        )
        .shadow(
            color: isSelected ? Color.white.opacity(0.2) : Color.black.opacity(0.05),
            radius: isSelected ? 8 : 4,
            x: 0,
            y: isSelected ? 4 : 2
        )
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
                .foregroundColor(isSelected ? Color.white : Color.appText)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial)
                
                if isSelected {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.3))
                }
                
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(isSelected ? 0.4 : 0.2), lineWidth: 0.5)
            }
        )
        .shadow(
            color: isSelected ? Color.white.opacity(0.2) : Color.black.opacity(0.05),
            radius: isSelected ? 8 : 4,
            x: 0,
            y: isSelected ? 4 : 2
        )
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
