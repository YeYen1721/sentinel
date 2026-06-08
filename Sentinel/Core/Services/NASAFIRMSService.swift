//
//  NASAFIRMSService.swift
//  Sentinel
//
//  Service to fetch active wildfire data from NASA FIRMS
//  Requires free NASA Earthdata account and FIRMS API key
//

import Foundation

/// Service for fetching real-time wildfire data from NASA FIRMS
class NASAFIRMSService {

    struct WildfireData {
        let activeFires: [ActiveFire]
        let riskLevel: WildfireRiskLevel
        let nearestFireDistance: Double? // miles
        let totalFiresNearby: Int
    }

    struct ActiveFire {
        let latitude: Double
        let longitude: Double
        let brightness: Double          // Temperature in Kelvin
        let confidence: Int              // 0-100
        let fireRadiativePower: Double   // MW (megawatts)
        let acquisitionDate: Date
        let distanceFromProperty: Double // miles
        let satellite: String            // VIIRS or MODIS
    }

    enum WildfireRiskLevel {
        case extreme   // Fire within 10 miles
        case high      // Fire within 25 miles
        case moderate  // Fire within 50 miles
        case low       // No fires within 50 miles

        var score: Double {
            switch self {
            case .extreme: return 95.0
            case .high: return 75.0
            case .moderate: return 45.0
            case .low: return 10.0
            }
        }

        var displayName: String {
            switch self {
            case .extreme: return "Extreme - Active fires nearby"
            case .high: return "High - Fires within 25 miles"
            case .moderate: return "Moderate - Fires within 50 miles"
            case .low: return "Low - No nearby fires"
            }
        }
    }

