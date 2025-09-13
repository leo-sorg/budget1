import SwiftUI

extension Color {
    /// Main background color. When a custom background image is set in
    /// `UserDefaults` under the key `"backgroundImage"`, this becomes `clear`
    /// so the image can be seen. Otherwise it defaults to the previous dark
    /// background.
    static var appBackground: Color {
        if UserDefaults.standard.data(forKey: "backgroundImage") != nil {
            return .clear
        } else {
            return .black
        }
    }

    static let appSecondaryBackground = Color(red: 27.0/255.0, green: 28.0/255.0, blue: 28.0/255.0)
    static let appAccent = Color(red: 0.0/255.0, green: 255.0/255.0, blue: 255.0/255.0)
    static let appText = Color.white
    static let appTabBar = Color(red: 49.0/255.0, green: 50.0/255.0, blue: 50.0/255.0)
}
