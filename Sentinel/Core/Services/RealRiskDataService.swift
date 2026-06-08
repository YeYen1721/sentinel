//
//  RealRiskDataService.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import Foundation

/// Real implementation of risk data service using actual weather APIs
class RealRiskDataService: RiskDataServiceProtocol {

    private let session: URLSession
    private let femaService = FEMAFloodService()
    private let firmsService = NASAFIRMSService()
    private let usgsService = USGSEarthquakeService()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchHazardAssessment(latitude: Double, longitude: Double) async throws -> HazardAssessment {
        print("ℹ️  Fetching hazard assessment for: \(latitude), \(longitude)")

        // Fetch forecasts (has built-in fallback to mock data)
        let weatherForecasts = await fetchWeatherForecasts(latitude: latitude, longitude: longitude)

        // Fetch REAL active weather alerts from NOAA
        let activeAlerts = (try? await fetchCurrentAlerts(latitude: latitude, longitude: longitude)) ?? []

        // Combine forecasts and active alerts, removing duplicates
        let allForecasts = deduplicateForecasts(activeAlerts + weatherForecasts)

        // Fetch historical perils (always succeeds with generated data)
        let perils = await fetchHistoricalPerils(latitude: latitude, longitude: longitude)

        // Fetch FEMA flood zone data
        let floodZone = try? await femaService.fetchFloodZone(latitude: latitude, longitude: longitude)

        // Fetch NASA FIRMS wildfire data
        let wildfireData = try? await firmsService.fetchWildfireData(latitude: latitude, longitude: longitude)

        // Fetch USGS earthquake data
        let earthquakeData = try? await usgsService.fetchEarthquakeData(latitude: latitude, longitude: longitude)

        let riskScores = calculateRiskScores(forecasts: allForecasts, perils: perils, floodZone: floodZone, wildfireData: wildfireData, earthquakeData: earthquakeData, latitude: latitude, longitude: longitude)

        print("✅ Hazard assessment complete - \(activeAlerts.count) active alerts, \(weatherForecasts.count) forecasts, \(perils.count) historical events")

        return HazardAssessment(
            location: HazardAssessment.Location(
                latitude: latitude,
                longitude: longitude,
                address: "",
                city: "",
                state: "",
                zipCode: ""
            ),
            historicalPerils: perils,
            currentForecasts: allForecasts,
            riskScores: riskScores,
            timestamp: Date()
        )
    }

