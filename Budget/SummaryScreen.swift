import SwiftUI

struct SummaryScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Summary").font(.title).bold()
                Text("Placeholder charts…").opacity(0.7)
            }
            .padding()
        }
        .background(Color.clear)
    }
}
