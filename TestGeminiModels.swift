//
//  TestGeminiModels.swift
//  Quick diagnostic to test different Gemini model names
//

import Foundation

func testGeminiModels() async {
    guard let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !apiKey.isEmpty else {
        print("Set GEMINI_API_KEY before running this diagnostic.")
        return
    }

    // Try different model names
    let modelsToTest = [
        "gemini-pro",
        "gemini-1.5-pro",
        "gemini-1.5-flash",
        "gemini-1.0-pro",
        "gemini-flash"
    ]

    let apiVersions = ["v1", "v1beta"]

    for version in apiVersions {
        print("\n========== Testing API version: \(version) ==========")

        for model in modelsToTest {
            let url = "https://generativelanguage.googleapis.com/\(version)/models/\(model):generateContent?key=\(apiKey)"

            let requestBody: [String: Any] = [
                "contents": [
                    [
                        "parts": [
                            ["text": "Say hello"]
                        ]
                    ]
                ]
            ]

            do {
                guard let urlObj = URL(string: url) else { continue }

                var request = URLRequest(url: urlObj)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("✅ SUCCESS: \(model) works with \(version)")
                    } else {
                        if let errorString = String(data: data, encoding: .utf8) {
                            // Just show status code, not full error
                            print("❌ FAILED: \(model) - Status \(httpResponse.statusCode)")
                        }
                    }
                }

            } catch {
                print("❌ ERROR: \(model) - \(error.localizedDescription)")
            }
        }
    }
}

// To run this:
// Task {
//     await testGeminiModels()
// }
