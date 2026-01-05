import SwiftUI
import SwiftData

struct ContentView: View {
    // 获取翻译官
    @EnvironmentObject var lm: LocalizationManager
    
    // ✨ 1. 获取快捷操作管理器
    @EnvironmentObject var quickActionManager: QuickActionManager
    
    // ✨ 2. 定义 Tab 选中状态 (0: 资产, 1: 账单)
    // 默认是 0 (资产页)
    @State private var selectedTab: Int = 0
    
    var body: some View {
        // ✨ 3. 绑定 selection
        TabView(selection: $selectedTab) {
            AssetView()
                .tabItem {
                    Label(lm.t("资产"), systemImage: "building.columns")
                }
                .tag(0) // ✨ 4. 给资产页打上标签 0
            
            BillView()
                .tabItem {
                    Label(lm.t("账单"), systemImage: "list.bullet.clipboard")
                }
                .tag(1) // ✨ 5. 给账单页打上标签 1
        }
        // ✨ 6. 核心逻辑：监听快捷指令信号
        .onChange(of: quickActionManager.shouldShowAddTransaction) { _, newValue in
            if newValue {
                // 一旦收到信号，强制跳转到“账单”标签页 (tag 1)
                selectedTab = 1
                
                // 注意：这里不需要把 shouldShowAddTransaction 设为 false
                // 我们只负责“带路”，真正的“弹窗”操作交给 BillView 自己处理
            }
        }
    }
}
