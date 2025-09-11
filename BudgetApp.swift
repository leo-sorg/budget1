import SwiftUI
import SwiftData   // <-- add this

@main
struct BudgetApp: App {
    var body: some Scene {
        WindowGroup {
            RootSwitcherView()   // still the default screen for now
        }
        // Tell SwiftData which models exist in your app:
        .modelContainer(for: [Transaction.self, Category.self, PaymentMethod.self])
    }
}

