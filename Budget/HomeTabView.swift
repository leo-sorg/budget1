import SwiftUI

struct HomeTabView: View {
    private enum Tab: String, CaseIterable {
        case input = "square.and.pencil"
        case history = "list.bullet"
        case summary = "chart.pie"
        case manage = "gearshape"

        var title: String {
            switch self {
            case .input: return "Input"
            case .history: return "History"
            case .summary: return "Summary"
            case .manage: return "Manage"
            }
        }
    }

    @State private var selection: Tab = .input
    @Namespace private var animation

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content views
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
            
            // Tab Bar Container
            ZStack {
                // Base glass container - PURE, identical to buttons
                Capsule()
                    .fill(.clear)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .opacity(0.5)
                    )
                    .overlay(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.25),
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2),
                                        Color.white.opacity(0.4)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .frame(height: 64)
                
                // Tab content
                HStack(spacing: 0) {
                    ForEach(Array(Tab.allCases.enumerated()), id: \.element) { index, tab in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selection = tab
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tab.rawValue)
                                    .font(.system(size: 16, weight: .semibold))
                                Text(tab.title)
                                    .font(.caption2.bold())
                            }
                            .foregroundColor(selection == tab ? .white : .white.opacity(0.3))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Add separator line between tabs (except after the last tab)
                        if index < Tab.allCases.count - 1 {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.6),
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.4)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 1, height: 32)
                                .opacity(0.7)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                // Lighting mask overlay - SMALL and contained
                if let activeIndex = Tab.allCases.firstIndex(of: selection) {
                    GeometryReader { geometry in
                        let tabWidth = geometry.size.width / CGFloat(Tab.allCases.count)
                        let activeTabCenter = tabWidth * (CGFloat(activeIndex) + 0.5)
                        
                        // Small, precise lighting effect
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.06),
                                Color.white.opacity(0.03),
                                Color.white.opacity(0.01),
                                Color.clear,
                                Color.clear
                            ],
                            center: UnitPoint(x: activeTabCenter / geometry.size.width, y: 0.5),
                            startRadius: 5,
                            endRadius: tabWidth * 1.5 // Only 1.5x tab width
                        )
                        .frame(width: geometry.size.width, height: 64) // Fixed size
                        .clipShape(Capsule())
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selection)
                    }
                    .frame(height: 64) // Fixed height
                    .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color.clear)
        .ignoresSafeArea(.all, edges: .bottom)
    }
}
