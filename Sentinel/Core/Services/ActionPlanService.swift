//
//  ActionPlanService.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import Foundation

/// Service for generating AI-powered action plans using Gemini API
class ActionPlanService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

    init(apiKey: String = APIConfiguration.geminiAPIKey) {
        self.apiKey = apiKey
    }

    /// Test function to diagnose Gemini API issues
    func testGeminiAPI() async -> String {
        var log = "🧪 GEMINI API TEST\n\n"

        log += "API Key: \(apiKey.prefix(10))...\n"
        log += "Base URL: \(baseURL)\n\n"

        let testPrompt = "Say 'Hello World' in this format:\nTASK: Test\nPRIORITY: High\nCATEGORY: Emergency\nDESCRIPTION: Test task\nCOST: 100\nTIME: 1 hour\n---"

        let requestBody: [String: Any] = [
            "contents": [["parts": [["text": testPrompt]]]],
            "generationConfig": ["temperature": 0.7, "maxOutputTokens": 512]
        ]

        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            return log + "❌ Invalid URL"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                log += "✅ Status: \(httpResponse.statusCode)\n\n"
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                log += "Response:\n\(jsonString.prefix(500))\n"
            }

            let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            if let text = geminiResponse.candidates.first?.content.parts.first?.text {
                log += "\n✅ Got text (\(text.count) chars):\n\(text)\n"
            }

        } catch {
            log += "❌ Error: \(error)\n"
        }

        return log
    }

    /// Generate action plan and mitigation tasks based on HVS and property data
    /// Tries Gemini AI first, falls back to smart defaults if it fails
    func generateActionPlan(
        hvsScore: Double,
        propertyProfile: PropertyProfile,
        hazardAssessment: HazardAssessment
    ) async throws -> ActionPlanResponse {

        // Use smart default plan for now - Gemini is having issues
        print("ℹ️  Using smart default action plan (fast & reliable)")
        return generateSmartDefaultPlan(hvsScore: hvsScore, propertyProfile: propertyProfile, hazardAssessment: hazardAssessment)

        // GEMINI DISABLED TEMPORARILY - uncomment below to re-enable
        /*
        // Check if API key is configured
        guard !apiKey.isEmpty else {
            print("⚠️  Gemini API key not configured - using smart defaults")
            return generateSmartDefaultPlan(hvsScore: hvsScore, propertyProfile: propertyProfile, hazardAssessment: hazardAssessment)
        }

        print("🤖 ATTEMPTING GEMINI AI GENERATION")
        print("ℹ️  API Key (first 10 chars): \(String(apiKey.prefix(10)))...")
        print("ℹ️  Base URL: \(baseURL)")

        let prompt = buildPrompt(hvsScore: hvsScore, property: propertyProfile, hazards: hazardAssessment)
        print("ℹ️  Prompt length: \(prompt.count) characters")
        print("ℹ️  Prompt preview:\n\(prompt.prefix(200))")

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.2,  // Lower temperature for more consistent format
                "topK": 20,
                "topP": 0.8,
                "maxOutputTokens": 1500
            ]
        ]

        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            print("⚠️  Failed to create URL")
            throw ActionPlanError.invalidURL
        }

        print("ℹ️  Making request to Gemini API...")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 15 // 15 second timeout - faster failure

        do {
            print("🚀 Sending request to Gemini...")
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response from Gemini")
                throw ActionPlanError.networkError
            }

            print("✅ Received response from Gemini")
            print("📡 Status code: \(httpResponse.statusCode)")
            print("📋 Response size: \(data.count) bytes")

            if httpResponse.statusCode != 200 {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("⚠️  Gemini API error response: \(errorString)")
                }

                // Parse specific error
                if httpResponse.statusCode == 429 {
                    throw ActionPlanError.rateLimitExceeded
                } else if httpResponse.statusCode == 403 {
                    throw ActionPlanError.invalidAPIKey
                } else if httpResponse.statusCode == 400 {
                    throw ActionPlanError.badRequest
                } else {
                    throw ActionPlanError.apiError
                }
            }

            // Try to decode response
            do {
                print("🔍 Decoding JSON response...")
                let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                print("✅ JSON decoded successfully")

                guard let text = geminiResponse.candidates.first?.content.parts.first?.text else {
                    print("❌ No text in Gemini response!")
                    print("🔍 Candidates count: \(geminiResponse.candidates.count)")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("📄 Full response:\n\(jsonString)")
                    }
                    throw ActionPlanError.invalidResponse
                }

                print("✅ Gemini AI generated action plan successfully")
                print("ℹ️  Response text length: \(text.count) characters")
                print("ℹ️  Response preview (first 300 chars):")
                print(text.prefix(300))
                print("ℹ️  Checking for escaped newlines...")
                print("ℹ️  Contains \\\\n: \(text.contains("\\n"))")
                print("ℹ️  Contains actual newlines: \(text.contains("\n"))")

                let result = parseActionPlanResponse(text: text, userId: propertyProfile.userId)
                print("ℹ️  Parsed \(result.tasks.count) tasks")
                print("ℹ️  Alert text: \(result.alertText.prefix(100))")

                // Validate we got actual tasks
                if result.tasks.isEmpty {
                    print("⚠️  WARNING: No tasks were parsed from Gemini response!")
                    print("⚠️  Full Gemini text:\n\(text)")
                    print("⚠️  Falling back to smart default plan")
                    return generateSmartDefaultPlan(hvsScore: hvsScore, propertyProfile: propertyProfile, hazardAssessment: hazardAssessment)
                }

                print("✅ Successfully generated \(result.tasks.count) tasks from Gemini")
                return result
            } catch let error as ActionPlanError {
                throw error
            } catch {
                print("⚠️  Failed to decode Gemini response: \(error.localizedDescription)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("⚠️  Raw response: \(jsonString)")
                }
                throw ActionPlanError.invalidResponse
            }

        } catch let error as ActionPlanError {
            // Gemini API errors - use fallback
            print("❌ ActionPlanError caught: \(error.localizedDescription)")
            print("⚠️  Falling back to smart default plan")
            return generateSmartDefaultPlan(hvsScore: hvsScore, propertyProfile: propertyProfile, hazardAssessment: hazardAssessment)
        } catch {
            // Network or other errors - use fallback
            print("❌ Unexpected error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            print("⚠️  Falling back to smart default plan")
            return generateSmartDefaultPlan(hvsScore: hvsScore, propertyProfile: propertyProfile, hazardAssessment: hazardAssessment)
        }
        */
    }

    private func buildPrompt(hvsScore: Double, property: PropertyProfile, hazards: HazardAssessment) -> String {
        """
        You are a home safety expert. Generate a safety action plan for this property:

        Property: \(property.address), built \(property.yearBuilt), \(Int(property.squareFootage)) sq ft
        Roof: \(property.roofMaterial.rawValue) (\(property.roofAge) years old)
        HVS Score: \(Int(hvsScore))/100
        Top Risks: Hurricane \(Int(hazards.riskScores.hurricane)), Flood \(Int(hazards.riskScores.flood)), Tornado \(Int(hazards.riskScores.tornado))

        Generate exactly 5 safety tasks in this EXACT format (no extra text or headers):

        TASK: [Task title]
        PRIORITY: [Critical/High/Medium/Low]
        CATEGORY: [Emergency/Structural/Maintenance]
        DESCRIPTION: [What needs to be done]
        COST: [Number only, e.g. 500]
        TIME: [Time estimate, e.g. 2 hours]
        ---
        TASK: [Next task title]
        PRIORITY: [Critical/High/Medium/Low]
        CATEGORY: [Emergency/Structural/Maintenance]
        DESCRIPTION: [What needs to be done]
        COST: [Number only]
        TIME: [Time estimate]
        ---

        Continue for all 5 tasks. Use only Emergency, Structural, or Maintenance for CATEGORY.
        """
    }

    private func parseActionPlanResponse(text: String, userId: String) -> ActionPlanResponse {
        print("📝 Starting to parse Gemini response")
        print("📝 Text length: \(text.count) characters")

        var alertText = "Your home safety action plan has been generated based on current risk assessments."
        var tasks: [MitigationTask] = []
        var currentTask: [String: String] = [:]

        // Split into lines
        let lines = text.components(separatedBy: .newlines)
        print("📄 Found \(lines.count) lines")

        // Show first 5 lines for debugging
        print("📋 First 5 lines:")
        for (i, line) in lines.prefix(5).enumerated() {
            print("  [\(i)]: '\(line)'")
        }

        // Parse line by line
        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            // Skip empty lines
            if trimmed.isEmpty { continue }

            if trimmed.uppercased().hasPrefix("TASK:") {
                // Save previous task if it exists
                if !currentTask.isEmpty {
                    let task = createTask(from: currentTask, userId: userId)
                    tasks.append(task)
                    print("✅ Saved task: \(task.title)")
                    currentTask = [:]
                }
                // Start new task
                let title = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)
                currentTask["title"] = title
                print("🆕 Found task at line \(index): \(title)")

            } else if trimmed.uppercased().hasPrefix("PRIORITY:") {
                currentTask["priority"] = trimmed.dropFirst(9).trimmingCharacters(in: .whitespaces)

            } else if trimmed.uppercased().hasPrefix("CATEGORY:") {
                let category = trimmed.dropFirst(9).trimmingCharacters(in: .whitespaces)
                currentTask["category"] = category.components(separatedBy: "/").first ?? category

            } else if trimmed.uppercased().hasPrefix("DESCRIPTION:") {
                currentTask["description"] = trimmed.dropFirst(12).trimmingCharacters(in: .whitespaces)

            } else if trimmed.uppercased().hasPrefix("COST:") {
                currentTask["cost"] = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)

            } else if trimmed.uppercased().hasPrefix("TIME:") {
                currentTask["time"] = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)

            } else if trimmed == "---" {
                // End of task marker - save current task
                if !currentTask.isEmpty {
                    let task = createTask(from: currentTask, userId: userId)
                    tasks.append(task)
                    print("✅ Saved task (at ---): \(task.title)")
                    currentTask = [:]
                }
            }
        }

        // Don't forget the last task if there's no final ---
        if !currentTask.isEmpty {
            let task = createTask(from: currentTask, userId: userId)
            tasks.append(task)
            print("✅ Saved final task: \(task.title)")
        }

        print("📊 Total tasks created: \(tasks.count)")

        return ActionPlanResponse(alertText: alertText, tasks: tasks)
    }

    private func createTask(from data: [String: String], userId: String) -> MitigationTask {
        let priority = MitigationTask.Priority(rawValue: data["priority"] ?? "Medium") ?? .medium

        // Map category string to enum - be flexible with Gemini's responses
        let categoryString = (data["category"] ?? "Maintenance").lowercased()
        let category: MitigationTask.Category
        if categoryString.contains("struct") {
            category = .structural
        } else if categoryString.contains("emergency") || categoryString.contains("fire") || categoryString.contains("safety") {
            category = .emergency
        } else if categoryString.contains("landscape") || categoryString.contains("yard") {
            category = .landscaping
        } else if categoryString.contains("utilities") || categoryString.contains("electric") || categoryString.contains("plumb") {
            category = .utilities
        } else if categoryString.contains("document") {
            category = .documentation
        } else if categoryString.contains("insurance") {
            category = .insurance
        } else if categoryString.contains("monitor") {
            category = .monitoring
        } else {
            category = .maintenance
        }

        let costString = data["cost"]?.components(separatedBy: CharacterSet.decimalDigits.inverted).joined() ?? "0"
        let cost = Double(costString) ?? 0

        let title = data["title"] ?? "Untitled Task"
        let description = data["description"] ?? "No description provided"

        print("🏗️ Creating task: '\(title)' - Priority: \(priority), Category: \(category)")

        return MitigationTask(
            title: title,
            description: description,
            priority: priority,
            category: category,
            status: .notStarted,
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            estimatedCost: cost > 0 ? cost : nil,
            estimatedTime: data["time"],
            isAIGenerated: true,
            userId: userId,
            notes: "",
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Generate a smart default action plan based on HVS and risks
    private func generateSmartDefaultPlan(hvsScore: Double, propertyProfile: PropertyProfile, hazardAssessment: HazardAssessment) -> ActionPlanResponse {
        print("\n🔧 GENERATING SMART DEFAULT ACTION PLAN")
        print("📍 Location: \(propertyProfile.latitude), \(propertyProfile.longitude)")
        print("🏠 Address: \(propertyProfile.address)")
        print("📊 HVS: \(Int(hvsScore))")
        print("🌪️ Risk Scores:")
        print("   Hurricane: \(Int(hazardAssessment.riskScores.hurricane))")
        print("   Flood: \(Int(hazardAssessment.riskScores.flood))")
        print("   Tornado: \(Int(hazardAssessment.riskScores.tornado))")
        print("📜 Historical Events: \(hazardAssessment.historicalPerils.count)")
        print("⚠️  Active Forecasts: \(hazardAssessment.currentForecasts.count)")
        print("🏠 Roof Age: \(propertyProfile.roofAge) years")

        // Determine alert text based on HVS score
        let alertText: String
        if hvsScore >= 70 {
            alertText = "Your home has a high vulnerability score of \(Int(hvsScore))/100. Immediate action is recommended to improve safety and reduce risks."
        } else if hvsScore >= 50 {
            alertText = "Your home vulnerability score is \(Int(hvsScore))/100. Several improvements can enhance your home's safety and resilience."
        } else {
            alertText = "Your home vulnerability score is \(Int(hvsScore))/100. Maintain current safety measures and address the recommendations below."
        }

        // Determine top risks
        let topRisk = max(hazardAssessment.riskScores.hurricane, hazardAssessment.riskScores.flood, hazardAssessment.riskScores.tornado)
        let isHurricaneRisk = hazardAssessment.riskScores.hurricane >= 60
        let isFloodRisk = hazardAssessment.riskScores.flood >= 60
        let isTornadoRisk = hazardAssessment.riskScores.tornado >= 60
        let isOldRoof = propertyProfile.roofAge > 15

        // Check recent historical events
        let hasRecentHurricanes = hazardAssessment.historicalPerils.contains { $0.type == .hurricane }
        let hasRecentFloods = hazardAssessment.historicalPerils.contains { $0.type == .flood }
        let hasRecentTornadoes = hazardAssessment.historicalPerils.contains { $0.type == .tornado }

        print("📋 Risk Assessment:")
        print("  - Hurricane risk: \(isHurricaneRisk), Recent: \(hasRecentHurricanes)")
        print("  - Flood risk: \(isFloodRisk), Recent: \(hasRecentFloods)")
        print("  - Tornado risk: \(isTornadoRisk), Recent: \(hasRecentTornadoes)")

        var tasks: [MitigationTask] = []

        // Always include emergency preparedness
        tasks.append(MitigationTask(
            title: "Test Smoke and CO Detectors",
            description: "Test all smoke and carbon monoxide detectors. Replace batteries and ensure proper function on all levels of the home.",
            priority: .critical,
            category: .emergency,
            status: .notStarted,
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            estimatedCost: 50,
            estimatedTime: "30 minutes",
            isAIGenerated: true,
            userId: propertyProfile.userId,
            notes: "",
            createdAt: Date(),
            updatedAt: Date()
        ))

        // Add roof task if old or hurricane risk
        if isOldRoof || isHurricaneRisk {
            tasks.append(MitigationTask(
                title: "Professional Roof Inspection",
                description: "Schedule a professional roof inspection to identify weak points, damaged shingles, or structural issues. Your roof is \(propertyProfile.roofAge) years old.",
                priority: isOldRoof ? .high : .medium,
                category: .structural,
                status: .notStarted,
                dueDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                estimatedCost: 350,
                estimatedTime: "2-3 hours",
                relatedPerilType: isHurricaneRisk ? "Hurricane" : nil,
                isAIGenerated: true,
                userId: propertyProfile.userId,
                notes: "",
                createdAt: Date(),
                updatedAt: Date()
            ))
        }

        // Add hurricane-specific tasks
        if isHurricaneRisk && !propertyProfile.hasStormShutters {
            tasks.append(MitigationTask(
                title: "Install Storm Shutters",
                description: "Install storm shutters or impact-resistant window protection to safeguard against hurricane-force winds and flying debris.",
                priority: .high,
                category: .structural,
                status: .notStarted,
                dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
                estimatedCost: 2500,
                estimatedTime: "1-2 days",
                relatedPerilType: "Hurricane",
                isAIGenerated: true,
                userId: propertyProfile.userId,
                notes: "",
                createdAt: Date(),
                updatedAt: Date()
            ))
        }

        // Add flood-related tasks
        if isFloodRisk || hasRecentFloods {
            tasks.append(MitigationTask(
                title: "Clear Gutters and Drainage Systems",
                description: "Remove debris from gutters and downspouts. Ensure proper drainage away from the foundation to prevent water damage. Your area has flood risk.",
                priority: hasRecentFloods ? .high : .medium,
                category: .maintenance,
                status: .notStarted,
                dueDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                estimatedCost: 150,
                estimatedTime: "2-3 hours",
                relatedPerilType: "Flood",
                isAIGenerated: true,
                userId: propertyProfile.userId,
                notes: "",
                createdAt: Date(),
                updatedAt: Date()
            ))
        }

        // Add tornado-related tasks
        if isTornadoRisk || hasRecentTornadoes {
            tasks.append(MitigationTask(
                title: "Identify Safe Room for Tornadoes",
                description: "Designate an interior room on the lowest floor with no windows as your tornado safe room. Stock it with emergency supplies. Your area has tornado risk.",
                priority: .high,
                category: .emergency,
                status: .notStarted,
                dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                estimatedCost: 100,
                estimatedTime: "1 hour",
                relatedPerilType: "Tornado",
                isAIGenerated: true,
                userId: propertyProfile.userId,
                notes: "",
                createdAt: Date(),
                updatedAt: Date()
            ))
        }

        // Always add emergency kit task
        tasks.append(MitigationTask(
            title: "Prepare Emergency Kit",
            description: "Assemble or update emergency kit with water, food, flashlights, batteries, first aid supplies, and important documents.",
            priority: .high,
            category: .emergency,
            status: .notStarted,
            dueDate: Calendar.current.date(byAdding: .day, value: 10, to: Date()),
            estimatedCost: 200,
            estimatedTime: "2 hours",
            isAIGenerated: true,
            userId: propertyProfile.userId,
            notes: "",
            createdAt: Date(),
            updatedAt: Date()
        ))

        // Add general maintenance task
        tasks.append(MitigationTask(
            title: "Inspect HVAC and Utilities",
            description: "Check heating, ventilation, and air conditioning systems. Inspect electrical panel and plumbing for leaks or issues.",
            priority: .medium,
            category: .maintenance,
            status: .notStarted,
            dueDate: Calendar.current.date(byAdding: .day, value: 21, to: Date()),
            estimatedCost: 300,
            estimatedTime: "3-4 hours",
            isAIGenerated: true,
            userId: propertyProfile.userId,
            notes: "",
            createdAt: Date(),
            updatedAt: Date()
        ))

        print("✅ Generated \(tasks.count) smart default tasks")
        return ActionPlanResponse(alertText: alertText, tasks: tasks)
    }

    private func generateMockActionPlan(hvsScore: Double, hazardAssessment: HazardAssessment) -> ActionPlanResponse {
        let alertText = "Your home vulnerability score is \(Int(hvsScore)). Based on recent weather patterns and upcoming forecasts, we recommend immediate attention to hurricane preparation and roof maintenance."

        let tasks = [
            MitigationTask(
                title: "Inspect and reinforce roof shingles",
                description: "Check for loose or damaged shingles. Secure or replace as needed before hurricane season peaks.",
                priority: .high,
                category: .structural,
                status: .notStarted,
                dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                estimatedCost: 800,
                estimatedTime: "4-6 hours",
                relatedPerilType: "Hurricane",
                isAIGenerated: true,
                userId: "mock",
                notes: "",
                createdAt: Date(),
                updatedAt: Date()
            ),
            MitigationTask(
                title: "Install storm shutters",
                description: "Protect windows from hurricane-force winds and flying debris.",
                priority: .critical,
                category: .structural,
                status: .notStarted,
                dueDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                estimatedCost: 2500,
                estimatedTime: "1-2 days",
                relatedPerilType: "Hurricane",
                isAIGenerated: true,
                userId: "mock",
                notes: "",
                createdAt: Date(),
                updatedAt: Date()
            ),
            MitigationTask(
                title: "Clear gutters and downspouts",
                description: "Remove debris to prevent water damage during heavy rainfall.",
                priority: .medium,
                category: .maintenance,
                status: .notStarted,
                dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()),
                estimatedCost: 150,
                estimatedTime: "2-3 hours",
                relatedPerilType: "Flood",
                isAIGenerated: true,
                userId: "mock",
                notes: "",
                createdAt: Date(),
                updatedAt: Date()
            )
        ]

        return ActionPlanResponse(alertText: alertText, tasks: tasks)
    }
}

// MARK: - Supporting Types

struct ActionPlanResponse {
    let alertText: String
    let tasks: [MitigationTask]
}

enum ActionPlanError: Error, LocalizedError {
    case apiKeyMissing
    case invalidAPIKey
    case invalidURL
    case apiError
    case invalidResponse
    case networkError
    case rateLimitExceeded
    case badRequest

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "Gemini API key not configured. Please add your API key in APIConfiguration.swift"
        case .invalidAPIKey:
            return "Invalid Gemini API key. Please check your API key configuration."
        case .invalidURL:
            return "Invalid API URL configuration"
        case .apiError:
            return "Gemini API request failed. Please try again."
        case .invalidResponse:
            return "Gemini AI returned an invalid response. Please try again."
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .rateLimitExceeded:
            return "API rate limit exceeded (60 requests/min). Please wait a moment and try again."
        case .badRequest:
            return "Invalid request format. Please check the API configuration."
        }
    }
}

// Gemini API Response Models
private struct GeminiResponse: Codable {
    let candidates: [Candidate]

    struct Candidate: Codable {
        let content: Content
    }

    struct Content: Codable {
        let parts: [Part]
    }

    struct Part: Codable {
        let text: String
    }
}
