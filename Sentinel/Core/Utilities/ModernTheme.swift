//
//  ModernTheme.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import SwiftUI

/// Modern Apple Design System with proper spacing and margins
struct ModernTheme {

    // MARK: - Colors

    /// Primary brand color
    static let primary = Color(hex: "0088FF")
    static let primaryLight = Color(hex: "0088FF").opacity(0.1)

    /// Background colors
    static let background = Color(hex: "F5F7FA")
    static let surface = Color.white
    static let surfaceElevated = Color.white

    /// Text colors
    static let textPrimary = Color(hex: "1A1A1A")
    static let textSecondary = Color(hex: "6B7280")
    static let textTertiary = Color(hex: "9CA3AF")

    /// Semantic colors
    static let success = Color(hex: "10B981")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")
    static let info = Color(hex: "3B82F6")

    // MARK: - Spacing Scale

    /// 4pt spacing scale for consistency
    static let spacing2: CGFloat = 2
    static let spacing4: CGFloat = 4
    static let spacing6: CGFloat = 6
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    static let spacing40: CGFloat = 40
    static let spacing48: CGFloat = 48
    static let spacing64: CGFloat = 64

    // MARK: - Layout Margins

    /// Consistent page margins
    static let marginHorizontal: CGFloat = 20
    static let marginVertical: CGFloat = 16

    /// Card padding
    static let cardPaddingSmall: CGFloat = 12
    static let cardPaddingMedium: CGFloat = 16
    static let cardPaddingLarge: CGFloat = 20

    // MARK: - Corner Radius

    static let radiusSmall: CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge: CGFloat = 16
    static let radiusXLarge: CGFloat = 20
    static let radiusFull: CGFloat = 999

    // MARK: - Shadows

    static let shadowSmall = Shadow(
        color: Color.black.opacity(0.04),
        radius: 4,
        y: 2
    )

    static let shadowMedium = Shadow(
        color: Color.black.opacity(0.06),
        radius: 8,
        y: 4
    )

    static let shadowLarge = Shadow(
        color: Color.black.opacity(0.08),
        radius: 16,
        y: 8
    )

    // MARK: - Typography Scale

    /// Display text (large headers)
    static func displayFont(size: CGFloat = 32, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Title text
    static func titleFont(size: CGFloat = 24, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Headline text
    static func headlineFont(size: CGFloat = 17, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Body text
    static func bodyFont(size: CGFloat = 15, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Caption text
    static func captionFont(size: CGFloat = 13, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Label text (small)
    static func labelFont(size: CGFloat = 11, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

// MARK: - View Modifiers

struct ModernCardModifier: ViewModifier {
    var padding: CGFloat = ModernTheme.cardPaddingMedium
    var shadow: Shadow = ModernTheme.shadowMedium

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(ModernTheme.surface)
            .cornerRadius(ModernTheme.radiusLarge)
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
}

struct ModernButtonStyle: ButtonStyle {
    var backgroundColor: Color = ModernTheme.primary
    var foregroundColor: Color = .white
    var height: CGFloat = 52

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ModernTheme.headlineFont())
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(
                RoundedRectangle(cornerRadius: ModernTheme.radiusMedium)
                    .fill(backgroundColor)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ModernBadgeModifier: ViewModifier {
    var count: Int
    var color: Color = ModernTheme.primary

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if count > 0 {
                    Text("\(count)")
                        .font(ModernTheme.labelFont(weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, count > 9 ? 6 : 0)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(
                            Circle()
                                .fill(color)
                        )
                        .offset(x: 8, y: -8)
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    func modernCard(
        padding: CGFloat = ModernTheme.cardPaddingMedium,
        shadow: Shadow = ModernTheme.shadowMedium
    ) -> some View {
        self.modifier(ModernCardModifier(padding: padding, shadow: shadow))
    }

    func modernButton(
        backgroundColor: Color = ModernTheme.primary,
        foregroundColor: Color = .white,
        height: CGFloat = 52
    ) -> some View {
        self.buttonStyle(ModernButtonStyle(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            height: height
        ))
    }

    func modernBadge(
        count: Int,
        color: Color = ModernTheme.primary
    ) -> some View {
        self.modifier(ModernBadgeModifier(count: count, color: color))
    }
}

// MARK: - Reusable Components

struct ModernAvatar: View {
    let initials: String
    let size: CGFloat
    var backgroundColor: Color = ModernTheme.primary

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor.opacity(0.1))

            Text(initials)
                .font(ModernTheme.bodyFont(weight: .semibold))
                .foregroundColor(backgroundColor)
        }
        .frame(width: size, height: size)
    }
}

struct ModernChip: View {
    let text: String
    let icon: String?
    var color: Color = ModernTheme.primary
    var isSelected: Bool = false

    init(text: String, icon: String? = nil, color: Color = ModernTheme.primary, isSelected: Bool = false) {
        self.text = text
        self.icon = icon
        self.color = color
        self.isSelected = isSelected
    }

    var body: some View {
        HStack(spacing: ModernTheme.spacing6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(ModernTheme.captionFont(weight: .semibold))
            }

            Text(text)
                .font(ModernTheme.captionFont(weight: .medium))
        }
        .foregroundColor(isSelected ? .white : color)
        .padding(.horizontal, ModernTheme.spacing12)
        .padding(.vertical, ModernTheme.spacing6)
        .background(
            Capsule()
                .fill(isSelected ? color : color.opacity(0.1))
        )
    }
}

struct ModernSectionHeader: View {
    let title: String
    let action: (() -> Void)?
    let actionTitle: String?

    init(title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack {
            Text(title)
                .font(ModernTheme.titleFont(size: 20))
                .foregroundColor(ModernTheme.textPrimary)

            Spacer()

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(ModernTheme.bodyFont(weight: .medium))
                        .foregroundColor(ModernTheme.primary)
                }
            }
        }
        .padding(.horizontal, ModernTheme.marginHorizontal)
    }
}
