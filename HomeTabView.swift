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
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Content area
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
                .frame(maxWidth: .infinity)
                .frame(height: geometry.size.height - 120)
                .clipped()
                
                // Tab bar
                HomeTabBar(selection: $selection)
                    .frame(height: 120)
                    .padding(.horizontal, 20)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Tab Bar Implementation
struct HomeTabBar: View {
    @Binding var selection: HomeTabView.Tab
    @Namespace private var tabTransition
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            HStack(spacing: 0) {
                ForEach(HomeTabView.Tab.allCases, id: \.self) { tab in
                    HomeTabButton(
                        tab: tab,
                        isSelected: selection == tab,
                        namespace: tabTransition
                    ) {
                        withAnimation(.bouncy(duration: 0.4)) {
                            selection = tab
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .background {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(.black.opacity(0.1))
                    }
            }
            .frame(height: 68)
            
            Spacer()
                .frame(height: 34)
        }
    }
}

struct HomeTabButton: View {
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
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.white.opacity(0.2))
                        .background {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                        }
                        .matchedGeometryEffect(id: "activeTab", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.bouncy(duration: 0.4), value: isSelected)
    }
}