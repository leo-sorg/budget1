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

        var systemImage: String { rawValue }
    }

    @State private var selection: Tab = .input
    @Namespace private var animation

    private var contentView: some View {
        Group {
            switch selection {
            case .input: InputView()
            case .history: HistoryView()
            case .summary: SummaryView()
            case .manage: ManageView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear) // Ensure content is transparent
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .background(
                    Capsule()
                        .fill(Color.appAccent.opacity(0.05))
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(colors: [Color.appAccent.opacity(0.8), Color.appAccent.opacity(0.1)],
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.appBackground.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func tabButton(for tab: Tab) -> some View {
        let isSelected = selection == tab
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                Text(tab.title)
                    .font(.caption2.bold())
            }
            .foregroundColor(isSelected ? Color.appBackground : Color.appTabBar)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(width: 80, height: 48)
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(Color.appAccent.opacity(0.6), lineWidth: 1)
                                    .blendMode(.overlay)
                            )
                            .shadow(color: Color.appBackground.opacity(0.1), radius: 2, x: 0, y: 1)
                            .matchedGeometryEffect(id: "TAB", in: animation)
                    }
                }
            )
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    var body: some View {
        // Remove the outer ZStack and simplify the structure
        ZStack(alignment: .bottom) {
            // Main content area
            contentView
                .ignoresSafeArea(.all, edges: .bottom)
            
            // Tab bar overlay
            tabBar
            
            // Background add button overlay
            VStack {
                HStack {
                    Spacer()
                    BackgroundAddButton()
                        .padding(.trailing, 16)
                }
                .padding(.top, 8)
                Spacer()
            }
            .allowsHitTesting(true)
        }
        .background(Color.clear) // This is crucial - keeps the entire view transparent
        .ignoresSafeArea(.all, edges: .bottom)
    }
}
