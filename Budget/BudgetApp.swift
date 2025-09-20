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
            ZStack {
                AppAppearance.shared.appBackgroundColor
                    .ignoresSafeArea(.all)
                
                appContent
                    .environmentObject(bgStore)
                    .environmentObject(AppAppearance.shared)
                    .tint(.appAccent)
            }
            .onReceive(bgStore.objectWillChange) { _ in
                // Update tab bar when background changes, but keep general appearance separate
                if bgStore.useCustomColor {
                    TabBarAppearance.updateForBackgroundChange(bgStore.backgroundColor)
                } else {
                    TabBarAppearance.updateForBackgroundChange(AppAppearance.shared.appBackgroundColor)
                }
            }
            .onAppear {
                // Configure tab bar with initial background color and force transparency
                if bgStore.useCustomColor {
                    TabBarAppearance.configure(with: bgStore.backgroundColor)
                } else {
                    TabBarAppearance.configure(with: AppAppearance.shared.appBackgroundColor)
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
