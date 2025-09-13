import SwiftUI

struct WindowBackgroundView: View {
    @EnvironmentObject private var store: BackgroundImageStore

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                if let ui = store.image {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                } else {
                    Color.appBackground
                }
            }
            .frame(width: size.width, height: size.height)
            .overlay(Color.black.opacity(store.dim))
            .blur(radius: store.blur)
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
