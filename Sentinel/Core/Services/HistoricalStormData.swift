//
//  HistoricalStormData.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import Foundation

/// Real historical storm and disaster data mapped to regions
struct HistoricalStormData {

    /// Major hurricanes and tropical storms (1950-2024)
    static let majorHurricanes: [RegionalStorm] = [
        // === 1950-1979 ===
        RegionalStorm(
            region: .gulfCoast,
            name: "Hurricane Camille",
            date: "1969-08-17",
            type: .hurricane,
            severity: .catastrophic,
            description: "Category 5 hurricane, one of only four Cat 5s to hit mainland US",
            maxWindSpeed: 190,
            estimatedDamage: 1420000000,
            affectedRadius: 300
        ),
        RegionalStorm(
            region: .florida,
            name: "Labor Day Hurricane",
            date: "1935-09-02",
            type: .hurricane,
            severity: .catastrophic,
            description: "Category 5, strongest hurricane to hit US at landfall",
            maxWindSpeed: 185,
            estimatedDamage: 6000000,
            affectedRadius: 250
        ),
        RegionalStorm(
            region: .atlanticCoast,
            name: "Hurricane Hazel",
            date: "1954-10-15",
            type: .hurricane,
            severity: .severe,
            description: "Category 4, affected Carolinas to Canada",
            maxWindSpeed: 130,
            estimatedDamage: 281000000,
            affectedRadius: 600
        ),
        RegionalStorm(
            region: .atlanticCoast,
            name: "Hurricane Diane",
            date: "1955-08-17",
            type: .hurricane,
            severity: .severe,
            description: "First hurricane to cause over $1 billion in damage",
            maxWindSpeed: 105,
            estimatedDamage: 831000000,
            affectedRadius: 400
        ),
        RegionalStorm(
            region: .texas,
            name: "Hurricane Carla",
            date: "1961-09-11",
            type: .hurricane,
            severity: .catastrophic,
            description: "Category 5, largest Texas hurricane on record",
            maxWindSpeed: 175,
            estimatedDamage: 325000000,
            affectedRadius: 450
        ),
        RegionalStorm(
            region: .florida,
            name: "Hurricane Betsy",
            date: "1965-09-09",
            type: .hurricane,
            severity: .severe,
            description: "First billion-dollar hurricane in US history",
            maxWindSpeed: 140,
            estimatedDamage: 1420000000,
            affectedRadius: 350
        ),

        // === 1980-1999 ===
        RegionalStorm(
            region: .atlanticCoast,
            name: "Hurricane Hugo",
            date: "1989-09-21",
            type: .hurricane,
            severity: .catastrophic,
            description: "Category 4, devastated South Carolina",
            maxWindSpeed: 140,
            estimatedDamage: 7000000000,
            affectedRadius: 300
        ),
        RegionalStorm(
            region: .florida,
            name: "Hurricane Andrew",
            date: "1992-08-24",
            type: .hurricane,
            severity: .catastrophic,
            description: "Category 5, strongest hurricane to hit Florida",
            maxWindSpeed: 165,
            estimatedDamage: 27300000000,
            affectedRadius: 350
        ),
        RegionalStorm(
            region: .atlanticCoast,
            name: "Hurricane Fran",
            date: "1996-09-06",
            type: .hurricane,
            severity: .severe,
            description: "Category 3, major damage to North Carolina",
            maxWindSpeed: 115,
            estimatedDamage: 3200000000,
            affectedRadius: 250
        ),
        RegionalStorm(
            region: .atlanticCoast,
            name: "Hurricane Floyd",
            date: "1999-09-16",
            type: .hurricane,
            severity: .severe,
            description: "Category 4, massive flooding in eastern US",
            maxWindSpeed: 155,
            estimatedDamage: 6900000000,
            affectedRadius: 500
        ),

        // === 2000-2024 (existing) ===
        // Gulf Coast / Florida
        RegionalStorm(
            region: .gulfCoast,
            name: "Hurricane Katrina",
            date: "2005-08-29",
            type: .hurricane,
            severity: .catastrophic,
            description: "Category 5 hurricane, devastating storm surge along Gulf Coast",
            maxWindSpeed: 175,
            estimatedDamage: 125000000000,
            affectedRadius: 400
        ),
        RegionalStorm(
            region: .gulfCoast,
            name: "Hurricane Ian",
            date: "2022-09-28",
            type: .hurricane,
            severity: .catastrophic,
            description: "Category 4 hurricane made landfall in Southwest Florida",
            maxWindSpeed: 155,
            estimatedDamage: 113000000000,
            affectedRadius: 350
        ),
        RegionalStorm(
            region: .florida,
            name: "Hurricane Michael",
            date: "2018-10-10",
            type: .hurricane,
            severity: .catastrophic,
            description: "Category 5 hurricane, Florida Panhandle",
            maxWindSpeed: 160,
            estimatedDamage: 25000000000,
            affectedRadius: 250
        ),
        RegionalStorm(
            region: .florida,
            name: "Hurricane Irma",
            date: "2017-09-10",
            type: .hurricane,
            severity: .catastrophic,
            description: "Category 4 hurricane, statewide impact in Florida",
            maxWindSpeed: 155,
            estimatedDamage: 50000000000,
            affectedRadius: 425
        ),

        // Atlantic Coast
        RegionalStorm(
            region: .atlanticCoast,
            name: "Hurricane Sandy",
            date: "2012-10-29",
            type: .hurricane,
            severity: .catastrophic,
            description: "Superstorm affecting Mid-Atlantic and Northeast",
            maxWindSpeed: 115,
            estimatedDamage: 70000000000,
            affectedRadius: 600
        ),
        RegionalStorm(
            region: .atlanticCoast,
            name: "Hurricane Florence",
            date: "2018-09-14",
            type: .hurricane,
            severity: .severe,
            description: "Category 4 hurricane, Carolinas flooding",
            maxWindSpeed: 140,
            estimatedDamage: 24000000000,
            affectedRadius: 300
        ),

        // Texas/Louisiana
        RegionalStorm(
            region: .texasCoast,
            name: "Hurricane Harvey",
            date: "2017-08-25",
            type: .hurricane,
            severity: .catastrophic,
            description: "Category 4 hurricane, catastrophic flooding in Houston",
            maxWindSpeed: 130,
            estimatedDamage: 125000000000,
            affectedRadius: 300
        ),
        RegionalStorm(
            region: .texasCoast,
            name: "Hurricane Rita",
            date: "2005-09-24",
            type: .hurricane,
            severity: .severe,
            description: "Category 5 hurricane, Texas-Louisiana border",
            maxWindSpeed: 180,
            estimatedDamage: 18000000000,
            affectedRadius: 350
        )
    ]

