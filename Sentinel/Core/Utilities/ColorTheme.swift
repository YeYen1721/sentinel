//
//  ColorTheme.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import SwiftUI

/// App color theme with semantic colors and primary brand color
extension Color {

    // MARK: - Primary Brand Color

    /// Primary brand color - Bright blue
    static let sentinelPrimary = Color(hex: "0088FF")

    // MARK: - Semantic Colors for Risk Levels

    /// Critical/High risk - Red/Coral
    static let riskCritical = Color(hex: "F26565")

    /// Medium/Moderate risk - Orange/Amber
    static let riskModerate = Color(hex: "F4A348")

    /// Low/Good risk - Green
    static let riskLow = Color(hex: "37B871")

    /// Safe/Excellent - Bright blue (matching primary)
    static let riskSafe = Color(hex: "0088FF")

    // MARK: - Helper for HVS Score Colors

    /// Get color based on Home Vulnerability Score (0-100)
    /// - Parameter hvs: Home Vulnerability Score
    /// - Returns: Appropriate color for the score
    static func colorForHVS(_ hvs: Double) -> Color {
        switch hvs {
        case 0..<40:
            return .riskCritical  // High risk (low HVS)
        case 40..<60:
            return .riskModerate  // Moderate risk
        case 60..<80:
            return .riskLow       // Low risk (good HVS)
        case 80...100:
            return .riskSafe      // Excellent (very high HVS)
        default:
            return .riskModerate
        }
    }

}

// MARK: - Hex Color Initializer

extension Color {
    /// Initialize Color from hex string
    /// - Parameter hex: Hex string (e.g., "3E2B7E" or "#3E2B7E")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
