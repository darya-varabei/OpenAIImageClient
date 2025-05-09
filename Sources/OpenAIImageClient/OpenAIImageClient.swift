import Foundation

public final class OpenAIImageClient: @unchecked Sendable {
    
    private let apiKey: String
    private let sessionManager = URLSessionsManager()
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func generateImage(
            prompt: String,
            model: OpenAIImageModels = .gpt_image_1,
            size: OpenAIImageSize = .auto,
            n: Int = 1
    ) async throws -> [OpenAIImageResult] {
        
        let body: [String: Any] = [
            "prompt": prompt,
            "model": model,
            "n": n,
            "size": size
        ]
        
        let (data, response) = try await sessionManager.session(url: URL(string: "https://api.openai.com/v1/images/generations")!, httpMethod: "POST", apiKey: apiKey, body: body)
        
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
    
    public func editImage(
            prompt: String,
            model: OpenAIImageModels = .gpt_image_1,
            size: OpenAIImageSize = .auto,
            n: Int = 1,
            imageFiles: [Data]
    ) async throws -> [OpenAIImageResult] {
        
        let body: [String: Any] = [
            "prompt": prompt,
            "model": model,
            "n": n,
            "size": size,
            "image": imageFiles
        ]
        
        let (data, response) = try await sessionManager.session(url: URL(string: "https://api.openai.com/v1/images/edits")!, httpMethod: "POST", apiKey: apiKey, body: body)
        
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
