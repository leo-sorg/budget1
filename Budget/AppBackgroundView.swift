import SwiftUI

struct AppBackgroundView: View {
    @EnvironmentObject var store: BackgroundImageStore

    var body: some View {
        Group {
            if let image = store.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.appBackground
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

extension View {
    func appBackground() -> some View {
        background(AppBackgroundView())
    }
}
