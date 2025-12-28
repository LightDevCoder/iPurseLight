import SwiftUI
import SwiftData

struct ContentView: View {
    // 获取翻译官
    @EnvironmentObject var lm: LocalizationManager
    
    var body: some View {
        TabView {
            AssetView()
                .tabItem {
                    Label(lm.t("资产"), systemImage: "building.columns")
                }
            
            BillView()
                .tabItem {
                    Label(lm.t("账单"), systemImage: "list.bullet.clipboard")
                }
        }
    }
}
