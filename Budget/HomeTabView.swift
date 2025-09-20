import SwiftUI

struct HomeTabView: View {
    var body: some View {
        TabView {
            InputView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Input")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Image(systemName: "hammer.fill")
                    Text("WIP")
                }
                .tag(1)
            
            SummaryView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Summary")
                }
                .tag(2)
            
            ManageView()
                .tabItem {
                    Image(systemName: "slider.horizontal.3")
                    Text("Manage")
                }
                .tag(3)
        }
        // IMPORTANT: Do not reset the global tab bar appearance here.
        // AppAppearance.configure() already sets a modern appearance app-wide.
        // Removing the reset prevents the “shapeless” transparent tab bar at launch.
    }
}
