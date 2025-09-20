import SwiftUI

struct HomeTabView: View {
    var body: some View {
        TabView {
            InputView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("New")
                }
                .tag(1)
            
            SummaryView()
                .tabItem {
                    Image(systemName: "dot.radiowaves.left.and.right")
                    Text("Radio")
                }
                .tag(2)
            
            ManageView()
                .tabItem {
                    Image(systemName: "music.note.list")
                    Text("Library")
                }
                .tag(3)
        }
        // IMPORTANT: Do not reset the global tab bar appearance here.
        // AppAppearance.configure() already sets a modern appearance app-wide.
        // Removing the reset prevents the “shapeless” transparent tab bar at launch.
    }
}
