//
//  TaskListViewModel.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import Foundation
import Observation

@Observable
class TaskListViewModel {
    var tasks: [MitigationTask] = []
    var filteredTasks: [MitigationTask] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var selectedFilter: TaskFilter = .all
    var searchText: String = "" {
        didSet {
            applyFilters()
        }
    }

    private let taskRepository: TaskRepository

    init(taskRepository: TaskRepository = TaskRepository()) {
        self.taskRepository = taskRepository
    }

    @MainActor
    func loadTasks(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            tasks = try await taskRepository.fetchTasks(userId: userId)
            applyFilters()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func startListening(userId: String) {
        taskRepository.startListening(userId: userId)

        // Observe changes from repository
        Task { @MainActor in
            // This will be updated through KVO/Combine in real implementation
            tasks = taskRepository.tasks
            applyFilters()
        }
    }

    func stopListening() {
        taskRepository.stopListening()
    }

    @MainActor
    func createTask(_ task: MitigationTask, userId: String) async {
        do {
            try await taskRepository.createTask(task, userId: userId)
            await loadTasks(userId: userId)
        } catch {
            errorMessage = "Failed to create task: \(error.localizedDescription)"
        }
    }

    @MainActor
    func updateTask(_ task: MitigationTask) async {
        do {
            try await taskRepository.updateTask(task)
        } catch {
            errorMessage = "Failed to update task: \(error.localizedDescription)"
        }
    }

    @MainActor
    func deleteTask(_ task: MitigationTask) async {
        do {
            try await taskRepository.deleteTask(task)
            tasks.removeAll { $0.id == task.id }
            applyFilters()
        } catch {
            errorMessage = "Failed to delete task: \(error.localizedDescription)"
        }
    }

    @MainActor
    func completeTask(_ task: MitigationTask) async {
        do {
            try await taskRepository.completeTask(task)
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index].status = .completed
                tasks[index].completedDate = Date()
            }
            applyFilters()
        } catch {
            errorMessage = "Failed to complete task: \(error.localizedDescription)"
        }
    }

    func applyFilters() {
        var filtered = tasks

        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            filtered = filtered.filter { $0.status != .completed && $0.status != .cancelled }
        case .completed:
            filtered = filtered.filter { $0.status == .completed }
        case .overdue:
            filtered = filtered.filter { $0.isOverdue }
        case .priority(let priority):
            filtered = filtered.filter { $0.priority == priority }
        case .category(let category):
            filtered = filtered.filter { $0.category == category }
        case .highestInsuranceImpact:
            // Filter to tasks with insurance impact and sort by savings
            filtered = filtered.filter { $0.hasInsuranceImpact }
        }

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort based on filter type
        if selectedFilter == .highestInsuranceImpact {
            // Sort by insurance savings (highest first)
            filteredTasks = filtered.sorted { task1, task2 in
                let savings1 = task1.estimatedInsuranceSavings ?? 0
                let savings2 = task2.estimatedInsuranceSavings ?? 0
                return savings1 > savings2
            }
        } else {
            // Default sort: by priority and due date
            filteredTasks = filtered.sorted { task1, task2 in
                if task1.priority.sortOrder != task2.priority.sortOrder {
                    return task1.priority.sortOrder < task2.priority.sortOrder
                }
                if let date1 = task1.dueDate, let date2 = task2.dueDate {
                    return date1 < date2
                }
                return task1.createdAt > task2.createdAt
            }
        }
    }

    func setFilter(_ filter: TaskFilter) {
        selectedFilter = filter
        applyFilters()
    }

    // MARK: - Statistics
    var completedTasksCount: Int {
        tasks.filter { $0.status == .completed }.count
    }

    var activeTasksCount: Int {
        tasks.filter { $0.status != .completed && $0.status != .cancelled }.count
    }

    var overdueTasksCount: Int {
        tasks.filter { $0.isOverdue }.count
    }

    var criticalTasksCount: Int {
        tasks.filter { $0.priority == .critical && $0.status != .completed }.count
    }
}

// MARK: - Task Filter

enum TaskFilter: Equatable {
    case all
    case active
    case completed
    case overdue
    case priority(MitigationTask.Priority)
    case category(MitigationTask.Category)
    case highestInsuranceImpact

    var displayName: String {
        switch self {
        case .all: return "All Tasks"
        case .active: return "Active"
        case .completed: return "Completed"
        case .overdue: return "Overdue"
        case .priority(let p): return p.rawValue
        case .category(let c): return c.rawValue
        case .highestInsuranceImpact: return "💰 Insurance"
        }
    }
}
