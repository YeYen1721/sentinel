//
//  USGSEarthquakeService.swift
//  Sentinel
//
//  Service to fetch earthquake data from USGS Earthquake Hazards Program
//  FREE - No API key required
//

import Foundation

/// Service for fetching real-time earthquake data from USGS
class USGSEarthquakeService {

    struct EarthquakeData {
        let recentQuakes: [Earthquake]
        let riskLevel: EarthquakeRiskLevel
        let significantQuakesNearby: Int
        let largestMagnitude: Double?
        let nearestQuakeDistance: Double? // miles
    }

    struct Earthquake {
        let magnitude: Double
        let location: String
        let latitude: Double
        let longitude: Double
        let depth: Double              // kilometers
        let time: Date
        let distanceFromProperty: Double // miles
        let significance: Int          // USGS significance score
        let url: String                // USGS event page
    }

    enum EarthquakeRiskLevel {
        case high      // Major quakes (5.0+) within 100 miles in last 30 days, or in high seismic zone
        case moderate  // Moderate quakes (3.0-4.9) nearby, or moderate seismic zone
        case low       // Minor quakes only, or low seismic zone
        case minimal   // No significant quakes, low seismic zone

        var score: Double {
            switch self {
            case .high: return 75.0
            case .moderate: return 45.0
            case .low: return 20.0
            case .minimal: return 5.0
            }
        }

        var displayName: String {
            switch self {
            case .high: return "High - Major seismic activity"
            case .moderate: return "Moderate - Active seismic zone"
            case .low: return "Low - Minor seismic activity"
            case .minimal: return "Minimal - Low seismic zone"
            }
        }
    }

    /// Fetch earthquake data for a specific location (last 30 days)
    func fetchEarthquakeData(latitude: Double, longitude: Double, radiusMiles: Double = 100) async throws -> EarthquakeData {

        print("\n🌋 FETCHING USGS EARTHQUAKE DATA")
        print("📍 GPS: \(latitude), \(longitude)")
        print("📍 Search Radius: \(Int(radiusMiles)) miles")

        // USGS Earthquake API endpoint
        // Query last 30 days, minimum magnitude 2.5, within radius
        let radiusKm = radiusMiles * 1.60934 // Convert miles to km

        let baseURL = "https://earthquake.usgs.gov/fdsnws/event/1/query"
        var components = URLComponents(string: baseURL)!

        components.queryItems = [
            URLQueryItem(name: "format", value: "geojson"),
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "maxradiuskm", value: String(Int(radiusKm))),
            URLQueryItem(name: "minmagnitude", value: "2.5"),
            URLQueryItem(name: "starttime", value: getStartDate()),
            URLQueryItem(name: "orderby", value: "magnitude")
        ]

        guard let url = components.url else {
            throw USGSError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw USGSError.invalidResponse
            }

            print("📡 USGS API status code: \(httpResponse.statusCode)")

