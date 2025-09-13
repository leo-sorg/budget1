import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.appText)
            Text("Hello, world!")
                .foregroundColor(.appText)
        }
        .padding()
        .background(Color.clear)
    }
}

#Preview {
    ContentView()
}
