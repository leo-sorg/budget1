import SwiftUI
import SwiftData

@main
struct BudgetApp: App {
    @StateObject private var bgStore = BackgroundImageStore()

    init() { AppAppearance.configure() }

    var body: some Scene {
        WindowGroup {
            ZStack {
                WindowBackgroundView()   // persistent base layer
                RootTabsView()           // your app (keeps the existing Tab Bar)
                    .background(Color.clear)
            }
            .environmentObject(bgStore)
            .preferredColorScheme(.dark)
            .tint(.appAccent)
        }
        .modelContainer(for: [Transaction.self, Category.self, PaymentMethod.self])
    }
}
