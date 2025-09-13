import SwiftUI

// MARK: - Transparent Section Header Style
struct TransparentSectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.appText.opacity(0.6))
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

// MARK: - App Picker Style
extension View {
    func appPickerStyle() -> some View {
        self
            .pickerStyle(.menu)
            .foregroundColor(.appAccent)
            .transparentListSection()
    }
}

// MARK: - Section Container Style
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
// MARK: - Ultra Thin Material Button Style
struct AppMaterialButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundColor(isDestructive ? .red : .appAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// MARK: - Extension for easy use
extension View {
    func appMaterialButton(isDestructive: Bool = false) -> some View {
        self.buttonStyle(AppMaterialButtonStyle(isDestructive: isDestructive))
    }
}

// MARK: - Material Container Style (for consistent containers)
struct MaterialContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

extension View {
    func materialContainer() -> some View {
        MaterialContainer { self }
    }
}
