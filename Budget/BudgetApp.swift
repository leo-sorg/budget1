import SwiftUI
import SwiftData

let SHEETS = SheetsClient(
    baseURL: URL(string: "https://script.google.com/macros/s/AKfycbyYTsos6GONUxCFSkLFA32alrshE7Km-ERvBhyKx1Y8QwPfrAKsmjIjGAN7aYsCzyVA/exec")!,
    secret: "budget2761"
)

@main
struct BudgetApp: App {
    @StateObject private var bgStore = BackgroundImageStore()

    init() {
        AppAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Background layer - always at the bottom
                WindowBackgroundView()
                    .ignoresSafeArea(.all)
                    .zIndex(0)
                
                // App content layer
                RootSwitcherView()
                    .background(Color.clear)
                    .zIndex(1)
            }
            .environmentObject(bgStore)
            .preferredColorScheme(.dark)
            .tint(.appAccent)
        }
        .modelContainer(for: [Transaction.self, Category.self, PaymentMethod.self])
    }
}

struct DebugBudgetApp: App {
    @StateObject private var bgStore = BackgroundImageStore()

    var body: some Scene {
        WindowGroup {
            ZStack {
                // Debug: Use a bright color instead of your background image
                Color.red.opacity(0.3)
                    .ignoresSafeArea(.all)
                    .zIndex(0)
                
                // Your normal content
                RootSwitcherView()
                    .background(Color.clear)
                    .zIndex(1)
                
                // Debug overlay
                VStack {
                    HStack {
                        Text("BG Store has image: \(bgStore.image != nil ? "YES" : "NO")")
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
                .zIndex(2)
            }
            .environmentObject(bgStore)
            .preferredColorScheme(.dark)
            .tint(.appAccent)
        }
        .modelContainer(for: [Transaction.self, Category.self, PaymentMethod.self])
    }
}
