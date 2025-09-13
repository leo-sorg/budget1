import SwiftUI

struct AppBackgroundView: View {
    @EnvironmentObject var store: BackgroundImageStore

    var body: some View {
        Group {
            if let ui = store.image {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.appBackground
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
