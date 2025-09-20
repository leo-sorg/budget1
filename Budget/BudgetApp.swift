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
            appContent
                .environmentObject(bgStore)
                .preferredColorScheme(.dark)
                .tint(.appAccent)
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
        ZStack {
            backgroundLayer
            contentLayer
        }
    }
    
    @ViewBuilder
    private var backgroundLayer: some View {
        Color.appBackground
            .ignoresSafeArea(.all)
        
        WindowBackgroundView()
            .ignoresSafeArea(.all)
    }
    
    @ViewBuilder
    private var contentLayer: some View {
        RootSwitcherView()
            .background(Color.clear)
    }
}
