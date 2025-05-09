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
            "model": model.rawValue,
            "n": n,
            "size": size.rawValue
        ]
        
        let (data, response) = try await sessionManager.session(url: OpenAIEnvironment.generateImageUrl,
                                                                httpMethod: "POST",
                                                                apiKey: apiKey,
                                                                body: body)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? OpenAIEnvironment.Error.unknownError
            throw NSError(domain: OpenAIEnvironment.Error.errorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        if let decoded = try? JSONDecoder().decode(APIResponse.self, from: data) {
            return try await withThrowingTaskGroup(of: OpenAIImageResult.self) { group in
                group.addTask {
                    let imageData = Data(base64Encoded: decoded.data.first?.b64_json ?? "")
                    return OpenAIImageResult(data: imageData ?? Data())
                }
                return try await group.reduce(into: [OpenAIImageResult]()) { $0.append($1) }
            }
        } else if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let err = errorJSON["error"] as? [String: Any],
                  let msg = err["message"] as? String {
            throw NSError(domain: OpenAIEnvironment.Error.errorDomain, code: 2, userInfo: [
                NSLocalizedDescriptionKey: "API Error: \(msg)"
            ])
        } else {
            let msg = String(data: data, encoding: .utf8) ?? OpenAIEnvironment.Error.unknownError
            throw NSError(domain: OpenAIEnvironment.Error.errorDomain, code: 3, userInfo: [
                NSLocalizedDescriptionKey: "Unexpected response: \(msg)"
            ])
        }
    }
    
    public func editImages(
        images: [Data],
        prompt: String,
        model: OpenAIImageModels = .gpt_image_1,
        size: OpenAIImageSize = .auto,
        n: Int = 1
    ) async throws -> [Data] {
        
        let boundary = "Boundary-\(UUID().uuidString)"
        
        var body = Data()
        
        body.appendField(name: "model", value: model.rawValue, boundary: boundary)
        body.appendField(name: "prompt", value: prompt, boundary: boundary)
        body.appendFileArray(name: "image", files: images, boundary: boundary)
        
        body.append("--\(boundary)--\r\n")
        
        let (data, response) = try await sessionManager.session(url: OpenAIEnvironment.editImageUrl,
                                                                httpMethod: "POST",
                                                                apiKey: apiKey,
                                                                bodyData: body)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? OpenAIEnvironment.Error.unknownError
            throw NSError(domain: OpenAIEnvironment.Error.errorDomain, code: 1, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        
        let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        return try decoded.data.compactMap {
            guard let imageData = Data(base64Encoded: $0.b64_json) else {
                throw NSError(domain: OpenAIEnvironment.Error.errorDomain, code: 2, userInfo: [
                    NSLocalizedDescriptionKey: OpenAIEnvironment.Error.decodeError
                ])
            }
            return imageData
        }
    }
}

fileprivate extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
    
    mutating func appendField(name: String, value: String, boundary: String) {
        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
        append("\(value)\r\n")
    }
    
    mutating func appendFileArray(name: String, files: [Data], boundary: String) {
        for (index, fileData) in files.enumerated() {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"\(name)[]\"; filename=\"image\(index).png\"\r\n")
            append("Content-Type: image/png\r\n\r\n")
            append(fileData)
            append("\r\n")
        }
    }
}
