//
//  FEMAFloodService.swift
//  Sentinel
//
//  Service to fetch flood zone data from FEMA National Flood Hazard Layer
//  FREE - No API key required
//

import Foundation

/// Service for fetching FEMA flood zone data
class FEMAFloodService {

    struct FloodZoneData {
        let zone: String              // e.g., "AE", "X", "VE"
        let riskLevel: FloodRiskLevel
        let description: String
        let baseFloodElevation: Double? // in feet
        let isSpecialFloodHazardArea: Bool // SFHA = high risk
    }

    enum FloodRiskLevel {
        case high      // Zones A, AE, AH, AO, AR, A99, V, VE
        case moderate  // Zones B, X (shaded)
        case minimal   // Zone X (unshaded), Zone C
        case unknown

        var score: Double {
            switch self {
            case .high: return 85.0
            case .moderate: return 50.0
            case .minimal: return 15.0
            case .unknown: return 30.0
            }
        }

        var displayName: String {
            switch self {
            case .high: return "High Risk"
            case .moderate: return "Moderate Risk"
            case .minimal: return "Minimal Risk"
            case .unknown: return "Unknown"
            }
        }
    }

    /// Fetch flood zone data for a specific location
    func fetchFloodZone(latitude: Double, longitude: Double) async throws -> FloodZoneData {

        print("\n🌊 FETCHING FEMA FLOOD ZONE DATA")
        print("📍 GPS: \(latitude), \(longitude)")

        // Try primary endpoint first
        do {
            return try await fetchFromPrimaryEndpoint(latitude: latitude, longitude: longitude)
        } catch {
            print("⚠️  Primary FEMA endpoint failed, trying alternative...")

            // Try alternative endpoint
            do {
                return try await fetchFromAlternativeEndpoint(latitude: latitude, longitude: longitude)
            } catch {
                print("⚠️  Both FEMA endpoints failed, using location-based flood risk estimation...")

                // Fallback to location-based flood risk estimation
                return estimateFloodRiskFromLocation(latitude: latitude, longitude: longitude)
            }
        }
    }