    /// Major flood events
    static let majorFloods: [RegionalStorm] = [
        RegionalStorm(
            region: .midwest,
            name: "Great Flood of 1993",
            date: "1993-07-12",
            type: .flood,
            severity: .catastrophic,
            description: "Worst flood in US history, Mississippi and Missouri Rivers",
            maxWindSpeed: 0,
            estimatedDamage: 15000000000,
            affectedRadius: 800
        ),
        RegionalStorm(
            region: .northeast,
            name: "Hurricane Agnes Flooding",
            date: "1972-06-21",
            type: .flood,
            severity: .catastrophic,
            description: "Deadliest hurricane of 1972, devastating floods",
            maxWindSpeed: 85,
            estimatedDamage: 2100000000,
            affectedRadius: 600
        ),
        RegionalStorm(
            region: .midwest,
            name: "Midwest Floods",
            date: "2019-03-15",
            type: .flood,
            severity: .severe,
            description: "Historic flooding along Missouri and Mississippi Rivers",
            maxWindSpeed: 0,
            estimatedDamage: 3000000000,
            affectedRadius: 500
        ),
        RegionalStorm(
            region: .southeast,
            name: "Nashville Floods",
            date: "2010-05-01",
            type: .flood,
            severity: .severe,
            description: "Record rainfall causing catastrophic flooding",
            maxWindSpeed: 0,
            estimatedDamage: 2000000000,
            affectedRadius: 100
        )
    ]

