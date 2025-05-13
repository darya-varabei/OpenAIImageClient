![Static Badge](https://img.shields.io/badge/Platforms-gray) ![Static Badge](https://img.shields.io/badge/iOS_%7C_macOS%20-%20blue)  ![Static Badge](https://img.shields.io/badge/Swift-gray) ![Static Badge](https://img.shields.io/badge/6.1_%7C_6.0_%7C_5.10_%7C_5.9-blue)


![logo](https://github.com/user-attachments/assets/24f054e6-801b-421c-8bbe-f48ae3653e75)

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
- Valid OpenAI API key with account verification
- Network permission enabled

## 📦 Installation

Add to your project via **Swift Package Manager**:

```swift
.package(url: "https://github.com/darya-varabei/OpenAIImageClient.git", from: "1.0.0")
```

## 💡 Usage

For image generation (generate image from prompt):

```swift
    private let client = OpenAIImageClient(apiKey: "sk-***") // recommended to NOT store in code for production apps

    let prompt = "Generate an image of a spaceship"
    
    do {
        let results = try await client.generateImage(prompt: prompt, size: .x1536x1024)
        if let data = results.first?.data {
            image = UIImage(data: data)
        }
    } catch {
        self.error = error.localizedDescription
    }
```


For image edit (edit provided images according to provided prompt):

```swift
    private let client = OpenAIImageClient(apiKey: "sk-***") // recommended to NOT store in code for production apps
    
    let prompt = "Make the room look like a spaceship"
    
    let images = [UIImage(named: "result")!.pngData()!]
    
    do {
        let results = try await client.editImages(images: images, prompt: prompt)
        if let data = results.first {
            image = UIImage(data: data)
        }
    } catch {
        self.error = error.localizedDescription
    }
```

## 🔮 To be added

- Test coverage
- More OpenAI requst parameters
- Anything else proposed by community :)
