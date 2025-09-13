import SwiftUI

struct RootSwitcherView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
            } else {
                HomeTabView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.3), value: showSplash)
        .background(Color.clear)
        .task {
            // Simulate small load, then switch to Home
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            showSplash = false
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.appAccent)
                Text("Budget")
                    .font(.title.bold())
            }
            .foregroundColor(.appText)
        }
        .ignoresSafeArea()
    }
}
