import SwiftUI

// MARK: - Glass Selector Background Component
private struct GlassSelectorBackground: View {
    let isSelected: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.clear)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .opacity(0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
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
                RoundedRectangle(cornerRadius: 12)
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

// MARK: - Glass Selector View
struct GlassSelector<T: Hashable>: View {
    @Binding var selection: T
    let options: [(T, String)]
    @Namespace private var animation
    
    init(selection: Binding<T>, options: [(T, String)]) {
        self._selection = selection
        self.options = options
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                let (value, title) = option
                let isSelected = selection == value
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = value
                    }
                } label: {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                }
                .background(
                    GlassSelectorBackground(isSelected: isSelected)
                        .matchedGeometryEffect(
                            id: isSelected ? "selection" : "background_\(index)",
                            in: animation
                        )
                )
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.clear)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .opacity(0.3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                        .opacity(0.5)
                )
        )
    }
}

// MARK: - Convenience Extensions
extension View {
    func glassSelector<T: Hashable>(
        selection: Binding<T>,
        options: [(T, String)]
    ) -> some View {
        GlassSelector(selection: selection, options: options)
    }
}

// MARK: - Boolean Glass Selector (for common true/false cases)
struct BooleanGlassSelector: View {
    @Binding var selection: Bool
    let trueTitle: String
    let falseTitle: String
    
    init(selection: Binding<Bool>, trueTitle: String, falseTitle: String) {
        self._selection = selection
        self.trueTitle = trueTitle
        self.falseTitle = falseTitle
    }
    
    var body: some View {
        GlassSelector(
            selection: $selection,
            options: [(true, trueTitle), (false, falseTitle)]
        )
    }
}
