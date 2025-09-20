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

// MARK: - Material Container (system only)
struct MaterialContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.thinMaterial, lineWidth: 1)
            )
    }
}

extension View {
    func materialContainer() -> some View {
        MaterialContainer { self }
    }
    
    // Keep compatibility helper; map to default liquid glass button styles
    func appMaterialButton(isDestructive: Bool = false) -> some View {
        // We use our custom liquid-glass button style everywhere for consistency.
        // Callers can apply a role or color as needed where the Button is created.
        self.buttonStyle(AppSmallButtonStyle())
    }
}
