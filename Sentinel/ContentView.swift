//
//  ContentView.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import CoreLocation

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var userId: String?
    @State private var propertyProfile: PropertyProfile?
    @State private var isLoading = true
    @State private var profileViewModel = ProfileViewModel()

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if let userId = userId, let profile = propertyProfile {
                MainTabView(userId: userId, propertyProfile: profile)
            } else if let userId = userId {
                OnboardingView(userId: userId, onComplete: { profile in
                    propertyProfile = profile
                    isLoading = false
                })
            } else {
                LoadingView()
            }
        }
        .task {
            await authenticateAndLoadProfile()
        }
    }

    @MainActor
    private func authenticateAndLoadProfile() async {
        do {
            // Check if Firebase is configured
            guard FirebaseApp.app() != nil else {
                // Demo mode - create a demo user
                print("ℹ️  Running in demo mode without Firebase")
                userId = "demo-user-\(UUID().uuidString.prefix(8))"
                propertyProfile = nil
                isLoading = false
                return
            }

            // Try to get current user or sign in
            let user = try await authenticateUser()
            userId = user.uid

            // Load property profile
            propertyProfile = try await profileViewModel.taskRepository.fetchPropertyProfile(userId: user.uid)

            // If no profile, show onboarding
            isLoading = false
        } catch {
            print("⚠️  Authentication error: \(error.localizedDescription)")
            print("ℹ️  Falling back to demo mode")
            // Fallback to demo mode
            userId = "demo-user-\(UUID().uuidString.prefix(8))"
            propertyProfile = nil
            isLoading = false
        }
    }

    private func authenticateUser() async throws -> User {
        // Only access Auth if Firebase is configured
        guard FirebaseApp.app() != nil else {
            struct DemoUser: Error {}
            throw DemoUser()  // This will trigger demo mode fallback
        }

        // Check if user is already signed in
        if let currentUser = Auth.auth().currentUser {
            return currentUser
        }

        // Try to sign in with custom token if available
        if let customToken = ProcessInfo.processInfo.environment["__initial_auth_token"] {
            do {
                let result = try await Auth.auth().signIn(withCustomToken: customToken)
                return result.user
            } catch {
                print("⚠️  Custom token sign-in failed: \(error.localizedDescription)")
            }
        }

        // Fallback to anonymous sign-in
        let result = try await Auth.auth().signInAnonymously()
        return result.user
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    let userId: String
    let propertyProfile: PropertyProfile
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            SentinelDashboard(userId: userId, propertyProfile: propertyProfile, selectedTab: $selectedTab)
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.dots.needle.67percent")
                }
                .tag(0)

            TaskListView(userId: userId)
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }
                .tag(1)

            HistoricalTimeline(userId: userId, propertyProfile: propertyProfile)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(2)

            ProfileView(userId: userId)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(.sentinelPrimary)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.sentinelPrimary, .sentinelPrimary.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Sentinel")
                .font(.system(size: 40, weight: .bold, design: .rounded))

            ProgressView()
                .scaleEffect(1.5)
                .padding()

            Text("Protecting your home")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    let userId: String
    @State private var address = ""
    @State private var yearBuilt = 2000
    @State private var squareFootage = 2000.0
    @State private var roofMaterial: PropertyProfile.RoofMaterial = .asphaltShingles
    @State private var currentStep = 0
    @State private var isCreating = false
    let onComplete: (PropertyProfile) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Progress Indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { step in
                        Capsule()
                            .fill(step <= currentStep ? Color.sentinelPrimary : Color.gray.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal)

                // Content
                ZStack {
                    if currentStep == 0 {
                        WelcomeStep()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    } else if currentStep == 1 {
                        AddressStep(address: $address)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .leading)
                            ))
                    } else if currentStep == 2 {
                        PropertyDetailsStep(
                            yearBuilt: $yearBuilt,
                            squareFootage: $squareFootage,
                            roofMaterial: $roofMaterial
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Navigation Buttons
                VStack(spacing: 0) {
                    // Skip button for property details (above main buttons)
                    if currentStep == 2 {
                        HStack {
                            Spacer()
                            Button(action: {
                                createProfileWithDefaults()
                            }) {
                                HStack(spacing: 6) {
                                    Text("Skip for Now")
                                        .font(.subheadline)
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }
                            .padding(.bottom, 12)
                        }
                    }

                    // Main navigation buttons
                    HStack {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .buttonStyle(.bordered)
                        }

                        Spacer()

                        Button(currentStep < 2 ? "Next" : "Get Started") {
                            if currentStep < 2 {
                                withAnimation {
                                    currentStep += 1
                                }
                            } else {
                                createProfile()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(currentStep == 1 && address.isEmpty)
                    }
                }
                .padding()
            }
            .navigationTitle("Welcome")
            .overlay {
                if isCreating {
                    LoadingOverlay()
                }
            }
        }
    }

    private func createProfile() {
        isCreating = true

        // Geocode the address to get real coordinates
        Task {
            let (latitude, longitude) = await geocodeAddress(address)

            let profile = PropertyProfile(
                address: address,
                latitude: latitude,
                longitude: longitude,
                roofMaterial: roofMaterial,
                roofAge: Calendar.current.component(.year, from: Date()) - yearBuilt,
                foundationType: .slab,
                yearBuilt: yearBuilt,
                squareFootage: squareFootage,
                stories: 1,
                hasBasement: false,
                exteriorMaterial: .vinyl,
                hasStormShutters: false,
                hasBackupGenerator: false,
                hasSmartHomeMonitoring: false,
                userId: userId,
                createdAt: Date(),
                updatedAt: Date()
            )

            // Save to Firestore (only if Firebase is configured)
            let repository = TaskRepository()
            do {
                try await repository.savePropertyProfile(profile)
            } catch {
                print("ℹ️  Profile not saved to Firestore: \(error.localizedDescription)")
            }

            await MainActor.run {
                onComplete(profile)
            }
        }
    }

    private func createProfileWithDefaults() {
        isCreating = true
        print("ℹ️  User skipped property details - using defaults")

        // Geocode the address to get real coordinates
        Task {
            let (latitude, longitude) = await geocodeAddress(address)

            // Create profile with default/unknown values
            let profile = PropertyProfile(
                address: address,
                latitude: latitude,
                longitude: longitude,
                roofMaterial: .asphaltShingles,  // Most common default
                roofAge: 10,  // Reasonable default
                foundationType: .slab,
                yearBuilt: 2010,  // Default to ~15 years old
                squareFootage: 2000,  // Average US home size
                stories: 1,
                hasBasement: false,
                exteriorMaterial: .vinyl,
                hasStormShutters: false,
                hasBackupGenerator: false,
                hasSmartHomeMonitoring: false,
                userId: userId,
                createdAt: Date(),
                updatedAt: Date()
            )

            // Save to Firestore (only if Firebase is configured)
            let repository = TaskRepository()
            do {
                try await repository.savePropertyProfile(profile)
            } catch {
                print("ℹ️  Profile not saved to Firestore: \(error.localizedDescription)")
            }

            await MainActor.run {
                onComplete(profile)
            }
        }
    }

    private func geocodeAddress(_ address: String) async -> (Double, Double) {
        print("\n🗺️  GEOCODING ADDRESS: '\(address)'")
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            if let location = placemarks.first?.location {
                let lat = location.coordinate.latitude
                let lon = location.coordinate.longitude
                print("✅ GEOCODED SUCCESSFULLY:")
                print("   Address: '\(address)'")
                print("   → Latitude: \(lat)")
                print("   → Longitude: \(lon)\n")
                return (lat, lon)
            }
        } catch {
            print("⚠️  GEOCODING FAILED for '\(address)': \(error.localizedDescription)")
        }

        // Fallback to Miami coordinates if geocoding fails
        print("⚠️  USING DEFAULT MIAMI COORDINATES (25.7617, -80.1918)\n")
        return (25.7617, -80.1918)
    }
}

