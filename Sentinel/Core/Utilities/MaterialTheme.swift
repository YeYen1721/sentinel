//
//  MaterialTheme.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import SwiftUI

/// Material Design 3 theme system
struct MaterialTheme {

    // MARK: - Material Design 3 Colors

    /// Primary brand color - Bright blue
    static let primary = Color(hex: "0088FF")
    static let onPrimary = Color.white

    /// Secondary accent color
    static let secondary = Color(hex: "03DAC6")
    static let onSecondary = Color.black

    /// Background colors
    static let background = Color(hex: "FAFAFA")
    static let surface = Color.white
    static let surfaceVariant = Color(hex: "F5F5F5")

    /// Text colors
    static let onBackground = Color(hex: "1C1B1F")
    static let onSurface = Color(hex: "1C1B1F")
    static let onSurfaceVariant = Color(hex: "49454F")

    /// Outline colors
    static let outline = Color(hex: "79747E")
    static let outlineVariant = Color(hex: "CAC4D0")

    // MARK: - Semantic Risk Colors (Material Design)

    static let riskCritical = Color(hex: "F26565")
    static let riskModerate = Color(hex: "F4A348")
    static let riskLow = Color(hex: "37B871")
    static let riskSafe = Color(hex: "0088FF")

    // MARK: - Material Design Elevation

    /// Shadow for elevation level 1 (subtle)
    static let elevation1 = Shadow(
        color: Color.black.opacity(0.05),
        radius: 1,
        y: 1
    )

    /// Shadow for elevation level 2 (cards)
    static let elevation2 = Shadow(
        color: Color.black.opacity(0.08),
        radius: 2,
        y: 2
    )

    /// Shadow for elevation level 3 (elevated cards)
    static let elevation3 = Shadow(
        color: Color.black.opacity(0.12),
        radius: 4,
        y: 4
    )

    // MARK: - Material Design Corner Radius

    static let cornerRadiusXS: CGFloat = 4
    static let cornerRadiusS: CGFloat = 8
    static let cornerRadiusM: CGFloat = 12
    static let cornerRadiusL: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 28

    // MARK: - Material Design Spacing

    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    init(color: Color, radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - Material Design View Modifiers

struct MaterialCardModifier: ViewModifier {
    var elevation: Shadow = MaterialTheme.elevation2
    var cornerRadius: CGFloat = MaterialTheme.cornerRadiusM
    var backgroundColor: Color = MaterialTheme.surface

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: elevation.color,
                radius: elevation.radius,
                x: elevation.x,
                y: elevation.y
            )
    }
}

struct MaterialFilledButtonStyle: ButtonStyle {
    var backgroundColor: Color = MaterialTheme.primary
    var foregroundColor: Color = MaterialTheme.onPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, MaterialTheme.spacing24)
            .padding(.vertical, MaterialTheme.spacing12)
            .background(
                RoundedRectangle(cornerRadius: MaterialTheme.cornerRadiusXL)
                    .fill(backgroundColor)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct MaterialOutlinedButtonStyle: ButtonStyle {
    var borderColor: Color = MaterialTheme.primary
    var foregroundColor: Color = MaterialTheme.primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, MaterialTheme.spacing24)
            .padding(.vertical, MaterialTheme.spacing12)
            .background(
                RoundedRectangle(cornerRadius: MaterialTheme.cornerRadiusXL)
                    .stroke(borderColor, lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: MaterialTheme.cornerRadiusXL)
                            .fill(MaterialTheme.surface)
                            .opacity(configuration.isPressed ? 0.1 : 0)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func materialCard(
        elevation: Shadow = MaterialTheme.elevation2,
        cornerRadius: CGFloat = MaterialTheme.cornerRadiusM,
        backgroundColor: Color = MaterialTheme.surface
    ) -> some View {
        self.modifier(MaterialCardModifier(
            elevation: elevation,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor
        ))
    }

    func materialFilledButton(
        backgroundColor: Color = MaterialTheme.primary,
        foregroundColor: Color = MaterialTheme.onPrimary
    ) -> some View {
        self.buttonStyle(MaterialFilledButtonStyle(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        ))
    }

    func materialOutlinedButton(
        borderColor: Color = MaterialTheme.primary,
        foregroundColor: Color = MaterialTheme.primary
    ) -> some View {
        self.buttonStyle(MaterialOutlinedButtonStyle(
            borderColor: borderColor,
            foregroundColor: foregroundColor
        ))
    }
}
