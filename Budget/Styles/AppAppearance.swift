import SwiftUI
import UIKit

// MARK: - General App Appearance (Non-TabBar)
enum AppAppearance {
    
    // DEFINE BACKGROUND COLOR - TESTING WITH BRIGHT BLUE
    static let appBackgroundColor: Color = Color.blue
    
    static func configure() {
        print("🔧 AppAppearance.configure() called")
        print("🔧 Using test background color: \(appBackgroundColor)")
        configureGeneralAppearance()
    }
    
    static func updateDynamicColors() {
        print("🔧 AppAppearance.updateDynamicColors() called")
        configureGeneralAppearance()
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
