import SwiftUI
import UIKit

enum AppAppearance2 {
    static func configure() {
        print("🔍 Configuring app appearance...")
        
        // Force ALL UIKit views to be transparent
        UIView.appearance().backgroundColor = UIColor.clear
        UITableView.appearance().backgroundColor = UIColor.clear
        UITableViewCell.appearance().backgroundColor = UIColor.clear
        UICollectionView.appearance().backgroundColor = UIColor.clear
        UIScrollView.appearance().backgroundColor = UIColor.clear
        
        // Navigation transparency
        let nav = UINavigationBar.appearance()
        nav.setBackgroundImage(UIImage(), for: .default)
        nav.shadowImage = UIImage()
        nav.isTranslucent = true
        nav.backgroundColor = UIColor.clear
        
        // Check for dark mode issues
        if #available(iOS 13.0, *) {
            UIView.appearance().overrideUserInterfaceStyle = .dark
        }
        
        // Window configuration with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("🔍 Configuring windows...")
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
                print("❌ No window scene found")
                return
            }
            
            for (index, window) in windowScene.windows.enumerated() {
                print("🔍 Window \(index): backgroundColor = \(window.backgroundColor?.description ?? "nil")")
                print("🔍 Window \(index): isOpaque = \(window.isOpaque)")
                
                // Force window transparency
                window.backgroundColor = UIColor.clear
                window.isOpaque = false
                
                if let rootVC = window.rootViewController {
                    print("🔍 Root VC background: \(rootVC.view.backgroundColor?.description ?? "nil")")
                    rootVC.view.backgroundColor = UIColor.clear
                }
                
                print("🔍 Window \(index) after: backgroundColor = \(window.backgroundColor?.description ?? "nil")")
            }
        }
    }
}
