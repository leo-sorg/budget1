import SwiftUI

// MARK: - Default Background Color
extension Color {
    // CHANGE THIS COLOR TO SET THE DEFAULT BACKGROUND FOR THE ENTIRE APP
    static let appDefaultBackground = Color(red: 0x22/255, green: 0x22/255, blue: 0x22/255) // #222222 - Dark grey
}

struct WindowBackgroundView: View {
    @EnvironmentObject private var store: BackgroundImageStore

    var body: some View {
        ZStack {
            // Show either custom color or default background
            if store.useCustomColor {
                store.backgroundColor
                    .ignoresSafeArea(.all)
            } else if store.image == nil {
                Color.appDefaultBackground
                    .ignoresSafeArea(.all)
            }
            
            // Show image on top if available
            if let ui = store.image {
                GeometryReader { proxy in
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .overlay(Color.black.opacity(store.dim))
                        .blur(radius: store.blur)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .ignoresSafeArea(.all)
    }
}
