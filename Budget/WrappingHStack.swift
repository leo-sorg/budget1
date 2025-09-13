import SwiftUI

struct WrappingHStack<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let spacing: CGFloat
    let lineSpacing: CGFloat
    let content: (Data.Element) -> Content
    @State private var totalHeight: CGFloat = .zero

    init(_ data: Data, spacing: CGFloat = 8, lineSpacing: CGFloat = 8, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(data) { item in
                content(item)
                    .alignmentGuide(.leading) { d in
                        if width + d.width > geometry.size.width {
                            width = 0
                            height += d.height + lineSpacing
                        }
                        let result = width
                        width += d.width + spacing
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        return result
                    }
            }
        }
        .background(GeometryReader { geo in
            Color.clear
                .preference(key: HeightPreferenceKey.self, value: geo.size.height)
        })
        .onPreferenceChange(HeightPreferenceKey.self) { totalHeight = $0 }
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

