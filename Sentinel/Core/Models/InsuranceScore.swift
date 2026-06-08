//
//  InsuranceScore.swift
//  Sentinel
//
//  Insurance score and savings calculation models
//

import Foundation

/// Insurance category based on savings impact
enum InsuranceCategory: String, Codable {
    case critical = "Critical"      // $500+/year savings
    case high = "High"              // $200-500/year
    case medium = "Medium"          // $50-200/year
    case low = "Low"                // $10-50/year

    var color: String {
        switch self {
        case .critical: return "#DC2626"  // Red
        case .high: return "#F59E0B"      // Amber
        case .medium: return "#10B981"    // Green
        case .low: return "#6B7280"       // Gray
        }
    }

    var displayName: String {
        return self.rawValue + " Impact"
    }
}

/// Individual savings item from a completed task
struct InsuranceSavingItem: Codable, Identifiable {
    var id: String
    let taskTitle: String
    let category: InsuranceCategory
    let annualSavings: Double
    let monthlySavings: Double
    let savingsPercentage: Double
    let completedDate: Date?
    let description: String

    init(taskTitle: String, category: InsuranceCategory, annualSavings: Double, completedDate: Date? = nil, description: String) {
        self.id = UUID().uuidString
        self.taskTitle = taskTitle
        self.category = category
        self.annualSavings = annualSavings
        self.monthlySavings = annualSavings / 12.0
        self.savingsPercentage = 0.0  // Calculated by InsuranceCalculator
        self.completedDate = completedDate
        self.description = description
    }
}

/// Complete insurance score and savings analysis
struct InsuranceScore: Codable {
    // Base premium information
    let basePremium: Double              // Annual premium without improvements
    let currentPremium: Double           // Current annual premium with improvements

    // Savings
    let totalAnnualSavings: Double
    let totalMonthlySavings: Double
    let lifetimeSavings: Double          // 30-year projection

    // Readiness score (0-100)
    let readinessScore: Double
    let readinessLevel: ReadinessLevel

    // Breakdown of savings
    let savingsItems: [InsuranceSavingItem]
    let potentialSavings: [InsuranceSavingItem]  // From incomplete tasks

    // Risk factors affecting premium
    let locationRiskMultiplier: Double   // 1.0-3.0 based on location
    let propertyAgeMultiplier: Double    // 1.0-1.5 based on age
    let riskZoneDescription: String

    // Calculation metadata
    let lastCalculated: Date
    let zipCode: String?

    enum ReadinessLevel: String, Codable {
        case excellent = "Excellent"     // 80-100
        case good = "Good"               // 60-79
        case fair = "Fair"               // 40-59
        case needsWork = "Needs Work"    // 0-39

        var color: String {
            switch self {
            case .excellent: return "#10B981"  // Green
            case .good: return "#3B82F6"       // Blue
            case .fair: return "#F59E0B"       // Amber
            case .needsWork: return "#DC2626"  // Red
            }
        }

        var icon: String {
            switch self {
            case .excellent: return "checkmark.seal.fill"
            case .good: return "checkmark.circle.fill"
            case .fair: return "exclamationmark.circle.fill"
            case .needsWork: return "xmark.circle.fill"
            }
        }
    }

    var savingsPercentage: Double {
        guard basePremium > 0 else { return 0 }
        return (totalAnnualSavings / basePremium) * 100
    }

    /// Get readiness level from score
    static func getReadinessLevel(score: Double) -> ReadinessLevel {
        switch score {
        case 80...100: return .excellent
        case 60..<80: return .good
        case 40..<60: return .fair
        default: return .needsWork
        }
    }
}

/// Insurance task impact data (extends MitigationTask)
struct TaskInsuranceImpact: Codable {
    let estimatedAnnualSavings: Double
    let estimatedMonthlySavings: Double
    let category: InsuranceCategory
    let impactPercentage: Double
    let justification: String

    init(annualSavings: Double, category: InsuranceCategory, impactPercentage: Double, justification: String) {
        self.estimatedAnnualSavings = annualSavings
        self.estimatedMonthlySavings = annualSavings / 12.0
        self.category = category
        self.impactPercentage = impactPercentage
        self.justification = justification
    }
}
