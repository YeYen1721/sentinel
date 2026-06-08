//
//  HistoricalTimeline.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import SwiftUI

struct HistoricalTimeline: View {
    @State private var hazardAssessment: HazardAssessment?
    @State private var isLoading = false
    @State private var selectedEvent: HazardAssessment.PerilEvent?
    let userId: String
    let propertyProfile: PropertyProfile

    // Use real service to show actual historical events
    private let riskDataService: RiskDataServiceProtocol = {
        if APIConfiguration.hasRealAPIs {
            return RealRiskDataService()
        } else {
            return MockRiskDataService()
        }
    }()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let assessment = hazardAssessment {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Summary Card
                            TimelineSummaryCard(
                                totalEvents: assessment.historicalPerils.count,
                                exposureScore: assessment.historicalExposureScore
                            )

                            // Recommended Actions based on risks
                            RecommendedActionsCard(
                                hazardAssessment: assessment,
                                propertyProfile: propertyProfile
                            )

                            // Timeline
                            if assessment.historicalPerils.isEmpty {
                                EmptyHistoryView()
                            } else {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Historical Events")
                                        .font(.headline)
                                        .padding(.horizontal)

                                    ForEach(assessment.historicalPerils.sorted(by: { $0.date > $1.date })) { event in
                                        TimelineEventCard(event: event)
                                            .onTapGesture {
                                                selectedEvent = event
                                            }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "No Data Available",
                        systemImage: "clock.badge.exclamationmark",
                        description: Text("Unable to load historical data")
                    )
                }
            }
            .navigationTitle("Historical Timeline")
            .sheet(item: $selectedEvent) { event in
                PerilEventDetailView(event: event)
            }
            .task {
                await loadHistoricalData()
            }
        }
    }

    @MainActor
    private func loadHistoricalData() async {
        isLoading = true
        do {
            hazardAssessment = try await riskDataService.fetchHazardAssessment(
                latitude: propertyProfile.latitude,
                longitude: propertyProfile.longitude
            )
        } catch {
            print("Error loading historical data: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Timeline Summary Card

struct TimelineSummaryCard: View {
    let totalEvents: Int
    let exposureScore: Double

    private var exposureLevel: String {
        switch exposureScore {
        case 0..<25: return "Low"
        case 25..<50: return "Moderate"
        case 50..<75: return "High"
        default: return "Very High"
        }
    }

    private var exposureColor: Color {
        switch exposureScore {
        case 0..<25: return .green
        case 25..<50: return .yellow
        case 50..<75: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Events (15 years)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(totalEvents)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Exposure Level")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(exposureLevel)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(exposureColor)
                }
            }

            // Exposure Score Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 8)
                        .fill(exposureColor)
                        .frame(width: geometry.size.width * (exposureScore / 100))
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: exposureScore)
                }
            }
            .frame(height: 12)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
    }
}

// MARK: - Timeline Event Card

struct TimelineEventCard: View {
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
        HStack(spacing: 16) {
            // Timeline Indicator
            VStack {
                Circle()
                    .fill(severityColor)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemBackground), lineWidth: 3)
                    )

                Rectangle()
                    .fill(severityColor.opacity(0.3))
                    .frame(width: 2)
            }

            // Event Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: perilIcon)
                        .font(.title2)
                        .foregroundColor(severityColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.type.rawValue)
                            .font(.headline)

                        Text(event.date.formatted(date: .long, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Severity Badge
                    Text(event.severity.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(severityColor)
                        )
                }

                Text(event.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    if let damage = event.damageEstimate {
                        Label("$\(Int(damage))", systemImage: "dollarsign.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Label("\(Int(event.affectedRadius)) mi radius", systemImage: "location.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
            )
        }
        .padding(.leading)
    }
}

// MARK: - Empty History View

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("No Historical Events")
                .font(.title2)
                .fontWeight(.semibold)

            Text("This area has no recorded severe weather events in the past 15 years")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(40)
    }
}

// MARK: - Recommended Actions Card

struct RecommendedActionsCard: View {
    let hazardAssessment: HazardAssessment
    let propertyProfile: PropertyProfile

    fileprivate struct RecommendedAction {
        let title: String
        let deadline: String
        let urgency: String
        let reason: String
        let icon: String
        let color: Color
    }

