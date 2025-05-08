
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
                "size": size,
                "response_format": "b64_json"
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
                    let b64_json: String
                }
                let data: [ImageData]
            }

            let decoded = try JSONDecoder().decode(APIResponse.self, from: data)

            return try decoded.data.map { imageData in
                guard let imageData = Data(base64Encoded: imageData.b64_json) else {
                    throw NSError(domain: "OpenAIImageGenerationClient", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to decode image"
                    ])
                }
                return OpenAIImageResult(data: imageData)
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