    /// Major tornado outbreaks
    static let majorTornadoes: [RegionalStorm] = [
        // Historic tornadoes
        RegionalStorm(
            region: .tornadoAlley,
            name: "1974 Super Outbreak",
            date: "1974-04-03",
            type: .tornado,
            severity: .catastrophic,
            description: "148 tornadoes in 13 states, 319 deaths, second-largest outbreak",
            maxWindSpeed: 260,
            estimatedDamage: 843000000,
            affectedRadius: 900
        ),
        RegionalStorm(
            region: .tornadoAlley,
            name: "Bridge Creek-Moore Tornado",
            date: "1999-05-03",
            type: .tornado,
            severity: .catastrophic,
            description: "Highest wind speed ever recorded: 321 mph",
            maxWindSpeed: 321,
            estimatedDamage: 1000000000,
            affectedRadius: 38
        ),
        RegionalStorm(
            region: .tornadoAlley,
            name: "Wichita Falls Tornado",
            date: "1979-04-10",
            type: .tornado,
            severity: .catastrophic,
            description: "F4 tornado, one of deadliest in Texas history",
            maxWindSpeed: 225,
            estimatedDamage: 400000000,
            affectedRadius: 8
        ),
        RegionalStorm(
            region: .southeast,
            name: "Tupelo-Gainesville Outbreak",
            date: "1936-04-05",
            type: .tornado,
            severity: .catastrophic,
            description: "Fourth-deadliest tornado day in US history, 454 deaths",
            maxWindSpeed: 260,
            estimatedDamage: 3000000,
            affectedRadius: 400
        ),
        RegionalStorm(
            region: .tornadoAlley,
            name: "Joplin Tornado",
            date: "2011-05-22",
            type: .tornado,
            severity: .catastrophic,
            description: "EF5 tornado, deadliest since 1950",
            maxWindSpeed: 200,
            estimatedDamage: 2800000000,
            affectedRadius: 22
        ),
        RegionalStorm(
            region: .tornadoAlley,
            name: "Moore Tornado",
            date: "2013-05-20",
            type: .tornado,
            severity: .catastrophic,
            description: "EF5 tornado in suburban Oklahoma City",
            maxWindSpeed: 210,
            estimatedDamage: 2000000000,
            affectedRadius: 17
        ),
        RegionalStorm(
            region: .southeast,
            name: "2011 Super Outbreak",
            date: "2011-04-27",
            type: .tornado,
            severity: .catastrophic,
            description: "Largest tornado outbreak in US history, 360 tornadoes",
            maxWindSpeed: 190,
            estimatedDamage: 11000000000,
            affectedRadius: 800
        )
    ]

    /// Major wildfires
    static let majorWildfires: [RegionalStorm] = [
        RegionalStorm(
            region: .westCoast,
            name: "Camp Fire",
            date: "2018-11-08",
            type: .wildfire,
            severity: .catastrophic,
            description: "Deadliest wildfire in California history",
            maxWindSpeed: 0,
            estimatedDamage: 16500000000,
            affectedRadius: 240
        ),
        RegionalStorm(
            region: .westCoast,
            name: "Dixie Fire",
            date: "2021-07-13",
            type: .wildfire,
            severity: .severe,
            description: "Second-largest wildfire in California history",
            maxWindSpeed: 0,
            estimatedDamage: 1150000000,
            affectedRadius: 1500
        )
    ]

