//
//  TaskRepository.swift
//  Sentinel
//
//  Created by Sentinel on 2025-10-24.
//

import Foundation
import Combine
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

/// Repository for managing MitigationTask persistence in Firestore
class TaskRepository: ObservableObject {
    // MARK: - In-Memory Storage for Demo Mode
    private static var demoModeTasks: [MitigationTask] = []
    private static var demoModeProfile: PropertyProfile? = nil

    // Cache Firebase availability check to avoid repeated warnings
    private static var firebaseAvailabilityChecked = false
    private static var isFirebaseConfigured = false

    private lazy var db: Firestore? = {
        // Only check Firebase availability once
        if !TaskRepository.firebaseAvailabilityChecked {
            TaskRepository.firebaseAvailabilityChecked = true
            if FirebaseApp.app() != nil {
                TaskRepository.isFirebaseConfigured = true
            } else {
                print("⚠️  Firestore not available - Firebase not configured")
                TaskRepository.isFirebaseConfigured = false
            }
        }

        guard TaskRepository.isFirebaseConfigured else {
            return nil
        }
        return Firestore.firestore()
    }()

    private var appId: String
    @Published var tasks: [MitigationTask] = []
    private var listener: ListenerRegistration?
    private var isFirebaseAvailable: Bool {
        db != nil
    }

    init(appId: String = "__app_id") {
        self.appId = appId
    }

    // MARK: - Firestore Path Construction
    private func tasksCollection(for userId: String) -> CollectionReference? {
        guard let db = db, !userId.isEmpty else { return nil }
        return db.collection("artifacts")
            .document(appId)
            .collection("users")
            .document(userId)
            .collection("tasks")
    }

    private func profileDocument(for userId: String) -> DocumentReference? {
        guard let db = db, !userId.isEmpty else { return nil }
        return db.collection("artifacts")
            .document(appId)
            .collection("users")
            .document(userId)
            .collection("profile")
            .document("current")
    }

    // MARK: - Task Operations

