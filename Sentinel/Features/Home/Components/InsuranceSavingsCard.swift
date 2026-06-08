//
//  InsuranceSavingsCard.swift
//  Sentinel
//
//  Compact insurance savings card for dashboard
//

import SwiftUI

struct InsuranceSavingsCard: View {
    let insuranceScore: InsuranceScore?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.downtrend.xyaxis.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(hex: "#10B981"))

                        Text("Insurance Savings")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 16)

                if let score = insuranceScore {
                    VStack(spacing: 16) {
                        // Annual Savings Row
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Annual Savings")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)

                                AnimatedSavingsText(value: score.totalAnnualSavings)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color(hex: "#10B981"))
                            }

                            Spacer()

                            // Readiness Badge
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Readiness")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 4) {
                                    Image(systemName: score.readinessLevel.icon)
                                        .font(.system(size: 14))

                                    Text("\(Int(score.readinessScore))%")
                                        .font(.system(size: 18, weight: .bold))
                                }
                                .foregroundStyle(Color(hex: score.readinessLevel.color))
                            }
                        }

                        Divider()

                        // Quick Stats
                        HStack(spacing: 20) {
                            // Monthly Savings
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Monthly")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)

                                Text(String(format: "$%.0f", score.totalMonthlySavings))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color(hex: "#10B981"))
                            }

                            Divider()
                                .frame(height: 30)

                            // Lifetime Savings
                            VStack(alignment: .leading, spacing: 2) {
                                Text("30-Year")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)

                                Text(String(format: "$%.0fK", score.lifetimeSavings / 1000))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color(hex: "#10B981"))
                            }

                            Spacer()
                        }

                        // Progress Bar
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Completed \(score.savingsItems.count) of \(score.savingsItems.count + score.potentialSavings.count) tasks")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text("\(Int(score.savingsPercentage))%")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color(hex: "#10B981"))
                            }

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: "#10B981").opacity(0.15))
                                        .frame(height: 6)

                                    // Progress
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color(hex: "#10B981"))
                                        .frame(width: geometry.size.width * (score.readinessScore / 100), height: 6)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: score.readinessScore)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                } else {
                    // Loading State
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(Color(hex: "#10B981"))

                        Text("Calculating insurance savings...")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#10B981").opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Animated text that counts up
struct AnimatedSavingsText: View {
    let value: Double
    @State private var displayValue: Double = 0

    var body: some View {
        Text(String(format: "$%.0f", displayValue))
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { oldValue, newValue in
                withAnimation(.easeOut(duration: 0.5)) {
                    displayValue = newValue
                }
            }
    }
}

// Scale button style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 20) {
        // With data
        InsuranceSavingsCard(
            insuranceScore: InsuranceScore(
                basePremium: 2400,
                currentPremium: 2100,
                totalAnnualSavings: 300,
                totalMonthlySavings: 25,
                lifetimeSavings: 9000,
                readinessScore: 65,
                readinessLevel: .good,
                savingsItems: [
                    InsuranceSavingItem(
                        taskTitle: "Install Storm Shutters",
                        category: .high,
                        annualSavings: 150,
                        completedDate: Date(),
                        description: "Test"
                    ),
                    InsuranceSavingItem(
                        taskTitle: "Roof Inspection",
                        category: .high,
                        annualSavings: 150,
                        completedDate: Date(),
                        description: "Test"
                    )
                ],
                potentialSavings: [
                    InsuranceSavingItem(
                        taskTitle: "Backup Generator",
                        category: .medium,
                        annualSavings: 100,
                        description: "Test"
                    )
                ],
                locationRiskMultiplier: 1.8,
                propertyAgeMultiplier: 1.2,
                riskZoneDescription: "High Hurricane Zone",
                lastCalculated: Date(),
                zipCode: nil
            ),
            onTap: {}
        )

        // Loading state
        InsuranceSavingsCard(insuranceScore: nil, onTap: {})
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
