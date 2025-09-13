import SwiftUI

struct AppChipModifier: ViewModifier {
    var isSelected: Bool
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.appAccent : Color.appTabBar)
            .foregroundColor(isSelected ? Color.appBackground : Color.appText)
            .clipShape(Capsule())
    }
}

extension View {
    func appChip(isSelected: Bool) -> some View {
        modifier(AppChipModifier(isSelected: isSelected))
    }
}
