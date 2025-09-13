import SwiftUI

extension View {
    func appSheetStyle() -> some View {
        self
            .presentationDetents([.fraction(0.5)])
            .presentationDragIndicator(.visible)
            .presentationBackground(Color.appBackground)
    }
}
