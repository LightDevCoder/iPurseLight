import SwiftUI
import Combine

// ⚡️ 快捷操作管理器
// 作用：接收来自 AppIntent (快捷指令) 的数据，并通知 UI 层进行响应
class QuickActionManager: ObservableObject {
    static let shared = QuickActionManager()
    
    // 待处理的输入文本 (即语音转文字的结果)
    @Published var pendingInputText: String? = nil
    
    // 是否应该触发“记一笔”页面
    @Published var shouldShowAddTransaction: Bool = false
    
    private init() {}
    
    // 供 Intent 调用：处理传入的文本
    @MainActor
    func handleIncomingText(_ text: String) {
        self.pendingInputText = text
        self.shouldShowAddTransaction = true
        print("⚡️ QuickActionManager received: \(text)")
    }
    
    // 供 View 调用：消费掉文本 (使用后清空，防止重复触发)
    func consumePendingText() -> String? {
        let text = pendingInputText
        pendingInputText = nil
        return text
    }
}
