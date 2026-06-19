import Foundation

enum AIProvider: String, CaseIterable, Identifiable {
    case deepSeek = "DeepSeek"
    case openAI = "OpenAI"
    case gemini = "Gemini"

    var id: String { rawValue }

    var key: APIKeyStore.Key {
        switch self {
        case .deepSeek:
            return .deepSeek
        case .openAI:
            return .openAI
        case .gemini:
            return .gemini
        }
    }
}

enum AIServiceError: LocalizedError {
    case unsupportedProvider(String)
    case missingAPIKey(AIProvider)
    case invalidResponse
    case invalidBill
    case httpError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .unsupportedProvider(let provider):
            return "Unsupported AI provider: \(provider)"
        case .missingAPIKey(let provider):
            return "Missing API key for \(provider.rawValue)"
        case .invalidResponse:
            return "The AI service returned an unreadable response."
        case .invalidBill:
            return "The AI response did not contain a valid transaction."
        case .httpError(let statusCode, let message):
            return "Request failed (\(statusCode)): \(message)"
        }
    }
}

final class AIService {
    struct ParsedBill: Codable {
        let amount: Double
        let category: String
        let type: String
        let note: String
        let channel: String
    }

    static let shared = AIService()

    private let keyStore = APIKeyStore.shared

    private let categories = Set(["交通", "饮食", "房租", "水电", "娱乐", "工作", "通讯", "医疗", "日常", "其他"])
    private let channels = Set(["微信", "支付宝", "银行卡", "现金", "其他"])
    private let transactionTypes = Set(["支出", "收入"])

    private init() {}

    func parseText(_ text: String, provider providerName: String) async throws -> ParsedBill {
        let provider = try resolveProvider(providerName)
        let prompt = """
        从下面的自然语言中提取一笔账单，并只返回 JSON：
        \(text)

        字段：
        - amount: 正数金额
        - type: "支出" 或 "收入"
        - channel: "微信"、"支付宝"、"银行卡"、"现金"、"其他"之一
        - category: "交通"、"饮食"、"房租"、"水电"、"娱乐"、"工作"、"通讯"、"医疗"、"日常"、"其他"之一
        - note: 简短保留原始事项

        归类提示：信用卡和借记卡归为银行卡；花呗和余额宝归为支付宝；未说明支付渠道时使用微信。
        """

        let response = try await complete(prompt: prompt, provider: provider, temperature: 0.1)
        let parsed = try JSONDecoder().decode(ParsedBill.self, from: extractJSON(from: response))

        guard
            parsed.amount.isFinite,
            parsed.amount != 0,
            categories.contains(parsed.category),
            channels.contains(parsed.channel),
            transactionTypes.contains(parsed.type)
        else {
            throw AIServiceError.invalidBill
        }

        return ParsedBill(
            amount: abs(parsed.amount),
            category: parsed.category,
            type: parsed.type,
            note: parsed.note,
            channel: parsed.channel
        )
    }

    func analyzeFinancialData(
        summary: String,
        provider providerName: String,
        language: Language
    ) async throws -> String {
        let provider = try resolveProvider(providerName)
        let prompt = language == .zhHans
            ? """
              请分析以下个人收支汇总：
              \(summary)

              用简洁中文给出消费结构评价、值得注意的异常和三条可执行建议。不要假设未提供的数据。
              """
            : """
              Analyze this personal finance summary:
              \(summary)

              In concise English, provide a spending assessment, notable anomalies, and three practical suggestions. Do not invent missing data.
              """

        return try await complete(prompt: prompt, provider: provider, temperature: 0.4)
    }

    func testConnection(to provider: AIProvider) async throws -> String {
        try await complete(
            prompt: "Reply with a short confirmation that the connection works.",
            provider: provider,
            temperature: 0
        )
    }

    private func resolveProvider(_ name: String) throws -> AIProvider {
        guard let provider = AIProvider(rawValue: name) else {
            throw AIServiceError.unsupportedProvider(name)
        }
        return provider
    }

    private func complete(
        prompt: String,
        provider: AIProvider,
        temperature: Double
    ) async throws -> String {
        let apiKey = keyStore.value(for: provider.key)
        guard !apiKey.isEmpty else {
            throw AIServiceError.missingAPIKey(provider)
        }

        switch provider {
        case .deepSeek:
            return try await callChatCompletion(
                endpoint: URL(string: "https://api.deepseek.com/chat/completions")!,
                model: "deepseek-chat",
                apiKey: apiKey,
                prompt: prompt,
                temperature: temperature
            )
        case .openAI:
            return try await callChatCompletion(
                endpoint: URL(string: "https://api.openai.com/v1/chat/completions")!,
                model: "gpt-5.2",
                apiKey: apiKey,
                prompt: prompt,
                temperature: temperature
            )
        case .gemini:
            return try await callGemini(
                apiKey: apiKey,
                prompt: prompt,
                temperature: temperature
            )
        }
    }

    private func callChatCompletion(
        endpoint: URL,
        model: String,
        apiKey: String,
        prompt: String,
        temperature: Double
    ) async throws -> String {
        let body = ChatCompletionRequest(
            model: model,
            messages: [
                .init(role: "system", content: "You are a careful personal finance assistant."),
                .init(role: "user", content: prompt)
            ],
            stream: false,
            temperature: temperature
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let response: ChatCompletionResponse = try await send(request)
        guard let content = response.choices.first?.message.content, !content.isEmpty else {
            throw AIServiceError.invalidResponse
        }
        return content
    }

    private func callGemini(
        apiKey: String,
        prompt: String,
        temperature: Double
    ) async throws -> String {
        let endpoint = URL(
            string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
        )!
        let body = GeminiRequest(
            contents: [.init(parts: [.init(text: prompt)])],
            generationConfig: .init(temperature: temperature)
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let response: GeminiResponse = try await send(request)
        guard
            let text = response.candidates.first?.content.parts.first?.text,
            !text.isEmpty
        else {
            throw AIServiceError.invalidResponse
        }
        return text
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw AIServiceError.httpError(
                statusCode: httpResponse.statusCode,
                message: String(message.prefix(500))
            )
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw AIServiceError.invalidResponse
        }
    }

    private func extractJSON(from response: String) throws -> Data {
        let withoutFences = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let start = withoutFences.firstIndex(of: "{"),
            let end = withoutFences.lastIndex(of: "}"),
            start <= end,
            let data = String(withoutFences[start...end]).data(using: .utf8)
        else {
            throw AIServiceError.invalidResponse
        }

        return data
    }
}

private struct ChatCompletionRequest: Encodable {
    struct Message: Codable {
        let role: String
        let content: String
    }

    let model: String
    let messages: [Message]
    let stream: Bool
    let temperature: Double
}

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }

        let message: Message
    }

    let choices: [Choice]
}

private struct GeminiRequest: Encodable {
    struct Content: Encodable {
        struct Part: Encodable {
            let text: String
        }

        let parts: [Part]
    }

    struct GenerationConfig: Encodable {
        let temperature: Double
    }

    let contents: [Content]
    let generationConfig: GenerationConfig
}

private struct GeminiResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String
            }

            let parts: [Part]
        }

        let content: Content
    }

    let candidates: [Candidate]
}
