//
//  OpenAIEnvironment.swift
//  OpenAIImageClient
//
//  Created by Daria Varabei on 9.05.25.
//

import Foundation

enum OpenAIEnvironment {
   static let generateImageUrl = URL(string: "https://api.openai.com/v1/images/generations")!
   static let editImageUrl = URL(string: "https://api.openai.com/v1/images/edits")!
    
    enum Error {
        static let errorDomain = "OpenAIImageEditClient"
        static let unknownError = "Unknown error"
        static let decodeError = "Invalid base64 image"
    }
}