    /// Major earthquakes
    static let majorEarthquakes: [RegionalStorm] = [
        RegionalStorm(
            region: .westCoast,
            name: "1994 Northridge Earthquake",
            date: "1994-01-17",
            type: .earthquake,
            severity: .catastrophic,
            description: "6.7 magnitude, costliest earthquake in US history",
            maxWindSpeed: 0,
            estimatedDamage: 50000000000,
            affectedRadius: 85
        ),
        RegionalStorm(
            region: .westCoast,
            name: "1989 Loma Prieta Earthquake",
            date: "1989-10-17",
            type: .earthquake,
            severity: .catastrophic,
            description: "6.9 magnitude, World Series Earthquake",
            maxWindSpeed: 0,
            estimatedDamage: 10000000000,
            affectedRadius: 70
        ),
        RegionalStorm(
            region: .westCoast,
            name: "1971 San Fernando Earthquake",
            date: "1971-02-09",
            type: .earthquake,
            severity: .severe,
            description: "6.6 magnitude, significant infrastructure damage",
            maxWindSpeed: 0,
            estimatedDamage: 505000000,
            affectedRadius: 60
        ),
        RegionalStorm(
            region: .westCoast,
            name: "2019 Ridgecrest Earthquakes",
            date: "2019-07-06",
            type: .earthquake,
            severity: .moderate,
            description: "7.1 magnitude, strongest in 20 years",
            maxWindSpeed: 0,
            estimatedDamage: 5000000000,
            affectedRadius: 100
        )
    ]

    /// Major hailstorm events
    static let majorHailstorms: [RegionalStorm] = [
        RegionalStorm(
            region: .tornadoAlley,
            name: "1990 Denver Hailstorm",
            date: "1990-07-11",
            type: .hailstorm,
            severity: .severe,
            description: "Baseball-sized hail, costliest hailstorm in US history",
            maxWindSpeed: 60,
            estimatedDamage: 625000000,
            affectedRadius: 30
        ),
        RegionalStorm(
            region: .tornadoAlley,
            name: "2001 Kansas City Hailstorm",
            date: "2001-04-10",
            type: .hailstorm,
            severity: .severe,
            description: "Softball-sized hail causing widespread damage",
            maxWindSpeed: 50,
            estimatedDamage: 2000000000,
            affectedRadius: 40
        ),
        RegionalStorm(
            region: .texas,
            name: "2016 Texas Hailstorm",
            date: "2016-04-12",
            type: .hailstorm,
            severity: .severe,
            description: "Hail up to 4.5 inches, San Antonio area",
            maxWindSpeed: 55,
            estimatedDamage: 1400000000,
            affectedRadius: 50
        )
    ]

    /// Winter storms
    static let majorWinterStorms: [RegionalStorm] = [
        RegionalStorm(
            region: .northeast,
            name: "Blizzard of 1993",
            date: "1993-03-13",
            type: .winterStorm,
            severity: .catastrophic,
            description: "Storm of the Century, affected 26 states",
            maxWindSpeed: 110,
            estimatedDamage: 6000000000,
            affectedRadius: 1500
        ),
        RegionalStorm(
            region: .northeast,
            name: "Blizzard of 1978",
            date: "1978-02-06",
            type: .winterStorm,
            severity: .catastrophic,
            description: "Northeastern US blizzard, 54 deaths",
            maxWindSpeed: 100,
            estimatedDamage: 520000000,
            affectedRadius: 600
        ),
        RegionalStorm(
            region: .texas,
            name: "Texas Winter Storm Uri",
            date: "2021-02-13",
            type: .winterStorm,
            severity: .catastrophic,
            description: "Historic freeze causing widespread power outages",
            maxWindSpeed: 50,
            estimatedDamage: 20000000000,
            affectedRadius: 800
        ),
        RegionalStorm(
            region: .northeast,
            name: "Blizzard of 2016",
            date: "2016-01-22",
            type: .winterStorm,
            severity: .severe,
            description: "Historic snowfall in Mid-Atlantic states",
            maxWindSpeed: 75,
            estimatedDamage: 3000000000,
            affectedRadius: 400
        )
    ]

