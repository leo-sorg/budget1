import SwiftUI
import SwiftData
import UIKit

let SHEETS = SheetsClient(
    baseURL: URL(string: "https://script.google.com/macros/s/AKfycbyYTsos6GONUxCFSkLFA32alrshE7Km-ERvBhyKx1Y8QwPfrAKsmjIjGAN7aYsCzyVA/exec")!,
    secret: "budget2761"
)

@main
struct BudgetApp: App {
    @StateObject private var bgStore = BackgroundImageStore()   // <- single source of truth
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterialDark)
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor(Color.appText)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.appText)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

        let segmented = UISegmentedControl.appearance()
        segmented.backgroundColor = .clear
        segmented.selectedSegmentTintColor = UIColor(Color.appAccent)
        segmented.setTitleTextAttributes([
            .foregroundColor: UIColor(Color.appText)
        ], for: .normal)
        segmented.setTitleTextAttributes([
            .foregroundColor: UIColor(Color.appBackground)
        ], for: .selected)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                AppBackgroundView()     // always-present base layer
                RootSwitcherView()      // your entire app on top
            }
            .environmentObject(bgStore) // inject ONCE at the root
            .preferredColorScheme(.dark)
            .tint(.appAccent)
        }
        .modelContainer(for: [Transaction.self, Category.self, PaymentMethod.self])
    }
}
