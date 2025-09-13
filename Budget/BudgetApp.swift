import SwiftUI
import SwiftData
import UIKit

let SHEETS = SheetsClient(
    baseURL: URL(string: "https://script.google.com/macros/s/AKfycbyYTsos6GONUxCFSkLFA32alrshE7Km-ERvBhyKx1Y8QwPfrAKsmjIjGAN7aYsCzyVA/exec")!,
    secret: "budget2761"
)

@main
struct BudgetApp: App {
    @StateObject private var bgStore = BackgroundImageStore()
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
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
            RootSwitcherView()
                .background(AppBackgroundView())
                .preferredColorScheme(.dark)
                .tint(.appAccent)
                .environmentObject(bgStore)
        }
        .modelContainer(for: [Transaction.self, Category.self, PaymentMethod.self])
    }
}