    /// Primary FEMA endpoint (original)
    private func fetchFromPrimaryEndpoint(latitude: Double, longitude: Double) async throws -> FloodZoneData {
        // FEMA NFHL MapServer endpoint
        let baseURL = "https://hazards.fema.gov/gis/nfhl/rest/services/public/NFHL/MapServer/identify"

        // Build query parameters
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "geometry", value: "\(longitude),\(latitude)"),
            URLQueryItem(name: "geometryType", value: "esriGeometryPoint"),
            URLQueryItem(name: "sr", value: "4326"), // WGS84
            URLQueryItem(name: "layers", value: "all:28"), // Layer 28 = Flood Hazard Zones
            URLQueryItem(name: "tolerance", value: "0"),
            URLQueryItem(name: "mapExtent", value: "\(longitude-0.1),\(latitude-0.1),\(longitude+0.1),\(latitude+0.1)"),
            URLQueryItem(name: "imageDisplay", value: "400,400,96"),
            URLQueryItem(name: "returnGeometry", value: "false"),
            URLQueryItem(name: "f", value: "json")
        ]

        guard let url = components.url else {
            throw FEMAError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FEMAError.invalidResponse
        }

        print("📡 FEMA Primary API status code: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ FEMA Primary API error: \(errorString)")
            }
            throw FEMAError.apiError
        }

        // Parse response
        let femaResponse = try JSONDecoder().decode(FEMAResponse.self, from: data)

        if let result = femaResponse.results.first {
            let zone = parseFloodZone(from: result)
            print("✅ FEMA Flood Zone: \(zone.zone) (\(zone.riskLevel.displayName))")
            return zone
        } else {
            // No flood zone data found - likely minimal risk
            print("ℹ️  No FEMA flood zone found - likely minimal risk area")
            return FloodZoneData(
                zone: "X",
                riskLevel: .minimal,
                description: "Area of minimal flood hazard",
                baseFloodElevation: nil,
                isSpecialFloodHazardArea: false
            )
        }
    }

    /// Alternative FEMA endpoint (query-based)
    private func fetchFromAlternativeEndpoint(latitude: Double, longitude: Double) async throws -> FloodZoneData {
        // Use query endpoint instead of identify
        let baseURL = "https://hazards.fema.gov/gis/nfhl/rest/services/public/NFHL/MapServer/28/query"

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "geometry", value: "\(longitude),\(latitude)"),
            URLQueryItem(name: "geometryType", value: "esriGeometryPoint"),
            URLQueryItem(name: "inSR", value: "4326"),
            URLQueryItem(name: "spatialRel", value: "esriSpatialRelIntersects"),
            URLQueryItem(name: "outFields", value: "FLD_ZONE,ZONE_SUBTY,STATIC_BFE"),
            URLQueryItem(name: "returnGeometry", value: "false"),
            URLQueryItem(name: "f", value: "json")
        ]

        guard let url = components.url else {
            throw FEMAError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FEMAError.invalidResponse
        }

        print("📡 FEMA Alternative API status code: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ FEMA Alternative API error: \(errorString)")
            }
            throw FEMAError.apiError
        }

        // Parse query response format (different from identify)
        let queryResponse = try JSONDecoder().decode(FEMAQueryResponse.self, from: data)

        if let feature = queryResponse.features.first {
            let zone = parseFloodZoneFromQuery(from: feature)
            print("✅ FEMA Flood Zone (alt): \(zone.zone) (\(zone.riskLevel.displayName))")
            return zone
        } else {
            // No flood zone data found
            print("ℹ️  No FEMA flood zone found (alt) - likely minimal risk area")
            return FloodZoneData(
                zone: "X",
                riskLevel: .minimal,
                description: "Area of minimal flood hazard",
                baseFloodElevation: nil,
                isSpecialFloodHazardArea: false
            )
        }
    }

    private func parseFloodZone(from result: FEMAResult) -> FloodZoneData {
        let attributes = result.attributes

        // Get flood zone designation
        let zone = attributes.fld_zone ?? attributes.zone_subty ?? "X"

        // Determine risk level based on zone
        let riskLevel = determineRiskLevel(zone: zone)

        // Get base flood elevation if available
        let bfe = attributes.static_bfe

        // Description
        let description = getZoneDescription(zone: zone)

        // Is SFHA (Special Flood Hazard Area)?
        let isSFHA = riskLevel == .high

        return FloodZoneData(
            zone: zone,
            riskLevel: riskLevel,
            description: description,
            baseFloodElevation: bfe,
            isSpecialFloodHazardArea: isSFHA
        )
    }

    private func determineRiskLevel(zone: String) -> FloodRiskLevel {
        let zoneUpper = zone.uppercased()

        // High risk zones (Special Flood Hazard Area - SFHA)
        if zoneUpper.hasPrefix("A") || zoneUpper.hasPrefix("V") {
            return .high
        }

        // Moderate risk zones
        if zoneUpper == "B" || (zoneUpper == "X" && zone.contains("shaded")) {
            return .moderate
        }

        // Minimal risk zones
        if zoneUpper == "C" || zoneUpper == "X" {
            return .minimal
        }

        return .unknown
    }

    private func getZoneDescription(zone: String) -> String {
        let zoneUpper = zone.uppercased()

        switch zoneUpper {
        case "A":
            return "High risk flood zone with no base flood elevation determined"
        case "AE":
            return "High risk flood zone with base flood elevations determined"
        case "AH":
            return "High risk flood zone with shallow flooding (1-3 feet)"
        case "AO":
            return "High risk flood zone with shallow flooding and sheet flow"
        case "AR":
            return "High risk flood zone with temporary flood protection"
        case "A99":
            return "High risk flood zone protected by federal flood control system under construction"
        case let v where v.hasPrefix("V"):
            return "High risk coastal flood zone with wave action (velocity zone)"
        case "B", "X":
            return "Moderate to minimal flood risk area"
        case "C":
            return "Minimal flood risk area"
        default:
            return "Flood zone: \(zone)"
        }
    }

    private func parseFloodZoneFromQuery(from feature: FEMAQueryFeature) -> FloodZoneData {
        let attributes = feature.attributes

        // Get flood zone designation
        let zone = attributes.fld_zone ?? attributes.zone_subty ?? "X"

        // Determine risk level based on zone
        let riskLevel = determineRiskLevel(zone: zone)

        // Get base flood elevation if available
        let bfe = attributes.static_bfe

        // Description
        let description = getZoneDescription(zone: zone)

        // Is SFHA (Special Flood Hazard Area)?
        let isSFHA = riskLevel == .high

        return FloodZoneData(
            zone: zone,
            riskLevel: riskLevel,
            description: description,
            baseFloodElevation: bfe,
            isSpecialFloodHazardArea: isSFHA
        )
    }

    /// Estimate flood risk based on geographic location when FEMA data is unavailable
    private func estimateFloodRiskFromLocation(latitude: Double, longitude: Double) -> FloodZoneData {
        // Known high-risk flood areas (coastal, river basins, low-lying areas)
        let isCoastal = isCoastalArea(latitude: latitude, longitude: longitude)
        let isLowLying = isLowLyingArea(latitude: latitude, longitude: longitude)
        let isRiverBasin = isRiverBasinArea(latitude: latitude, longitude: longitude)

        var riskLevel: FloodRiskLevel
        var zone: String
        var description: String

        if isCoastal {
            riskLevel = .high
            zone = "AE (Est.)"
            description = "Estimated coastal flood zone - high risk area based on proximity to coast"
            print("ℹ️  Estimated flood zone: AE (Coastal) - High Risk")
        } else if isRiverBasin {
            riskLevel = .moderate
            zone = "X-Shaded (Est.)"
            description = "Estimated moderate flood risk - area near major river basin"
            print("ℹ️  Estimated flood zone: X-Shaded (River Basin) - Moderate Risk")
        } else if isLowLying {
            riskLevel = .moderate
            zone = "X-Shaded (Est.)"
            description = "Estimated moderate flood risk - low-lying area"
            print("ℹ️  Estimated flood zone: X-Shaded (Low-lying) - Moderate Risk")
        } else {
            riskLevel = .minimal
            zone = "X (Est.)"
            description = "Estimated minimal flood risk - area outside typical floodplains"
            print("ℹ️  Estimated flood zone: X - Minimal Risk")
        }

        return FloodZoneData(
            zone: zone,
            riskLevel: riskLevel,
            description: description,
            baseFloodElevation: nil,
            isSpecialFloodHazardArea: riskLevel == .high
        )
    }

    /// Check if location is in coastal flood-prone area
    private func isCoastalArea(latitude: Double, longitude: Double) -> Bool {
        // Gulf Coast (high hurricane/storm surge risk)
        let isGulfCoast = latitude >= 24 && latitude <= 31 && longitude >= -98 && longitude <= -80

        // Atlantic Coast (Florida to Maine)
        let isAtlanticCoast = latitude >= 24 && latitude <= 45 && longitude >= -81 && longitude <= -66

        // Pacific Coast (California to Washington)
        let isPacificCoast = latitude >= 32 && latitude <= 49 && longitude >= -125 && longitude <= -117

        return isGulfCoast || isAtlanticCoast || isPacificCoast
    }

    /// Check if location is in low-lying flood-prone area
    private func isLowLyingArea(latitude: Double, longitude: Double) -> Bool {
        // Louisiana (below sea level)
        if latitude >= 29 && latitude <= 33 && longitude >= -94 && longitude <= -89 {
            return true
        }

        // Florida Everglades
        if latitude >= 25 && latitude <= 27 && longitude >= -81 && longitude <= -80 {
            return true
        }

        // Central Valley, California
        if latitude >= 35 && latitude <= 40 && longitude >= -122 && longitude <= -119 {
            return true
        }

        return false
    }

    /// Check if location is in major river basin
    private func isRiverBasinArea(latitude: Double, longitude: Double) -> Bool {
        // Mississippi River Basin
        let isMississippi = latitude >= 29 && latitude <= 49 && longitude >= -95 && longitude <= -84

        // Missouri River Basin
        let isMissouri = latitude >= 38 && latitude <= 49 && longitude >= -112 && longitude <= -90

        // Ohio River Basin
        let isOhio = latitude >= 36 && latitude <= 41 && longitude >= -89 && longitude <= -77

        return isMississippi || isMissouri || isOhio
    }
}

