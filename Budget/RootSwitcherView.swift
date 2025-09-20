import SwiftUI

struct RootSwitcherView: View {
    @EnvironmentObject private var bgStore: BackgroundImageStore
    @State private var showSplash = true

    var body: some View {
        ZStack {
            // FORCE THE FUCKING BACKGROUND TO SHOW
            Color.red
                .ignoresSafeArea(.all)
                .onAppear {
                    print("🔥🔥🔥 FORCING RED BACKGROUND - IF THIS DOESN'T SHOW, THE PROBLEM IS NOT BACKGROUND LOGIC")
                    print("🔥🔥🔥 bgStore.dim = \(bgStore.dim)")
                    print("🔥🔥🔥 bgStore.blur = \(bgStore.blur)")
                    print("🔥🔥🔥 bgStore.image = \(bgStore.image != nil)")
                }
            
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
        let _ = print("🔥 RootSwitcher: backgroundLayer rebuilding - useCustomColor: \(bgStore.useCustomColor), backgroundColor: \(bgStore.backgroundColor)")
        
        Group {
            if bgStore.useCustomColor {
                bgStore.backgroundColor
                    .ignoresSafeArea(.all)
                    .onAppear { 
                        print("🔥 RootSwitcher: SHOWING CUSTOM COLOR: \(bgStore.backgroundColor)")
                        print("🔥 RootSwitcher: useCustomColor = \(bgStore.useCustomColor)")
                    }
            } else if let image = bgStore.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea(.all)
                    .onAppear { 
                        print("🔥 RootSwitcher: Showing background image")
                    }
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
                    AppAppearance.appBackgroundColor
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
                .onAppear { 
                    print("🔥 RootSwitcher: SHOWING DEFAULT APP BACKGROUND: \(AppAppearance.appBackgroundColor)")
                    print("🔥 RootSwitcher: useCustomColor = \(bgStore.useCustomColor)")
                    print("🔥 RootSwitcher: backgroundColor = \(bgStore.backgroundColor)")
                }
            }
        }
    }
    
    @ViewBuilder
    private var mainAppView: some View {
        ZStack {
            // Ensure the background is always present, even if other layers interfere
            backgroundLayer
            
            TabView {
                InputView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                
                HistoryView()
                    .tabItem {
                        Image(systemName: "square.grid.2x2.fill")
                        Text("New")
                    }
                    .tag(1)
                
                SummaryView()
                    .tabItem {
                        Image(systemName: "dot.radiowaves.left.and.right")
                        Text("Radio")
                    }
                    .tag(2)
                
                ManageView()
                    .tabItem {
                        Image(systemName: "music.note.list")
                        Text("Library")
                    }
                    .tag(3)
            }
            .onAppear {
                print("🎨 mainAppView appeared")
                // Configure tab bar with the current background
                if bgStore.useCustomColor {
                    TabBarAppearance.configure(with: bgStore.backgroundColor)
                } else {
                    TabBarAppearance.configure(with: AppAppearance.appBackgroundColor)
                }
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            AppAppearance.appBackgroundColor.ignoresSafeArea(.all)
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
