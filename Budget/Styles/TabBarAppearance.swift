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
        
        // Simple item colors with better contrast
        let normalColor = UIColor.systemGray
        let selectedColor = UIColor.white
        
        print("🔥 Setting tab colors - Normal: \(normalColor), Selected: \(selectedColor)")
        
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
        print("🔥 forceRefreshExistingTabBars() STARTED")
        for scene in UIApplication.shared.connectedScenes {
            print("🔥 Checking scene: \(scene)")
            if let windowScene = scene as? UIWindowScene {
                print("🔥 Found windowScene with \(windowScene.windows.count) windows")
                for window in windowScene.windows {
                    print("🔥 Checking window: \(window)")
                    if let tabBarController = window.rootViewController?.findTabBarController() {
                        print("🔥 Found tab bar controller! Tab bar items count: \(tabBarController.tabBar.items?.count ?? 0)")
                        
                        // Log each tab item with more detail
                        if let items = tabBarController.tabBar.items {
                            for (index, item) in items.enumerated() {
                                let title = item.title ?? "nil"
                                let hasImage = item.image != nil
                                let imageDescription = item.image?.description ?? "nil"
                                print("🔥 Tab \(index): title='\(title)', hasImage=\(hasImage), image=\(imageDescription)")
                                
                                // Special debugging for the manage tab (index 3)
                                if index == 3 {
                                    print("🔥 MANAGE TAB DETAILS:")
                                    print("🔥   - Title: '\(title)'")
                                    print("🔥   - Has Image: \(hasImage)")
                                    print("🔥   - Image Size: \(item.image?.size ?? CGSize.zero)")
                                    print("🔥   - Badge Value: \(item.badgeValue ?? "nil")")
                                    print("🔥   - Is Enabled: \(item.isEnabled)")
                                }
                            }
                        }
                        
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
