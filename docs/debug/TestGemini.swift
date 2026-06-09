//
//  TestGemini.swift
//  Quick test to verify Gemini API works
//
//  Run this in a playground or add to your app temporarily
//

import Foundation

func testGeminiAPI() async {
    guard let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !apiKey.isEmpty else {
        print("Set GEMINI_API_KEY before running this diagnostic.")
        return
    }

    // Test with the simplest possible request first
    let simpleURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)"

    let requestBody: [String: Any] = [
        "contents": [
            [
                "parts": [
                    ["text": "Say 'Hello' in JSON format with a field called 'greeting'"]
                ]
            ]
        ],
        "generationConfig": [
            "responseMimeType": "application/json",
            "responseSchema": [
                "type": "OBJECT",
                "properties": [
                    "greeting": ["type": "STRING"]
                ],
                "required": ["greeting"]
            ]
        ]
    ]

    do {
        guard let url = URL(string: simpleURL) else {
            print("❌ Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("🧪 Testing Gemini API...")
        print("📍 Model: gemini-2.0-flash")
        print("📍 Endpoint: v1beta")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ No HTTP response")
            return
        }

        print("📡 Status Code: \(httpResponse.statusCode)")

        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Response:")
            print(responseString)
        }

        if httpResponse.statusCode == 200 {
            print("✅ SUCCESS! Gemini API works with gemini-2.0-flash")

            // Try to parse the response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = json["candidates"] as? [[String: Any]],
               let content = candidates.first?["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]],
               let text = parts.first?["text"] as? String {
                print("📝 Parsed text:")
                print(text)
                print("✅ JSON parsing works!")
            }
        } else {
            print("❌ FAILED - Wrong model name or API issue")
        }

    } catch {
        print("❌ Error: \(error)")
    }
}

// Usage:
// Task {
//     await testGeminiAPI()
// }
