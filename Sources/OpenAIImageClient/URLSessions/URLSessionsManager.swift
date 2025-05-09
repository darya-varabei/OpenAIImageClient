//
//  URLSessionsManager.swift
//  OpenAIImageClient
//
//  Created by Daria Varabei on 9.05.25.
//

import Foundation

class URLSessionsManager {
    
    private let session: URLSession = .shared
    
    func session(
        url: URL,
        httpMethod: String,
        apiKey: String,
        body: [String: Any]
    ) async throws -> (Data, Any) {
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        return try await session.data(for: request)
    }
}
