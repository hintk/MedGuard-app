import Foundation
import UIKit

// MARK: - Doubao AI Service

final class DoubaoService {
    static let shared = DoubaoService()

    private let apiKey = "ark-0755e5d2-1471-4926-a6a4-2b1ef5d57452-861e1"
    /// 视觉模型推理接入点（Doubao-Seed-1.6-vision）
    private let visionEndpointID = "ep-20260616152526-z5v6t"
    /// 文本模型推理接入点（Doubao-Lite — 用于风险分析）
    private let textEndpointID = "ark-0755e5d2-1471-4926-a6a4-2b1ef5d57452-861e1"

    private let visionBaseURL = "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
    private let textBaseURL = "https://ark.cn-beijing.volces.com/api/v3/chat/completions"

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Drug Recognition from Photo (Responses API)

    struct DrugRecognitionResult: Codable {
        let name: String
        let category: String
        let manufacturer: String
        let specification: String
        let approvalNumber: String?

        enum CodingKeys: String, CodingKey {
            case name, category, manufacturer, specification
            case approvalNumber = "approval_number"
        }
    }

    func recognizeDrug(imageData: Data) async throws -> (result: DrugRecognitionResult, rawResponse: String) {
        let compressedData = compressImage(imageData, maxSizeKB: 500)
        let base64 = compressedData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64)"

        let prompt = """
        请识别这张药品包装盒图片，提取药品信息。
        按以下JSON格式返回，不要包含其他文字：
        {"name": "药品名称", "category": "药品分类", "manufacturer": "生产厂家", "specification": "规格", "approval_number": "批准文号"}

        分类从以下选择：心脑血管、降糖药、消化系统、感冒药、止咳药、抗生素、维生素矿物质、镇痛消炎、抗过敏、安神助眠、常用药
        如果某个字段无法识别则填"未知"
        """

        // Chat Completions API 格式
        let body: [String: Any] = [
            "model": visionEndpointID,
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "image_url", "image_url": ["url": dataURL, "detail": "high"]],
                    ["type": "text", "text": prompt]
                ]
            ]],
            "temperature": 0.1,
            "max_tokens": 1000
        ]

        let raw = try await sendChatRequest(body: body)
        let result: DrugRecognitionResult = try parseJSON(from: raw, type: DrugRecognitionResult.self)
        return (result, raw)
    }

    // MARK: - Drug Interaction Analysis (Chat Completions API)

    struct InteractionRisk: Codable, Identifiable {
        let id: String
        let level: String
        let medications: [String]
        let description: String
        let recommendation: String

        var riskLevel: RiskLevel? {
            switch level {
            case "high": return .high
            case "medium": return .medium
            case "low": return .low
            default: return nil
            }
        }
    }

    func analyzeRisks(medications: [Medication]) async throws -> [InteractionRisk] {
        let valid = medications.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        guard valid.count >= 2 else { return [] }

        let drugList = valid.map { "\($0.name)（\($0.category)）" }.joined(separator: "，")

        let prompt = """
        以下药品清单：\(drugList)

        分析所有可能的药物相互作用风险，按风险等级从高到低排列。
        按以下JSON数组格式返回，不要包含其他文字：
        [{"level": "high/medium/low", "medications": ["药A","药B"], "description": "风险描述", "recommendation": "建议措施"}]

        high=高风险需立即处理，medium=中风险需留意，low=低风险常规注意。
        如无任何相互作用风险则返回空数组[]。
        """

        let body: [String: Any] = [
            "model": textEndpointID,
            "messages": [[
                "role": "user",
                "content": [["type": "text", "text": prompt]]
            ]],
            "temperature": 0.1,
            "max_tokens": 2000
        ]

        let content = try await sendChatRequest(body: body)
        let items: [InteractionRisk] = try parseJSONArray(from: content)
        return items.enumerated().map { i, item in
            InteractionRisk(id: UUID().uuidString,
                            level: item.level,
                            medications: item.medications,
                            description: item.description,
                            recommendation: item.recommendation)
        }
    }

    // MARK: - Chat Completions API Networking

    private struct ChatResponse: Codable {
        let choices: [Choice]
    }

    private struct Choice: Codable {
        let message: Message
    }

    private struct Message: Codable {
        let content: String
    }

    private func sendChatRequest(body: [String: Any]) async throws -> String {
        guard let url = URL(string: textBaseURL) else { throw ServiceError.networkError }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.networkError
        }

        if httpResponse.statusCode != 200 {
            let bodyStr = String(data: data, encoding: .utf8) ?? "no body"
            throw ServiceError.apiError("HTTP \(httpResponse.statusCode): \(bodyStr)")
        }

        let apiResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = apiResponse.choices.first?.message.content else {
            throw ServiceError.noResult
        }
        return content
    }

    // MARK: - Error

    enum ServiceError: LocalizedError {
        case networkError
        case noResult
        case parsingError(String)
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .networkError: return "网络请求失败，请稍后重试"
            case .noResult: return "AI 未返回有效结果"
            case .parsingError(let msg): return "数据解析失败: \(msg)"
            case .apiError(let msg): return msg
            }
        }
    }

    // MARK: - JSON Parsing

    private func parseJSON<T: Decodable>(from text: String, type: T.Type) throws -> T {
        let cleaned = extractJSON(from: text)
        guard let data = cleaned.data(using: .utf8) else {
            throw ServiceError.parsingError("JSON编码失败")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func parseJSONArray<T: Decodable>(from text: String) throws -> [T] {
        let cleaned = extractJSON(from: text)
        guard let data = cleaned.data(using: .utf8) else {
            throw ServiceError.parsingError("JSON编码失败")
        }
        do {
            return try JSONDecoder().decode([T].self, from: data)
        } catch {
            let single = try JSONDecoder().decode(T.self, from: data)
            return [single]
        }
    }

    private func extractJSON(from text: String) -> String {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let jsonStart = text.range(of: "```json"),
           let jsonEnd = text[jsonStart.upperBound...].range(of: "```") {
            return String(text[jsonStart.upperBound..<jsonEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let blockStart = text.range(of: "```"),
           let blockEnd = text[blockStart.upperBound...].range(of: "```") {
            return String(text[blockStart.upperBound..<blockEnd.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let firstBrace = text.firstIndex(of: "{"),
           let lastBrace = text.lastIndex(of: "}") {
            return String(text[firstBrace...lastBrace])
        }
        if let firstBracket = text.firstIndex(of: "["),
           let lastBracket = text.lastIndex(of: "]") {
            return String(text[firstBracket...lastBracket])
        }
        return text
    }

    // MARK: - Image Compression

    private func compressImage(_ data: Data, maxSizeKB: Int) -> Data {
        guard let image = UIImage(data: data) else { return data }
        let maxBytes = maxSizeKB * 1024
        if data.count <= maxBytes { return data }

        var compression: CGFloat = 0.8
        var result = data
        while result.count > maxBytes && compression > 0.1 {
            guard let compressed = image.jpegData(compressionQuality: compression) else { break }
            result = compressed
            compression -= 0.1
        }
        return result
    }
}
