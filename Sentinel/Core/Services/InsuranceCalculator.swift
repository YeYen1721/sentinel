//
//  InsuranceCalculator.swift
//  Sentinel
//
//  Service for calculating insurance premiums and savings
//

import Foundation

/// Service for calculating insurance costs and savings
class InsuranceCalculator {

    // MARK: - Base Premium Calculation

    /// Calculate base annual insurance premium
    /// Based on industry averages: $1,200-$4,000/year for homeowners insurance
    static func calculateBasePremium(
        propertyProfile: PropertyProfile,
        riskScores: (hurricane: Double, flood: Double, wildfire: Double, earthquake: Double)
    ) -> Double {
        // Start with national average
        var basePremium = 1800.0 // $1,800/year national average

        // 1. Square footage multiplier (larger homes = more coverage needed)
        let sqftMultiplier = propertyProfile.squareFootage / 2000.0 // Normalize to 2000 sqft
        basePremium *= max(0.8, min(1.5, sqftMultiplier))

        // 2. Location risk multiplier (biggest factor in premiums)
        let locationRisk = calculateLocationRiskMultiplier(riskScores: riskScores)
        basePremium *= locationRisk

        // 3. Property age multiplier (older homes = higher risk)
        let buildingAge = Calendar.current.component(.year, from: Date()) - propertyProfile.yearBuilt
        let ageMultiplier = 1.0 + (Double(buildingAge) * 0.005) // +0.5% per year
        basePremium *= min(1.5, ageMultiplier) // Cap at 50% increase

        // 4. Roof age penalty (most important structural factor)
        if propertyProfile.roofAge > 20 {
            basePremium *= 1.3 // 30% increase for old roof
        } else if propertyProfile.roofAge > 15 {
            basePremium *= 1.15 // 15% increase
        } else if propertyProfile.roofAge > 10 {
            basePremium *= 1.05 // 5% increase
        }

        // 5. Roof material discount/penalty
        switch propertyProfile.roofMaterial {
        case .metalRoof:
            basePremium *= 0.80 // 20% discount (most durable)
        case .slate, .concrete:
            basePremium *= 0.85 // 15% discount
        case .clay:
            basePremium *= 0.90 // 10% discount
        case .asphaltShingles:
            basePremium *= 1.0 // No change (standard)
        case .woodShakes:
            basePremium *= 1.25 // 25% penalty (fire risk)
        }

        // 6. Stories multiplier (more stories = higher risk)
        basePremium *= (1.0 + Double(propertyProfile.stories - 1) * 0.1)

        return round(basePremium)
    }

    /// Calculate location risk multiplier (1.0-3.0)
    static func calculateLocationRiskMultiplier(
        riskScores: (hurricane: Double, flood: Double, wildfire: Double, earthquake: Double)
    ) -> Double {
        // Weighted average of risk scores
        let weightedRisk = (
            riskScores.hurricane * 0.35 +  // Hurricane is biggest insurance factor
            riskScores.flood * 0.30 +      // Flood is second
            riskScores.wildfire * 0.20 +   // Fire is third
            riskScores.earthquake * 0.15   // Earthquake is fourth
        ) / 100.0

        // Convert to multiplier (1.0-3.0)
        return 1.0 + (weightedRisk * 2.0)
    }

    // MARK: - Savings Calculation

