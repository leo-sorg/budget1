import SwiftUI
import UIKit

/// Stores and retrieves a custom background image using the documents directory.
@MainActor
class BackgroundImageStore: ObservableObject {
    @Published var image: UIImage?

    private let filename = "background.png"

    init() {
        loadImage()
    }

    /// Save a new image and persist it to disk.
    func updateImage(_ newImage: UIImage) {
        image = newImage
        if let data = newImage.pngData() {
            try? data.write(to: fileURL())
        }
    }

    /// Remove the stored image.
    func clearImage() {
        image = nil
        try? FileManager.default.removeItem(at: fileURL())
    }

    private func loadImage() {
        let url = fileURL()
        if let data = try? Data(contentsOf: url),
           let uiImage = UIImage(data: data) {
            image = uiImage
        }
    }

    private func fileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(filename)
    }
}
