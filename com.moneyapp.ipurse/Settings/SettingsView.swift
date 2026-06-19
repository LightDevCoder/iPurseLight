import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var lm: LocalizationManager

    @AppStorage("selected_ai_provider") private var selectedProvider = AIProvider.deepSeek.rawValue
    @State private var deepSeekKey = ""
    @State private var openAIKey = ""
    @State private var geminiKey = ""

    private let keyStore = APIKeyStore.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(lm.t("应用语言"), selection: $lm.language) {
                        Text(lm.t("中文简体")).tag(Language.zhHans)
                        Text(lm.t("英文")).tag(Language.en)
                    }
                } header: {
                    Text(lm.t("语言设置"))
                }

                Section {
                    Picker(lm.t("服务商"), selection: $selectedProvider) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.rawValue).tag(provider.rawValue)
                        }
                    }
                } header: {
                    Text(lm.t("AI 模型选择"))
                }

                Section {
                    switch AIProvider(rawValue: selectedProvider) ?? .deepSeek {
                    case .deepSeek:
                        SecureField("DeepSeek Key", text: $deepSeekKey)
                    case .openAI:
                        SecureField("OpenAI Key", text: $openAIKey)
                    case .gemini:
                        SecureField("Gemini Key", text: $geminiKey)
                    }
                } header: {
                    Text(lm.t("API Key 配置 (仅本地保存)"))
                } footer: {
                    Text(lm.t("配置 API Key 后，您可以使用自然语言记账（如'打车20元'）以及获取智能财务分析建议。"))
                }

                Section {
                    Link(destination: providerConsoleURL) {
                        Label("Open \(selectedProvider) console", systemImage: "arrow.up.right.square")
                    }
                }

                Section {
                    NavigationLink(lm.t("进入网络诊断实验室")) {
                        DebugView()
                    }
                }
            }
            .navigationTitle(lm.t("AI 设置"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm.t("完成")) { dismiss() }
                }
            }
            .task {
                deepSeekKey = keyStore.value(for: .deepSeek)
                openAIKey = keyStore.value(for: .openAI)
                geminiKey = keyStore.value(for: .gemini)
            }
            .onChange(of: deepSeekKey) { _, value in
                keyStore.set(value, for: .deepSeek)
            }
            .onChange(of: openAIKey) { _, value in
                keyStore.set(value, for: .openAI)
            }
            .onChange(of: geminiKey) { _, value in
                keyStore.set(value, for: .gemini)
            }
        }
    }

    private var providerConsoleURL: URL {
        switch AIProvider(rawValue: selectedProvider) ?? .deepSeek {
        case .deepSeek:
            return URL(string: "https://platform.deepseek.com")!
        case .openAI:
            return URL(string: "https://platform.openai.com/api-keys")!
        case .gemini:
            return URL(string: "https://aistudio.google.com/app/apikey")!
        }
    }
}
