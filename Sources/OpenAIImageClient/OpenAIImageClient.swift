
import Foundation

public final class OpenAIImageClient: @unchecked Sendable {
    
    private let apiKey: String
    private let session: URLSession
    
    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    public struct OpenAIImageEditResult: Sendable {
        public let data: Data
        public init(data: Data) {
            self.data = data
        }
    }
    
    public func generateImage(
            prompt: String,
            model: String = "gpt-image-1",
            size: String = "1024x1024",
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
        
        struct APIResponse: Decodable {
            struct ImageData: Decodable {
                let url: String
            }
            let data: [ImageData]
        }
        
        let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        
        return try await withThrowingTaskGroup(of: OpenAIImageResult.self) { group in
            for imageData in decoded.data {
                group.addTask {
                    guard let imageURL = URL(string: imageData.url) else {
                        throw URLError(.badURL)
                    }
                    let (imageData, _) = try await self.session.data(from: imageURL)
                    return OpenAIImageResult(data: imageData)
                }
            }
            
            return try await group.reduce(into: [OpenAIImageResult]()) { $0.append($1) }
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
