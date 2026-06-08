//
//  MitigationTask.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import Foundation
import FirebaseFirestore

struct MitigationTask: Codable, Identifiable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var priority: Priority
    var category: Category
    var status: TaskStatus
    var dueDate: Date?
    var completedDate: Date?
    var estimatedCost: Double?
    var estimatedTime: String? // e.g., "2-3 hours"
    var relatedPerilType: String? // Links to HazardAssessment.PerilEvent.PerilType
    var isAIGenerated: Bool
    var userId: String
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    // Insurance impact fields
    var estimatedInsuranceSavings: Double? // Annual savings in dollars
    var insuranceImpactCategory: String? // "Critical", "High", "Medium", "Low"
    var insuranceImpactPercentage: Double? // Percentage reduction in premium
    var insuranceImpactDescription: String? // Why this saves money

    enum Priority: String, Codable, CaseIterable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"

        var color: String {
            switch self {
            case .critical: return "red"
            case .high: return "orange"
            case .medium: return "yellow"
            case .low: return "green"
            }
        }

        var sortOrder: Int {
            switch self {
            case .critical: return 0
            case .high: return 1
            case .medium: return 2
            case .low: return 3
            }
        }
    }

    enum Category: String, Codable, CaseIterable {
        case structural = "Structural"
        case landscaping = "Landscaping"
        case utilities = "Utilities"
        case emergency = "Emergency Preparedness"
        case documentation = "Documentation"
        case insurance = "Insurance"
        case monitoring = "Monitoring"
        case maintenance = "Maintenance"
    }

    enum TaskStatus: String, Codable, CaseIterable {
        case notStarted = "Not Started"
        case inProgress = "In Progress"
        case completed = "Completed"
        case deferred = "Deferred"
        case cancelled = "Cancelled"

        var icon: String {
            switch self {
            case .notStarted: return "circle"
            case .inProgress: return "circle.lefthalf.filled"
            case .completed: return "checkmark.circle.fill"
            case .deferred: return "clock"
            case .cancelled: return "xmark.circle"
            }
        }
    }

    var isOverdue: Bool {
        guard let dueDate = dueDate, status != .completed else { return false }
        return dueDate < Date()
    }

    var isCompleted: Bool {
        status == .completed
    }

    // Insurance-related computed properties
    var hasInsuranceImpact: Bool {
        estimatedInsuranceSavings != nil && (estimatedInsuranceSavings ?? 0) > 0
    }

    var estimatedMonthlySavings: Double? {
        guard let annual = estimatedInsuranceSavings else { return nil }
        return annual / 12.0
    }

    var insuranceSavingsText: String {
        guard let savings = estimatedInsuranceSavings, savings > 0 else {
            return "No estimated savings"
        }
        return String(format: "$%.0f/yr", savings)
    }

    var insuranceCategoryColor: String {
        switch insuranceImpactCategory {
        case "Critical": return "#DC2626"  // Red
        case "High": return "#F59E0B"      // Amber
        case "Medium": return "#10B981"    // Green
        case "Low": return "#6B7280"       // Gray
        default: return "#6B7280"
        }
    }
}

// Extension for creating sample data
extension MitigationTask {
    static func sample() -> MitigationTask {
        MitigationTask(
            title: "Inspect and repair roof damage",
            description: "Check for loose or missing shingles and repair any damage before hurricane season.",
            priority: .high,
            category: .structural,
            status: .notStarted,
            dueDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            estimatedCost: 500,
            estimatedTime: "4-6 hours",
            relatedPerilType: "Hurricane",
            isAIGenerated: true,
            userId: "sample-user",
            notes: "",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
