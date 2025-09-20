import SwiftUI
import UIKit

// MARK: - TabBar Appearance Management
enum TabBarAppearance {
    static func configure(with backgroundColor: Color) {
        print("🔥 TabBarAppearance.configure() called with color: \(backgroundColor)")
        configureTabBar(with: backgroundColor)
    }
    
    private static func configureTabBar(with backgroundColor: Color) {
        print("🔥 configureTabBar() STARTED")
        print("🔥 Input backgroundColor: \(backgroundColor)")
        
        // Convert SwiftUI Color to UIColor
        let uiBackgroundColor = UIColor(backgroundColor)
        print("🔥 Converted to UIColor: \(uiBackgroundColor)")
        
        // SIMPLE APPROACH - Just set basic appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = uiBackgroundColor.withAlphaComponent(0.9)
        
        print("🔥 Set tabBarAppearance.backgroundColor to: \(uiBackgroundColor)")
        
        // Simple item colors
        let normalColor = UIColor.white
        let selectedColor = UIColor.white
        
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = normalColor
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        
        // Apply to the tab bar appearance proxy
        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabBarAppearance
        tabBar.scrollEdgeAppearance = tabBarAppearance
        
        print("🔥 configureTabBar() COMPLETED")
    }
    
    private static func configureTabBarItemAppearance(_ appearance: UITabBarItemAppearance, normal: UIColor, selected: UIColor) {
        appearance.normal.iconColor = normal
        appearance.normal.titleTextAttributes = [.foregroundColor: normal]
        appearance.selected.iconColor = selected
        appearance.selected.titleTextAttributes = [.foregroundColor: selected]
    }
    
    static func updateForBackgroundChange(_ backgroundColor: Color) {
        print("🔥 TabBarAppearance.updateForBackgroundChange() STARTED with color: \(backgroundColor)")
        configureTabBar(with: backgroundColor)
        
        // The key insight: force refresh through multiple approaches
        DispatchQueue.main.async {
            forceRefreshExistingTabBars()
        }
    }
    
    private static func forceRefreshExistingTabBars() {
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    if let tabBarController = window.rootViewController?.findTabBarController() {
                        print("🔥 Found tab bar controller! Forcing appearance refresh")
                        
                        // Force the tab bar to re-read its appearance
                        tabBarController.tabBar.setNeedsLayout()
                        tabBarController.tabBar.layoutIfNeeded()
                        
                        print("🔥 Tab bar appearance refresh completed")
                        
                        // Exit early since we found and refreshed the tab bar
                        return
                    }
                }
            }
        }
        print("🔥 No tab bar controller found in any window")
    }
}

// MARK: - Helper Extensions
extension UIViewController {
    func findTabBarController() -> UITabBarController? {
        if let tabBarController = self as? UITabBarController {
            return tabBarController
        }
        
        for child in children {
            if let result = child.findTabBarController() {
                return result
            }
        }
        
        return nil
    }
}
