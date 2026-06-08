//
//  ProfileView.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @State private var showingPropertyEdit = false
    let userId: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // User Info Card
                    UserInfoCard(userId: userId)

                    // Property Resilience Score
                    if let profile = viewModel.propertyProfile {
                        ResilienceScoreCard(score: profile.resilienceScore)
                    }

                    // Property Details
                    if let profile = viewModel.propertyProfile {
                        PropertyDetailsSection(profile: profile) {
                            showingPropertyEdit = true
                        }
                    }

                    // Settings Section
                    SettingsSection()
                }
                .padding()
            }
            .navigationTitle("Profile")
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
            .sheet(isPresented: $showingPropertyEdit) {
                if let profile = viewModel.propertyProfile {
                    PropertyEditView(profile: profile) { updatedProfile in
                        Task {
                            await viewModel.saveProfile(updatedProfile)
                        }
                    }
                }
            }
            .task {
                await viewModel.loadProfile(userId: userId)
            }
            .alert("Success", isPresented: .constant(viewModel.successMessage != nil)) {
                Button("OK") {
                    viewModel.successMessage = nil
                }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - User Info Card

struct UserInfoCard: View {
    let userId: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("User Account")
                .font(.title2)
                .fontWeight(.bold)

            Text(userId)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
    }
}

// MARK: - Resilience Score Card

struct ResilienceScoreCard: View {
    let score: Double

    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Property Resilience Score")
                .font(.headline)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: score / 100)
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(score))")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(scoreColor)
            }

            Text(getScoreDescription())
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
    }

    private func getScoreDescription() -> String {
        switch score {
        case 80...100: return "Excellent - Your property has strong resilience features"
        case 60..<80: return "Good - Consider some improvements for better protection"
        case 40..<60: return "Fair - Several upgrades recommended"
        default: return "Needs Improvement - Priority upgrades needed"
        }
    }
}

// MARK: - Property Details Section

struct PropertyDetailsSection: View {
    let profile: PropertyProfile
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Property Details")
                    .font(.headline)

                Spacer()

                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                        .font(.subheadline)
                }
            }

            VStack(spacing: 12) {
                PropertyDetailRow(icon: "mappin.circle.fill", label: "Address", value: profile.address.isEmpty ? "Not set" : profile.address)
                PropertyDetailRow(icon: "house.fill", label: "Year Built", value: "\(profile.yearBuilt)")
                PropertyDetailRow(icon: "square.grid.3x3.fill", label: "Size", value: "\(Int(profile.squareFootage)) sq ft")
                PropertyDetailRow(icon: "building.2.fill", label: "Stories", value: "\(profile.stories)")
                PropertyDetailRow(icon: "hammer.fill", label: "Roof Material", value: profile.roofMaterial.rawValue)
                PropertyDetailRow(icon: "calendar", label: "Roof Age", value: "\(profile.roofAge) years")
                PropertyDetailRow(icon: "square.stack.3d.down.right.fill", label: "Foundation", value: profile.foundationType.rawValue)
                PropertyDetailRow(icon: "paintbrush.fill", label: "Exterior", value: profile.exteriorMaterial.rawValue)

                Divider()

                PropertyFeatureRow(icon: "shield.lefthalf.filled", label: "Storm Shutters", enabled: profile.hasStormShutters)
                PropertyFeatureRow(icon: "bolt.fill", label: "Backup Generator", enabled: profile.hasBackupGenerator)
                PropertyFeatureRow(icon: "sensor.fill", label: "Smart Monitoring", enabled: profile.hasSmartHomeMonitoring)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
    }
}

struct PropertyDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct PropertyFeatureRow: View {
    let icon: String
    let label: String
    let enabled: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(enabled ? .green : .gray)
                .frame(width: 24)

            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(enabled ? .green : .gray)
        }
        .font(.subheadline)
    }
}

// MARK: - Settings Section

struct SettingsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.headline)

            VStack(spacing: 0) {
                SettingsRow(icon: "bell.fill", title: "Notifications", color: .orange)
                Divider().padding(.leading, 44)
                SettingsRow(icon: "info.circle.fill", title: "About Sentinel", color: .blue)
                Divider().padding(.leading, 44)
                SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        )
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

#Preview {
    ProfileView(userId: "preview-user")
}