// MARK: - FEMA API Response Models

private struct FEMAResponse: Codable {
    let results: [FEMAResult]
}

private struct FEMAResult: Codable {
    let layerId: Int
    let layerName: String
    let attributes: FEMAAttributes
}

private struct FEMAAttributes: Codable {
    let fld_zone: String?       // Flood zone designation
    let zone_subty: String?     // Zone subtype
    let static_bfe: Double?     // Base Flood Elevation
    let depth: Double?          // Flood depth
    let velocity: Double?       // Velocity zone indicator

    enum CodingKeys: String, CodingKey {
        case fld_zone = "FLD_ZONE"
        case zone_subty = "ZONE_SUBTY"
        case static_bfe = "STATIC_BFE"
        case depth = "DEPTH"
        case velocity = "VELOCITY"
    }
}

// Query endpoint response format
private struct FEMAQueryResponse: Codable {
    let features: [FEMAQueryFeature]
}

private struct FEMAQueryFeature: Codable {
    let attributes: FEMAQueryAttributes
}

private struct FEMAQueryAttributes: Codable {
    let fld_zone: String?
    let zone_subty: String?
    let static_bfe: Double?

    enum CodingKeys: String, CodingKey {
        case fld_zone = "FLD_ZONE"
        case zone_subty = "ZONE_SUBTY"
        case static_bfe = "STATIC_BFE"
    }
}

// MARK: - Error Types

enum FEMAError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError
    case noDataFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid FEMA API URL"
        case .invalidResponse:
            return "Invalid response from FEMA"
        case .apiError:
            return "FEMA API error"
        case .noDataFound:
            return "No flood zone data found"
        }
    }
}
