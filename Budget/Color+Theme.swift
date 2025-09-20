import SwiftUI
import Foundation

extension Color {
    // From original Color+Theme.swift
    static let appSecondaryBackground = Color(red: 27/255, green: 28/255, blue: 28/255)
    static let appTabBar = Color(red: 49/255, green: 50/255, blue: 50/255)
    static let appAccent = Color(red: 255/255, green: 255/255, blue: 255/255)
    static let appText = Color(red: 255/255, green: 255/255, blue: 255/255)
    
    // From Color+AppBackground.swift
    static var appBackground: Color {
        // Use your app's natural dark background instead of clear
        // Ensure this is a solid, opaque color to prevent grey system backgrounds from showing
        Color(red: 27/255, green: 28/255, blue: 28/255)
    }
}

// MARK: - Hex Color Support
extension Color {
    /// Creates a Color from a hex string
    /// Supports 3, 6, and 8 character hex strings (RGB, RRGGBB, AARRGGBB)
    static func fromHex(_ hexString: String) -> Color? {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        
        guard Scanner(string: hex).scanHexInt64(&int) else {
            return nil
        }
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        return Color(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
