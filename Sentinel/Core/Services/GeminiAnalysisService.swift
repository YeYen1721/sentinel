//
//  GeminiAnalysisService.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import Foundation

/// Service to analyze property and hazard data using Gemini AI to generate personalized risk scores and recommendations
class GeminiAnalysisService {

    struct AnalysisResult {
        let hvsScore: Double
        let riskScores: HazardAssessment.RiskScores
        let historicalExposureScore: Double
        let forecastedSeverityScore: Double
        let alertText: String
        let summaryText: String
        let tasks: [MitigationTask]
    }

    func analyzePropertyRisk(
        propertyProfile: PropertyProfile,
        hazardAssessment: HazardAssessment
    ) async throws -> AnalysisResult {

        print("\n🤖 GEMINI ANALYSIS STARTING")
        print("📍 Location: \(propertyProfile.latitude), \(propertyProfile.longitude)")
        print("🏠 Address: \(propertyProfile.address)")

        // Build comprehensive data summary for Gemini
        let prompt = buildAnalysisPrompt(propertyProfile: propertyProfile, hazardAssessment: hazardAssessment)

        // Call Gemini API
        let response = try await callGeminiAPI(prompt: prompt)

        // Parse the structured response
        let result = try parseAnalysisResponse(response, propertyProfile: propertyProfile)

        print("✅ GEMINI ANALYSIS COMPLETE")
        print("   HVS: \(Int(result.hvsScore))")
        print("   Tasks: \(result.tasks.count)")

        return result
    }

    private func buildAnalysisPrompt(propertyProfile: PropertyProfile, hazardAssessment: HazardAssessment) -> String {
        var prompt = """
        You are a home risk analysis expert. Analyze the following property and location data to provide a comprehensive, personalized risk assessment.

        PROPERTY INFORMATION:
        - Address: \(propertyProfile.address)
        - Location: \(propertyProfile.latitude)°N, \(propertyProfile.longitude)°W
        - Year Built: \(propertyProfile.yearBuilt)
        - Square Footage: \(Int(propertyProfile.squareFootage)) sq ft
        - Stories: \(propertyProfile.stories)
        - Roof: \(propertyProfile.roofMaterial.rawValue), \(propertyProfile.roofAge) years old
        - Foundation: \(propertyProfile.foundationType.rawValue)
        - Exterior: \(propertyProfile.exteriorMaterial.rawValue)
        - Storm Shutters: \(propertyProfile.hasStormShutters ? "Yes" : "No")
        - Backup Generator: \(propertyProfile.hasBackupGenerator ? "Yes" : "No")
        - Smart Home Monitoring: \(propertyProfile.hasSmartHomeMonitoring ? "Yes" : "No")

        HISTORICAL WEATHER EVENTS (Last 15 years):
        """

        if hazardAssessment.historicalPerils.isEmpty {
            prompt += "\n- No major events recorded in this area"
        } else {
            for event in hazardAssessment.historicalPerils.prefix(10) {
                let dateStr = event.date.formatted(date: .abbreviated, time: .omitted)
                prompt += "\n- \(event.type.rawValue) (\(event.severity.rawValue)) on \(dateStr): \(event.description)"
            }
        }

        prompt += "\n\nCURRENT WEATHER FORECASTS & ALERTS:"
        if hazardAssessment.currentForecasts.isEmpty {
            prompt += "\n- No active weather alerts"
        } else {
            for forecast in hazardAssessment.currentForecasts {
                prompt += "\n- \(forecast.type.rawValue) (\(forecast.alertLevel.rawValue)): \(Int(forecast.probability))% probability, \(forecast.intensity) intensity"
            }
        }

        prompt += """


        ANALYSIS TASK:
        Based on this specific location and property data, provide a comprehensive risk analysis:

        1. HVS Score (Home Vulnerability Score 0-100): Calculate based on property resilience vs hazard exposure
        2. Risk Scores (0-100 each): Base ONLY on the actual location's geography and historical data
           - hurricane: Risk of hurricane damage
           - tornado: Risk of tornado damage
           - flood: Risk of flooding
           - wildfire: Risk of wildfire
           - earthquake: Risk of earthquake
           - hail: Risk of hail damage
           - winterStorm: Risk of winter storm damage

        3. Historical Exposure Score (0-100): How much this specific location has been affected historically
        4. Forecasted Severity Score (0-100): Based on current alerts and upcoming weather
        5. Alert Text: Brief alert about the most urgent risk for THIS specific location
        6. Summary Text: One sentence summary of overall risk

        7. Tasks: Provide 4-7 specific, actionable tasks with realistic deadlines based on:
           - The actual risks for THIS location (not generic advice)
           - The property's age and condition (e.g., if roof is 20 years old, prioritize roof inspection)
           - Active weather alerts
           - Historical events in the area

           For each task:
           - title: Short task name
           - description: Detailed explanation of what to do and why
           - priority: "High", "Medium", or "Low"
           - category: One of: "Structural", "Landscaping", "Utilities", "Emergency Preparedness", "Documentation", "Insurance", "Monitoring", "Maintenance"
           - estimatedCost: Dollar amount (can be 0 for free tasks)
           - estimatedTime: Time estimate like "2-3 hours" or "1 day"
           - deadline: Specific deadline like "within 1 week", "within 2 weeks", "within 1 month", "within 2 months", "within 3 months"
           - perilType: Related peril like "Hurricane", "Tornado", "Flood", etc.
           - insuranceSavings: Estimated annual insurance savings in dollars (e.g., 150 for $150/year savings)
           - insuranceImpact: "Critical" ($500+/yr), "High" ($200-500/yr), "Medium" ($50-200/yr), or "Low" ($10-50/yr)

        Provide personalized, location-specific analysis based on the real data provided.
        """

        return prompt
    }

