import SwiftUI

struct WindowBackgroundView: View {
    @EnvironmentObject private var store: BackgroundImageStore

    var body: some View {
        ZStack {
            // Background color layer
            backgroundColorLayer
            
            // Image layer (if available)
            backgroundImageLayer
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .ignoresSafeArea(.all)
    }
    
    @ViewBuilder
    private var backgroundColorLayer: some View {
        if store.useCustomColor {
            store.backgroundColor
                .ignoresSafeArea(.all)
        } else if store.image == nil {
            Color.appBackground
                .ignoresSafeArea(.all)
        }
    }
    
    @ViewBuilder
    private var backgroundImageLayer: some View {
        if let uiImage = store.image {
            GeometryReader { geometry in
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .overlay(overlayEffects)
            }
        }
    }
    
    @ViewBuilder
    private var overlayEffects: some View {
        Color.black
            .opacity(store.dim)
            .blur(radius: store.blur)
    }
}
