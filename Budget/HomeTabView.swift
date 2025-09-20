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
            
            // PROPER LIQUID GLASS TAB BAR
            LiquidGlassTabBar(selection: $selection)
                .padding(.horizontal, 20)
                .padding(.bottom, 34)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

/// Liquid Glass Tab Bar following Apple documentation
private struct LiquidGlassTabBar: View {
    @Binding var selection: HomeTabView.Tab
    @Namespace private var glassNamespace
    
    var body: some View {
        // Use GlassEffectContainer for proper liquid glass behavior
        GlassEffectContainer(spacing: 20.0) {
            HStack(spacing: 0) {
                ForEach(HomeTabView.Tab.allCases, id: \.self) { tab in
                    LiquidGlassTabButton(
                        tab: tab,
                        isSelected: selection == tab,
                        namespace: glassNamespace
                    ) {
                        withAnimation(.bouncy(duration: 0.4)) {
                            selection = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        // Apply glass effect to the container with proper corner radius
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }
}

/// Individual tab button with proper Liquid Glass behavior
private struct LiquidGlassTabButton: View {
    let tab: HomeTabView.Tab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                
                Text(tab.title)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                if isSelected {
                    // Use separate glass effect for active tab with interactive behavior
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.clear)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
                        .matchedGeometryEffect(id: "activeTab", in: namespace)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.bouncy(duration: 0.4), value: isSelected)
    }
}