    /// Calculate insurance savings from a specific task
    static func calculateTaskSavings(
        task: MitigationTask,
        basePremium: Double
    ) -> (annualSavings: Double, category: InsuranceCategory, percentage: Double, description: String) {
        var savingsPercentage = 0.0
        var description = ""

        // Calculate savings based on task category and priority
        switch task.category {
        case .structural:
            if task.title.lowercased().contains("roof") {
                // Roof improvements (highest impact)
                if task.priority == .critical || task.priority == .high {
                    savingsPercentage = 0.15 // 15% savings
                    description = "Major roof improvements significantly reduce weather damage risk"
                } else {
                    savingsPercentage = 0.08 // 8% savings
                    description = "Roof maintenance reduces storm damage claims"
                }
            } else if task.title.lowercased().contains("foundation") {
                savingsPercentage = 0.10 // 10% savings
                description = "Foundation reinforcement prevents major structural damage"
            } else if task.title.lowercased().contains("shutter") {
                savingsPercentage = 0.12 // 12% savings
                description = "Storm shutters protect windows and prevent interior water damage"
            } else if task.title.lowercased().contains("siding") || task.title.lowercased().contains("exterior") {
                savingsPercentage = 0.06 // 6% savings
                description = "Exterior improvements reduce wind and water penetration"
            } else {
                savingsPercentage = 0.05 // 5% generic structural
                description = "Structural improvements reduce damage risk"
            }

        case .utilities:
            if task.title.lowercased().contains("generator") {
                savingsPercentage = 0.08 // 8% savings
                description = "Backup power prevents food spoilage and sump pump failures"
            } else if task.title.lowercased().contains("plumbing") {
                savingsPercentage = 0.04 // 4% savings
                description = "Plumbing upgrades prevent costly water damage"
            } else if task.title.lowercased().contains("electrical") {
                savingsPercentage = 0.05 // 5% savings
                description = "Electrical upgrades reduce fire risk"
            } else {
                savingsPercentage = 0.03 // 3% generic utility
                description = "Utility improvements reduce system failure risk"
            }

        case .emergency:
            if task.title.lowercased().contains("alarm") || task.title.lowercased().contains("monitoring") {
                savingsPercentage = 0.10 // 10% savings
                description = "Security systems qualify for monitored alarm discount"
            } else if task.title.lowercased().contains("kit") || task.title.lowercased().contains("supplies") {
                savingsPercentage = 0.02 // 2% savings
                description = "Emergency preparedness reduces claim severity"
            } else {
                savingsPercentage = 0.03 // 3% generic emergency
                description = "Emergency preparedness reduces losses during disasters"
            }

        case .monitoring:
            if task.title.lowercased().contains("smart home") || task.title.lowercased().contains("sensors") {
                savingsPercentage = 0.07 // 7% savings
                description = "Smart monitoring detects water leaks and fires early"
            } else {
                savingsPercentage = 0.04 // 4% generic monitoring
                description = "Monitoring systems provide early warning of problems"
            }

        case .landscaping:
            if task.title.lowercased().contains("tree") {
                savingsPercentage = 0.04 // 4% savings
                description = "Tree removal/trimming prevents roof and structure damage"
            } else if task.title.lowercased().contains("drainage") || task.title.lowercased().contains("gutter") {
                savingsPercentage = 0.05 // 5% savings
                description = "Proper drainage prevents foundation and basement flooding"
            } else {
                savingsPercentage = 0.02 // 2% generic landscaping
                description = "Landscaping improvements reduce property damage risk"
            }

        case .maintenance:
            if task.priority == .critical || task.priority == .high {
                savingsPercentage = 0.06 // 6% savings
                description = "Critical maintenance prevents expensive claims"
            } else {
                savingsPercentage = 0.03 // 3% savings
                description = "Regular maintenance reduces unexpected failures"
            }

        case .insurance:
            savingsPercentage = 0.02 // 2% savings
            description = "Insurance review can identify additional discounts"

        case .documentation:
            savingsPercentage = 0.01 // 1% savings
            description = "Documentation speeds up claims and may reduce premiums"
        }

        // Priority multiplier (critical tasks have higher impact)
        if task.priority == .critical {
            savingsPercentage *= 1.2 // 20% boost
        }

        // Calculate actual dollar savings
        let annualSavings = round(basePremium * savingsPercentage)

        // Determine category
        let category = categorizeImpact(annualSavings: annualSavings)

        return (annualSavings, category, savingsPercentage * 100, description)
    }

    /// Categorize insurance impact based on annual savings
    static func categorizeImpact(annualSavings: Double) -> InsuranceCategory {
        switch annualSavings {
        case 500...: return .critical    // $500+/year
        case 200..<500: return .high     // $200-500/year
        case 50..<200: return .medium    // $50-200/year
        default: return .low             // $10-50/year
        }
    }

    // MARK: - Complete Insurance Score Calculation

