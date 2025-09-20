import SwiftUI

struct RootSwitcherView: View {
    @EnvironmentObject private var bgStore: BackgroundImageStore
    @State private var showSplash = true

    var body: some View {
        ZStack {
            AppAppearance.shared.appBackgroundColor
                .ignoresSafeArea(.all)
            
            // Content with splash/main transition
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                mainAppView
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
        .animation(.easeInOut(duration: 0.3), value: showSplash)
        .task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                withAnimation { showSplash = false }
            }
        }
    }
    
    @ViewBuilder
    private var backgroundLayer: some View {
        Group {
            if bgStore.useCustomColor {
                bgStore.backgroundColor
                    .ignoresSafeArea(.all)
            } else if let image = bgStore.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea(.all)
                    .overlay {
                        if bgStore.dim > 0 || bgStore.blur > 0 {
                            Color.black
                                .opacity(bgStore.dim)
                                .blur(radius: bgStore.blur)
                                .ignoresSafeArea(.all)
                        }
                    }
            } else {
                ZStack {
                    AppAppearance.shared.appBackgroundColor
                    // Subtle gradient overlay
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.02),
                            Color.clear,
                            Color.black.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea(.all)
            }
        }
    }
    
    @ViewBuilder
    private var mainAppView: some View {
        ZStack {
            // Ensure the background is always present, even if other layers interfere
            backgroundLayer
            
            HomeTabView()
            .onAppear {
                // Configure tab bar with the current background
                if bgStore.useCustomColor {
                    TabBarAppearance.configure(with: bgStore.backgroundColor)
                } else {
                    TabBarAppearance.configure(with: AppAppearance.shared.appBackgroundColor)
                }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            AppAppearance.shared.appBackgroundColor.ignoresSafeArea(.all)
            Text("Budget")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 180, height: 180)
                .glassEffect(.regular, in: .rect(cornerRadius: 32))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
    }
}
