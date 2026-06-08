//
//  HazardAssessment.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import Foundation

struct HazardAssessment: Codable, Identifiable {
    var id = UUID()
    var location: Location
    var historicalPerils: [PerilEvent]
    var currentForecasts: [WeatherForecast]
    var riskScores: RiskScores
    var timestamp: Date

    struct Location: Codable {
        var latitude: Double
        var longitude: Double
        var address: String
        var city: String
        var state: String
        var zipCode: String
    }

    struct PerilEvent: Codable, Identifiable {
        var id = UUID()
        var type: PerilType
        var date: Date
        var severity: Severity
        var description: String
        var damageEstimate: Double?
        var affectedRadius: Double // miles

        enum PerilType: String, Codable {
            case hurricane = "Hurricane"
            case tornado = "Tornado"
            case flood = "Flood"
            case wildfire = "Wildfire"
            case earthquake = "Earthquake"
            case hailstorm = "Hailstorm"
            case winterStorm = "Winter Storm"
            case severeThunderstorm = "Severe Thunderstorm"
        }

        enum Severity: String, Codable {
            case minor = "Minor"
            case moderate = "Moderate"
            case severe = "Severe"
            case catastrophic = "Catastrophic"

            var score: Double {
                switch self {
                case .minor: return 25
                case .moderate: return 50
                case .severe: return 75
                case .catastrophic: return 100
                }
            }
        }
    }

    struct WeatherForecast: Codable, Identifiable {
        var id = UUID()
        var type: PerilEvent.PerilType
        var probability: Double // 0-100
        var expectedDate: Date
        var duration: TimeInterval // seconds
        var intensity: String
        var alertLevel: AlertLevel

        enum AlertLevel: String, Codable {
            case watch = "Watch"
            case advisory = "Advisory"
            case warning = "Warning"
            case emergency = "Emergency"

            var color: String {
                switch self {
                case .watch: return "yellow"
                case .advisory: return "orange"
                case .warning: return "red"
                case .emergency: return "darkred"
                }
            }
        }
    }

    struct RiskScores: Codable {
        var overall: Double // 0-100
        var hurricane: Double
        var tornado: Double
        var flood: Double
        var wildfire: Double
        var earthquake: Double
        var hail: Double
        var winterStorm: Double

        func getTopRisk() -> (name: String, score: Double) {
            let risks = [
                ("Hurricane", hurricane),
                ("Tornado", tornado),
                ("Flood", flood),
                ("Wildfire", wildfire),
                ("Earthquake", earthquake),
                ("Hail", hail),
                ("Winter Storm", winterStorm)
            ]
            return risks.max(by: { $0.1 < $1.1 }) ?? ("Hurricane", 0)
        }
    }

    // Calculate historical exposure score
    var historicalExposureScore: Double {
        guard !historicalPerils.isEmpty else { return 0 }

        let recentPerils = historicalPerils.filter {
            let yearsAgo = Calendar.current.dateComponents([.year], from: $0.date, to: Date()).year ?? 0
            return yearsAgo <= 15 // Last 15 years
        }

        let totalSeverity = recentPerils.reduce(0.0) { $0 + $1.severity.score }
        let avgSeverity = totalSeverity / Double(max(1, recentPerils.count))

        // Weight by frequency
        let frequencyMultiplier = min(2.0, 1.0 + Double(recentPerils.count) * 0.1)

        return min(100, avgSeverity * frequencyMultiplier)
    }

    // Calculate forecasted severity score
    var forecastedSeverityScore: Double {
        guard !currentForecasts.isEmpty else { return 0 }

        let highPriorityForecasts = currentForecasts.filter { $0.probability > 30 }

        let weightedScore = highPriorityForecasts.reduce(0.0) { sum, forecast in
            let alertWeight: Double = switch forecast.alertLevel {
            case .watch: 1.0
            case .advisory: 1.5
            case .warning: 2.0
            case .emergency: 3.0
            }
            return sum + (forecast.probability * alertWeight)
        }

        return min(100, weightedScore / Double(max(1, highPriorityForecasts.count)))
    }
}