    func fetchPropertyData(address: String) async throws -> PropertyProfile? {
        // In production, this would call a geocoding API and property data API
        // For now, return basic data with geocoded coordinates
        let coordinates = try await geocodeAddress(address)

        return PropertyProfile(
            address: address,
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            roofMaterial: .asphaltShingles,
            roofAge: 10,
            foundationType: .slab,
            yearBuilt: 2010,
            squareFootage: 2000,
            stories: 1,
            hasBasement: false,
            exteriorMaterial: .vinyl,
            hasStormShutters: false,
            hasBackupGenerator: false,
            hasSmartHomeMonitoring: false,
            userId: "",
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func fetchCurrentAlerts(latitude: Double, longitude: Double) async throws -> [HazardAssessment.WeatherForecast] {
        // Use NOAA API to fetch current weather alerts (free, no key required)
        let url = URL(string: "https://api.weather.gov/alerts/active?point=\(latitude),\(longitude)")!
        var request = URLRequest(url: url)
        request.setValue("SentinelApp/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("⚠️  NOAA API returned error, returning empty alerts")
                return []
            }

            let alertResponse = try JSONDecoder().decode(NOAAAlertResponse.self, from: data)

            // Convert NOAA alerts to WeatherForecast objects
            return alertResponse.features.compactMap { feature in
                let event = feature.properties.event
                let (type, alertLevel) = mapAlertToType(event)

                return HazardAssessment.WeatherForecast(
                    type: type,
                    probability: 80, // Alerts have high probability
                    expectedDate: Date(),
                    duration: 3600 * 24, // 24 hours
                    intensity: "Active Alert",
                    alertLevel: alertLevel
                )
            }
        } catch {
            print("⚠️  Failed to fetch alerts: \(error.localizedDescription)")
            return []
        }
    }

    private func mapAlertToType(_ event: String) -> (HazardAssessment.PerilEvent.PerilType, HazardAssessment.WeatherForecast.AlertLevel) {
        let lower = event.lowercased()
        if lower.contains("tornado") {
            return (.tornado, .warning)
        } else if lower.contains("hurricane") {
            return (.hurricane, .emergency)
        } else if lower.contains("flood") {
            return (.flood, .warning)
        } else if lower.contains("fire") {
            return (.wildfire, .warning)
        } else if lower.contains("winter") || lower.contains("snow") {
            return (.winterStorm, .warning)
        } else {
            return (.severeThunderstorm, .watch)
        }
    }

    private func deduplicateForecasts(_ forecasts: [HazardAssessment.WeatherForecast]) -> [HazardAssessment.WeatherForecast] {
        var seen: Set<String> = []
        var unique: [HazardAssessment.WeatherForecast] = []

        for forecast in forecasts {
            // Create a unique key based on type, alert level, and date (within same day)
            let dateKey = Calendar.current.startOfDay(for: forecast.expectedDate)
            let key = "\(forecast.type.rawValue)-\(forecast.alertLevel.rawValue)-\(dateKey)"

            if !seen.contains(key) {
                seen.insert(key)
                unique.append(forecast)
            }
        }

        print("📋 Deduplicated forecasts: \(forecasts.count) → \(unique.count)")
        return unique
    }

    // MARK: - Private Methods

    private func fetchWeatherForecasts(latitude: Double, longitude: Double) async -> [HazardAssessment.WeatherForecast] {
        // If OpenWeather API is configured, try it first
        if APIConfiguration.isWeatherAPIConfigured {
            do {
                print("ℹ️  Attempting OpenWeather API...")
                return try await fetchOpenWeatherForecasts(latitude: latitude, longitude: longitude)
            } catch {
                print("⚠️  OpenWeather failed, falling back to NOAA: \(error.localizedDescription)")
                // Fall through to NOAA
            }
        }

        // Try NOAA (free, US only)
        do {
            print("ℹ️  Attempting NOAA API...")
            return try await fetchNOAAForecasts(latitude: latitude, longitude: longitude)
        } catch {
            print("⚠️  NOAA also failed: \(error.localizedDescription)")
            print("ℹ️  Using mock weather data")
            return generateMockForecasts()
        }
    }

    private func fetchOpenWeatherForecasts(latitude: Double, longitude: Double) async throws -> [HazardAssessment.WeatherForecast] {
        let urlString = "\(APIConfiguration.openWeatherBaseURL)/forecast?lat=\(latitude)&lon=\(longitude)&appid=\(APIConfiguration.openWeatherAPIKey)&units=imperial"

        guard let url = URL(string: urlString) else {
            print("⚠️  Invalid OpenWeather URL")
            throw RiskDataError.invalidResponse
        }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("⚠️  OpenWeather: Invalid HTTP response")
                throw RiskDataError.networkError
            }

            print("ℹ️  OpenWeather API status code: \(httpResponse.statusCode)")

            guard httpResponse.statusCode == 200 else {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("⚠️  OpenWeather error: \(errorString)")
                }
                throw RiskDataError.networkError
            }