// MARK: - Onboarding Steps

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.sentinelPrimary, .sentinelPrimary.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Welcome to Sentinel")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Protect your home with AI-powered hazard assessment and personalized action plans")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "gauge.with.dots.needle.67percent", title: "Real-time Vulnerability Score")
                FeatureRow(icon: "brain", title: "AI-Generated Action Plans")
                FeatureRow(icon: "clock.arrow.circlepath", title: "Historical Event Tracking")
                FeatureRow(icon: "checkmark.circle", title: "Task Management")
            }
            .padding()

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct AddressStep: View {
    @Binding var address: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "house.fill")
                .font(.system(size: 80))
                .foregroundColor(.sentinelPrimary)

            Text("Your Property")
                .font(.title)
                .fontWeight(.bold)

            Text("Enter your home address to get started")
                .font(.body)
                .foregroundColor(.secondary)

            TextField("123 Main Street, City, State", text: $address)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PropertyDetailsStep: View {
    @Binding var yearBuilt: Int
    @Binding var squareFootage: Double
    @Binding var roofMaterial: PropertyProfile.RoofMaterial

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                Image(systemName: "hammer.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.sentinelPrimary)

                Text("Property Details")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Help us understand your property better")
                    .font(.body)
                    .foregroundColor(.secondary)

                Text("You can always update these later in your profile")
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(spacing: 16) {
                    Stepper("Year Built: \(yearBuilt)", value: $yearBuilt, in: 1900...2025)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    Stepper("Square Feet: \(Int(squareFootage))", value: $squareFootage, in: 500...10000, step: 100)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    // Menu style selector (instead of Picker to avoid gesture conflicts)
                    HStack {
                        Text("Roof Material")
                            .foregroundColor(.primary)

                        Spacer()

                        Menu {
                            ForEach(PropertyProfile.RoofMaterial.allCases, id: \.self) { material in
                                Button(action: {
                                    roofMaterial = material
                                }) {
                                    HStack {
                                        Text(material.rawValue)
                                        if material == roofMaterial {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(roofMaterial.rawValue)
                                    .foregroundColor(.sentinelPrimary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                                    .foregroundColor(.sentinelPrimary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer(minLength: 20)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.sentinelPrimary)
                .frame(width: 30)

            Text(title)
                .font(.body)
        }
    }
}

#Preview {
    ContentView()
}
