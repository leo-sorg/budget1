import SwiftUI
import UIKit

enum AppAppearance {
    static func configure() {
        // On iOS 18 and later, do NOT override system appearances.
        // This lets the system's Liquid glass design show through everywhere.
        if #available(iOS 18.0, *) {
            return
        }

        // Older iOS: retain the previous transparent setup so materials still look correct.
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
        
        // Make sure window backgrounds use our default color
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                for window in windowScene.windows {
                    // Set window background to our default color
                    window.backgroundColor = UIColor(Color.appBackground)
                    window.isOpaque = true
                    if let rootVC = window.rootViewController {
                        rootVC.view.backgroundColor = .clear
                    }
                }
            }
        }
    }
}
