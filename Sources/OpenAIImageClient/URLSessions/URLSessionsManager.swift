//
//  URLSessionsManager.swift
//  OpenAIImageClient
//
//  Created by Daria Varabei on 9.05.25.
//

import Foundation

class URLSessionsManager {
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
    }
    
    func session(
        url: URL,
        httpMethod: String,
        apiKey: String,
        boundary: String = "",
        body: [String: Any] = [:],
        bodyData: Data = Data()
    ) async throws -> (Data, Any) {
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(boundary.isEmpty ? "multipart/form-data; boundary=\(boundary)" : "application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = body.isEmpty ? bodyData : try JSONSerialization.data(withJSONObject: body)
        
        return try await session.data(for: request)
    }
}
