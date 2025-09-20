import SwiftUI

struct HomeTabView: View {
    enum Tab: CaseIterable, Hashable {
        case input, history, summary, manage
        
        var icon: String {
            switch self {
            case .input:   return "house.fill"
            case .history: return "square.grid.2x2.fill"
            case .summary: return "dot.radiowaves.left.and.right"
            case .manage:  return "music.note.list"
            }
        }
        
        var title: String {
            switch self {
            case .input:   return "Home"
            case .history: return "New"
            case .summary: return "Radio"
            case .manage:  return "Library"
            }
        }
    }
    
    @State private var selection: Tab = .input
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .input:
                    InputView()
                case .history:
                    HistoryView()
                case .summary:
                    SummaryView()
                case .manage:
                    ManageView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            
            // Liquid Glass Tab Bar
            LiquidGlassTabBar(selection: $selection)
                .padding(.horizontal, 20)
                .padding(.bottom, 34) // Safe area + visual padding
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .tint(.appAccent)
    }
}

/// Liquid Glass Tab Bar following proper Apple design guidelines
private struct LiquidGlassTabBar: View {
    @Binding var selection: HomeTabView.Tab
    @Namespace private var tabTransition
    
    var body: some View {
        GlassEffectContainer(spacing: 8.0) {
            HStack(spacing: 8) {
                ForEach(HomeTabView.Tab.allCases, id: \.self) { tab in
                    TabBarButton(
                        tab: tab,
                        isSelected: selection == tab,
                        namespace: tabTransition
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selection = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

/// Clean tab bar button following Apple's standard design
private struct TabBarButton: View {
    let tab: HomeTabView.Tab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                
                Text(tab.title)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    Capsule()
                        .fill(.thinMaterial)
                        .matchedGeometryEffect(id: "selectedTab", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}


