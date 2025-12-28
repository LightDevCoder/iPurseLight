import Foundation
import SwiftUI

class AIService {
    static let shared = AIService()
    
    struct ParsedBill: Codable {
        let amount: Double
        let category: String
        let type: String
        let note: String
        let channel: String
    }
    
    // MARK: - 公开方法
    
    func parseText(_ text: String, provider: String) async throws -> ParsedBill {
        let prompt = """
        从文本中提取账单："\(text)"
        严格返回纯JSON，不要Markdown。默认渠道"微信"。
        字段: amount(数字), category(字符串), type(收入/支出), note(备注), channel(字符串)。
        """
        return try await parseAndClean(prompt: prompt, provider: provider)
    }
    
    func analyzeFinancialData(summary: String, provider: String, language: Language) async throws -> String {
        let prompt: String
        if language == .zhHans {
            prompt = """
            作为理财顾问，分析：\n\(summary)
            给出：1.消费评价 2.异常预警 3.省钱建议。简洁中文分点。
            """
        } else {
            prompt = """
            As a financial advisor, analyze: \n\(summary)
            Provide: 1. Spending Evaluation 2. Abnormal Alerts 3. Saving Tips. Concise English bullet points.
            """
        }
        
        print("🚀 [Debug] 开始请求 AI，服务商: [\(provider)]")
        
        switch provider {
        case "Gemini":
            return try await callGemini(prompt: prompt)
        default:
            return try await callOpenAICompatible(prompt: prompt, provider: provider)
        }
    }
    
    // MARK: - 内部逻辑
    
    private func parseAndClean(prompt: String, provider: String) async throws -> ParsedBill {
        let jsonString = (provider == "Gemini") ? try await callGemini(prompt: prompt) : try await callOpenAICompatible(prompt: prompt, provider: provider)
        let cleanJson = jsonString.replacingOccurrences(of: "```json", with: "")
                                  .replacingOccurrences(of: "```", with: "")
                                  .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = cleanJson.data(using: .utf8) else {
            print("❌ [Debug] JSON 转换 Data 失败"); throw URLError(.cannotDecodeContentData)
        }
        do { return try JSONDecoder().decode(ParsedBill.self, from: data) }
        catch { print("❌ [Debug] JSON 解码失败: \(error)"); throw error }
    }

    // OpenAI / DeepSeek 通用调用
    private func callOpenAICompatible(prompt: String, provider: String) async throws -> String {
        let isDeepSeek = provider == "DeepSeek"
        let keyName = isDeepSeek ? "deepseek_key" : "openai_key"
        var apiKey = UserDefaults.standard.string(forKey: keyName) ?? ""
        apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if apiKey.isEmpty { print("❌ [Debug] API Key 为空"); throw URLError(.userAuthenticationRequired) }
        
        let baseUrl = isDeepSeek ? "https://api.deepseek.com/chat/completions" : "https://api.openai.com/v1/chat/completions"
        let model = isDeepSeek ? "deepseek-chat" : "gpt-5.2"
                
        guard let url = URL(string: baseUrl) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "system", "content": "You are a helpful financial assistant."], ["role": "user", "content": prompt]],
            "stream": false, "temperature": 0.7
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 错误处理
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            print("❌ [Debug] OpenAI/DeepSeek 报错 (\(httpResponse.statusCode)): \(errorMsg)")
            throw URLError(.badServerResponse)
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]], let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any], let content = message["content"] as? String {
            return content
        }
        throw URLError(.cannotDecodeContentData)
    }
    
    // Gemini 调用 (修复版)
    private func callGemini(prompt: String) async throws -> String {
            var apiKey = UserDefaults.standard.string(forKey: "gemini_key") ?? ""
            apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if apiKey.isEmpty { throw URLError(.userAuthenticationRequired) }
            
            // gemini-2.5-flash
            let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
            
            guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["contents": [["parts": [["text": prompt]]]]]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // ✨ 修改 2: 增加错误信息的打印
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            // 打印 Google 返回的具体错误原因
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown Error"
            print("❌ [Debug] Gemini 报错 (Code \(httpResponse.statusCode)): \(errorMsg)")
            throw URLError(.badServerResponse)
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let candidates = json["candidates"] as? [[String: Any]], let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any], let parts = content["parts"] as? [[String: Any]],
           let firstPart = parts.first, let text = firstPart["text"] as? String {
            return text
        }
        throw URLError(.badServerResponse)
    }
}
