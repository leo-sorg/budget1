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
            // TEST: Now test ManageView (the last one!)
            Group {
                switch selection {
                case .input:
                    InputView()  // ✅ Works
                case .history:
                    HistoryView()  // ✅ Works
                case .summary:
                    SummaryView()  // ✅ Works now with new styles!
                case .manage:
                    ManageView()  // <-- Test this final view
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Simple tab bar
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
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
                        .foregroundColor(selection == tab ? .black : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(width: 80, height: 48)
                        .background(selection == tab ? Color.white.opacity(0.9) : Color.clear)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.8))
            .clipShape(Capsule())
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Background add button
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
        .background(Color.clear)
        .ignoresSafeArea(.all, edges: .bottom)
    }
}
