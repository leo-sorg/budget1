import SwiftUI
import UIKit

enum AppAppearance {
    static func configure() {
        // Make ALL system backgrounds completely transparent
        UIView.appearance().backgroundColor = .clear
        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear
        UICollectionView.appearance().backgroundColor = .clear
        UIScrollView.appearance().backgroundColor = .clear
        
        // Navigation transparency
        let nav = UINavigationBar.appearance()
        nav.setBackgroundImage(UIImage(), for: .default)
        nav.shadowImage = UIImage()
        nav.isTranslucent = true
        nav.backgroundColor = .clear
        
        // Form/List specific transparency
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().allowsSelection = true
        
        // SECTION HEADERS - Fix the black section backgrounds
        UITableViewHeaderFooterView.appearance().backgroundColor = .clear
        UITableViewHeaderFooterView.appearance().tintColor = .clear
        
        // PICKER BACKGROUNDS - Fix the black backgrounds
        UISegmentedControl.appearance().backgroundColor = .clear
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.appAccent)
        
        // Date picker backgrounds
        UIDatePicker.appearance().backgroundColor = .clear
        
        // Text field backgrounds (for your custom text fields)
        UITextField.appearance().backgroundColor = .clear
        
        // Toolbar backgrounds (for your keyboard toolbars)
        UIToolbar.appearance().backgroundColor = .clear
        UIToolbar.appearance().barTintColor = .clear
        UIToolbar.appearance().isTranslucent = true
        
        // Make sure window backgrounds are clear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                for window in windowScene.windows {
                    window.backgroundColor = UIColor.clear
                    window.isOpaque = false
                    if let rootVC = window.rootViewController {
                        rootVC.view.backgroundColor = UIColor.clear
                    }
                }
            }
        }
    }
}
