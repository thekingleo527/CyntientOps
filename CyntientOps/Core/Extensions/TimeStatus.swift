//
//  TimeStatus.swift
//  CyntientOps
//
//  Extensions to add real-time status to existing MaintenanceTask model
//

import Foundation
import SwiftUI

// MARK: - Task Time Status
extension CoreTypes.MaintenanceTask {
    
    enum TimeStatus {
        case upcoming(minutesUntil: Int)
        case inProgress(percentComplete: Double)
        case overdue(minutesLate: Int)
        case completed
        case notToday
        
        var displayColor: Color {
            switch self {
            case .upcoming(let minutes):
                return minutes <= 30 ? .orange : .blue
            case .inProgress:
                return .green
            case .overdue:
                return .red
            case .completed:
                return .gray
            case .notToday:
                return .gray.opacity(0.5)
            }
        }
        
        var statusText: String {
            switch self {
            case .upcoming(let minutes):
                if minutes <= 0 { return "Starting now" }
                if minutes < 60 { return "In \(minutes) min" }
                let hours = minutes / 60
                return "In \(hours)h \(minutes % 60)m"
            case .inProgress(let percent):
                return "\(Int(percent * 100))% complete"
            case .overdue(let minutes):
                if minutes < 60 { return "\(minutes) min late" }
                let hours = minutes / 60
                return "\(hours)h \(minutes % 60)m late"
            case .completed:
                return "Completed"
            case .notToday:
                return "Not scheduled today"
            }
        }
        
        var actionIcon: String {
            switch self {
            case .upcoming:
                return "clock.arrow.circlepath"
            case .inProgress:
                return "play.circle.fill"
            case .overdue:
                return "exclamationmark.circle.fill"
            case .completed:
                return "checkmark.circle.fill"
            case .notToday:
                return "calendar.circle"
            }
        }
    }
    
    // Computed time status
    var timeStatus: TimeStatus {
        let now = Date()
        let calendar = Calendar.current
        
        // Check if task is for today
        guard let dueDate = dueDate else {
            return .notToday
        }
        
        if !calendar.isDateInToday(dueDate) {
            return .notToday
        }
        
        if status == .completed {
            return .completed
        }
        
        // Calculate task timing based on estimated duration
        let taskStartTime = dueDate.addingTimeInterval(-estimatedDuration)
        let taskEndTime = dueDate
        
        if now < taskStartTime {
            let minutes = calendar.dateComponents([.minute], from: now, to: taskStartTime).minute ?? 0
            return .upcoming(minutesUntil: minutes)
        } else if now >= taskStartTime && now <= taskEndTime {
            let totalDuration = taskEndTime.timeIntervalSince(taskStartTime)
            let elapsed = now.timeIntervalSince(taskStartTime)
            let percent = elapsed / totalDuration
            return .inProgress(percentComplete: percent)
        } else {
            let minutes = calendar.dateComponents([.minute], from: taskEndTime, to: now).minute ?? 0
            return .overdue(minutesLate: minutes)
        }
    }
    
