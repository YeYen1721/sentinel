//
//  PerilEventDetailView.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import SwiftUI
import MapKit

struct PerilEventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let event: HazardAssessment.PerilEvent

    private var severityColor: Color {
        switch event.severity {
        case .minor: return .green
        case .moderate: return .yellow
        case .severe: return .orange
        case .catastrophic: return .red
        }
    }

    private var perilIcon: String {
        switch event.type {
        case .hurricane: return "hurricane"
        case .tornado: return "tornado"
        case .flood: return "water.waves"
        case .wildfire: return "flame.fill"
        case .earthquake: return "earthquake"
        case .hailstorm: return "cloud.hail.fill"
        case .winterStorm: return "snowflake"
        case .severeThunderstorm: return "cloud.bolt.fill"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: perilIcon)
                            .font(.system(size: 60))
                            .foregroundColor(severityColor)
                            .padding()
                            .background(
                                Circle()
                                    .fill(severityColor.opacity(0.1))
                            )

                        Text(event.type.rawValue)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(event.date.formatted(date: .long, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Severity Badge
                        Text(event.severity.rawValue)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(severityColor)
                            )
                    }
                    .padding()

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)

                        Text(event.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)

                    // Details Grid
                    VStack(spacing: 16) {
                        if let damage = event.damageEstimate {
                            DetailRow(
                                icon: "dollarsign.circle.fill",
                                title: "Estimated Damage",
                                value: "$\(Int(damage).formatted())",
                                color: .orange
                            )
                        }

                        DetailRow(
                            icon: "location.circle.fill",
                            title: "Affected Radius",
                            value: "\(Int(event.affectedRadius)) miles",
                            color: .blue
                        )

                        DetailRow(
                            icon: "gauge.high",
                            title: "Severity Score",
                            value: "\(Int(event.severity.score))/100",
                            color: severityColor
                        )

                        DetailRow(
                            icon: "calendar",
                            title: "Years Ago",
                            value: "\(Calendar.current.dateComponents([.year], from: event.date, to: Date()).year ?? 0) years",
                            color: .secondary
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    )
                    .padding(.horizontal)

                    // Mitigation Recommendations
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Recommended Actions", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundColor(.orange)

                        Text(getMitigationRecommendations())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func getMitigationRecommendations() -> String {
        switch event.type {
        case .hurricane:
            return "Ensure storm shutters are installed, reinforce roof connections, trim trees near the home, and maintain an emergency supply kit."
        case .tornado:
            return "Identify a safe room or shelter area, secure outdoor items, and consider a tornado-resistant safe room installation."
        case .flood:
            return "Install sump pumps, elevate utilities, consider flood barriers, and ensure proper drainage around the property."
        case .wildfire:
            return "Create defensible space around your home, use fire-resistant materials, clear gutters regularly, and maintain an evacuation plan."
        case .earthquake:
            return "Secure heavy furniture, reinforce foundation, install flexible gas lines, and maintain emergency supplies."
        case .hailstorm:
            return "Inspect and upgrade roof to impact-resistant materials, protect windows with shutters, and cover vehicles."
        case .winterStorm:
            return "Insulate pipes, maintain heating systems, stock emergency supplies, and ensure roof can handle snow load."
        case .severeThunderstorm:
            return "Trim trees, secure loose outdoor items, install surge protectors, and maintain proper drainage."
        }
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.headline)
            }

            Spacer()
        }
    }
}

#Preview {
    PerilEventDetailView(
        event: HazardAssessment.PerilEvent(
            type: .hurricane,
            date: Calendar.current.date(byAdding: .year, value: -2, to: Date())!,
            severity: .severe,
            description: "Hurricane Ian caused significant damage to the region with sustained winds of 150 mph",
            damageEstimate: 15000,
            affectedRadius: 50
        )
    )
}
