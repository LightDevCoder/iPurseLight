import SwiftUI
import SwiftData

@main
struct iPurseLightApp: App {
    // 1. 初始化翻译官
    @StateObject private var localizationManager = LocalizationManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            BillItem.self,
            AssetItem.self,
            AssetPortfolio.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("数据库初始化失败: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // 2. 把翻译官注入环境变量，让所有视图都能访问
                .environmentObject(localizationManager)
                // 3. 关键：通过改变 ID 来强制刷新整个视图树，实现语言即时切换
                .id(localizationManager.language)
        }
        .modelContainer(sharedModelContainer)
    }
}
