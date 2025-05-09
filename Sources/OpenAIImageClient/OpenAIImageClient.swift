
import Foundation

public struct OpenAIImageEditResult: Sendable {
    public let data: Data
    public init(data: Data) {
        self.data = data
    }
}

struct APIResponse: Decodable {
    let created: Int
    let data: [ImageData]
    let usage: Usage
    
    struct ImageData: Decodable {
        let b64_json: String
    }
    
    struct Usage: Decodable {
        let total_tokens: Int
        let input_tokens: Int
        let output_tokens: Int
        let input_tokens_details: InputTokensDetails
    }
    
    struct InputTokensDetails: Decodable {
        let text_tokens: Int
        let image_tokens: Int
    }
}

public final class OpenAIImageClient: @unchecked Sendable {
    
    private let apiKey: String
    private let session: URLSession
    
    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    public func generateImage(
            prompt: String,
            model: String = "gpt-image-1",
            size: String = "auto",
            n: Int = 1
    ) async throws -> [OpenAIImageResult] {
        
        let url = URL(string: "https://api.openai.com/v1/images/generations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "prompt": prompt,
            "model": model,
            "n": n,
            "size": size
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAIImageGenerationClient", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Request failed: \(msg)"
            ])
        }
        
        print(String(data: data, encoding: .utf8) ?? "No readable response")
        
        if let decoded = try? JSONDecoder().decode(APIResponse.self, from: data) {
            return try await withThrowingTaskGroup(of: OpenAIImageResult.self) { group in
                for imageData in decoded.data {
                    group.addTask {
                        let imageData = Data(base64Encoded: decoded.data.first?.b64_json ?? "")
                        return OpenAIImageResult(data: imageData ?? Data())
                    }
                }
                return try await group.reduce(into: [OpenAIImageResult]()) { $0.append($1) }
            }
        } else if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let err = errorJSON["error"] as? [String: Any],
                  let msg = err["message"] as? String {
            throw NSError(domain: "OpenAIImageGenerationClient", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "API Error: \(msg)"
            ])
        } else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown response"
            throw NSError(domain: "OpenAIImageGenerationClient", code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Unexpected response: \(msg)"
            ])
        }
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}


public struct OpenAIImageResult: Sendable {
    public let data: Data
    public init(data: Data) {
        self.data = data
    }
}
