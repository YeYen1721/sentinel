//
//  TaskListView.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import SwiftUI

struct TaskListView: View {
    @State private var viewModel = TaskListViewModel()
    @State private var showingAddTask = false
    @State private var selectedTask: MitigationTask?
    let userId: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Bar
                FilterBar(
                    selectedFilter: $viewModel.selectedFilter,
                    activeCount: viewModel.activeTasksCount,
                    completedCount: viewModel.completedTasksCount,
                    overdueCount: viewModel.overdueTasksCount
                ) {
                    viewModel.applyFilters()
                }

                // Search Bar
                SearchBar(text: $viewModel.searchText)

                // Task Statistics
                TaskStatistics(
                    total: viewModel.tasks.count,
                    active: viewModel.activeTasksCount,
                    completed: viewModel.completedTasksCount,
                    critical: viewModel.criticalTasksCount
                )
                .padding(MaterialTheme.spacing20)

                // Task List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(MaterialTheme.primary)
                    Spacer()
                } else if viewModel.filteredTasks.isEmpty {
                    EmptyTasksView()
                } else {
                    List {
                        ForEach(viewModel.filteredTasks) { task in
                            TaskRow(task: task)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTask = task
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteTask(task)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }

                                    if task.status != .completed {
                                        Button {
                                            Task {
                                                await viewModel.completeTask(task)
                                            }
                                        } label: {
                                            Label("Complete", systemImage: "checkmark")
                                        }
                                        .tint(MaterialTheme.riskLow)
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(MaterialTheme.background)
            .navigationTitle("Action Plan")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(MaterialTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                TaskEditView(userId: userId, onSave: { task in
                    Task {
                        await viewModel.createTask(task, userId: userId)
                    }
                })
            }
            .sheet(item: $selectedTask) { task in
                TaskEditView(task: task, userId: userId, onSave: { updatedTask in
                    Task {
                        await viewModel.updateTask(updatedTask)
                    }
                })
            }
            .task {
                await viewModel.loadTasks(userId: userId)
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

// MARK: - Filter Bar

struct FilterBar: View {
    @Binding var selectedFilter: TaskFilter
    let activeCount: Int
    let completedCount: Int
    let overdueCount: Int
    let onFilterChange: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    count: nil,
                    isSelected: selectedFilter == .all
                ) {
                    selectedFilter = .all
                    onFilterChange()
                }

                FilterChip(
                    title: "Active",
                    count: activeCount,
                    isSelected: selectedFilter == .active
                ) {
                    selectedFilter = .active
                    onFilterChange()
                }

                FilterChip(
                    title: "Completed",
                    count: completedCount,
                    isSelected: selectedFilter == .completed
                ) {
                    selectedFilter = .completed
                    onFilterChange()
                }

                if overdueCount > 0 {
                    FilterChip(
                        title: "Overdue",
                        count: overdueCount,
                        isSelected: selectedFilter == .overdue,
                        color: .red
                    ) {
                        selectedFilter = .overdue
                        onFilterChange()
                    }
                }

                FilterChip(
                    title: "💰 Insurance",
                    count: nil,
                    isSelected: selectedFilter == .highestInsuranceImpact,
                    color: Color(hex: "#10B981")
                ) {
                    selectedFilter = .highestInsuranceImpact
                    onFilterChange()
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

struct FilterChip: View {
    let title: String
    let count: Int?
    let isSelected: Bool
    var color: Color = MaterialTheme.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: MaterialTheme.spacing4) {
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))

                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? MaterialTheme.onPrimary : color.opacity(0.15))
                        )
                        .foregroundColor(isSelected ? color : color.opacity(0.8))
                }
            }
            .foregroundColor(isSelected ? MaterialTheme.onPrimary : color)
            .padding(.horizontal, MaterialTheme.spacing16)
            .padding(.vertical, MaterialTheme.spacing8)
            .background(
                Capsule()
                    .fill(isSelected ? color : MaterialTheme.surfaceVariant)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? color : MaterialTheme.outline.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .scaleEffect(isSelected ? 1.0 : 0.95)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: MaterialTheme.spacing12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(MaterialTheme.onSurfaceVariant)

            TextField("Search tasks...", text: $text)
                .font(.system(size: 16, weight: .regular))
                .textFieldStyle(.plain)
                .foregroundColor(MaterialTheme.onSurface)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(MaterialTheme.onSurfaceVariant)
                }
            }
        }
        .padding(MaterialTheme.spacing16)
        .background(MaterialTheme.surfaceVariant)
        .cornerRadius(MaterialTheme.cornerRadiusXL)
        .overlay(
            RoundedRectangle(cornerRadius: MaterialTheme.cornerRadiusXL)
                .stroke(text.isEmpty ? MaterialTheme.outline.opacity(0.3) : MaterialTheme.primary, lineWidth: text.isEmpty ? 1 : 2)
        )
        .padding(.horizontal, MaterialTheme.spacing20)
        .padding(.vertical, MaterialTheme.spacing12)
    }
}

