import SwiftUI

struct RootTabsView: View {
    var body: some View {
        TabView {
            HistoryScreen()
                .tabItem { Label("History", systemImage: "list.bullet") }

            InputScreen()
                .tabItem { Label("Input", systemImage: "plus.circle") }

            SummaryScreen()
                .tabItem { Label("Summary", systemImage: "chart.pie.fill") }

            ManageScreen()
                .tabItem { Label("Manage", systemImage: "gearshape.fill") }
        }
        .background(Color.clear)
    }
}
