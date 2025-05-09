# OpenAIImageClient

A lightweight Swift package for interacting with OpenAI's `gpt-image-1` model to generate or edit images using natural language prompts and image files.

## ✨ Features

- Supports multiple input images (`image[]`) for editing
- Uses `multipart/form-data` requests to match OpenAI API requirements
- Returns generated image data in decoded PNG format
- Compatible with SwiftUI and UIKit
- Swift Concurrency (`async/await`) support

## 🛠 Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.7+
- Valid OpenAI API key
- Network permission enabled

## 📦 Installation

Add to your project via **Swift Package Manager**:

```swift
.package(url: "https://github.com/darya-varabei/OpenAIImageClient.git", from: "1.0.0")

