import SwiftUI
import SwiftData

@main
struct BudgetApp: App {
    @StateObject private var bgStore = BackgroundImageStore()

    init() {
        AppAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                WindowBackgroundView()
                    .ignoresSafeArea(.all)
                
                RootSwitcherView()
                    .background(Color.clear)
            }
            .environmentObject(bgStore)
            .preferredColorScheme(.dark)
            .tint(.appAccent)
        }
        .modelContainer(for: [Transaction.self, Category.self, PaymentMethod.self])
    }
}
