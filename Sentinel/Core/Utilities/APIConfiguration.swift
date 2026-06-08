//
//  APIConfiguration.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import Foundation

/// Configuration for API keys and endpoints
struct APIConfiguration {

    // MARK: - Weather Data API

    /// OpenWeatherMap API key
    /// Get your free API key at: https://openweathermap.org/api
    static let openWeatherAPIKey: String = {
        // Check environment variable first (for CI/CD)
        if let envKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"], !envKey.isEmpty {
            return envKey
        }

        return ""
    }()

    static let openWeatherBaseURL = "https://api.openweathermap.org/data/2.5"

    // MARK: - Gemini AI API

    /// Google Gemini API key
    /// Get your API key at: https://makersuite.google.com/app/apikey
    static let geminiAPIKey: String = {
        // Check environment variable first
        if let envKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !envKey.isEmpty {
            return envKey
        }

        return ""
    }()

    // Use current free tier model - gemini-2.0-flash
    static let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

    // MARK: - NOAA Weather API (Free, no key required)

    static let noaaBaseURL = "https://api.weather.gov"

    // MARK: - NASA FIRMS (Fire Information) API

    /// NASA FIRMS API key
    /// Get your free API key at: https://firms.modaps.eosdis.nasa.gov/api/
    /// Requires NASA Earthdata account: https://urs.earthdata.nasa.gov/
    static let nasaFIRMSKey: String = {
        // Check environment variable first
        if let envKey = ProcessInfo.processInfo.environment["NASA_FIRMS_KEY"], !envKey.isEmpty {
            return envKey
        }

        return ""
    }()

    static let nasaFIRMSBaseURL = "https://firms.modaps.eosdis.nasa.gov/api"

    // MARK: - Configuration Status

    /// Check if weather API is configured
    static var isWeatherAPIConfigured: Bool {
        !openWeatherAPIKey.isEmpty
    }

    /// Check if Gemini AI is configured
    static var isGeminiConfigured: Bool {
        !geminiAPIKey.isEmpty
    }

    /// Check if NASA FIRMS is configured
    static var isNASAFIRMSConfigured: Bool {
        !nasaFIRMSKey.isEmpty
    }

    /// Check if any real API is configured
    static var hasRealAPIs: Bool {
        isWeatherAPIConfigured || isGeminiConfigured || isNASAFIRMSConfigured
    }
}
