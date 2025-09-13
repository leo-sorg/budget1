import SwiftUI
import UIKit

struct BackgroundView: View {
    @AppStorage("backgroundImageData") private var backgroundImageData: Data?

    var body: some View {
        if let data = backgroundImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()
                // Ensure the background image does not intercept touches
                .allowsHitTesting(false)
        } else {
            // Static background color that never captures interactions
            Color.appBackground
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
}
