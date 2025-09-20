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
            
            // TAB BAR WITH PROPER HIT TESTING
            TabBarView(selection: $selection)
                .padding(.horizontal, 16)
                .padding(.bottom, 34)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

/// Tab bar with proper liquid glass morphing for active state
private struct TabBarView: View {
    @Binding var selection: HomeTabView.Tab
    @Namespace private var activeTabNamespace
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(HomeTabView.Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.bouncy(duration: 0.4)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(selection == tab ? .primary : .secondary)
                            .scaleEffect(selection == tab ? 1.1 : 1.0)
                        
                        Text(tab.title)
                            .font(.caption2)
                            .foregroundStyle(selection == tab ? .primary : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background {
                        if selection == tab {
                            // Simple active indicator - NO GLASS EFFECTS HERE
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.2))
                                .matchedGeometryEffect(id: "activeTab", in: activeTabNamespace)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassEffect() // SINGLE GLASS EFFECT ON THE WHOLE TAB BAR
        .contentShape(.capsule)
        .animation(.bouncy(duration: 0.4), value: selection)
    }
}