    // Time slot display
    var timeSlot: String {
        guard let dueDate = dueDate else { return "Not scheduled" }
        
        let startTime = dueDate.addingTimeInterval(-estimatedDuration)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: dueDate))"
    }
    
    // Duration display
    var durationText: String {
        let minutes = Int(estimatedDuration / 60)
        if minutes < 60 {
            return "\(minutes) min"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
}

// MARK: - TaskService Extensions for Real-Time Features
extension TaskService {
    
    /// Fetch today's tasks for a worker with real-time status
    func fetchTodaysTasks(forWorker workerId: String) async throws -> (current: [CoreTypes.MaintenanceTask], upcoming: [CoreTypes.MaintenanceTask], completed: [CoreTypes.MaintenanceTask]) {
        
        // Get tasks for today
        let todaysTasks = try await getTasksForWorker(workerId)
            .filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDateInToday(dueDate)
            }
            .compactMap { contextualTask -> CoreTypes.MaintenanceTask? in
                // Convert ContextualTask to MaintenanceTask
                CoreTypes.MaintenanceTask(
                    id: contextualTask.id,
                    title: contextualTask.title,
                    description: contextualTask.description ?? "",
                    category: contextualTask.category ?? .maintenance,
                    urgency: contextualTask.urgency ?? .medium,
                    status: contextualTask.status,
                    buildingId: contextualTask.buildingId ?? "",
                    assignedWorkerId: workerId,
                    estimatedDuration: 3600, // Default 1 hour
                    createdDate: Date(),
                    dueDate: contextualTask.dueDate,
                    completedDate: contextualTask.completedAt
                )
            }
        
        var current: [CoreTypes.MaintenanceTask] = []
        var upcoming: [CoreTypes.MaintenanceTask] = []
        var completed: [CoreTypes.MaintenanceTask] = []
        
        for task in todaysTasks {
            switch task.timeStatus {
            case .inProgress, .overdue:
                current.append(task)
            case .upcoming:
                upcoming.append(task)
            case .completed:
                completed.append(task)
            case .notToday:
                break // Skip
            }
        }
        
        // Sort by time
        current.sort { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
        upcoming.sort { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
        completed.sort { ($0.dueDate ?? Date()) > ($1.dueDate ?? Date()) }
        
        return (current, upcoming, completed)
    }
    
    /// Get next task for worker
    func getNextTask(forWorker workerId: String) async throws -> CoreTypes.MaintenanceTask? {
        let (current, upcoming, _) = try await fetchTodaysTasks(forWorker: workerId)
        
        // First check current tasks (in progress or overdue)
        if let currentTask = current.first {
            return currentTask
        }
        
        // Then check upcoming
        return upcoming.first
    }
    
    /// Get time until next task
    func getTimeUntilNextTask(forWorker workerId: String) async throws -> String? {
        guard let nextTask = try await getNextTask(forWorker: workerId) else { return nil }
        
        switch nextTask.timeStatus {
        case .upcoming(let minutes):
            if minutes <= 0 { return "Starting now" }
            if minutes < 60 { return "\(minutes) minutes" }
            let hours = minutes / 60
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        case .inProgress:
            return "In progress"
        case .overdue:
            return "Overdue"
        default:
            return nil
        }
    }
}

// MARK: - Observable Task State Manager
@MainActor
class TaskStateManager: ObservableObject {
    @Published var currentTasks: [CoreTypes.MaintenanceTask] = []
    @Published var upcomingTasks: [CoreTypes.MaintenanceTask] = []
    @Published var completedTasks: [CoreTypes.MaintenanceTask] = []
    @Published var isLoading = false
    
    private var refreshTimer: Timer?
    private let taskService = TaskService.shared
    
    init() {
        startAutoRefresh()
    }
    
    func loadTasks(forWorker workerId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (current, upcoming, completed) = try await taskService.fetchTodaysTasks(forWorker: workerId)
            
            self.currentTasks = current
            self.upcomingTasks = upcoming
            self.completedTasks = completed
        } catch {
            print("Error loading tasks: \(error)")
        }
    }
    
    func markTaskComplete(_ taskId: String, evidence: CoreTypes.ActionEvidence) async {
        do {
            try await taskService.completeTask(taskId, evidence: evidence)
            
            // Reload tasks
            if let workerId = currentTasks.first?.assignedWorkerId {
                await loadTasks(forWorker: workerId)
            }
        } catch {
            print("Error completing task: \(error)")
        }
    }
    
    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                // Re-categorize tasks based on current time
                let allTasks = self.currentTasks + self.upcomingTasks
                
                var newCurrent: [CoreTypes.MaintenanceTask] = []
                var newUpcoming: [CoreTypes.MaintenanceTask] = []
                
                for task in allTasks {
                    switch task.timeStatus {
                    case .inProgress, .overdue:
                        newCurrent.append(task)
                    case .upcoming:
                        newUpcoming.append(task)
                    default:
                        break
                    }
                }
                
                self.currentTasks = newCurrent.sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
                self.upcomingTasks = newUpcoming.sorted { ($0.dueDate ?? Date()) < ($1.dueDate ?? Date()) }
            }
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    var taskSummary: (total: Int, completed: Int, remaining: Int) {
        let total = currentTasks.count + upcomingTasks.count + completedTasks.count
        let completed = completedTasks.count
        let remaining = currentTasks.count + upcomingTasks.count
        
        return (total, completed, remaining)
    }
    
    var timeUntilNextTask: String? {
        let nextTask = currentTasks.first ?? upcomingTasks.first
        guard let next = nextTask else { return nil }
        
        switch next.timeStatus {
        case .upcoming(let minutes):
            if minutes <= 0 { return "Starting now" }
            if minutes < 60 { return "\(minutes) minutes" }
            let hours = minutes / 60
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        case .inProgress:
            return "In progress"
        case .overdue:
            return "Overdue"
        default:
            return nil
        }
    }
}
