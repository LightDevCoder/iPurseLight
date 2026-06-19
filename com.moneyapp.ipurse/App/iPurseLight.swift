import SwiftUI
import SwiftData

@main
struct iPurseLightApp: App {
    @StateObject private var localizationManager = LocalizationManager()
    @StateObject private var quickActionManager = QuickActionManager.shared

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
                .environmentObject(localizationManager)
                .environmentObject(quickActionManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