            let weatherResponse = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)

            print("✅ OpenWeather API success - got \(weatherResponse.list.count) forecasts")

            // Convert OpenWeather data to our forecast format
            return weatherResponse.list.prefix(5).map { forecast in
                let condition = forecast.weather.first?.main ?? "Clear"
                let (type, alertLevel, probability) = mapWeatherCondition(condition, windSpeed: forecast.wind.speed)

                return HazardAssessment.WeatherForecast(
                    type: type,
                    probability: Double(probability),
                    expectedDate: Date(timeIntervalSince1970: TimeInterval(forecast.dt)),
                    duration: 3600 * 6, // 6 hours
                    intensity: forecast.wind.speed > 40 ? "Severe" : "Moderate",
                    alertLevel: alertLevel
                )
            }
        } catch {
            print("⚠️  OpenWeather API failed: \(error.localizedDescription)")
            throw error
        }
    }

    private func fetchNOAAForecasts(latitude: Double, longitude: Double) async throws -> [HazardAssessment.WeatherForecast] {
        // NOAA requires a two-step process: get grid point, then get forecast
        let pointURL = URL(string: "https://api.weather.gov/points/\(latitude),\(longitude)")!
        var pointRequest = URLRequest(url: pointURL)
        pointRequest.setValue("SentinelApp/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (pointData, pointResponse) = try await session.data(for: pointRequest)

            guard let httpResponse = pointResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                // If NOAA fails, return mock forecast
                return generateMockForecasts()
            }

            let pointInfo = try JSONDecoder().decode(NOAAPointResponse.self, from: pointData)
            let forecastURL = URL(string: pointInfo.properties.forecast)!
            var forecastRequest = URLRequest(url: forecastURL)
            forecastRequest.setValue("SentinelApp/1.0", forHTTPHeaderField: "User-Agent")

            let (forecastData, forecastResponse) = try await session.data(for: forecastRequest)

            guard let httpForecastResponse = forecastResponse as? HTTPURLResponse, httpForecastResponse.statusCode == 200 else {
                return generateMockForecasts()
            }

            let noaaForecast = try JSONDecoder().decode(NOAAForecastResponse.self, from: forecastData)

            // Convert NOAA periods to our forecast format
            return noaaForecast.properties.periods.prefix(5).map { period in
                let (type, alertLevel, probability) = mapNOAACondition(period.shortForecast, isDaytime: period.isDaytime)

                return HazardAssessment.WeatherForecast(
                    type: type,
                    probability: Double(probability),
                    expectedDate: Date(timeIntervalSinceNow: 0), // NOAA doesn't provide exact dates
                    duration: 3600 * 12, // 12 hours
                    intensity: period.windSpeed.contains("30") || period.windSpeed.contains("40") ? "Severe" : "Moderate",
                    alertLevel: alertLevel
                )
            }
        } catch {
            print("⚠️  NOAA API failed: \(error.localizedDescription), using mock data")
            return generateMockForecasts()
        }
    }

    private func fetchHistoricalPerils(latitude: Double, longitude: Double) async -> [HazardAssessment.PerilEvent] {
        // Use real historical storm data mapped to location
        print("ℹ️  Fetching real historical storm events for location...")
        let events = HistoricalStormData.getEventsForLocation(latitude: latitude, longitude: longitude)

        if events.isEmpty {
            print("ℹ️  No major historical events in this region, using sample data")
            return generateHistoricalPerilsForLocation(latitude: latitude, longitude: longitude)
        }

        print("✅ Found \(events.count) real historical events for this region")
        return events
    }

    private func geocodeAddress(_ address: String) async throws -> (latitude: Double, longitude: Double) {
        // Use OpenStreetMap Nominatim for free geocoding
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? address
        let urlString = "https://nominatim.openstreetmap.org/search?q=\(encodedAddress)&format=json&limit=1"

        guard let url = URL(string: urlString) else {
            throw RiskDataError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.setValue("SentinelApp/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw RiskDataError.networkError
        }

        let results = try JSONDecoder().decode([GeocodingResult].self, from: data)

        guard let first = results.first,
              let lat = Double(first.lat),
              let lon = Double(first.lon) else {
            // Default to Miami coordinates if geocoding fails
            return (25.7617, -80.1918)
        }

        return (lat, lon)
    }

    private func calculateRiskScores(forecasts: [HazardAssessment.WeatherForecast], perils: [HazardAssessment.PerilEvent], floodZone: FEMAFloodService.FloodZoneData?, wildfireData: NASAFIRMSService.WildfireData?, earthquakeData: USGSEarthquakeService.EarthquakeData?, latitude: Double, longitude: Double) -> HazardAssessment.RiskScores {
        print("\n🎯 CALCULATING RISK SCORES for \(latitude), \(longitude)")

        // Calculate risk based on location and historical data
        let isCoastal = abs(latitude) < 35 && (longitude < -80 || longitude > -70) // Gulf/Atlantic coast
        let isTornadoAlley = latitude > 30 && latitude < 45 && longitude < -90 && longitude > -105
        let isFloodProne = perils.filter { $0.type == .flood }.count > 2

        print("   Location flags: Coastal=\(isCoastal), TornadoAlley=\(isTornadoAlley), FloodProne=\(isFloodProne)")

        var hurricaneScore = 0.0
        var floodScore = 0.0
        var tornadoScore = 0.0
        var wildFireScore = 0.0
        var earthquakeScore = 0.0
        var hailScore = 20.0
        var winterStormScore = latitude > 35 ? 40.0 : 10.0

        // Base scores on location
        if isCoastal {
            hurricaneScore = 65.0
            floodScore = 55.0
        }

        if isTornadoAlley {
            tornadoScore = 70.0
        }

        // Use FEMA flood zone data for accurate flood risk
        if let floodZone = floodZone {
            print("   🌊 FEMA Flood Zone: \(floodZone.zone) (\(floodZone.riskLevel.displayName))")
            floodScore = max(floodScore, floodZone.riskLevel.score)
        } else if isFloodProne {
            floodScore = max(floodScore, 60.0)
        }

        // Use NASA FIRMS data for accurate wildfire risk
        if let wildfireData = wildfireData {
            print("   🔥 NASA FIRMS: \(wildfireData.riskLevel.displayName)")
            if wildfireData.totalFiresNearby > 0 {
                print("      \(wildfireData.totalFiresNearby) active fires detected")
                if let nearest = wildfireData.nearestFireDistance {
                    print("      Nearest fire: \(String(format: "%.1f", nearest)) miles")
                }
            }
            wildFireScore = wildfireData.riskLevel.score
        }

        // Use USGS data for accurate earthquake risk
        if let earthquakeData = earthquakeData {
            print("   🌋 USGS Earthquake: \(earthquakeData.riskLevel.displayName)")
            if earthquakeData.recentQuakes.count > 0 {
                print("      \(earthquakeData.recentQuakes.count) earthquakes (M2.5+) in last 30 days")
                if let largest = earthquakeData.largestMagnitude {
                    print("      Largest magnitude: M\(String(format: "%.1f", largest))")
                }
            }
            earthquakeScore = earthquakeData.riskLevel.score
        }

        print("   Base scores: Hurricane=\(hurricaneScore), Flood=\(floodScore), Tornado=\(tornadoScore), Wildfire=\(Int(wildFireScore)), Earthquake=\(Int(earthquakeScore))")

        // Adjust based on forecasts
        for forecast in forecasts {
            switch forecast.type {
            case .hurricane:
                hurricaneScore = min(100, hurricaneScore + Double(forecast.probability) * 0.3)
            case .flood:
                floodScore = min(100, floodScore + Double(forecast.probability) * 0.3)
            case .tornado:
                tornadoScore = min(100, tornadoScore + Double(forecast.probability) * 0.3)
            case .wildfire:
                wildFireScore = min(100, wildFireScore + Double(forecast.probability) * 0.3)
            case .hailstorm:
                hailScore = min(100, hailScore + Double(forecast.probability) * 0.3)
            case .winterStorm:
                winterStormScore = min(100, winterStormScore + Double(forecast.probability) * 0.3)
            default:
                break
            }
        }

        // Adjust based on historical perils
        for peril in perils {
            switch peril.type {
            case .hurricane:
                hurricaneScore = min(100, hurricaneScore + 10)
            case .flood:
                floodScore = min(100, floodScore + 10)
            case .tornado:
                tornadoScore = min(100, tornadoScore + 10)
            case .wildfire:
                wildFireScore = min(100, wildFireScore + 10)
            case .hailstorm:
                hailScore = min(100, hailScore + 10)
            case .winterStorm:
                winterStormScore = min(100, winterStormScore + 10)
            default:
                break
            }
        }

        let overall = (hurricaneScore + floodScore + tornadoScore + wildFireScore + hailScore + winterStormScore) / 6.0

        print("   📊 FINAL RISK SCORES:")
        print("      Overall: \(Int(overall))")
        print("      Hurricane: \(Int(hurricaneScore))")
        print("      Flood: \(Int(floodScore))")
        print("      Tornado: \(Int(tornadoScore))")
        print("      Wildfire: \(Int(wildFireScore))")
        print("      Hail: \(Int(hailScore))")
        print("      Winter Storm: \(Int(winterStormScore))\n")

        return HazardAssessment.RiskScores(
            overall: overall,
            hurricane: hurricaneScore,
            tornado: tornadoScore,
            flood: floodScore,
            wildfire: wildFireScore,
            earthquake: earthquakeScore, // Now using real USGS data!
            hail: hailScore,
            winterStorm: winterStormScore
        )
    }

    // MARK: - Helper Methods

    private func mapWeatherCondition(_ condition: String, windSpeed: Double) -> (HazardAssessment.PerilEvent.PerilType, HazardAssessment.WeatherForecast.AlertLevel, Int) {
        switch condition.lowercased() {
        case let c where c.contains("thunder") || c.contains("storm"):
            return (.severeThunderstorm, windSpeed > 40 ? .warning : .watch, 70)
        case let c where c.contains("rain") || c.contains("drizzle"):
            return (.flood, .advisory, 40)
        case let c where c.contains("tornado"):
            return (.tornado, .warning, 85)
        case let c where c.contains("hurricane"):
            return (.hurricane, .warning, 90)
        default:
            return (.severeThunderstorm, .advisory, 20)
        }
    }

    private func mapNOAACondition(_ forecast: String, isDaytime: Bool) -> (HazardAssessment.PerilEvent.PerilType, HazardAssessment.WeatherForecast.AlertLevel, Int) {
        let lower = forecast.lowercased()
        if lower.contains("storm") || lower.contains("thunder") {
            return (.severeThunderstorm, .watch, 60)
        } else if lower.contains("rain") || lower.contains("shower") {
            return (.flood, .advisory, 35)
        } else if lower.contains("tornado") {
            return (.tornado, .warning, 80)
        } else if lower.contains("hurricane") {
            return (.hurricane, .warning, 85)
        } else if lower.contains("wind") {
            return (.severeThunderstorm, .advisory, 45)
        }
        return (.severeThunderstorm, .advisory, 15)
    }

    private func generateMockForecasts() -> [HazardAssessment.WeatherForecast] {
        [
            HazardAssessment.WeatherForecast(
                type: .severeThunderstorm,
                probability: 65,
                expectedDate: Date(timeIntervalSinceNow: 86400),
                duration: 3600 * 6,
                intensity: "Moderate",
                alertLevel: .watch
            ),
            HazardAssessment.WeatherForecast(
                type: .flood,
                probability: 40,
                expectedDate: Date(timeIntervalSinceNow: 86400 * 2),
                duration: 3600 * 12,
                intensity: "Minor",
                alertLevel: .advisory
            )
        ]
    }

    private func generateHistoricalPerilsForLocation(latitude: Double, longitude: Double) -> [HazardAssessment.PerilEvent] {
        var events: [HazardAssessment.PerilEvent] = []

        // Coastal areas - hurricanes
        if abs(latitude) < 35 && (longitude < -80 || longitude > -70) {
            events.append(HazardAssessment.PerilEvent(
                type: .hurricane,
                date: Calendar.current.date(byAdding: .month, value: -4, to: Date())!,
                severity: .severe,
                description: "Category 3 hurricane passed 50 miles offshore",
                damageEstimate: 15000,
                affectedRadius: 100
            ))
        }

        // Add some general weather events
        events.append(HazardAssessment.PerilEvent(
            type: .severeThunderstorm,
            date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
            severity: .moderate,
            description: "Severe thunderstorms with hail",
            damageEstimate: 500,
            affectedRadius: 25
        ))

        return events
    }
}

// MARK: - API Response Models

private struct OpenWeatherResponse: Codable {
    let list: [ForecastItem]

    struct ForecastItem: Codable {
        let dt: Int
        let main: Main
        let weather: [Weather]
        let wind: Wind

        struct Main: Codable {
            let temp: Double
        }

        struct Weather: Codable {
            let main: String
            let description: String
        }

        struct Wind: Codable {
            let speed: Double
        }
    }
}

private struct NOAAPointResponse: Codable {
    let properties: Properties

    struct Properties: Codable {
        let forecast: String
    }
}

private struct NOAAForecastResponse: Codable {
    let properties: Properties

    struct Properties: Codable {
        let periods: [Period]
    }

    struct Period: Codable {
        let name: String
        let temperature: Int
        let windSpeed: String
        let shortForecast: String
        let isDaytime: Bool
    }
}

private struct NOAAAlertResponse: Codable {
    let features: [Feature]

    struct Feature: Codable {
        let properties: Properties
    }

    struct Properties: Codable {
        let event: String
    }
}

private struct GeocodingResult: Codable {
    let lat: String
    let lon: String
}
