//
//  PropertyEditView.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import SwiftUI

struct PropertyEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var editedProfile: PropertyProfile
    let onSave: (PropertyProfile) -> Void

    init(profile: PropertyProfile, onSave: @escaping (PropertyProfile) -> Void) {
        _editedProfile = State(initialValue: profile)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    TextField("Address", text: $editedProfile.address)

                    HStack {
                        Text("Coordinates")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(editedProfile.latitude, specifier: "%.4f"), \(editedProfile.longitude, specifier: "%.4f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Building Information") {
                    Stepper("Year Built: \(editedProfile.yearBuilt)", value: $editedProfile.yearBuilt, in: 1800...2025)

                    Stepper("Square Footage: \(Int(editedProfile.squareFootage))", value: $editedProfile.squareFootage, in: 500...10000, step: 100)

                    Stepper("Stories: \(editedProfile.stories)", value: $editedProfile.stories, in: 1...5)

                    Toggle("Has Basement", isOn: $editedProfile.hasBasement)
                }

                Section("Roof Details") {
                    Picker("Roof Material", selection: $editedProfile.roofMaterial) {
                        ForEach(PropertyProfile.RoofMaterial.allCases, id: \.self) { material in
                            Text(material.rawValue).tag(material)
                        }
                    }

                    Stepper("Roof Age: \(editedProfile.roofAge) years", value: $editedProfile.roofAge, in: 0...100)
                }

                Section("Construction") {
                    Picker("Foundation Type", selection: $editedProfile.foundationType) {
                        ForEach(PropertyProfile.FoundationType.allCases, id: \.self) { foundation in
                            Text(foundation.rawValue).tag(foundation)
                        }
                    }

                    Picker("Exterior Material", selection: $editedProfile.exteriorMaterial) {
                        ForEach(PropertyProfile.ExteriorMaterial.allCases, id: \.self) { material in
                            Text(material.rawValue).tag(material)
                        }
                    }
                }

                Section("Safety Features") {
                    Toggle("Storm Shutters", isOn: $editedProfile.hasStormShutters)
                    Toggle("Backup Generator", isOn: $editedProfile.hasBackupGenerator)
                    Toggle("Smart Home Monitoring", isOn: $editedProfile.hasSmartHomeMonitoring)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Updated Resilience Score")
                            .font(.headline)

                        HStack {
                            Text("\(Int(editedProfile.resilienceScore))")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(resilienceColor)

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text(resilienceLevel)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(resilienceColor)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Edit Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        editedProfile.updatedAt = Date()
                        onSave(editedProfile)
                        dismiss()
                    }
                }
            }
        }
    }

    private var resilienceColor: Color {
        let score = editedProfile.resilienceScore
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }

    private var resilienceLevel: String {
        let score = editedProfile.resilienceScore
        switch score {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Needs Improvement"
        }
    }
}

#Preview {
    PropertyEditView(
        profile: PropertyProfile(
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
    ) { _ in }
}
