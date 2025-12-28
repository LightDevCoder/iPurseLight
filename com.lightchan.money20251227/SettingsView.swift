import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    // 1. 获取翻译官
    @EnvironmentObject var lm: LocalizationManager
    
    @AppStorage("deepseek_key") private var deepseekKey = ""
    @AppStorage("openai_key") private var openaiKey = ""
    @AppStorage("gemini_key") private var geminiKey = ""
    @AppStorage("selected_ai_provider") private var selectedProvider = "DeepSeek"
    
    let providers = ["DeepSeek", "OpenAI", "Gemini"]
    
    var body: some View {
        NavigationStack {
            Form {
                // 新增：语言设置区块
                Section(header: Text(lm.t("语言设置"))) {
                    Picker(lm.t("应用语言"), selection: $lm.language) {
                        Text(lm.t("中文简体")).tag(Language.zhHans)
                        Text(lm.t("英文")).tag(Language.en)
                    }
                }
                
                Section(header: Text(lm.t("AI 模型选择"))) {
                    Picker(lm.t("服务商"), selection: $selectedProvider) {
                        ForEach(providers, id: \.self) { Text($0) }
                    }
                }
                
                Section(header: Text(lm.t("API Key 配置 (仅本地保存)"))) {
                    if selectedProvider == "DeepSeek" {
                        SecureField("DeepSeek Key (sk-...)", text: $deepseekKey)
                    } else if selectedProvider == "OpenAI" {
                        SecureField("OpenAI Key (sk-...)", text: $openaiKey)
                    } else if selectedProvider == "Gemini" {
                        SecureField("Gemini Key", text: $geminiKey)
                    }
                }
                
                Section {
                    Button(lm.t("获取 DeepSeek Key (推荐)")) {
                        if let url = URL(string: "https://platform.deepseek.com") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                Section(header: Text(lm.t("说明"))) {
                    Text(lm.t("配置 API Key 后，您可以使用自然语言记账（如'打车20元'）以及获取智能财务分析建议。"))
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            // 在 SettingsView 的 Form 的最后，添加这个 Section：

            // 在 SettingsView 的 Form 底部
                Section {
                    // ✨ 修复：加上 lm.t()
                    NavigationLink(lm.t("进入网络诊断实验室")) {
                        DebugView()
                        }
                }
            .navigationTitle(lm.t("AI 设置")) // 标题也翻译
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm.t("完成")) { dismiss() }
                }
            }
        }
    }
}