            if httpResponse.statusCode != 200 {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ USGS API error: \(errorString)")
                }
                print("⚠️  Falling back to estimated earthquake risk")
                return generateEstimatedRisk(latitude: latitude, longitude: longitude)
            }

            // Parse GeoJSON response
            let earthquakeResponse = try JSONDecoder().decode(USGSResponse.self, from: data)

            let quakes = parseEarthquakes(from: earthquakeResponse, propertyLat: latitude, propertyLon: longitude)

            let earthquakeData = analyzeEarthquakeRisk(
                quakes: quakes,
                propertyLat: latitude,
                propertyLon: longitude
            )

            print("✅ USGS: Found \(quakes.count) earthquakes (M2.5+) in last 30 days")
            if let largest = earthquakeData.largestMagnitude {
                print("   🌋 Largest magnitude: M\(String(format: "%.1f", largest))")
            }
            if let nearest = earthquakeData.nearestQuakeDistance {
                print("   📍 Nearest quake: \(String(format: "%.1f", nearest)) miles away")
            }
            print("   📊 Risk Level: \(earthquakeData.riskLevel.displayName)")

            return earthquakeData

        } catch {
            print("⚠️  USGS API failed: \(error.localizedDescription)")
            print("⚠️  Using estimated earthquake risk")
            return generateEstimatedRisk(latitude: latitude, longitude: longitude)
        }
    }

    private func parseEarthquakes(from response: USGSResponse, propertyLat: Double, propertyLon: Double) -> [Earthquake] {
        var quakes: [Earthquake] = []

        for feature in response.features {
            let props = feature.properties
            let coords = feature.geometry.coordinates

            let magnitude = props.mag
            let location = props.place
            let time = Date(timeIntervalSince1970: TimeInterval(props.time) / 1000.0)
            let significance = props.sig
            let url = props.url

            let quakeLon = coords[0]
            let quakeLat = coords[1]
            let depth = coords[2]

            // Calculate distance from property
            let distance = calculateDistance(
                lat1: propertyLat, lon1: propertyLon,
                lat2: quakeLat, lon2: quakeLon
            )

            let quake = Earthquake(
                magnitude: magnitude,
                location: location,
                latitude: quakeLat,
                longitude: quakeLon,
                depth: depth,
                time: time,
                distanceFromProperty: distance,
                significance: significance,
                url: url
            )

            quakes.append(quake)
        }

        return quakes.sorted { $0.magnitude > $1.magnitude }
    }

    private func analyzeEarthquakeRisk(quakes: [Earthquake], propertyLat: Double, propertyLon: Double) -> EarthquakeData {

        let significantQuakes = quakes.filter { $0.magnitude >= 5.0 }
        let moderateQuakes = quakes.filter { $0.magnitude >= 3.0 && $0.magnitude < 5.0 }

        let largestMagnitude = quakes.first?.magnitude
        let nearestQuake = quakes.min(by: { $0.distanceFromProperty < $1.distanceFromProperty })

        // Determine risk level
        let riskLevel: EarthquakeRiskLevel

        // Check if in known high seismic zones (California, Alaska, Pacific Northwest)
        let isHighSeismicZone = isInHighSeismicZone(latitude: propertyLat, longitude: propertyLon)

        if !significantQuakes.isEmpty || isHighSeismicZone {
            riskLevel = .high
        } else if !moderateQuakes.isEmpty || quakes.count > 10 {
            riskLevel = .moderate
        } else if !quakes.isEmpty {
            riskLevel = .low
        } else {
            riskLevel = .minimal
        }

        return EarthquakeData(
            recentQuakes: quakes,
            riskLevel: riskLevel,
            significantQuakesNearby: significantQuakes.count,
            largestMagnitude: largestMagnitude,
            nearestQuakeDistance: nearestQuake?.distanceFromProperty
        )
    }

    private func isInHighSeismicZone(latitude: Double, longitude: Double) -> Bool {
        // California
        if latitude > 32 && latitude < 42 && longitude > -125 && longitude < -114 {
            return true
        }

        // Alaska
        if latitude > 51 && longitude > -180 && longitude < -130 {
            return true
        }

        // Pacific Northwest (Oregon, Washington)
        if latitude > 42 && latitude < 49 && longitude > -125 && longitude < -116 {
            return true
        }

        // Nevada (active seismic zone)
        if latitude > 36 && latitude < 42 && longitude > -120 && longitude < -114 {
            return true
        }

        return false
    }

    private func generateEstimatedRisk(latitude: Double, longitude: Double) -> EarthquakeData {
        print("🔧 Generating estimated earthquake risk based on location")

        let isHighSeismicZone = isInHighSeismicZone(latitude: latitude, longitude: longitude)

        let riskLevel: EarthquakeRiskLevel = isHighSeismicZone ? .moderate : .minimal

        return EarthquakeData(
            recentQuakes: [],
            riskLevel: riskLevel,
            significantQuakesNearby: 0,
            largestMagnitude: nil,
            nearestQuakeDistance: nil
        )
    }

    private func getStartDate() -> String {
        // 30 days ago
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: thirtyDaysAgo)
    }

    // Calculate distance between two coordinates using Haversine formula
    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let earthRadius = 3959.0 // miles

        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0

        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon/2) * sin(dLon/2)

        let c = 2 * atan2(sqrt(a), sqrt(1-a))

        return earthRadius * c
    }
}

// MARK: - USGS API Response Models

private struct USGSResponse: Codable {
    let features: [EarthquakeFeature]
}

private struct EarthquakeFeature: Codable {
    let properties: EarthquakeProperties
    let geometry: EarthquakeGeometry
}

private struct EarthquakeProperties: Codable {
    let mag: Double
    let place: String
    let time: Int64
    let sig: Int
    let url: String
}

private struct EarthquakeGeometry: Codable {
    let coordinates: [Double] // [longitude, latitude, depth]
}

// MARK: - Error Types

enum USGSError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError
    case noDataFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid USGS API URL"
        case .invalidResponse:
            return "Invalid response from USGS"
        case .apiError:
            return "USGS API error"
        case .noDataFound:
            return "No earthquake data found"
        }
    }
}
