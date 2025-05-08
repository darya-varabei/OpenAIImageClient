
import Foundation

public final class OpenAIImageClient: @unchecked Sendable {
    
    private let apiKey: String
    private let session: URLSession
    
    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    public func editImage(
        prompt: String,
        imageFiles: [Data],
        model: String = "gpt-image-1"
    ) async throws -> [ImageGenResult] {
        
        let url = URL(string: "https://api.openai.com/v1/images/edits")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let body = try createMultipartBody(
            model: model,
            prompt: prompt,
            imageFiles: imageFiles,
            boundary: boundary
        )
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "ImageGenKit", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to edit image"
            ])
        }

        struct APIResponse: Decodable {
            struct Item: Decodable {
                let url: URL
            }
            let data: [Item]
        }

        let decoded = try JSONDecoder().decode(APIResponse.self, from: data)

        var results: [ImageGenResult] = []
        for item in decoded.data {
            let (imageData, _) = try await session.data(from: item.url)
            results.append(ImageGenResult(data: imageData))
        }

        return results
    }
    
    private func createMultipartBody(
        model: String,
        prompt: String,
        imageFiles: [Data],
        boundary: String
    ) throws -> Data {
        
        var body = Data()
        let lineBreak = "\r\n"
        
        // Model
        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"model\"\(lineBreak + lineBreak)")
        body.append("\(model)\(lineBreak)")

        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"prompt\"\(lineBreak + lineBreak)")
        body.append("\(prompt)\(lineBreak)")

        for (index, imageData) in imageFiles.enumerated() {
            body.append("--\(boundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"file\(index).png\"\(lineBreak)")
            body.append("Content-Type: image/png\(lineBreak + lineBreak)")
            body.append(imageData)
            body.append(lineBreak)
        }

        body.append("--\(boundary)--\(lineBreak)")
        return body
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}