    /// Get relevant historical events for a location
    static func getEventsForLocation(latitude: Double, longitude: Double) -> [HazardAssessment.PerilEvent] {
        let region = determineRegion(latitude: latitude, longitude: longitude)
        print("📍 LOCATION: \(latitude), \(longitude) → REGION: \(region)")
        var events: [HazardAssessment.PerilEvent] = []

        // Get storms that affected this region
        let allStorms = majorHurricanes + majorFloods + majorTornadoes + majorWildfires + majorWinterStorms + majorEarthquakes + majorHailstorms

        let relevantStorms = allStorms.filter { storm in
            storm.region == region || storm.region == .nationwide
        }

        print("🌪️  Found \(relevantStorms.count) storms for region \(region)")

        // Convert to PerilEvent format
        for storm in relevantStorms.prefix(5) {
            if let date = parseDate(storm.date) {
                events.append(HazardAssessment.PerilEvent(
                    type: storm.type,
                    date: date,
                    severity: storm.severity,
                    description: "\(storm.name) - \(storm.description)",
                    damageEstimate: storm.estimatedDamage / 1000000, // Convert to millions
                    affectedRadius: storm.affectedRadius
                ))
                print("   ✓ \(storm.name) (\(storm.type))")
            }
        }

        return events
    }

    private static func determineRegion(latitude: Double, longitude: Double) -> Region {
        // Florida
        if latitude >= 24.5 && latitude <= 31.0 && longitude >= -87.6 && longitude <= -80.0 {
            return .florida
        }

        // Gulf Coast (Texas, Louisiana, Mississippi, Alabama)
        if latitude >= 25.0 && latitude <= 31.0 && longitude >= -97.0 && longitude <= -87.6 {
            return .gulfCoast
        }

        // Texas Coast specific
        if latitude >= 26.0 && latitude <= 30.0 && longitude >= -97.5 && longitude <= -93.8 {
            return .texasCoast
        }

        // Atlantic Coast (Georgia, Carolinas, Virginia, Maryland, Delaware)
        if latitude >= 32.0 && latitude <= 39.7 && longitude >= -81.0 && longitude <= -75.0 {
            return .atlanticCoast
        }

        // Tornado Alley (Oklahoma, Kansas, Nebraska, parts of Texas)
        if latitude >= 33.0 && latitude <= 43.0 && longitude >= -103.0 && longitude <= -94.0 {
            return .tornadoAlley
        }

        // West Coast (California, Oregon, Washington)
        if longitude >= -125.0 && longitude <= -117.0 {
            return .westCoast
        }

        // Northeast (New York, Pennsylvania, New Jersey, Connecticut, etc.)
        if latitude >= 39.7 && latitude <= 47.5 && longitude >= -80.0 && longitude <= -67.0 {
            return .northeast
        }

        // Midwest
        if latitude >= 37.0 && latitude <= 49.0 && longitude >= -104.0 && longitude <= -80.0 {
            return .midwest
        }

        // Southeast
        if latitude >= 30.0 && latitude <= 37.0 && longitude >= -92.0 && longitude <= -75.0 {
            return .southeast
        }

        // Texas (inland)
        if latitude >= 25.8 && latitude <= 36.5 && longitude >= -106.6 && longitude <= -93.5 {
            return .texas
        }

        return .other
    }

    private static func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}

// MARK: - Supporting Types

struct RegionalStorm {
    let region: Region
    let name: String
    let date: String
    let type: HazardAssessment.PerilEvent.PerilType
    let severity: HazardAssessment.PerilEvent.Severity
    let description: String
    let maxWindSpeed: Int
    let estimatedDamage: Double // in dollars
    let affectedRadius: Double // in miles
}

enum Region {
    case florida
    case gulfCoast
    case texasCoast
    case atlanticCoast
    case tornadoAlley
    case westCoast
    case northeast
    case midwest
    case southeast
    case texas
    case nationwide
    case other
}
