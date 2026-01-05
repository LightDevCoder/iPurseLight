import AppIntents
import SwiftUI

// 🗣️ 定义“记一笔”意图
struct AddTransactionIntent: AppIntent {
    // 快捷指令中显示的标题
    static var title: LocalizedStringResource = "Note a Bill"
    
    // 描述
    static var description: IntentDescription = IntentDescription("Add a transaction via voice or text input.")
    
    // 核心设置：设置为 true 表示运行此指令时必须把 App 拉起到前台
    static var openAppWhenRun: Bool = true
    
    // 参数：接收用户输入的文本 (或语音听写的结果)
    @Parameter(title: "Input Text", requestValueDialog: "What did you spend?")
    var text: String
    
    // 空初始化器 (系统要求)
    init() {}
    
    // 修改后：移除 Dialog (更简洁，体验更快)
    @MainActor
    func perform() async throws -> some IntentResult { // 不需要 & ProvidesDialog 了
        
        QuickActionManager.shared.handleIncomingText(text)
        
        // ✨ 直接返回空结果，App 会立即启动
        return .result()
    }
}

// 📦 提供快捷指令的预设 (AppShortcuts)
// 让用户在“快捷指令”App 里搜索你的应用时，能直接看到这个建议
struct iPurseLightShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTransactionIntent(),
            phrases: [
                "Note a bill in \(.applicationName)",
                "Add transaction in \(.applicationName)",
                "记一笔 \(.applicationName)"
            ],
            shortTitle: "Note Bill",
            systemImageName: "square.and.pencil"
        )
    }
}
