import SwiftUI

struct DebugView: View {
    @EnvironmentObject var lm: LocalizationManager
    
    @State private var log: String = ""
    @AppStorage("deepseek_key") private var deepseekKey = ""
    @AppStorage("gemini_key") private var geminiKey = ""
    @AppStorage("openai_key") private var openaiKey = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextEditor(text: .constant(log.isEmpty ? lm.t("准备就绪，请点击下方按钮测试...") : log))
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .frame(height: 300)
                
                // ✨ 修改：按钮内容改为上下结构 (VStack)
                HStack(spacing: 12) {
                    // 1. Gemini
                    Button(action: testGemini) {
                        VStack(spacing: 2) {
                            Text(lm.t("测试")) // 上面显示 Test/测试
                                .font(.caption2)
                                .fontWeight(.regular)
                            Text("Gemini")     // 下面显示模型名
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4) // 增加一点高度，防误触
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.regular)
                    
                    // 2. DeepSeek
                    Button(action: testDeepSeek) {
                        VStack(spacing: 2) {
                            Text(lm.t("测试"))
                                .font(.caption2)
                                .fontWeight(.regular)
                            Text("DeepSeek")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                    .controlSize(.regular)
                    
                    // 3. ChatGPT
                    Button(action: testChatGPT) {
                        VStack(spacing: 2) {
                            Text(lm.t("测试"))
                                .font(.caption2)
                                .fontWeight(.regular)
                            Text("ChatGPT")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.regular)
                }
                
                Text("Gemini / DeepSeek / ChatGPT")
                    .font(.caption).foregroundStyle(.gray)
            }
            .padding()
            .navigationTitle(lm.t("网络诊断实验室"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - 测试逻辑 (保持不变)
    
    func testGemini() {
        guard !geminiKey.isEmpty else { log = lm.t("❌ 错误: Gemini Key 为空"); return }
        log = lm.t("⏳ 正在请求 Gemini...")
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(geminiKey.trimmingCharacters(in: .whitespacesAndNewlines))"
        guard let url = URL(string: urlString) else { log = lm.t("❌ URL 构造失败"); return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["contents": [["parts": [["text": "Hello"]]]]]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        performRequest(request: request, name: "Gemini")
    }
    
    func testDeepSeek() {
        guard !deepseekKey.isEmpty else { log = lm.t("❌ 错误: DeepSeek Key 为空"); return }
        log = lm.t("⏳ 正在请求 DeepSeek...")
        let url = URL(string: "https://api.deepseek.com/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(deepseekKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["model": "deepseek-chat", "messages": [["role": "user", "content": "hi"]], "stream": false]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        performRequest(request: request, name: "DeepSeek")
    }
    
    func testChatGPT() {
            guard !openaiKey.isEmpty else { log = lm.t("❌ 错误: OpenAI Key 为空"); return }
            
            log = lm.t("⏳ 正在请求 ChatGPT (GPT-5.2)...")
            // 依然使用标准的 Chat 接口以支持 System Role
            let url = URL(string: "https://api.openai.com/v1/chat/completions")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("Bearer \(openaiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "model": "gpt-5.2", // ✨ 升级为 gpt-5.2
                "messages": [["role": "user", "content": "hi"]],
                "stream": false
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            performRequest(request: request, name: "ChatGPT (GPT-5.2)")
        }
    
    func performRequest(request: URLRequest, name: String) {
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let httpResp = response as? HTTPURLResponse
                let statusCode = httpResp?.statusCode ?? 0
                let responseBody = String(data: data, encoding: .utf8) ?? lm.t("无法解析内容")
                await MainActor.run {
                    var result = "📡 \(name) \(lm.t("响应结果")):\n"
                    result += "\(lm.t("状态码")): \(statusCode)\n"
                    result += "----------------\n"
                    result += responseBody
                    self.log = result
                }
            } catch {
                await MainActor.run { self.log = "\(lm.t("❌ 请求错误")):\n\(error.localizedDescription)" }
            }
        }
    }
}
