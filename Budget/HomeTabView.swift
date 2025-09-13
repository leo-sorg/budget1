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
        .background(Color.appBackground)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 16, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2.bold())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(width: 80, height: 48)
                    .background(
                        Capsule().fill(selection == tab ? .thinMaterial : .clear)
                    )
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(selection == tab ? Color.appBackground : Color.appText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            contentView
            tabBar
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}
