import SwiftUI

@MainActor
final class BackgroundImageStore: ObservableObject {
    @Published var image: UIImage? = nil
    @Published var blur: CGFloat = 0
    @Published var dim: Double = 0

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("window_background.jpg")
    }()

    init() { loadFromDisk() }

    func setImage(_ newImage: UIImage?) {
        image = newImage
        if let img = newImage, let data = img.jpegData(compressionQuality: 0.9) {
            try? data.write(to: fileURL, options: .atomic)
        } else {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private func loadFromDisk() {
        if let data = try? Data(contentsOf: fileURL), let img = UIImage(data: data) {
            image = img
        }
    }
}
