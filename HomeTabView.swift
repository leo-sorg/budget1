import SwiftUI

struct HomeTabView: View {
    var body: some View {
        TabView {
            InputView()
                .tabItem { Label("Input", systemImage: "square.and.pencil") }

            HistoryView()
                .tabItem { Label("History", systemImage: "list.bullet") }

            SummaryView()
                .tabItem { Label("Summary", systemImage: "chart.pie") }

            ManageView()
                .tabItem { Label("Manage", systemImage: "gearshape") }
        }
    }
}
