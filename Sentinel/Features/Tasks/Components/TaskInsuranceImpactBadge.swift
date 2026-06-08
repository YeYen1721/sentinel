//
//  TaskInsuranceImpactBadge.swift
//  Sentinel
//
//  Badge component to display insurance savings on tasks
//

import SwiftUI

struct TaskInsuranceImpactBadge: View {
    let task: MitigationTask
    let compact: Bool

    init(task: MitigationTask, compact: Bool = false) {
        self.task = task
        self.compact = compact
    }

    var body: some View {
        if task.hasInsuranceImpact {
            if compact {
                // Compact badge for list views
                HStack(spacing: 3) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#10B981"))

                    Text(task.insuranceSavingsText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(hex: "#10B981"))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color(hex: "#10B981").opacity(0.12))
                .clipShape(Capsule())
            } else {
                // Full badge for detail views
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "#10B981"))

                        Text("Insurance Savings")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        // Annual savings
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Annual")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)

                            Text(String(format: "$%.0f", task.estimatedInsuranceSavings ?? 0))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "#10B981"))
                        }

                        Divider()
                            .frame(height: 30)

                        // Monthly savings
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Monthly")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)

                            Text(String(format: "$%.0f", task.estimatedMonthlySavings ?? 0))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "#10B981"))
                        }

                        Spacer()

                        // Impact category badge
                        if let category = task.insuranceImpactCategory {
                            Text(category)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: task.insuranceCategoryColor))
                                .clipShape(Capsule())
                        }
                    }

                    if let description = task.insuranceImpactDescription {
                        Text(description)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(12)
                .background(Color(hex: "#10B981").opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#10B981").opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Compact badge
        TaskInsuranceImpactBadge(
            task: MitigationTask(
                title: "Install Storm Shutters",
                description: "Test task",
                priority: .high,
                category: .structural,
                status: .notStarted,
                isAIGenerated: true,
                userId: "test",
                notes: "",
                createdAt: Date(),
                updatedAt: Date(),
                estimatedInsuranceSavings: 250,
                insuranceImpactCategory: "High",
                insuranceImpactPercentage: 12,
                insuranceImpactDescription: "Storm shutters protect windows and prevent interior water damage"
            ),
            compact: true
        )

        // Full badge
        TaskInsuranceImpactBadge(
            task: MitigationTask(
                title: "Install Storm Shutters",
                description: "Test task",
                priority: .high,
                category: .structural,
                status: .notStarted,
                isAIGenerated: true,
                userId: "test",
                notes: "",
                createdAt: Date(),
                updatedAt: Date(),
                estimatedInsuranceSavings: 250,
                insuranceImpactCategory: "High",
                insuranceImpactPercentage: 12,
                insuranceImpactDescription: "Storm shutters protect windows and prevent interior water damage"
            ),
            compact: false
        )
    }
    .padding()
}
