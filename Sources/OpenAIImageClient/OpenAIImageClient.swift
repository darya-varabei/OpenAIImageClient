
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
    
    public func editImage(
            prompt: String,
            image: Data,
            mask: Data? = nil,
            n: Int = 1,
            size: String = "1024x1024"
        ) async throws -> [OpenAIImageEditResult] {
            
            let request = try createRequest(
                prompt: prompt,
                image: image,
                mask: mask,
                n: n,
                size: size
            )
            
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else {
                let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "OpenAIImageEditClient", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "Request failed: \(msg)"
                ])
            }

            struct OpenAIImageResponse: Decodable {
                let data: [ImageData]
                struct ImageData: Decodable {
                    let b64_json: String
                }
            }

            let decoded = try JSONDecoder().decode(OpenAIImageResponse.self, from: data)

            let results: [OpenAIImageEditResult] = try decoded.data.map { imageData in
                guard let decodedData = Data(base64Encoded: imageData.b64_json) else {
                    throw NSError(domain: "OpenAIImageEditClient", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "Failed to decode base64 image"
                    ])
                }
                return OpenAIImageEditResult(data: decodedData)
            }

            return results
        }

        private func createRequest(
            prompt: String,
            image: Data,
            mask: Data?,
            n: Int,
            size: String
        ) throws -> URLRequest {
            
            let url = URL(string: "https://api.openai.com/v1/images/edits")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            let boundary = UUID().uuidString
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var body = Data()

            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n")
            body.append("dall-e-2\r\n")

            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n")
            body.append("\(prompt)\r\n")

            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"n\"\r\n\r\n")
            body.append("\(n)\r\n")

            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"size\"\r\n\r\n")
            body.append("\(size)\r\n")

            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"response_format\"\r\n\r\n")
            body.append("b64_json\r\n")

            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.png\"\r\n")
            body.append("Content-Type: image/png\r\n\r\n")
            body.append(image)
            body.append("\r\n")

            if let mask = mask {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"mask\"; filename=\"mask.png\"\r\n")
                body.append("Content-Type: image/png\r\n\r\n")
                body.append(mask)
                body.append("\r\n")
            }

            body.append("--\(boundary)--\r\n")

            request.httpBody = body
            return request
        }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}
