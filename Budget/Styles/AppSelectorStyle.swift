import SwiftUI

// MARK: - Simple selector using Apple Materials only
private struct SelectorBackground: View {
    let isSelected: Bool

    var body: some View {
        let background: Material = isSelected ? .regularMaterial : .ultraThinMaterial
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(background)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.thinMaterial, lineWidth: 1)
            )
    }
}

// MARK: - Glass Selector View (Material only)
struct GlassSelector<T: Hashable>: View {
    @Binding var selection: T
    let options: [(T, String)]

    init(selection: Binding<T>, options: [(T, String)]) {
        self._selection = selection
        self.options = options
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                let (value, title) = option
                let isSelected = selection == value
                
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        selection = value
                    }
                } label: {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                }
                .background(SelectorBackground(isSelected: isSelected))
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.thinMaterial, lineWidth: 1)
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

// MARK: - Boolean Glass Selector
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
