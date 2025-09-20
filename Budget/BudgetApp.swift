import SwiftUI
import SwiftData

@main
struct BudgetApp: App {
    @StateObject private var bgStore = BackgroundImageStore()

    init() {
        // Configure general app appearance (everything except TabBar)
        AppAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            appContent
                .environmentObject(bgStore)
                // REMOVE DARK MODE OVERRIDE - THIS WAS FORCING BLACK BACKGROUNDS
                // .preferredColorScheme(.dark)
                .tint(.appAccent)
                .onReceive(bgStore.objectWillChange) { _ in
                    print("🔥 BudgetApp: bgStore.objectWillChange triggered!")
                    print("🔥 BudgetApp: useCustomColor: \(bgStore.useCustomColor), backgroundColor: \(bgStore.backgroundColor)")
                    
                    // Update tab bar when background changes, but keep general appearance separate
                    if bgStore.useCustomColor {
                        print("🔥 BudgetApp: Using custom color, updating tab bar")
                        TabBarAppearance.updateForBackgroundChange(bgStore.backgroundColor)
                    } else {
                        print("🔥 BudgetApp: Using default color, updating tab bar")
                        TabBarAppearance.updateForBackgroundChange(AppAppearance.appBackgroundColor)
                    }
                    print("🔥 BudgetApp: objectWillChange handling completed")
                }
                .onAppear {
                    // Configure tab bar with initial background color and force transparency
                    if bgStore.useCustomColor {
                        TabBarAppearance.configure(with: bgStore.backgroundColor)
                    } else {
                        TabBarAppearance.configure(with: AppAppearance.appBackgroundColor)
                    }
                }
        }
        .modelContainer(modelContainer)
    }
    
    // Explicit ModelContainer to avoid ambiguous init
    private var modelContainer: ModelContainer {
        do {
            let schema = Schema([
                Transaction.self,
                Category.self, 
                PaymentMethod.self
            ])
            let config = ModelConfiguration(schema: schema)
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    @ViewBuilder
    private var appContent: some View {
        RootSwitcherView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
