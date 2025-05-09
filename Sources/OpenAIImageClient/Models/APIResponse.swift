//
//  APIResponse.swift
//  OpenAIImageClient
//
//  Created by Daria Varabei on 9.05.25.
//

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
