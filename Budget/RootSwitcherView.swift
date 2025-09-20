import SwiftUI

struct RootSwitcherView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .animation(.easeInOut(duration: 0.3), value: showSplash)
        .task {
            // Simulate small load, then switch to Home
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            await MainActor.run {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            // Use a proper background color
            splashBackground
            
            // Liquid glass logo with modern design
            splashLogo
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
    }
    
    @ViewBuilder
    private var splashBackground: some View {
        Color.appBackground
            .ignoresSafeArea(.all)
    }
    
    @ViewBuilder
    private var splashLogo: some View {
        Text("Budget")
            .font(.system(size: 32, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 180, height: 180)
            .background {
                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)
                    .background {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(.black.opacity(0.1))
                    }
            }
    }
}