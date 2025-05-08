//
//  ImageGenResult.swift
//  OpenAIImageClient
//
//  Created by Daria Varabei on 8.05.25.
//

import Foundation

public struct ImageGenResult {
    public let data: Data
    
    public init(data: Data) {
        self.data = data
    }
}
