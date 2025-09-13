import SwiftUI
import UIKit

/// Displays the stored background image behind all content.
struct BackgroundImageView: View {
    @EnvironmentObject private var store: BackgroundImageStore

    var body: some View {
        Group {
            if let image = store.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                Color.appBackground
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
