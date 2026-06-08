//
//  MockRiskDataService.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import Foundation

/// Mock implementation of RiskDataServiceProtocol for development and previews
class MockRiskDataService: RiskDataServiceProtocol {

    func fetchHazardAssessment(latitude: Double, longitude: Double) async throws -> HazardAssessment {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        let location = HazardAssessment.Location(
            latitude: latitude,
            longitude: longitude,
            address: "123 Main Street",
            city: "Miami",
            state: "FL",
            zipCode: "33101"
        )

        // Generate mock historical peril events
        let historicalPerils: [HazardAssessment.PerilEvent] = [
            .init(
                type: .hurricane,
                date: Calendar.current.date(byAdding: .year, value: -2, to: Date())!,
                severity: .severe,
                description: "Hurricane Ian caused significant damage to the region",
                damageEstimate: 15000,
                affectedRadius: 50
            ),
            .init(
                type: .flood,
                date: Calendar.current.date(byAdding: .month, value: -8, to: Date())!,
                severity: .moderate,
                description: "Heavy rainfall led to flash flooding",
                damageEstimate: 3000,
                affectedRadius: 15
            ),
            .init(
                type: .hailstorm,
                date: Calendar.current.date(byAdding: .month, value: -14, to: Date())!,
                severity: .minor,
                description: "Severe thunderstorm with golf ball-sized hail",
                damageEstimate: 1200,
                affectedRadius: 10
            )
        ]

        // Generate mock weather forecasts
        let currentForecasts: [HazardAssessment.WeatherForecast] = [
            .init(
                type: .severeThunderstorm,
                probability: 65,
                expectedDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                duration: 3600 * 4, // 4 hours
                intensity: "Moderate with high winds",
                alertLevel: .watch
            ),
            .init(
                type: .hurricane,
                probability: 45,
                expectedDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
                duration: 3600 * 24 * 2, // 2 days
                intensity: "Category 2-3 possible",
                alertLevel: .advisory
            )
        ]

        let riskScores = HazardAssessment.RiskScores(
            overall: 72,
            hurricane: 85,
            tornado: 45,
            flood: 68,
            wildfire: 15,
            earthquake: 10,
            hail: 55,
            winterStorm: 5
        )

        return HazardAssessment(
            location: location,
            historicalPerils: historicalPerils,
            currentForecasts: currentForecasts,
            riskScores: riskScores,
            timestamp: Date()
        )
    }

    func fetchPropertyData(address: String) async throws -> PropertyProfile? {
        try await Task.sleep(nanoseconds: 500_000_000)

        return PropertyProfile(
            address: address,
            latitude: 25.7617,
            longitude: -80.1918,
            roofMaterial: .asphaltShingles,
            roofAge: 12,
            foundationType: .slab,
            yearBuilt: 2005,
            squareFootage: 2400,
            stories: 2,
            hasBasement: false,
            exteriorMaterial: .stucco,
            hasStormShutters: false,
            hasBackupGenerator: false,
            hasSmartHomeMonitoring: true,
            userId: "mock-user",
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func fetchCurrentAlerts(latitude: Double, longitude: Double) async throws -> [HazardAssessment.WeatherForecast] {
        try await Task.sleep(nanoseconds: 300_000_000)

        return [
            .init(
                type: .severeThunderstorm,
                probability: 75,
                expectedDate: Date().addingTimeInterval(3600 * 6),
                duration: 3600 * 3,
                intensity: "High winds and heavy rain expected",
                alertLevel: .warning
            )
        ]
    }
}