    private var recommendedActions: [RecommendedAction] {
        var actions: [RecommendedAction] = []

        // Determine urgency based on risk scores and upcoming forecasts
        let hurricaneRisk = hazardAssessment.riskScores.hurricane
        let floodRisk = hazardAssessment.riskScores.flood
        let tornadoRisk = hazardAssessment.riskScores.tornado

        let hasUpcomingWeather = !hazardAssessment.currentForecasts.isEmpty
        let hasRecentEvents = !hazardAssessment.historicalPerils.isEmpty

        // Hurricane preparation
        if hurricaneRisk >= 60 {
            let deadline = hasUpcomingWeather ? "Complete within 1 month" : "Complete within 2 months"
            actions.append(RecommendedAction(
                title: "Hurricane Preparedness",
                deadline: deadline,
                urgency: "High Priority",
                reason: "Area has high hurricane risk (\(Int(hurricaneRisk))/100)",
                icon: "hurricane",
                color: .orange
            ))
        }

        // Flood mitigation
        if floodRisk >= 60 {
            let deadline = hasRecentEvents ? "Complete within 2 weeks" : "Complete within 1 month"
            actions.append(RecommendedAction(
                title: "Flood Protection",
                deadline: deadline,
                urgency: hasRecentEvents ? "Urgent" : "High Priority",
                reason: "Area has flood risk (\(Int(floodRisk))/100)",
                icon: "water.waves",
                color: .blue
            ))
        }

        // Tornado safety
        if tornadoRisk >= 60 {
            let deadline = "Complete within 2 weeks"
            actions.append(RecommendedAction(
                title: "Tornado Safety Plan",
                deadline: deadline,
                urgency: "High Priority",
                reason: "Area has tornado risk (\(Int(tornadoRisk))/100)",
                icon: "tornado",
                color: .red
            ))
        }

        // Roof maintenance (based on age and risk)
        if propertyProfile.roofAge > 15 || hurricaneRisk >= 50 {
            let deadline = hurricaneRisk >= 70 ? "Complete within 1 month" : "Complete within 3 months"
            actions.append(RecommendedAction(
                title: "Roof Inspection & Repair",
                deadline: deadline,
                urgency: propertyProfile.roofAge > 20 ? "Urgent" : "Medium Priority",
                reason: "Roof is \(propertyProfile.roofAge) years old",
                icon: "house.fill",
                color: .purple
            ))
        }

        // Emergency preparedness (always important)
        if hasUpcomingWeather || hasRecentEvents {
            actions.append(RecommendedAction(
                title: "Emergency Kit & Plan",
                deadline: "Complete within 1 week",
                urgency: "High Priority",
                reason: "Active weather alerts in your area",
                icon: "exclamationmark.triangle.fill",
                color: .orange
            ))
        }

        return actions
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.title3)
                    .foregroundColor(.sentinelPrimary)

                Text("Recommended Actions & Deadlines")
                    .font(.headline)
            }
            .padding(.horizontal)

            if recommendedActions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)

                    Text("No urgent actions needed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(recommendedActions.indices, id: \.self) { index in
                        RecommendedActionRow(action: recommendedActions[index])
                    }
                }
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
        .padding(.horizontal)
    }
}

struct RecommendedActionRow: View {
    fileprivate let action: RecommendedActionsCard.RecommendedAction

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: action.icon)
                .font(.title2)
                .foregroundColor(action.color)
                .frame(width: 40, height: 40)
                .background(action.color.opacity(0.1))
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack {
                    Text(action.urgency)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(action.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(action.color.opacity(0.1))
                        .clipShape(Capsule())

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(action.deadline)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(action.reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

#Preview {
    HistoricalTimeline(
        userId: "preview-user",
        propertyProfile: PropertyProfile(
            address: "123 Main St",
            latitude: 25.7617,
            longitude: -80.1918,
            roofMaterial: .asphaltShingles,
            roofAge: 10,
            foundationType: .slab,
            yearBuilt: 2005,
            squareFootage: 2400,
            stories: 2,
            hasBasement: false,
            exteriorMaterial: .stucco,
            hasStormShutters: false,
            hasBackupGenerator: false,
            hasSmartHomeMonitoring: true,
            userId: "preview-user",
            createdAt: Date(),
            updatedAt: Date()
        )
    )
}
