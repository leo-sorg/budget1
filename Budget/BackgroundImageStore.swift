import SwiftUI

@MainActor
final class BackgroundImageStore: ObservableObject {
    @Published var image: UIImage? = nil
    @Published var blur: CGFloat = 0
    @Published var dim: Double = 0
    @Published var backgroundColor: Color = AppAppearance.appBackgroundColor
    @Published var useCustomColor: Bool = false
    @Published var isInitialized: Bool = false

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
        
        // Mark as initialized after loading is complete
        Task { @MainActor in
            // Small delay to ensure all loading operations complete
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            self.isInitialized = true
            print("🎨 BackgroundImageStore: Initialization complete")
            
            // Instead of forcing objectWillChange, configure tab bar properly
            if self.useCustomColor {
                TabBarAppearance.configure(with: self.backgroundColor)
                print("🎨 BackgroundImageStore: Configured TabBar with custom color")
            } else {
                TabBarAppearance.configure(with: AppAppearance.appBackgroundColor)
                print("🎨 BackgroundImageStore: Configured TabBar with default color")
            }
        }
    }

    func setImage(_ newImage: UIImage?) {
        Task { @MainActor in
            self.useCustomColor = false // Switch to image mode first
            self.image = newImage
            
            if let img = newImage, let data = img.jpegData(compressionQuality: 0.9) {
                try? data.write(to: self.fileURL, options: .atomic)
            } else {
                try? FileManager.default.removeItem(at: self.fileURL)
            }
            self.saveColorToDisk()
        }
    }
    
    func setColor(_ newColor: Color) {
        print("🔥 BackgroundImageStore.setColor() STARTED")
        print("🔥 Input color: \(newColor)")
        print("🔥 Current state BEFORE - useCustomColor: \(useCustomColor), backgroundColor: \(backgroundColor)")
        
        // Ensure we're on the main thread and update atomically
        Task { @MainActor in
            print("🔥 Inside Task @MainActor - about to update state")
            
            // Update all properties at once to prevent intermediate states
            let wasUsingCustomColor = self.useCustomColor
            let oldImage = self.image
            let oldBackgroundColor = self.backgroundColor
            
            print("🔥 Stored old values - wasUsingCustomColor: \(wasUsingCustomColor), oldBackgroundColor: \(oldBackgroundColor)")
            
            self.image = nil // Clear image first
            self.useCustomColor = true
            self.backgroundColor = newColor
            
            print("🔥 State updated - useCustomColor: \(self.useCustomColor), backgroundColor: \(self.backgroundColor)")
            print("🔥 About to save to disk and update TabBar")
            
            // Only save and clean up files if we successfully set the new state
            do {
                self.saveColorToDisk()
                
                // Remove image file when switching to color
                if oldImage != nil {
                    try? FileManager.default.removeItem(at: self.fileURL)
                }
                print("🔥 Successfully saved color to disk")
                
                // Update the tab bar appearance with the new background color
                print("🔥 About to call TabBarAppearance.updateForBackgroundChange")
                TabBarAppearance.updateForBackgroundChange(newColor)
                print("🔥 TabBar appearance update completed")
                
                // Force a UI update
                print("🔥 About to trigger objectWillChange")
                self.objectWillChange.send()
                print("🔥 objectWillChange.send() completed")
                
            } catch {
                // If something goes wrong, revert the state
                print("🔥 ERROR saving color settings: \(error)")
                self.useCustomColor = wasUsingCustomColor
                self.image = oldImage
                self.backgroundColor = oldBackgroundColor
            }
            
            print("🔥 BackgroundImageStore.setColor() COMPLETED")
        }
    }
    
    func resetToDefault() {
        Task { @MainActor in
            self.image = nil
            self.useCustomColor = false
            self.backgroundColor = AppAppearance.appBackgroundColor
            
            try? FileManager.default.removeItem(at: self.fileURL)
            try? FileManager.default.removeItem(at: self.colorFileURL)
        }
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
        } else {
            // If no saved data, ensure we start with proper defaults
            useCustomColor = false
            backgroundColor = AppAppearance.appBackgroundColor
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
