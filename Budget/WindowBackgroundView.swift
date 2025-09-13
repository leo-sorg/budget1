import SwiftUI

struct WindowBackgroundView: View {
    @EnvironmentObject private var store: BackgroundImageStore

    var body: some View {
        GeometryReader { proxy in
            if let ui = store.image {
                Image(uiImage: ui)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .overlay(Color.black.opacity(store.dim))
                    .blur(radius: store.blur)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .ignoresSafeArea(.all)
    }
}
