import SwiftUI
import SwiftData
import UIKit

let SHEETS = SheetsClient(
    baseURL: URL(string: "https://script.google.com/macros/s/AKfycbyYTsos6GONUxCFSkLFA32alrshE7Km-ERvBhyKx1Y8QwPfrAKsmjIjGAN7aYsCzyVA/exec")!,
    secret: "budget2761"
)

@main
struct BudgetApp: App {
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.appBackground)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(Color.appText)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.appText)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

        let segmented = UISegmentedControl.appearance()
        segmented.backgroundColor = UIColor(Color.appBackground)
        segmented.selectedSegmentTintColor = UIColor(Color.appAccent)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                RootSwitcherView()
            }
            .preferredColorScheme(.dark)
            .tint(.appAccent)
        }
        .modelContainer(for: [Transaction.self, Category.self, PaymentMethod.self])
    }
}
