//
//  ProfileViewModel.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import Foundation
import Observation

@Observable
class ProfileViewModel {
    var propertyProfile: PropertyProfile?
    var isLoading: Bool = false
    var isSaving: Bool = false
    var errorMessage: String?
    var successMessage: String?

    let taskRepository: TaskRepository
    private let riskDataService: RiskDataServiceProtocol

    init(
        taskRepository: TaskRepository = TaskRepository(),
        riskDataService: RiskDataServiceProtocol = MockRiskDataService()
    ) {
        self.taskRepository = taskRepository
        self.riskDataService = riskDataService
    }

    @MainActor
    func loadProfile(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            propertyProfile = try await taskRepository.fetchPropertyProfile(userId: userId)

            // If no profile exists, create a default one
            if propertyProfile == nil {
                propertyProfile = createDefaultProfile(userId: userId)
            }

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    @MainActor
    func saveProfile(_ profile: PropertyProfile) async {
        isSaving = true
        errorMessage = nil
        successMessage = nil

        do {
            try await taskRepository.savePropertyProfile(profile)
            propertyProfile = profile
            successMessage = "Profile saved successfully"
            isSaving = false

            // Clear success message after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await MainActor.run {
                    successMessage = nil
                }
            }
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            isSaving = false
        }
    }

    @MainActor
    func updateAddress(_ address: String, userId: String) async {
        guard var profile = propertyProfile else { return }

        isLoading = true

        do {
            // Try to fetch property data from API
            if let fetchedProfile = try await riskDataService.fetchPropertyData(address: address) {
                profile = fetchedProfile
                profile.userId = userId
            } else {
                // Just update the address
                profile.address = address
            }

            try await taskRepository.savePropertyProfile(profile)
            propertyProfile = profile
            successMessage = "Address updated successfully"
            isLoading = false
        } catch {
            errorMessage = "Failed to update address: \(error.localizedDescription)"
            isLoading = false
        }
    }

    private func createDefaultProfile(userId: String) -> PropertyProfile {
        PropertyProfile(
            address: "",
            latitude: 0,
            longitude: 0,
            roofMaterial: .asphaltShingles,
            roofAge: 10,
            foundationType: .slab,
            yearBuilt: 2000,
            squareFootage: 2000,
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
    }

    func calculateResilienceScore() -> Double {
        propertyProfile?.resilienceScore ?? 0
    }
}
