import SwiftUI

// MARK: - Transparent Section Header Style (system colors)
struct TransparentSectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.clear)
        .listRowInsets(EdgeInsets())
    }
}

// MARK: - Transparent List Section
extension View {
    func transparentListSection() -> some View {
        self
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

// MARK: - App Picker Style (system only)
extension View {
    func appPickerStyle() -> some View {
        self
            .pickerStyle(.menu)
            .tint(.accentColor)
            .transparentListSection()
    }
}

// MARK: - Section Container (Material only)
struct SectionContainer<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TransparentSectionHeader(title: title)
            
            VStack(spacing: 8) {
                content
            }
            .padding(.horizontal, 16)
        }
        .background(Color.clear)
    }
}

// MARK: - Glass Container (Apple Liquid Glass)
struct GlassContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

// MARK: - Material Container (Updated to use Liquid Glass)
struct MaterialContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: .rect(cornerRadius: 8))
    }
}

extension View {
    func materialContainer() -> some View {
        MaterialContainer { self }
    }
    
    // Updated to use proper Liquid Glass API
    func appMaterialButton(isDestructive: Bool = false) -> some View {
        self.buttonStyle(AppSmallButtonStyle())
    }
    
    // Helper for using glass effects easily
    func glassContainer() -> some View {
        GlassContainer { self }
    }
}
