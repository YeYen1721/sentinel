//
//  DashboardViewModel.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import Foundation
import Observation

@Observable
class DashboardViewModel {
    var propertyProfile: PropertyProfile?
    var hazardAssessment: HazardAssessment?
    var hvsScore: Double = 0
    var riskLevel: RiskLevel = .moderate
    var summaryText: String = ""
    var alertText: String = ""
    var historicalExposureScore: Double = 0
    var forecastedSeverityScore: Double = 0
    var insuranceScore: InsuranceScore?
    var isLoading: Bool = false
    var errorMessage: String?

    // Cache management to prevent duplicate loads
    private var lastLoadedLocation: (latitude: Double, longitude: Double)?
    private var lastLoadTime: Date?
    private var currentLoadTask: Task<Void, Never>?

    private let riskDataService: RiskDataServiceProtocol
    private let geminiAnalysisService: GeminiAnalysisService
    private let taskRepository: TaskRepository

    init(
        riskDataService: RiskDataServiceProtocol? = nil,
        geminiAnalysisService: GeminiAnalysisService = GeminiAnalysisService(),
        taskRepository: TaskRepository = TaskRepository()
    ) {
        // Use RealRiskDataService if any API is configured, otherwise use mock
        if let service = riskDataService {
            self.riskDataService = service
        } else if APIConfiguration.hasRealAPIs {
            self.riskDataService = RealRiskDataService()
            print("✅ Using real weather APIs")
        } else {
            self.riskDataService = MockRiskDataService()
            print("ℹ️  Using mock data - configure API keys in APIConfiguration.swift")
        }

        self.geminiAnalysisService = geminiAnalysisService
        self.taskRepository = taskRepository
    }