    /// Calculate complete insurance score for a property
    static func calculateInsuranceScore(
        propertyProfile: PropertyProfile,
        tasks: [MitigationTask],
        riskScores: (hurricane: Double, flood: Double, wildfire: Double, earthquake: Double)
    ) -> InsuranceScore {
        // Calculate base premium (what you'd pay with no improvements)
        let basePremium = calculateBasePremium(
            propertyProfile: propertyProfile,
            riskScores: riskScores
        )

        // Calculate savings from completed tasks
        let completedTasks = tasks.filter { $0.status == .completed }
        var savingsItems: [InsuranceSavingItem] = []
        var totalCompletedSavings = 0.0

        for task in completedTasks {
            // Use existing insurance data from Gemini if available, otherwise calculate
            let (savings, category, description): (Double, InsuranceCategory, String)

            if let existingSavings = task.estimatedInsuranceSavings, existingSavings > 0 {
                // Use data from Gemini
                let categoryString = task.insuranceImpactCategory ?? "Medium"
                let impactCategory = InsuranceCategory(rawValue: categoryString) ?? .medium
                let impactDescription = task.insuranceImpactDescription ?? "Insurance premium reduction"

                savings = existingSavings
                category = impactCategory
                description = impactDescription
            } else {
                // Calculate if no existing data
                let calculatedData = calculateTaskSavings(task: task, basePremium: basePremium)
                savings = calculatedData.0
                category = calculatedData.1
                description = calculatedData.3
            }

            if savings > 0 {
                let item = InsuranceSavingItem(
                    taskTitle: task.title,
                    category: category,
                    annualSavings: savings,
                    completedDate: task.completedDate,
                    description: description
                )
                savingsItems.append(item)
                totalCompletedSavings += savings
            }
        }

        // Calculate potential savings from incomplete tasks
        let incompleteTasks = tasks.filter { $0.status != .completed && $0.status != .cancelled }
        var potentialSavings: [InsuranceSavingItem] = []
        var totalPotentialSavings = 0.0

        for task in incompleteTasks {
            // Use existing insurance data from Gemini if available, otherwise calculate
            let (savings, category, description): (Double, InsuranceCategory, String)

            if let existingSavings = task.estimatedInsuranceSavings, existingSavings > 0 {
                // Use data from Gemini
                let categoryString = task.insuranceImpactCategory ?? "Medium"
                let impactCategory = InsuranceCategory(rawValue: categoryString) ?? .medium
                let impactDescription = task.insuranceImpactDescription ?? "Insurance premium reduction"

                savings = existingSavings
                category = impactCategory
                description = impactDescription
            } else {
                // Calculate if no existing data
                let calculatedData = calculateTaskSavings(task: task, basePremium: basePremium)
                savings = calculatedData.0
                category = calculatedData.1
                description = calculatedData.3
            }

            if savings > 0 {
                let item = InsuranceSavingItem(
                    taskTitle: task.title,
                    category: category,
                    annualSavings: savings,
                    completedDate: nil,
                    description: description
                )
                potentialSavings.append(item)
                totalPotentialSavings += savings
            }
        }

        // Calculate current premium (after discounts)
        let currentPremium = max(basePremium * 0.5, basePremium - totalCompletedSavings) // Min 50% of base

        // Calculate readiness score (0-100)
        let maxPossibleSavings = totalCompletedSavings + totalPotentialSavings
        let readinessScore = maxPossibleSavings > 0
            ? (totalCompletedSavings / maxPossibleSavings) * 100
            : 0

        let readinessLevel = InsuranceScore.getReadinessLevel(score: readinessScore)

        // Calculate location risk multiplier
        let locationRisk = calculateLocationRiskMultiplier(riskScores: riskScores)

        // Property age multiplier
        let buildingAge = Calendar.current.component(.year, from: Date()) - propertyProfile.yearBuilt
        let ageMultiplier = 1.0 + (Double(buildingAge) * 0.005)

        // Risk zone description
        let riskDescription = generateRiskZoneDescription(
            riskScores: riskScores,
            locationMultiplier: locationRisk
        )

        return InsuranceScore(
            basePremium: basePremium,
            currentPremium: currentPremium,
            totalAnnualSavings: totalCompletedSavings,
            totalMonthlySavings: totalCompletedSavings / 12.0,
            lifetimeSavings: totalCompletedSavings * 30, // 30-year projection
            readinessScore: readinessScore,
            readinessLevel: readinessLevel,
            savingsItems: savingsItems,
            potentialSavings: potentialSavings,
            locationRiskMultiplier: locationRisk,
            propertyAgeMultiplier: min(1.5, ageMultiplier),
            riskZoneDescription: riskDescription,
            lastCalculated: Date(),
            zipCode: nil
        )
    }

    /// Generate risk zone description
    static func generateRiskZoneDescription(
        riskScores: (hurricane: Double, flood: Double, wildfire: Double, earthquake: Double),
        locationMultiplier: Double
    ) -> String {
        var risks: [String] = []

        if riskScores.hurricane >= 70 {
            risks.append("High Hurricane Zone")
        }
        if riskScores.flood >= 70 {
            risks.append("High Flood Zone")
        }
        if riskScores.wildfire >= 70 {
            risks.append("High Wildfire Risk")
        }
        if riskScores.earthquake >= 70 {
            risks.append("Seismic Zone")
        }

        if risks.isEmpty {
            if locationMultiplier < 1.3 {
                return "Low Risk Area - Base Rate Zone"
            } else {
                return "Moderate Risk Area"
            }
        } else {
            return risks.joined(separator: ", ")
        }
    }

    // MARK: - Task Insurance Impact Assignment

    /// Assign insurance impact to tasks that don't have it yet
    static func assignInsuranceImpact(
        tasks: [MitigationTask],
        basePremium: Double
    ) -> [MitigationTask] {
        var updatedTasks = tasks

        for i in 0..<updatedTasks.count {
            if updatedTasks[i].estimatedInsuranceSavings == nil {
                let (savings, category, percentage, description) = calculateTaskSavings(
                    task: updatedTasks[i],
                    basePremium: basePremium
                )

                updatedTasks[i].estimatedInsuranceSavings = savings
                updatedTasks[i].insuranceImpactCategory = category.rawValue
                updatedTasks[i].insuranceImpactPercentage = percentage
                updatedTasks[i].insuranceImpactDescription = description
            }
        }

        return updatedTasks
    }
}
