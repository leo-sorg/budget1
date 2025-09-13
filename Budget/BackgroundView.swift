import SwiftUI
import UIKit

/// Renders the stored background image behind all content.
struct BackgroundView: View {
    @EnvironmentObject private var manager: BackgroundManager

    var body: some View {
        Group {
            if let image = manager.image {
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
