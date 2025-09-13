import SwiftUI
import UIKit

enum AppAppearance {
    static func configure() {
        // Make all system backgrounds transparent
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
        UICollectionView.appearance().backgroundColor = .clear
        UIScrollView.appearance().backgroundColor = .clear
        
        // Navigation bar transparency
        let nav = UINavigationBar.appearance()
        nav.setBackgroundImage(UIImage(), for: .default)
        nav.shadowImage = UIImage()
        nav.isTranslucent = true
        nav.backgroundColor = .clear
        
        // Tab bar transparency (if you were using UITabBar)
        let tabBar = UITabBar.appearance()
        tabBar.backgroundColor = .clear
        tabBar.barTintColor = .clear
        
        // Make sure Form/List backgrounds are transparent
        UITableView.appearance(whenContainedInInstancesOf: [UINavigationController.self]).backgroundColor = .clear
        
        // Window background
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.backgroundColor = .clear
        }
    }
}