    /// Fetch wildfire data for a specific location (last 7 days)
    func fetchWildfireData(latitude: Double, longitude: Double, radiusMiles: Double = 50) async throws -> WildfireData {

        print("\n🔥 FETCHING NASA FIRMS WILDFIRE DATA")
        print("📍 GPS: \(latitude), \(longitude)")
        print("📍 Search Radius: \(Int(radiusMiles)) miles")

        guard !APIConfiguration.nasaFIRMSKey.isEmpty else {
            print("⚠️  NASA FIRMS API key not configured - using estimated wildfire risk")
            return generateEstimatedRisk(latitude: latitude, longitude: longitude)
        }

        // Use VIIRS data (375m resolution, best for active fires)
        // Area query: get fires within bounding box around property
        let radiusDegrees = radiusMiles / 69.0 // rough conversion miles to degrees

        let minLat = latitude - radiusDegrees
        let maxLat = latitude + radiusDegrees
        let minLon = longitude - radiusDegrees
        let maxLon = longitude + radiusDegrees

        let urlString = "\(APIConfiguration.nasaFIRMSBaseURL)/area/csv/\(APIConfiguration.nasaFIRMSKey)/VIIRS_NOAA20_NRT/\(minLon),\(minLat),\(maxLon),\(maxLat)/7"

        guard let url = URL(string: urlString) else {
            throw FIRMSError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FIRMSError.invalidResponse
            }

            print("📡 NASA FIRMS API status code: \(httpResponse.statusCode)")

            if httpResponse.statusCode != 200 {
                if let errorString = String(data: data, encoding: .utf8) {
                    print("❌ NASA FIRMS error: \(errorString)")
                }
                print("⚠️  Falling back to estimated wildfire risk")
                return generateEstimatedRisk(latitude: latitude, longitude: longitude)
            }

            // Parse CSV response
            guard let csvString = String(data: data, encoding: .utf8) else {
                throw FIRMSError.invalidResponse
            }

            let fires = parseCSV(csvString, propertyLat: latitude, propertyLon: longitude)

            let wildfireData = analyzeFireRisk(fires: fires, propertyLat: latitude, propertyLon: longitude)

            print("✅ NASA FIRMS: Found \(fires.count) active fires within \(Int(radiusMiles)) miles")
            if let nearest = wildfireData.nearestFireDistance {
                print("   🔥 Nearest fire: \(String(format: "%.1f", nearest)) miles away")
            }
            print("   📊 Risk Level: \(wildfireData.riskLevel.displayName)")

            return wildfireData

        } catch {
            print("⚠️  NASA FIRMS failed: \(error.localizedDescription)")
            print("⚠️  Using estimated wildfire risk")
            return generateEstimatedRisk(latitude: latitude, longitude: longitude)
        }
    }

    private func parseCSV(_ csv: String, propertyLat: Double, propertyLon: Double) -> [ActiveFire] {
        var fires: [ActiveFire] = []

        let lines = csv.components(separatedBy: .newlines)
        guard lines.count > 1 else { return fires }

        // First line is header, skip it
        for line in lines.dropFirst() {
            let fields = line.components(separatedBy: ",")
            guard fields.count >= 9 else { continue }

            // CSV format: latitude,longitude,bright_ti4,scan,track,acq_date,acq_time,satellite,confidence,version,bright_ti5,frp,daynight
            guard let lat = Double(fields[0]),
                  let lon = Double(fields[1]),
                  let brightness = Double(fields[2]),
                  let confidence = Int(fields[8]),
                  let frp = Double(fields[11]) else {
                continue
            }

            // Parse acquisition date
            let dateString = fields[5] + " " + fields[6]
            let date = parseDateTime(dateString)

            let satellite = fields[7]

            // Calculate distance from property
            let distance = calculateDistance(
                lat1: propertyLat, lon1: propertyLon,
                lat2: lat, lon2: lon
            )

            let fire = ActiveFire(
                latitude: lat,
                longitude: lon,
                brightness: brightness,
                confidence: confidence,
                fireRadiativePower: frp,
                acquisitionDate: date,
                distanceFromProperty: distance,
                satellite: satellite
            )

            fires.append(fire)
        }

        return fires.sorted { $0.distanceFromProperty < $1.distanceFromProperty }
    }

    private func analyzeFireRisk(fires: [ActiveFire], propertyLat: Double, propertyLon: Double) -> WildfireData {

        let nearestFire = fires.first?.distanceFromProperty

        let riskLevel: WildfireRiskLevel
        if let nearest = nearestFire {
            if nearest <= 10 {
                riskLevel = .extreme
            } else if nearest <= 25 {
                riskLevel = .high
            } else if nearest <= 50 {
                riskLevel = .moderate
            } else {
                riskLevel = .low
            }
        } else {
            riskLevel = .low
        }

        return WildfireData(
            activeFires: fires,
            riskLevel: riskLevel,
            nearestFireDistance: nearestFire,
            totalFiresNearby: fires.count
        )
    }

    private func generateEstimatedRisk(latitude: Double, longitude: Double) -> WildfireData {
        print("🔧 Generating estimated wildfire risk based on location")

        // High fire risk areas: California, Oregon, Washington, Colorado, Arizona, New Mexico, Idaho, Montana, Wyoming
        let isHighFireRiskState = (longitude < -114 && latitude > 32) || // CA, OR, WA
                                   (longitude < -102 && longitude > -115 && latitude > 31 && latitude < 49) // Mountain West

        let riskLevel: WildfireRiskLevel = isHighFireRiskState ? .moderate : .low

        return WildfireData(
            activeFires: [],
            riskLevel: riskLevel,
            nearestFireDistance: nil,
            totalFiresNearby: 0
        )
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

    private func parseDateTime(_ dateTime: String) -> Date {
        // Format: "2025-10-25 1430" (YYYY-MM-DD HHMM)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HHmm"

        return formatter.date(from: dateTime) ?? Date()
    }
}

// MARK: - Error Types

enum FIRMSError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError
    case noDataFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid NASA FIRMS API URL"
        case .invalidResponse:
            return "Invalid response from NASA FIRMS"
        case .apiError:
            return "NASA FIRMS API error"
        case .noDataFound:
            return "No wildfire data found"
        }
    }
}
