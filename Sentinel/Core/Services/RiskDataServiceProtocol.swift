//
//  RiskDataServiceProtocol.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import Foundation

protocol RiskDataServiceProtocol {
    /// Fetch hazard assessment for a given property location
    func fetchHazardAssessment(latitude: Double, longitude: Double) async throws -> HazardAssessment

    /// Fetch property profile data from external APIs
    func fetchPropertyData(address: String) async throws -> PropertyProfile?

    /// Get current weather alerts for location
    func fetchCurrentAlerts(latitude: Double, longitude: Double) async throws -> [HazardAssessment.WeatherForecast]
}

enum RiskDataError: Error, LocalizedError {
    case networkError
    case invalidResponse
    case dataNotFound
    case apiKeyMissing
    case rateLimitExceeded

    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Unable to connect to risk data service"
        case .invalidResponse:
            return "Invalid response from risk data service"
        case .dataNotFound:
            return "Risk data not found for this location"
        case .apiKeyMissing:
            return "API key configuration missing"
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again later."
        }
    }
}
