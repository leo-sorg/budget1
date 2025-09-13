import SwiftUI
import UIKit

struct BackgroundView: View {
    @AppStorage("backgroundImageData") private var backgroundImageData: Data?

    var body: some View {
        if let data = backgroundImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        } else {
            Color.appBackground.ignoresSafeArea()
        }
    }
}
