import SwiftUI
import UIKit

// MARK: - TabBar Appearance Management
enum TabBarAppearance {
    static func configure(with backgroundColor: Color) {
        configureTabBar(with: backgroundColor)
    }
    
    private static func configureTabBar(with backgroundColor: Color) {
        // Convert SwiftUI Color to UIColor
        let uiBackgroundColor = UIColor(backgroundColor)
        
        // SIMPLE APPROACH - Just set basic appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundColor = uiBackgroundColor.withAlphaComponent(0.9)
        
        // Simple item colors with better contrast
        let normalColor = UIColor.systemGray
        let selectedColor = UIColor.white
        
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = normalColor
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        // Also configure compact and inline layouts for better compatibility
        tabBarAppearance.compactInlineLayoutAppearance.normal.iconColor = normalColor
        tabBarAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        tabBarAppearance.compactInlineLayoutAppearance.selected.iconColor = selectedColor
        tabBarAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        tabBarAppearance.inlineLayoutAppearance.normal.iconColor = normalColor
        tabBarAppearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        tabBarAppearance.inlineLayoutAppearance.selected.iconColor = selectedColor
        tabBarAppearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
        
        // Apply to the tab bar appearance proxy
        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = tabBarAppearance
        tabBar.scrollEdgeAppearance = tabBarAppearance
    }
    
    private static func configureTabBarItemAppearance(_ appearance: UITabBarItemAppearance, normal: UIColor, selected: UIColor) {
        appearance.normal.iconColor = normal
        appearance.normal.titleTextAttributes = [.foregroundColor: normal]
        appearance.selected.iconColor = selected
        appearance.selected.titleTextAttributes = [.foregroundColor: selected]
    }
    
    static func updateForBackgroundChange(_ backgroundColor: Color) {
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
                        // Force the tab bar to re-read its appearance
                        tabBarController.tabBar.setNeedsLayout()
                        tabBarController.tabBar.layoutIfNeeded()
                        
                        // Exit early since we found and refreshed the tab bar
                        return
                    }
                }
            }
        }
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
