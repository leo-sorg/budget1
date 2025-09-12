import SwiftUI

struct HomeTabView: View {
    init() {
        let tabBar = UITabBar.appearance()
        tabBar.backgroundColor = UIColor(Color.appSecondaryBackground)
        tabBar.unselectedItemTintColor = UIColor(Color.appText)
    }

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
        .background(Color.appBackground)
        .foregroundColor(.appText)
        .tint(.appAccent)
    }
}
