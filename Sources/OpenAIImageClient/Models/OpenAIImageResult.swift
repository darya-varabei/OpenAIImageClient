//
//  OpenAIImageResult.swift
//  OpenAIImageClient
//
//  Created by Daria Varabei on 9.05.25.
//

public struct OpenAIImageResult: Sendable {
    public let data: Data
    public init(data: Data) {
        self.data = data
    }
}
