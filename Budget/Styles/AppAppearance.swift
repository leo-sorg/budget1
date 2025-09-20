import SwiftUI
import UIKit

// MARK: - General App Appearance (Non-TabBar)
@MainActor
class AppAppearance: ObservableObject {
    
    // DYNAMIC BACKGROUND COLOR - starts with magenta, can be changed
    @Published var appBackgroundColor: Color = Color(red: 1.0, green: 0.0, blue: 1.0) // BRIGHT MAGENTA
    
    // Shared instance for global access
    static let shared = AppAppearance()
    
    private init() {}
    
    // Update the background color globally
    func setBackgroundColor(_ newColor: Color) {
        appBackgroundColor = newColor
        print("🎨 AppAppearance: Updated global background color to: \(newColor)")
        updateDynamicColors()
    }
    
    static func configure() {
        print("🔧 AppAppearance.configure() called")
        print("🔧 Using background color: \(shared.appBackgroundColor)")
        
        // CRITICAL: FORCE ALL WINDOWS TO NOT OVERRIDE INTERFACE STYLE
        DispatchQueue.main.async {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        // SET TO UNSPECIFIED - DO NOT FORCE ANY MODE
                        window.overrideUserInterfaceStyle = .unspecified
                        // ALSO SET BACKGROUND COLOR AT WINDOW LEVEL
                        window.backgroundColor = UIColor(shared.appBackgroundColor)
                        print("🔧 Set window background to: \(shared.appBackgroundColor)")
                        print("🔧 Set window.overrideUserInterfaceStyle to .unspecified")
                    }
                }
            }
        }
        
        configureGeneralAppearance()
    }
    
    func updateDynamicColors() {
        print("🔧 AppAppearance.updateDynamicColors() called")
        AppAppearance.configureGeneralAppearance()
        
        // Update window backgrounds when color changes
        DispatchQueue.main.async {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene {
                    for window in windowScene.windows {
                        window.backgroundColor = UIColor(self.appBackgroundColor)
                        print("🔧 Updated window background to new color: \(self.appBackgroundColor)")
                    }
                }
            }
        }
    }
    
    private static func configureGeneralAppearance() {
        print("🔧 Configuring general app appearance (non-TabBar)")
        
        // Navigation Bar - Transparent (ONLY thing that should be clear)
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = UIColor.clear
        navBarAppearance.shadowColor = UIColor.clear
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = navBarAppearance
        navBar.scrollEdgeAppearance = navBarAppearance
        navBar.compactAppearance = navBarAppearance
        navBar.isTranslucent = true
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.shadowImage = UIImage()
        
        // STOP CLEARING EVERYTHING - this was making the screen black!
        // Only clear table view separators
        UITableView.appearance().separatorStyle = .none
        
        print("🔧 General app appearance configured")
    }
}