    /// Fetch all tasks for a user
    func fetchTasks(userId: String) async throws -> [MitigationTask] {
        guard let collection = tasksCollection(for: userId) else {
            // Demo mode: return from in-memory storage
            print("💾 Demo mode: Returning \(TaskRepository.demoModeTasks.count) tasks from memory")
            return TaskRepository.demoModeTasks.sorted { $0.createdAt > $1.createdAt }
        }

        let snapshot = try await collection
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            try? doc.data(as: MitigationTask.self)
        }
    }

    /// Listen to real-time task updates
    func startListening(userId: String) {
        listener?.remove()

        guard let collection = tasksCollection(for: userId) else {
            // Demo mode: load from in-memory storage
            print("💾 Demo mode: Loading \(TaskRepository.demoModeTasks.count) tasks from memory")
            self.tasks = TaskRepository.demoModeTasks.sorted { $0.createdAt > $1.createdAt }
            return
        }

        listener = collection
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching tasks: \(error?.localizedDescription ?? "Unknown")")
                    return
                }

                self?.tasks = documents.compactMap { doc in
                    try? doc.data(as: MitigationTask.self)
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    /// Create a new task
    func createTask(_ task: MitigationTask, userId: String) async throws {
        guard let collection = tasksCollection(for: userId) else {
            // Demo mode: save to in-memory storage
            print("💾 Demo mode: Saving task to memory")
            var newTask = task
            newTask.userId = userId
            newTask.createdAt = Date()
            newTask.updatedAt = Date()
            newTask.id = UUID().uuidString
            TaskRepository.demoModeTasks.append(newTask)

            // Update published tasks property for UI
            DispatchQueue.main.async {
                self.tasks = TaskRepository.demoModeTasks.sorted { $0.createdAt > $1.createdAt }
            }
            return
        }

        var newTask = task
        newTask.userId = userId
        newTask.createdAt = Date()
        newTask.updatedAt = Date()

        try collection.addDocument(from: newTask)
    }

    /// Create multiple tasks (bulk operation)
    func createTasks(_ tasks: [MitigationTask], userId: String) async throws {
        guard let db = db, let collection = tasksCollection(for: userId) else {
            // Demo mode: save to in-memory storage
            print("💾 Demo mode: Saving \(tasks.count) tasks to memory")
            let preparedTasks = tasks.map { task in
                var newTask = task
                newTask.userId = userId
                newTask.createdAt = Date()
                newTask.updatedAt = Date()
                newTask.id = UUID().uuidString // Generate ID for demo mode
                return newTask
            }
            TaskRepository.demoModeTasks.append(contentsOf: preparedTasks)

            // Update published tasks property for UI
            DispatchQueue.main.async {
                self.tasks = TaskRepository.demoModeTasks.sorted { $0.createdAt > $1.createdAt }
            }
            return
        }

        let batch = db.batch()

        for var task in tasks {
            task.userId = userId
            task.createdAt = Date()
            task.updatedAt = Date()

            let docRef = collection.document()
            try batch.setData(from: task, forDocument: docRef)
        }

        try await batch.commit()
    }

    /// Update an existing task
    func updateTask(_ task: MitigationTask) async throws {
        guard let taskId = task.id else {
            throw TaskRepositoryError.invalidTaskId
        }

        guard let collection = tasksCollection(for: task.userId) else {
            // Demo mode: update in-memory storage
            print("💾 Demo mode: Updating task in memory")
            if let index = TaskRepository.demoModeTasks.firstIndex(where: { $0.id == taskId }) {
                var updatedTask = task
                updatedTask.updatedAt = Date()
                TaskRepository.demoModeTasks[index] = updatedTask

                // Update published tasks property for UI
                DispatchQueue.main.async {
                    self.tasks = TaskRepository.demoModeTasks.sorted { $0.createdAt > $1.createdAt }
                }
            }
            return
        }

        var updatedTask = task
        updatedTask.updatedAt = Date()

        try collection
            .document(taskId)
            .setData(from: updatedTask, merge: true)
    }

    /// Delete a task
    func deleteTask(_ task: MitigationTask) async throws {
        guard let taskId = task.id else {
            throw TaskRepositoryError.invalidTaskId
        }

        guard let collection = tasksCollection(for: task.userId) else {
            // Demo mode: delete from in-memory storage
            print("💾 Demo mode: Deleting task from memory")
            TaskRepository.demoModeTasks.removeAll { $0.id == taskId }

            // Update published tasks property for UI
            DispatchQueue.main.async {
                self.tasks = TaskRepository.demoModeTasks.sorted { $0.createdAt > $1.createdAt }
            }
            return
        }

        try await collection
            .document(taskId)
            .delete()
    }

    /// Mark task as completed
    func completeTask(_ task: MitigationTask) async throws {
        var completedTask = task
        completedTask.status = .completed
        completedTask.completedDate = Date()
        try await updateTask(completedTask)
    }

    // MARK: - Property Profile Operations

    /// Save property profile
    func savePropertyProfile(_ profile: PropertyProfile) async throws {
        guard let document = profileDocument(for: profile.userId) else {
            // Demo mode: save to in-memory storage
            print("💾 Demo mode: Saving profile to memory")
            var updatedProfile = profile
            updatedProfile.updatedAt = Date()
            TaskRepository.demoModeProfile = updatedProfile
            return
        }

        var updatedProfile = profile
        updatedProfile.updatedAt = Date()

        try document.setData(from: updatedProfile, merge: true)
    }

    /// Fetch property profile
    func fetchPropertyProfile(userId: String) async throws -> PropertyProfile? {
        guard let docRef = profileDocument(for: userId) else {
            // Demo mode: return from in-memory storage
            print("💾 Demo mode: Returning profile from memory")
            return TaskRepository.demoModeProfile
        }

        let document = try await docRef.getDocument()
        return try? document.data(as: PropertyProfile.self)
    }

    deinit {
        stopListening()
    }
}

// MARK: - Errors

enum TaskRepositoryError: Error, LocalizedError {
    case invalidTaskId
    case userNotAuthenticated
    case firestoreUnavailable
    case firestoreError(String)

    var errorDescription: String? {
        switch self {
        case .invalidTaskId:
            return "Invalid task identifier"
        case .userNotAuthenticated:
            return "User must be authenticated"
        case .firestoreUnavailable:
            return "Firestore not available - app running in demo mode"
        case .firestoreError(let message):
            return "Firestore error: \(message)"
        }
    }
}
