//
//  PropertyProfile.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import Foundation
import FirebaseFirestore

struct PropertyProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var address: String
    var latitude: Double
    var longitude: Double

    // Structural Properties
    var roofMaterial: RoofMaterial
    var roofAge: Int // Years
    var foundationType: FoundationType
    var yearBuilt: Int
    var squareFootage: Double
    var stories: Int
    var hasBasement: Bool
    var exteriorMaterial: ExteriorMaterial

    // Additional Features
    var hasStormShutters: Bool
    var hasBackupGenerator: Bool
    var hasSmartHomeMonitoring: Bool

    var userId: String
    var createdAt: Date
    var updatedAt: Date

    enum RoofMaterial: String, Codable, CaseIterable {
        case asphaltShingles = "Asphalt Shingles"
        case metalRoof = "Metal Roof"
        case clay = "Clay Tiles"
        case slate = "Slate"
        case woodShakes = "Wood Shakes"
        case concrete = "Concrete Tiles"
    }

    enum FoundationType: String, Codable, CaseIterable {
        case slab = "Slab"
        case crawlSpace = "Crawl Space"
        case basement = "Basement"
        case piersAndBeams = "Piers and Beams"
    }

    enum ExteriorMaterial: String, Codable, CaseIterable {
        case vinyl = "Vinyl Siding"
        case brick = "Brick"
        case stucco = "Stucco"
        case wood = "Wood"
        case fiberCement = "Fiber Cement"
        case stone = "Stone"
    }

    // Calculate property resilience score (0-100)
    var resilienceScore: Double {
        var score = 50.0 // Base score

        // Roof material scoring
        switch roofMaterial {
        case .metalRoof: score += 15
        case .slate, .concrete: score += 12
        case .clay: score += 8
        case .asphaltShingles: score += 5
        case .woodShakes: score -= 5
        }

        // Roof age penalty
        let roofAgePenalty = Double(roofAge) * 0.5
        score -= roofAgePenalty

        // Foundation scoring
        switch foundationType {
        case .basement: score += 10
        case .slab: score += 8
        case .crawlSpace: score += 5
        case .piersAndBeams: score += 3
        }

        // Age penalty
        let buildingAge = Calendar.current.component(.year, from: Date()) - yearBuilt
        score -= Double(buildingAge) * 0.1

        // Positive features
        if hasStormShutters { score += 8 }
        if hasBackupGenerator { score += 5 }
        if hasSmartHomeMonitoring { score += 3 }

        return max(0, min(100, score))
    }
}