    private func callGeminiAPI(prompt: String) async throws -> String {
        let url = URL(string: APIConfiguration.geminiBaseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Define the exact JSON schema we want back - this forces Gemini to ONLY return JSON
        let responseSchema: [String: Any] = [
            "type": "OBJECT",
            "properties": [
                "hvsScore": ["type": "NUMBER"],
                "riskScores": [
                    "type": "OBJECT",
                    "properties": [
                        "hurricane": ["type": "NUMBER"],
                        "tornado": ["type": "NUMBER"],
                        "flood": ["type": "NUMBER"],
                        "wildfire": ["type": "NUMBER"],
                        "earthquake": ["type": "NUMBER"],
                        "hail": ["type": "NUMBER"],
                        "winterStorm": ["type": "NUMBER"]
                    ],
                    "required": ["hurricane", "tornado", "flood", "wildfire", "earthquake", "hail", "winterStorm"]
                ],
                "historicalExposureScore": ["type": "NUMBER"],
                "forecastedSeverityScore": ["type": "NUMBER"],
                "alertText": ["type": "STRING"],
                "summaryText": ["type": "STRING"],
                "tasks": [
                    "type": "ARRAY",
                    "items": [
                        "type": "OBJECT",
                        "properties": [
                            "title": ["type": "STRING"],
                            "description": ["type": "STRING"],
                            "priority": ["type": "STRING"],
                            "category": ["type": "STRING"],
                            "estimatedCost": ["type": "NUMBER"],
                            "estimatedTime": ["type": "STRING"],
                            "deadline": ["type": "STRING"],
                            "perilType": ["type": "STRING"],
                            "insuranceSavings": ["type": "NUMBER"],
                            "insuranceImpact": ["type": "STRING"]
                        ],
                        "required": ["title", "description", "priority", "category", "deadline", "insuranceSavings", "insuranceImpact"]
                    ]
                ]
            ],
            "required": ["hvsScore", "riskScores", "historicalExposureScore", "forecastedSeverityScore", "alertText", "summaryText", "tasks"]
        ]

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.3,
                "topK": 20,
                "topP": 0.8,
                "maxOutputTokens": 2048,
                // CRITICAL: Force JSON-only response
                "responseMimeType": "application/json",
                "responseSchema": responseSchema
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let fullURL = url.absoluteString + "?key=" + APIConfiguration.geminiAPIKey
        request.url = URL(string: fullURL)

        print("🌐 Calling Gemini API for comprehensive analysis...")
        print("📤 Request body size: \(request.httpBody?.count ?? 0) bytes")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            throw AnalysisError.networkError
        }

        print("📡 Gemini API status code: \(httpResponse.statusCode)")
        print("📥 Response size: \(data.count) bytes")

        // Always print the full response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("\n\n")
            print("🚨 🚨 🚨 IMPORTANT - COPY THIS SECTION 🚨 🚨 🚨")
            print(String(repeating: "=", count: 80))
            print("📄 FULL GEMINI API RESPONSE:")
            print(String(repeating: "=", count: 80))
            print(responseString)
            print(String(repeating: "=", count: 80))
            print("🚨 🚨 🚨 END OF RESPONSE - COPY EVERYTHING ABOVE 🚨 🚨 🚨")
            print("\n\n")
        }

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Gemini API error (\(httpResponse.statusCode)):")
                print(errorString)
            }
            throw AnalysisError.apiError
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            // Check for error in response
            if let error = json?["error"] as? [String: Any] {
                print("❌ Gemini returned an error:")
                print("   Code: \(error["code"] ?? "unknown")")
                print("   Message: \(error["message"] ?? "unknown")")
                print("   Status: \(error["status"] ?? "unknown")")
                throw AnalysisError.apiError
            }

            guard let candidates = json?["candidates"] as? [[String: Any]] else {
                print("❌ No candidates in response")
                print("Response keys: \(json?.keys.joined(separator: ", ") ?? "none")")
                throw AnalysisError.invalidResponse
            }

            guard let firstCandidate = candidates.first else {
                print("❌ Candidates array is empty")
                throw AnalysisError.invalidResponse
            }

            print("✅ Found candidate")
            print("   Candidate keys: \(firstCandidate.keys.joined(separator: ", "))")

            guard let content = firstCandidate["content"] as? [String: Any] else {
                print("❌ No content in candidate")
                throw AnalysisError.invalidResponse
            }

            guard let parts = content["parts"] as? [[String: Any]] else {
                print("❌ No parts in content")
                throw AnalysisError.invalidResponse
            }

            guard let text = parts.first?["text"] as? String else {
                print("❌ No text in parts")
                print("   Parts: \(parts)")
                throw AnalysisError.invalidResponse
            }

            print("✅ Gemini API call successful")
            print("📝 Response text length: \(text.count) characters")
            return text
        } catch let error as AnalysisError {
            throw error
        } catch {
            print("❌ JSON parsing error: \(error)")
            throw AnalysisError.invalidResponse
        }
    }

    private func parseAnalysisResponse(_ response: String, propertyProfile: PropertyProfile) throws -> AnalysisResult {
        print("📥 Parsing Gemini analysis response...")
        print("📄 RAW RESPONSE (first 500 chars):")
        print(String(response.prefix(500)))

        // Since we enforced JSON-only response with responseSchema,
        // the response should be clean JSON without any markdown
        let cleanedResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleanedResponse.data(using: .utf8) else {
            print("❌ Failed to convert response to data")
            throw AnalysisError.invalidResponse
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let json = json else {
                print("❌ Failed to parse JSON - not a dictionary")
                print("Response was: \(cleanedResponse)")
                throw AnalysisError.invalidResponse
            }

            print("✅ JSON parsed successfully")
            print("📊 Keys in response: \(json.keys.joined(separator: ", "))")

            // Continue with parsing...
            return try parseFields(json: json, propertyProfile: propertyProfile)
        } catch {
            print("❌ JSON parsing error: \(error)")
            print("Response was: \(cleanedResponse)")
            throw AnalysisError.invalidResponse
        }
    }

    private func parseFields(json: [String: Any], propertyProfile: PropertyProfile) throws -> AnalysisResult {
        // Helper to convert Any to Double
        func toDouble(_ value: Any?) -> Double {
            if let d = value as? Double { return d }
            if let i = value as? Int { return Double(i) }
            return 0.0
        }

        // Parse scores with flexible type handling (Int or Double)
        guard let hvsScoreValue = json["hvsScore"] else {
            print("❌ Missing hvsScore")
            throw AnalysisError.invalidResponse
        }
        let hvsScore = toDouble(hvsScoreValue)

        guard let riskScoresDict = json["riskScores"] as? [String: Any] else {
            print("❌ Missing riskScores")
            throw AnalysisError.invalidResponse
        }

        guard let historicalExposureValue = json["historicalExposureScore"] else {
            print("❌ Missing historicalExposureScore")
            throw AnalysisError.invalidResponse
        }
        let historicalExposure = toDouble(historicalExposureValue)

        guard let forecastedSeverityValue = json["forecastedSeverityScore"] else {
            print("❌ Missing forecastedSeverityScore")
            throw AnalysisError.invalidResponse
        }
        let forecastedSeverity = toDouble(forecastedSeverityValue)

        guard let alertText = json["alertText"] as? String else {
            print("❌ Missing alertText")
            throw AnalysisError.invalidResponse
        }

        guard let summaryText = json["summaryText"] as? String else {
            print("❌ Missing summaryText")
            throw AnalysisError.invalidResponse
        }

        // Parse individual risk scores
        let hurricane = toDouble(riskScoresDict["hurricane"])
        let tornado = toDouble(riskScoresDict["tornado"])
        let flood = toDouble(riskScoresDict["flood"])
        let wildfire = toDouble(riskScoresDict["wildfire"])
        let earthquake = toDouble(riskScoresDict["earthquake"])
        let hail = toDouble(riskScoresDict["hail"])
        let winterStorm = toDouble(riskScoresDict["winterStorm"])
        let overall = (hurricane + tornado + flood + wildfire + earthquake + hail + winterStorm) / 7.0

        print("🎯 Risk Scores Parsed:")
        print("   Hurricane: \(Int(hurricane)), Tornado: \(Int(tornado)), Flood: \(Int(flood))")

        let riskScores = HazardAssessment.RiskScores(
            overall: overall,
            hurricane: hurricane,
            tornado: tornado,
            flood: flood,
            wildfire: wildfire,
            earthquake: earthquake,
            hail: hail,
            winterStorm: winterStorm
        )

        // Parse tasks
        var tasks: [MitigationTask] = []
        if let tasksArray = json["tasks"] as? [[String: Any]] {
            print("📋 Parsing \(tasksArray.count) tasks...")

            for (index, taskDict) in tasksArray.enumerated() {
                guard let title = taskDict["title"] as? String,
                      let description = taskDict["description"] as? String,
                      let priorityStr = taskDict["priority"] as? String,
                      let categoryStr = taskDict["category"] as? String else {
                    print("⚠️  Skipping task \(index + 1) - missing required fields")
                    print("   Available keys: \(taskDict.keys)")
                    continue
                }

                let priority = MitigationTask.Priority(rawValue: priorityStr) ?? .medium
                let category = MitigationTask.Category(rawValue: categoryStr) ?? .maintenance

                // Handle cost as Int or Double
                let cost: Double?
                if let costDouble = taskDict["estimatedCost"] as? Double {
                    cost = costDouble
                } else if let costInt = taskDict["estimatedCost"] as? Int {
                    cost = Double(costInt)
                } else {
                    cost = nil
                }

                let timeEstimate = taskDict["estimatedTime"] as? String
                let deadline = taskDict["deadline"] as? String ?? "within 1 month"
                let perilType = taskDict["perilType"] as? String

                // Parse insurance impact fields
                let insuranceSavings: Double? = {
                    if let savingsDouble = taskDict["insuranceSavings"] as? Double {
                        return savingsDouble
                    } else if let savingsInt = taskDict["insuranceSavings"] as? Int {
                        return Double(savingsInt)
                    }
                    return nil
                }()
                let insuranceImpact = taskDict["insuranceImpact"] as? String
                let insurancePercentage = insuranceSavings != nil ? (insuranceSavings! / 1800.0) * 100 : nil

                var task = MitigationTask(
                    title: title,
                    description: description,
                    priority: priority,
                    category: category,
                    status: .notStarted,
                    dueDate: calculateDueDate(from: deadline),
                    completedDate: nil,
                    estimatedCost: cost,
                    estimatedTime: timeEstimate,
                    relatedPerilType: perilType,
                    isAIGenerated: true,
                    userId: propertyProfile.userId,
                    notes: "",
                    createdAt: Date(),
                    updatedAt: Date(),
                    estimatedInsuranceSavings: insuranceSavings,
                    insuranceImpactCategory: insuranceImpact,
                    insuranceImpactPercentage: insurancePercentage,
                    insuranceImpactDescription: insuranceImpact != nil ? "Estimated insurance premium reduction" : nil
                )

                tasks.append(task)
                print("   ✓ Task \(index + 1): \(title)")
            }
        } else {
            print("⚠️  No tasks array found in response")
        }

        print("✅ Parsed: HVS=\(Int(hvsScore)), Tasks=\(tasks.count)")

        return AnalysisResult(
            hvsScore: hvsScore,
            riskScores: riskScores,
            historicalExposureScore: historicalExposure,
            forecastedSeverityScore: forecastedSeverity,
            alertText: alertText,
            summaryText: summaryText,
            tasks: tasks
        )
    }

    private func calculateDueDate(from deadline: String) -> Date {
        let calendar = Calendar.current
        let now = Date()

        let lowercased = deadline.lowercased()

        if lowercased.contains("1 week") || lowercased.contains("one week") {
            return calendar.date(byAdding: .day, value: 7, to: now) ?? now
        } else if lowercased.contains("2 week") || lowercased.contains("two week") {
            return calendar.date(byAdding: .day, value: 14, to: now) ?? now
        } else if lowercased.contains("1 month") || lowercased.contains("one month") {
            return calendar.date(byAdding: .month, value: 1, to: now) ?? now
        } else if lowercased.contains("2 month") || lowercased.contains("two month") {
            return calendar.date(byAdding: .month, value: 2, to: now) ?? now
        } else if lowercased.contains("3 month") || lowercased.contains("three month") {
            return calendar.date(byAdding: .month, value: 3, to: now) ?? now
        } else if lowercased.contains("6 month") || lowercased.contains("six month") {
            return calendar.date(byAdding: .month, value: 6, to: now) ?? now
        } else {
            // Default to 1 month
            return calendar.date(byAdding: .month, value: 1, to: now) ?? now
        }
    }
}

enum AnalysisError: Error, LocalizedError {
    case networkError
    case apiError
    case invalidResponse
    case missingData

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection failed"
        case .apiError:
            return "Gemini API returned an error"
        case .invalidResponse:
            return "Could not parse Gemini response"
        case .missingData:
            return "Missing required data for analysis"
        }
    }
}
