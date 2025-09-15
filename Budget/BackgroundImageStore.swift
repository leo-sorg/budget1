import SwiftUI

@MainActor
final class BackgroundImageStore: ObservableObject {
    @Published var image: UIImage? = nil
    @Published var blur: CGFloat = 0
    @Published var dim: Double = 0
    @Published var backgroundColor: Color = Color.appDefaultBackground
    @Published var useCustomColor: Bool = false

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("window_background.jpg")
    }()
    
    private let colorFileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("background_color.json")
    }()

    init() {
        loadFromDisk()
        loadColorFromDisk()
    }

    func setImage(_ newImage: UIImage?) {
        image = newImage
        useCustomColor = false // Switch to image mode
        if let img = newImage, let data = img.jpegData(compressionQuality: 0.9) {
            try? data.write(to: fileURL, options: .atomic)
        } else {
            try? FileManager.default.removeItem(at: fileURL)
        }
        saveColorToDisk()
    }
    
    func setColor(_ newColor: Color) {
        // Force UI update by updating all properties on main thread
        backgroundColor = newColor
        useCustomColor = true
        image = nil // Clear image when using color
        saveColorToDisk()
        // Remove image file when switching to color
        try? FileManager.default.removeItem(at: fileURL)
        
        // Force view refresh
        objectWillChange.send()
    }
    
    func resetToDefault() {
        image = nil
        useCustomColor = false
        backgroundColor = Color.appDefaultBackground
        try? FileManager.default.removeItem(at: fileURL)
        try? FileManager.default.removeItem(at: colorFileURL)
        
        // Force view refresh
        objectWillChange.send()
    }

    private func loadFromDisk() {
        if let data = try? Data(contentsOf: fileURL), let img = UIImage(data: data) {
            image = img
        }
    }
    
    private func loadColorFromDisk() {
        if let data = try? Data(contentsOf: colorFileURL),
           let json = try? JSONDecoder().decode(ColorData.self, from: data) {
            useCustomColor = json.useCustomColor
            if useCustomColor {
                backgroundColor = Color(
                    red: json.red,
                    green: json.green,
                    blue: json.blue
                )
            }
        }
    }
    
    private func saveColorToDisk() {
        let uiColor = UIColor(backgroundColor)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let colorData = ColorData(
            useCustomColor: useCustomColor,
            red: Double(red),
            green: Double(green),
            blue: Double(blue)
        )
        
        if let data = try? JSONEncoder().encode(colorData) {
            try? data.write(to: colorFileURL, options: .atomic)
        }
    }
}

private struct ColorData: Codable {
    let useCustomColor: Bool
    let red: Double
    let green: Double
    let blue: Double
}
