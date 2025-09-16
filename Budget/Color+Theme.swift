import SwiftUI

extension Color {
    // From original Color+Theme.swift
    static let appSecondaryBackground = Color(red: 27/255, green: 28/255, blue: 28/255)
    static let appTabBar = Color(red: 49/255, green: 50/255, blue: 50/255)
    static let appAccent = Color(red: 255/255, green: 255/255, blue: 255/255)
    static let appText = Color(red: 255/255, green: 255/255, blue: 255/255)
    
    // From Color+AppBackground.swift
    static var appBackground: Color {
        // Use your app's natural dark background instead of clear
        Color(red: 27/255, green: 28/255, blue: 28/255)
    }
}
