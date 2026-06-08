//
//  InsuranceScoreView.swift
//  Sentinel
//
//  Detailed insurance score and savings view
//

import SwiftUI

struct InsuranceScoreView: View {
    let insuranceScore: InsuranceScore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section - Readiness Score
                    ReadinessScoreCard(score: insuranceScore)

                    // Annual Savings Overview
                    SavingsOverviewCard(score: insuranceScore)

                    // Premium Breakdown
                    PremiumBreakdownCard(score: insuranceScore)

                    // Completed Improvements
                    if !insuranceScore.savingsItems.isEmpty {
                        SavingsBreakdownSection(
                            title: "Completed Improvements",
                            subtitle: "Savings you've already earned",
                            items: insuranceScore.savingsItems,
                            showCompletedDate: true
                        )
                    }

                    // Potential Savings
                    if !insuranceScore.potentialSavings.isEmpty {
                        SavingsBreakdownSection(
                            title: "Potential Savings",
                            subtitle: "Complete these tasks to save more",
                            items: insuranceScore.potentialSavings,
                            showCompletedDate: false
                        )
                    }

                    // Risk Factors
                    RiskFactorsCard(score: insuranceScore)

                    // Info Footer
                    InfoFooter()
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Insurance Savings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Readiness Score Card

struct ReadinessScoreCard: View {
    let score: InsuranceScore

    var body: some View {
        VStack(spacing: 20) {
            // Score Gauge
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Color(hex: score.readinessLevel.color).opacity(0.2), lineWidth: 16)
                    .frame(width: 160, height: 160)

                // Progress Circle
                Circle()
                    .trim(from: 0, to: score.readinessScore / 100)
                    .stroke(
                        Color(hex: score.readinessLevel.color),
                        style: StrokeStyle(lineWidth: 16, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.7), value: score.readinessScore)

                // Score Text
                VStack(spacing: 4) {
                    Text("\(Int(score.readinessScore))")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: score.readinessLevel.color))

                    Text("Score")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            // Status Badge
            HStack(spacing: 8) {
                Image(systemName: score.readinessLevel.icon)
                    .font(.system(size: 16, weight: .semibold))

                Text(score.readinessLevel.rawValue)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(Color(hex: score.readinessLevel.color))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(hex: score.readinessLevel.color).opacity(0.15))
            .clipShape(Capsule())

            Text("Insurance Readiness Score")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Savings Overview Card

struct SavingsOverviewCard: View {
    let score: InsuranceScore

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Your Savings")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
            }

            // Annual Savings
            VStack(alignment: .leading, spacing: 8) {
                Text("Annual Savings")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                Text(String(format: "$%.0f", score.totalAnnualSavings))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#10B981"))

                Text(String(format: "%.1f%% reduction in premiums", score.savingsPercentage))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Monthly & Lifetime
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Monthly")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Text(String(format: "$%.0f", score.totalMonthlySavings))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#10B981"))

                    Text("per month")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 60)

                VStack(alignment: .leading, spacing: 8) {
                    Text("30-Year Total")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Text(String(format: "$%.0fK", score.lifetimeSavings / 1000))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#10B981"))

                    Text("lifetime savings")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Premium Breakdown Card

struct PremiumBreakdownCard: View {
    let score: InsuranceScore

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Premium Breakdown")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
            }

            // Base Premium
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Base Premium")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    Text(String(format: "$%.0f/year", score.basePremium))
                        .font(.system(size: 20, weight: .semibold))
                }

                Spacer()

                Image(systemName: "house.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .padding(16)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Minus Savings
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Improvements")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#10B981"))

                    Text(String(format: "-$%.0f/year", score.totalAnnualSavings))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(hex: "#10B981"))
                }

                Spacer()

                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color(hex: "#10B981"))
            }
            .padding(16)
            .background(Color(hex: "#10B981").opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Divider()

            // Current Premium
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Premium")
                        .font(.system(size: 14, weight: .medium))

                    Text(String(format: "$%.0f/year", score.currentPremium))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "$%.0f", score.currentPremium / 12))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.secondary)

                    Text("per month")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 2)
            )
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Savings Breakdown Section

struct SavingsBreakdownSection: View {
    let title: String
    let subtitle: String
    let items: [InsuranceSavingItem]
    let showCompletedDate: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(items) { item in
                    SavingsItemRow(item: item, showCompletedDate: showCompletedDate)
                }
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct SavingsItemRow: View {
    let item: InsuranceSavingItem
    let showCompletedDate: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(Color(hex: item.category.color).opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: showCompletedDate ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: item.category.color))
            }

            // Task Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.taskTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)

                if showCompletedDate, let date = item.completedDate {
                    Text("Completed \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                } else {
                    Text(item.category.rawValue + " Impact")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Savings Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.0f", item.annualSavings))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "#10B981"))

                Text("/year")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Risk Factors Card

struct RiskFactorsCard: View {
    let score: InsuranceScore

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Risk Factors Affecting Premium")
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
            }

            VStack(spacing: 12) {
                // Location Risk
                RiskFactorRow(
                    icon: "mappin.circle.fill",
                    title: "Location Risk",
                    value: String(format: "%.1fx", score.locationRiskMultiplier),
                    description: score.riskZoneDescription,
                    color: score.locationRiskMultiplier > 2.0 ? "#DC2626" : score.locationRiskMultiplier > 1.5 ? "#F59E0B" : "#10B981"
                )

                // Property Age
                RiskFactorRow(
                    icon: "calendar.circle.fill",
                    title: "Property Age",
                    value: String(format: "%.1fx", score.propertyAgeMultiplier),
                    description: "Age-based premium adjustment",
                    color: score.propertyAgeMultiplier > 1.3 ? "#F59E0B" : "#10B981"
                )
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct RiskFactorRow: View {
    let icon: String
    let title: String
    let value: String
    let description: String
    let color: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Color(hex: color))
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))

                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(hex: color))
        }
        .padding(12)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Info Footer

struct InfoFooter: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                Text("How Savings Are Calculated")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text("Insurance savings are estimated based on industry standards and typical premium reductions for home improvements. Actual savings may vary by insurer. Contact your insurance provider for personalized quotes.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .padding(20)
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    InsuranceScoreView(
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
                    description: "Storm shutters protect windows"
                ),
                InsuranceSavingItem(
                    taskTitle: "Roof Inspection and Repair",
                    category: .critical,
                    annualSavings: 150,
                    completedDate: Date(),
                    description: "Roof maintenance"
                )
            ],
            potentialSavings: [
                InsuranceSavingItem(
                    taskTitle: "Install Backup Generator",
                    category: .medium,
                    annualSavings: 100,
                    description: "Generator for power outages"
                ),
                InsuranceSavingItem(
                    taskTitle: "Smart Home Monitoring",
                    category: .medium,
                    annualSavings: 80,
                    description: "Smart sensors"
                )
            ],
            locationRiskMultiplier: 1.8,
            propertyAgeMultiplier: 1.2,
            riskZoneDescription: "High Hurricane Zone, High Flood Zone",
            lastCalculated: Date(),
            zipCode: nil
        )
    )
}
