import SwiftUI
import SwiftData

let SHEETS = SheetsClient(
    baseURL: URL(string: "https://script.google.com/macros/s/AKfycbyYTsos6GONUxCFSkLFA32alrshE7Km-ERvBhyKx1Y8QwPfrAKsmjIjGAN7aYsCzyVA/exec")!,
    secret: "budget2761"
)

@main
struct BudgetApp: App {
    @StateObject private var bgStore = BackgroundImageStore()

    init() { AppAppearance.configure() }

    var body: some Scene {
        WindowGroup {
            ZStack {
                WindowBackgroundView()      // base layer
                RootSwitcherView()          // app content
                    .background(Color.clear)
            }
            .environmentObject(bgStore)
            .preferredColorScheme(.dark)
            .tint(.appAccent)
        }
        .modelContainer(for: [Transaction.self, Category.self, PaymentMethod.self])
    }
}
