import SwiftUI
import UIKit

/// Manages the optional background image for the app.
class BackgroundManager: ObservableObject {
    @AppStorage("backgroundImageData") private var storedData: Data?
    @Published var image: UIImage?

    init() {
        if let data = storedData, let uiImage = UIImage(data: data) {
            image = uiImage
        }
    }

    /// Update the background image with raw data.
    func setImageData(_ data: Data) {
        storedData = data
        image = UIImage(data: data)
    }
}
