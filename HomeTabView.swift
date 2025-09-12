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

    var body: some View {
        ZStack(alignment: .bottom) {
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
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule().fill(selection == tab ? Color.appAccent : Color.clear),
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selection == tab ? Color.appBackground : Color.appText)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(Color.appTabBar)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}
