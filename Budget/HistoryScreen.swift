import SwiftUI

struct HistoryScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("History").font(.title).bold()
                Text("Placeholder list…").opacity(0.7)
            }
            .padding()
        }
        .background(Color.clear)
    }
}
