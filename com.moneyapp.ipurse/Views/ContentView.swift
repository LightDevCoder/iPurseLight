import SwiftUI
import SwiftData

struct ContentView: View {
    private enum Tab: Hashable {
        case assets
        case bills
    }

    @EnvironmentObject private var lm: LocalizationManager
    @EnvironmentObject private var quickActionManager: QuickActionManager
    @State private var selectedTab: Tab = .assets

    var body: some View {
        TabView(selection: $selectedTab) {
            AssetView()
                .tabItem {
                    Label(lm.t("资产"), systemImage: "building.columns")
                }
                .tag(Tab.assets)

            BillView()
                .tabItem {
                    Label(lm.t("账单"), systemImage: "list.bullet.clipboard")
                }
                .tag(Tab.bills)
        }
        .onChange(of: quickActionManager.shouldShowAddTransaction) { _, newValue in
            if newValue {
                selectedTab = .bills
            }
        }
    }
}
