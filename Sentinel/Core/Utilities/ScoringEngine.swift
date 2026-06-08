//
//  ScoringEngine.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import Foundation
import SwiftUI

/// Pure Swift logic for calculating Home Vulnerability Score (HVS)
struct ScoringEngine {

    // MARK: - Weights for HVS Calculation
    private static let propertyResilienceWeight = 0.35
    private static let historicalExposureWeight = 0.35
    private static let forecastedSeverityWeight = 0.30

    /// Calculate the comprehensive Home Vulnerability Score (0-100)
    /// Lower score = Higher vulnerability
    static func calculateHVS(
        propertyProfile: PropertyProfile,
        hazardAssessment: HazardAssessment
    ) -> Double {

        let resilienceScore = propertyProfile.resilienceScore
        let exposureScore = hazardAssessment.historicalExposureScore
        let forecastScore = hazardAssessment.forecastedSeverityScore

        // Calculate weighted average
        // Note: Higher resilience = Lower vulnerability
        // Higher exposure/forecast = Higher vulnerability
        let vulnerability = (
            (100 - resilienceScore) * propertyResilienceWeight +
            exposureScore * historicalExposureWeight +
            forecastScore * forecastedSeverityWeight
        )

        // Invert to get HVS (higher = better/safer)
        let hvs = 100 - vulnerability

        return max(0, min(100, hvs))
    }

    /// Get risk level category based on HVS
    static func getRiskLevel(hvs: Double) -> RiskLevel {
        switch hvs {
        case 80...100:
            return .low
        case 60..<80:
            return .moderate
        case 40..<60:
            return .elevated
        case 20..<40:
            return .high
        default:
            return .critical
        }
    }

    /// Get color representation for HVS score
    static func getScoreColor(hvs: Double) -> String {
        let riskLevel = getRiskLevel(hvs: hvs)
        return riskLevel.color
    }

    /// Generate a summary message based on HVS
    static func generateSummary(hvs: Double, riskLevel: RiskLevel) -> String {
        switch riskLevel {
        case .low:
            return "Your home is well-protected with a strong vulnerability score of \(Int(hvs)). Continue regular maintenance."
        case .moderate:
            return "Your home has good protection (score: \(Int(hvs))), but there are opportunities to improve resilience."
        case .elevated:
            return "Your home shows moderate vulnerability (score: \(Int(hvs))). We recommend addressing the suggested improvements."
        case .high:
            return "Your home has significant vulnerabilities (score: \(Int(hvs))). Immediate action is recommended."
        case .critical:
            return "URGENT: Your home is at critical risk (score: \(Int(hvs))). Please address high-priority items immediately."
        }
    }

    /// Calculate priority score for a mitigation task based on multiple factors
    static func calculateTaskPriority(
        task: MitigationTask,
        propertyProfile: PropertyProfile,
        hazardAssessment: HazardAssessment
    ) -> Double {
        var priorityScore = 0.0

        // Base priority weight
        switch task.priority {
        case .critical: priorityScore += 100
        case .high: priorityScore += 75
        case .medium: priorityScore += 50
        case .low: priorityScore += 25
        }

        // Adjust based on due date proximity
        if let dueDate = task.dueDate {
            let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
            if daysUntilDue < 0 {
                priorityScore += 50 // Overdue
            } else if daysUntilDue < 7 {
                priorityScore += 30 // Due within a week
            } else if daysUntilDue < 30 {
                priorityScore += 15 // Due within a month
            }
        }

        // Adjust based on related peril risk
        if let perilType = task.relatedPerilType {
            let riskScore = getRiskScoreForPeril(perilType, in: hazardAssessment)
            priorityScore += riskScore * 0.2
        }

        return priorityScore
    }

    private static func getRiskScoreForPeril(_ perilType: String, in assessment: HazardAssessment) -> Double {
        switch perilType.lowercased() {
        case "hurricane": return assessment.riskScores.hurricane
        case "tornado": return assessment.riskScores.tornado
        case "flood": return assessment.riskScores.flood
        case "wildfire": return assessment.riskScores.wildfire
        case "earthquake": return assessment.riskScores.earthquake
        case "hailstorm", "hail": return assessment.riskScores.hail
        case "winter storm": return assessment.riskScores.winterStorm
        default: return assessment.riskScores.overall
        }
    }
}

// MARK: - Supporting Types

enum RiskLevel: String, CaseIterable {
    case low = "Low Risk"
    case moderate = "Moderate Risk"
    case elevated = "Elevated Risk"
    case high = "High Risk"
    case critical = "Critical Risk"

    var swiftUIColor: Color {
        switch self {
        case .low: return .riskLow        // Green #37B871
        case .moderate: return .riskModerate  // Orange #F4A348
        case .elevated: return .riskModerate  // Orange #F4A348
        case .high: return .riskCritical  // Red #F26565
        case .critical: return .riskCritical  // Red #F26565
        }
    }

    var color: String {
        switch self {
        case .low: return "green"
        case .moderate: return "yellow"
        case .elevated: return "orange"
        case .high: return "red"
        case .critical: return "darkred"
        }
    }

    var icon: String {
        switch self {
        case .low: return "checkmark.shield.fill"
        case .moderate: return "shield.fill"
        case .elevated: return "exclamationmark.shield.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.shield.fill"
        }
    }
}
