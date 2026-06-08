//
//  SentinelDashboard.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import SwiftUI

struct SentinelDashboard: View {
    @State private var viewModel = DashboardViewModel()
    @State private var showingActionPlan = false
    @State private var showingRefresh = false
    @State private var showingInsuranceDetail = false
    let userId: String
    let propertyProfile: PropertyProfile
    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Alert Banner
                    if !viewModel.alertText.isEmpty {
                        AlertBanner(
                            text: viewModel.alertText,
                            severity: viewModel.riskLevel
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture {
                            showingActionPlan = true
                        }
                    }

                    // HVS Gauge Card
                    VStack(spacing: 16) {
                        Text("Home Vulnerability Score")
                            .font(.title2)
                            .fontWeight(.bold)

                        VulnerabilityGauge(score: viewModel.hvsScore, size: 200)

                        Text(viewModel.summaryText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    )

                    // Quick Stats
                    QuickStatsGrid(
                        propertyResilience: propertyProfile.resilienceScore,
                        historicalExposure: viewModel.historicalExposureScore,
                        forecastedSeverity: viewModel.forecastedSeverityScore
                    )

                    // Insurance Savings Card
                    InsuranceSavingsCard(
                        insuranceScore: viewModel.insuranceScore,
                        onTap: {
                            showingInsuranceDetail = true
                        }
                    )

                    // Current Forecasts
                    if let forecasts = viewModel.hazardAssessment?.currentForecasts, !forecasts.isEmpty {
                        ForecastSection(forecasts: forecasts)
                    }

                    // Action Button
                    Button(action: {
                        Task {
                            let success = await viewModel.generateActionPlan(userId: userId)
                            if success {
                                // Navigate to Tasks tab after successful generation
                                withAnimation {
                                    selectedTab = 1
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Generate Action Plan")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.sentinelPrimary)
                        )
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding()
            }
            .navigationTitle("Sentinel")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await viewModel.refreshData(userId: userId)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                await viewModel.loadDashboardData(userId: userId, propertyProfile: propertyProfile)
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $showingInsuranceDetail) {
                if let score = viewModel.insuranceScore {
                    InsuranceScoreView(insuranceScore: score)
                }
            }
        }
    }
}

// MARK: - Alert Banner

struct AlertBanner: View {
    let text: String
    let severity: RiskLevel
    @State private var isVisible = false

    private var bannerColor: Color {
        switch severity {
        case .low: return .green
        case .moderate: return .yellow
        case .elevated: return .orange
        case .high: return .red
        case .critical: return Color(red: 0.5, green: 0, blue: 0)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: severity.icon)
                .font(.title2)
                .foregroundColor(.white)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(3)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(bannerColor)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Quick Stats Grid

struct QuickStatsGrid: View {
    let propertyResilience: Double
    let historicalExposure: Double
    let forecastedSeverity: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Risk Breakdown")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 12) {
                StatCard(
                    title: "Property\nResilience",
                    value: Int(propertyResilience),
                    color: .green,
                    icon: "house.fill"
                )

                StatCard(
                    title: "Historical\nExposure",
                    value: Int(historicalExposure),
                    color: .orange,
                    icon: "clock.fill"
                )

                StatCard(
                    title: "Forecast\nSeverity",
                    value: Int(forecastedSeverity),
                    color: .red,
                    icon: "cloud.bolt.fill"
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text("\(value)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }
}

// MARK: - Forecast Section

struct ForecastSection: View {
    let forecasts: [HazardAssessment.WeatherForecast]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Weather Alerts")
                .font(.headline)
                .padding(.horizontal)

            ForEach(forecasts.prefix(3)) { forecast in
                ForecastCard(forecast: forecast)
            }
        }
    }
}

struct ForecastCard: View {
    let forecast: HazardAssessment.WeatherForecast

    private var alertColor: Color {
        switch forecast.alertLevel {
        case .watch: return .yellow
        case .advisory: return .orange
        case .warning: return .red
        case .emergency: return Color(red: 0.5, green: 0, blue: 0)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(alertColor)

                Text("\(Int(forecast.probability))%")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(forecast.type.rawValue)
                    .font(.headline)

                Text(forecast.alertLevel.rawValue)
                    .font(.subheadline)
                    .foregroundColor(alertColor)

                Text("Expected: \(forecast.expectedDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(alertColor.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            ProgressView()
                .scaleEffect(1.5)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
        }
    }
}

#Preview {
    @Previewable @State var selectedTab = 0
    SentinelDashboard(
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
        ),
        selectedTab: $selectedTab
    )
}
