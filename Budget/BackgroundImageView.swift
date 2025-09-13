import SwiftUI
import UIKit

/// Displays either the user-selected background image or the default
/// background color. The image automatically scales to fill the screen.
struct BackgroundImageView: View {
    @AppStorage("backgroundImage") private var backgroundImageData: Data?

    var body: some View {
        Group {
            if let data = backgroundImageData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
        }
    }
}