// MARK: - Task Statistics

struct TaskStatistics: View {
    let total: Int
    let active: Int
    let completed: Int
    let critical: Int

    var body: some View {
        HStack(spacing: 16) {
            StatBadge(title: "Total", value: total, color: .blue)
            StatBadge(title: "Active", value: active, color: .orange)
            StatBadge(title: "Done", value: completed, color: .green)
            if critical > 0 {
                StatBadge(title: "Critical", value: critical, color: .red)
            }
        }
    }
}

struct StatBadge: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: MaterialTheme.spacing8) {
            Text("\(value)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(MaterialTheme.onSurfaceVariant)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MaterialTheme.spacing12)
        .materialCard(
            elevation: MaterialTheme.elevation1,
            cornerRadius: MaterialTheme.cornerRadiusS
        )
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: MitigationTask

    private var priorityColor: Color {
        switch task.priority {
        case .critical: return MaterialTheme.riskCritical
        case .high: return MaterialTheme.riskModerate
        case .medium: return Color(hex: "FFA726")
        case .low: return MaterialTheme.riskLow
        }
    }

    var body: some View {
        HStack(spacing: MaterialTheme.spacing16) {
            // Status Icon with Material background
            ZStack {
                Circle()
                    .fill(task.status == .completed ? MaterialTheme.riskLow.opacity(0.15) : MaterialTheme.surfaceVariant)
                    .frame(width: 40, height: 40)

                Image(systemName: task.status.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(task.status == .completed ? MaterialTheme.riskLow : MaterialTheme.onSurfaceVariant)
            }

            // Content
            VStack(alignment: .leading, spacing: MaterialTheme.spacing8) {
                HStack(spacing: MaterialTheme.spacing8) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MaterialTheme.onSurface)
                        .strikethrough(task.status == .completed)

                    Spacer()

                    // Priority indicator
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 8, height: 8)
                }

                HStack(spacing: MaterialTheme.spacing12) {
                    Label(task.category.rawValue, systemImage: "folder")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(MaterialTheme.onSurfaceVariant)

                    if let dueDate = task.dueDate {
                        Label(
                            dueDate.formatted(date: .abbreviated, time: .omitted),
                            systemImage: task.isOverdue ? "exclamationmark.circle.fill" : "calendar"
                        )
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(task.isOverdue ? MaterialTheme.riskCritical : MaterialTheme.onSurfaceVariant)
                    }
                }

                HStack {
                    if task.isAIGenerated {
                        Text("AI")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(MaterialTheme.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(MaterialTheme.primary.opacity(0.12))
                            )
                    }

                    // Cost Badge
                    if let cost = task.estimatedCost {
                        Text("$\(Int(cost))")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(MaterialTheme.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(MaterialTheme.primary.opacity(0.12))
                            )
                    }

                    // Insurance Savings Badge
                    if task.hasInsuranceImpact {
                        TaskInsuranceImpactBadge(task: task, compact: true)
                    }
                }
            }
        }
        .padding(MaterialTheme.spacing12)
    }
}

// MARK: - Empty State

struct EmptyTasksView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No tasks found")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Create a task or generate an action plan to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    TaskListView(userId: "preview-user")
}