    @MainActor
    func loadDashboardData(userId: String, propertyProfile: PropertyProfile) async {
        // Check if already loading (prevent concurrent loads)
        if isLoading {
            print("⏭️  Skipping duplicate load - already loading")
            return
        }

        // Check if we already have data for this location (cache for 5 minutes)
        if let lastLocation = lastLoadedLocation,
           let lastTime = lastLoadTime,
           lastLocation.latitude == propertyProfile.latitude,
           lastLocation.longitude == propertyProfile.longitude,
           Date().timeIntervalSince(lastTime) < 300 { // 5 minutes
            print("📦 Using cached dashboard data (loaded \(Int(Date().timeIntervalSince(lastTime)))s ago)")
            return
        }

        // Cancel any previous load task
        currentLoadTask?.cancel()

        // Start new load task
        currentLoadTask = Task {
            isLoading = true
            errorMessage = nil

            // Reset all scores to ensure clean state when changing locations
            hvsScore = 0
            historicalExposureScore = 0
            forecastedSeverityScore = 0
            alertText = ""
            summaryText = ""
            riskLevel = .moderate

            do {
                self.propertyProfile = propertyProfile

                print("\n🔄 LOADING DASHBOARD DATA")
                print("📍 Location: \(propertyProfile.latitude), \(propertyProfile.longitude)")
                print("🏠 Address: \(propertyProfile.address)")

            // Fetch real hazard assessment from APIs
            hazardAssessment = try await riskDataService.fetchHazardAssessment(
                latitude: propertyProfile.latitude,
                longitude: propertyProfile.longitude
            )

            guard let assessment = hazardAssessment else {
                throw NSError(domain: "Dashboard", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch hazard data"])
            }

            // Try Gemini first, but fall back to local calculation if it fails
            do {
                print("\n🤖 Trying Gemini for personalized analysis...")
                let analysis = try await geminiAnalysisService.analyzePropertyRisk(
                    propertyProfile: propertyProfile,
                    hazardAssessment: assessment
                )

                // Update UI with Gemini's analysis
                hvsScore = analysis.hvsScore
                historicalExposureScore = analysis.historicalExposureScore
                forecastedSeverityScore = analysis.forecastedSeverityScore
                alertText = analysis.alertText
                summaryText = analysis.summaryText
                riskLevel = ScoringEngine.getRiskLevel(hvs: hvsScore)

                // Update hazard assessment with Gemini's risk scores
                hazardAssessment = HazardAssessment(
                    location: assessment.location,
                    historicalPerils: assessment.historicalPerils,
                    currentForecasts: assessment.currentForecasts,
                    riskScores: analysis.riskScores,
                    timestamp: assessment.timestamp
                )

                print("✅ Dashboard loaded with Gemini AI analysis")
                print("   HVS: \(Int(hvsScore))")
                print("   Historical Exposure: \(Int(historicalExposureScore))")
                print("   Forecasted Severity: \(Int(forecastedSeverityScore))")

            } catch {
                // Gemini failed - use local calculation as fallback
                print("⚠️  Gemini failed, using local calculation: \(error.localizedDescription)")
                print("🔧 Calculating scores locally...")

                // Calculate HVS locally
                hvsScore = ScoringEngine.calculateHVS(
                    propertyProfile: propertyProfile,
                    hazardAssessment: assessment
                )
                riskLevel = ScoringEngine.getRiskLevel(hvs: hvsScore)
                summaryText = ScoringEngine.generateSummary(hvs: hvsScore, riskLevel: riskLevel)

                // Calculate exposure scores
                historicalExposureScore = assessment.historicalExposureScore
                forecastedSeverityScore = assessment.forecastedSeverityScore

                // Generate alert text based on highest risk
                let topRisk = assessment.riskScores.getTopRisk()
                alertText = "Your property has elevated \(topRisk.name.lowercased()) risk"

                print("✅ Dashboard loaded with local calculation")
                print("   HVS: \(Int(hvsScore))")
                print("   Historical Exposure: \(Int(historicalExposureScore))")
                print("   Forecasted Severity: \(Int(forecastedSeverityScore))")
            }

                // Update cache timestamps
                lastLoadedLocation = (propertyProfile.latitude, propertyProfile.longitude)
                lastLoadTime = Date()

                isLoading = false

                // Calculate insurance score after dashboard loads
                await calculateInsuranceScore(userId: userId)
            } catch {
                print("❌ Dashboard load failed: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }

        // Await the task completion
        await currentLoadTask?.value
    }

    @MainActor
    func generateActionPlan(userId: String) async -> Bool {
        guard let profile = propertyProfile,
              let assessment = hazardAssessment else {
            errorMessage = "Missing property or hazard data"
            isLoading = false
            return false
        }

        isLoading = true
        errorMessage = nil

        do {
            print("\n🔄 GENERATING ACTION PLAN WITH GEMINI")

            // Use Gemini to analyze and generate personalized tasks
            let analysis = try await geminiAnalysisService.analyzePropertyRisk(
                propertyProfile: profile,
                hazardAssessment: assessment
            )

            alertText = analysis.alertText

            print("ℹ️  Saving \(analysis.tasks.count) Gemini-generated tasks...")

            // Save tasks (await completion to ensure they're available for insurance calculation)
            do {
                try await taskRepository.createTasks(analysis.tasks, userId: userId)
                print("✅ Tasks saved to Firestore")
            } catch {
                print("⚠️  Firestore save failed (non-critical): \(error.localizedDescription)")
            }

            print("✅ Action plan generated with \(analysis.tasks.count) tasks")

            // Recalculate insurance score now that tasks exist
            print("🔄 Recalculating insurance score with new tasks...")
            await calculateInsuranceScore(userId: userId)

            print("🔓 Setting isLoading = false")
            isLoading = false
            return true

        } catch {
            // Gemini failed - generate smart default tasks locally
            print("⚠️  Gemini failed, generating smart default tasks locally: \(error.localizedDescription)")

            var tasks = generateLocalTasks(userId: userId, propertyProfile: profile, hazardAssessment: assessment)

            // Calculate base premium for insurance impact
            let riskScores = (
                hurricane: assessment.riskScores.hurricane,
                flood: assessment.riskScores.flood,
                wildfire: assessment.riskScores.wildfire,
                earthquake: assessment.riskScores.earthquake
            )
            let basePremium = InsuranceCalculator.calculateBasePremium(
                propertyProfile: profile,
                riskScores: riskScores
            )

            // Assign insurance impact to local tasks
            tasks = InsuranceCalculator.assignInsuranceImpact(tasks: tasks, basePremium: basePremium)
            print("✅ Assigned insurance impact to \(tasks.count) local tasks")

            // Save tasks (await completion to ensure they're available for insurance calculation)
            do {
                try await taskRepository.createTasks(tasks, userId: userId)
                print("✅ Local tasks saved to Firestore")
            } catch {
                print("⚠️  Firestore save failed (non-critical): \(error.localizedDescription)")
            }

            print("✅ Generated \(tasks.count) smart default tasks locally")

            // Recalculate insurance score now that tasks exist
            print("🔄 Recalculating insurance score with new tasks...")
            await calculateInsuranceScore(userId: userId)

            print("🔓 Setting isLoading = false")
            isLoading = false
            return true
        }
    }

    @MainActor
    func refreshData(userId: String) async {
        guard let profile = propertyProfile else { return }
        await loadDashboardData(userId: userId, propertyProfile: profile)
    }

    // Generate smart default tasks when Gemini is unavailable
    private func generateLocalTasks(userId: String, propertyProfile: PropertyProfile, hazardAssessment: HazardAssessment) -> [MitigationTask] {
        print("\n🔧 GENERATING SMART DEFAULT TASKS")
        print("📊 HVS: \(Int(hvsScore))")
        print("🌪️  Hurricane Risk: \(Int(hazardAssessment.riskScores.hurricane))")
        print("💧 Flood Risk: \(Int(hazardAssessment.riskScores.flood))")
        print("🌀 Tornado Risk: \(Int(hazardAssessment.riskScores.tornado))")

        var tasks: [MitigationTask] = []

        let isHurricaneRisk = hazardAssessment.riskScores.hurricane >= 60
        let isFloodRisk = hazardAssessment.riskScores.flood >= 60
        let isTornadoRisk = hazardAssessment.riskScores.tornado >= 60
        let isOldRoof = propertyProfile.roofAge > 15

        // High-priority emergency preparedness
        tasks.append(MitigationTask(
            title: "Prepare Emergency Kit",
            description: "Assemble or update emergency kit with water (1 gallon per person per day for 3 days), non-perishable food, flashlights, batteries, first aid supplies, medications, and copies of important documents.",
            priority: .high,
            category: .emergency,
            status: .notStarted,
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            estimatedCost: 200,
            estimatedTime: "2-3 hours",
            isAIGenerated: true,
            userId: userId,
            notes: "",
            createdAt: Date(),
            updatedAt: Date()
        ))

        // Roof inspection if old or hurricane risk
        if isOldRoof || isHurricaneRisk {
            tasks.append(MitigationTask(
                title: "Professional Roof Inspection",
                description: "Schedule a professional roof inspection to identify weak points, damaged shingles, or structural issues. Your roof is \(propertyProfile.roofAge) years old and should be assessed for storm readiness.",
                priority: isOldRoof ? .high : .medium,
                category: .structural,
                status: .notStarted,
                dueDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                estimatedCost: 350,
                estimatedTime: "2-3 hours",
                relatedPerilType: isHurricaneRisk ? "Hurricane" : nil,
                isAIGenerated: true,
                userId: userId,
                notes: "",
                createdAt: Date(),
                updatedAt: Date()
            ))
        }

        // Hurricane-specific tasks
        if isHurricaneRisk {
            if !propertyProfile.hasStormShutters {
                tasks.append(MitigationTask(
                    title: "Install Storm Shutters",
                    description: "Install storm shutters or impact-resistant window protection to safeguard against hurricane-force winds and flying debris. This is a high priority for your coastal location.",
                    priority: .high,
                    category: .structural,
                    status: .notStarted,
                    dueDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
                    estimatedCost: 2500,
                    estimatedTime: "1-2 days",
                    relatedPerilType: "Hurricane",
                    isAIGenerated: true,
                    userId: userId,
                    notes: "",
                    createdAt: Date(),
                    updatedAt: Date()
                ))
            }

            tasks.append(MitigationTask(
                title: "Secure Outdoor Items",
                description: "Identify and secure all outdoor furniture, decorations, trash cans, and other items that could become projectiles in high winds. Have a plan to move them indoors when a storm approaches.",
                priority: .medium,
                category: .emergency,
                status: .notStarted,
                dueDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                estimatedCost: 0,
                estimatedTime: "1-2 hours",
                relatedPerilType: "Hurricane",
                isAIGenerated: true,
                userId: userId,
                notes: "",
                createdAt: Date(),
                updatedAt: Date()
            ))
        }

        // Flood-related tasks
        if isFloodRisk {
            tasks.append(MitigationTask(
                title: "Clear Gutters and Improve Drainage",
                description: "Remove debris from gutters, downspouts, and drainage systems. Ensure water flows away from the foundation. Consider extending downspouts if needed.",
                priority: .medium,
                category: .maintenance,
                status: .notStarted,
                dueDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
                estimatedCost: 150,
                estimatedTime: "2-3 hours",
                relatedPerilType: "Flood",
                isAIGenerated: true,
                userId: userId,
                notes: "",
                createdAt: Date(),
                updatedAt: Date()
            ))
        }

        // Tornado-related tasks
        if isTornadoRisk {
            tasks.append(MitigationTask(
                title: "Identify Safe Room for Severe Weather",
                description: "Designate an interior room on the lowest floor with no windows as your safe room for tornadoes and severe weather. Stock it with emergency supplies, flashlight, and weather radio.",
                priority: .high,
                category: .emergency,
                status: .notStarted,
                dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                estimatedCost: 100,
                estimatedTime: "1 hour",
                relatedPerilType: "Tornado",
                isAIGenerated: true,
                userId: userId,
                notes: "",
                createdAt: Date(),
                updatedAt: Date()
            ))
        }

        // Always add insurance review
        tasks.append(MitigationTask(
            title: "Review Insurance Coverage",
            description: "Review your homeowner's insurance policy to ensure adequate coverage for your area's risks. Verify coverage limits, deductibles, and consider flood insurance if not included.",
            priority: .medium,
            category: .insurance,
            status: .notStarted,
            dueDate: Calendar.current.date(byAdding: .day, value: 21, to: Date()),
            estimatedCost: 0,
            estimatedTime: "1-2 hours",
            isAIGenerated: true,
            userId: userId,
            notes: "",
            createdAt: Date(),
            updatedAt: Date()
        ))

        print("✅ Generated \(tasks.count) smart default tasks")
        return tasks
    }

    // MARK: - Insurance Calculations

    @MainActor
    func calculateInsuranceScore(userId: String) async {
        guard let profile = propertyProfile,
              let assessment = hazardAssessment else {
            print("⚠️  Cannot calculate insurance score - missing profile or assessment")
            return
        }

        print("\n💰 CALCULATING INSURANCE SCORE")

        // Fetch all tasks for this user
        do {
            let tasks = try await taskRepository.fetchTasks(userId: userId)
            print("📋 Found \(tasks.count) tasks for insurance calculation")

            // Calculate insurance score
            let riskScores = (
                hurricane: assessment.riskScores.hurricane,
                flood: assessment.riskScores.flood,
                wildfire: assessment.riskScores.wildfire,
                earthquake: assessment.riskScores.earthquake
            )

            let score = InsuranceCalculator.calculateInsuranceScore(
                propertyProfile: profile,
                tasks: tasks,
                riskScores: riskScores
            )

            insuranceScore = score

            print("✅ Insurance score calculated:")
            print("   Base Premium: $\(Int(score.basePremium))/year")
            print("   Current Premium: $\(Int(score.currentPremium))/year")
            print("   Annual Savings: $\(Int(score.totalAnnualSavings))")
            print("   Readiness Score: \(Int(score.readinessScore))%")
            print("   Completed Tasks: \(score.savingsItems.count)")
            print("   Potential Savings: \(score.potentialSavings.count)")
        } catch {
            print("❌ Failed to calculate insurance score: \(error.localizedDescription)")
        }
    }

    @MainActor
    func recalculateInsuranceScore(userId: String) async {
        // Force recalculation without cache
        await calculateInsuranceScore(userId: userId)
    }
}
