import SwiftUI

struct WindowBackgroundView: View {
    @EnvironmentObject private var store: BackgroundImageStore

    var body: some View {
        ZStack {
            if store.useCustomColor {
                // Test with a very obvious, bright color first
                let testColor = store.backgroundColor
                Rectangle()
                    .fill(testColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { 
                        print("🎨 Rendering custom color rectangle: \(testColor)")
                        print("🎨 Color components - R: \(testColor.components.red), G: \(testColor.components.green), B: \(testColor.components.blue)")
                    }
            } else if let uiImage = store.image {
                // Custom image background
                Color.appBackground
                backgroundImageLayer(uiImage)
            } else {
                // Default background with material for tab bar
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appBackground,
                                Color.appBackground.opacity(0.95),
                                Color.appBackground
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { 
                        print("🌑 Showing default gradient background") 
                    }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .ignoresSafeArea(.all)
        .onReceive(store.objectWillChange) {
            print("🔄 Background store objectWillChange triggered")
            print("🔄 Current state - useCustomColor: \(store.useCustomColor), backgroundColor: \(store.backgroundColor)")
        }
    }
    
    @ViewBuilder
    private func backgroundImageLayer(_ uiImage: UIImage) -> some View {
        GeometryReader { geometry in
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .overlay(overlayEffects)
        }
    }
    
    @ViewBuilder
    private var overlayEffects: some View {
        if store.dim > 0 || store.blur > 0 {
            Color.black
                .opacity(store.dim)
                .blur(radius: store.blur)
        }
    }
}

// Helper extension to debug color values
extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var opacity: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &opacity)
        return (Double(red), Double(green), Double(blue), Double(opacity))
    }
}
