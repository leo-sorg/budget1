import SwiftUI

struct RootSwitcherView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                HomeTabView()
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .animation(.easeInOut(duration: 0.3), value: showSplash)
        .task {
            // Simulate small load, then switch to Home
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            withAnimation {
                showSplash = false
            }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea(.all)
    }
}
