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
            // Use the app's default background color instead of black
            Color.appDefaultBackground
                .ignoresSafeArea(.all)
            
            // Liquid glass square with "Budget" text
            Text("Budget")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 180, height: 180)
                .background(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(.clear)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(.ultraThinMaterial)
                                .opacity(0.8)  // Increased from 0.5 to 0.8
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.35),  // Increased from 0.25
                                            Color.white.opacity(0.25),  // Increased from 0.15
                                            Color.white.opacity(0.25)   // Increased from 0.15
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .opacity(0.8)  // Increased from 0.6
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.8),  // Increased from 0.6
                                            Color.white.opacity(0.4),  // Increased from 0.2
                                            Color.white.opacity(0.6)   // Increased from 0.4
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                                .opacity(0.9)  // Increased from 0.7
                        )
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appDefaultBackground)
        .ignoresSafeArea(.all)
    }
}
