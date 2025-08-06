
//  TaskService+DepartureChecklist.swift
//  CyntientOps
//
//  Extensions to TaskService for site departure functionality
//
//  Place this file in: CyntientOps/Services/
//

import Foundation
import CoreLocation

// MARK: - Data Models

public struct DepartureChecklist {
    public let allTasks: [CoreTypes.ContextualTask]
    public let completedTasks: [CoreTypes.ContextualTask]
    public let incompleteTasks: [CoreTypes.ContextualTask]
    public let photoCount: Int
    public let timeSpentMinutes: Int?
    public let requiredPhotoCount: Int
    
    public var completionPercentage: Double {
        guard !allTasks.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(allTasks.count) * 100
    }
    
    public var hasRequiredPhotos: Bool {
        photoCount >= requiredPhotoCount
    }
}

public struct DepartureLogRecord: Identifiable {
    public let id: String
    public let workerId: String
    public let buildingId: String
    public let buildingName: String
    public let buildingAddress: String?
    public let departedAt: Date
    public let tasksCompletedCount: Int
    public let tasksRemainingCount: Int
    public let photosProvidedCount: Int
    public let isFullyCompliant: Bool
    public let notes: String?
    public let timeSpentMinutes: Int?
    public let departureMethod: DepartureMethod
    public let workerName: String?
    
    init(from row: [String: Any]) {
        self.id = row["id"] as? String ?? ""
        self.workerId = row["worker_id"] as? String ?? ""
        self.buildingId = row["building_id"] as? String ?? ""
        self.buildingName = row["building_name"] as? String ?? ""
        self.buildingAddress = row["building_address"] as? String
        self.departedAt = ISO8601DateFormatter().date(from: row["departed_at"] as? String ?? "") ?? Date()
        self.tasksCompletedCount = (row["tasks_completed_count"] as? Int64).map(Int.init) ?? (row["tasks_completed_count"] as? Int ?? 0)
        self.tasksRemainingCount = (row["tasks_remaining_count"] as? Int64).map(Int.init) ?? (row["tasks_remaining_count"] as? Int ?? 0)
        self.photosProvidedCount = (row["photos_provided_count"] as? Int64).map(Int.init) ?? (row["photos_provided_count"] as? Int ?? 0)
        self.isFullyCompliant = (row["is_fully_compliant"] as? Int64 ?? 0) == 1 || (row["is_fully_compliant"] as? Int ?? 0) == 1
        self.notes = row["notes"] as? String
        self.timeSpentMinutes = (row["time_spent_minutes"] as? Int64).map(Int.init) ?? (row["time_spent_minutes"] as? Int)
        self.departureMethod = DepartureMethod(rawValue: row["departure_method"] as? String ?? "") ?? .normal
        self.workerName = row["worker_name"] as? String
    }
    
    public var totalTasks: Int {
        tasksCompletedCount + tasksRemainingCount
    }
    
    public var completionRate: Double {
        guard totalTasks > 0 else { return 0 }
        return Double(tasksCompletedCount) / Double(totalTasks) * 100
    }
}

public enum DepartureMethod: String, CaseIterable {
    case normal = "normal"
    case emergency = "emergency"
    case endOfDay = "end_of_day"
    
    public var displayName: String {
        switch self {
        case .normal: return "Normal Departure"
        case .emergency: return "Emergency Departure"
        case .endOfDay: return "End of Day"
        }
    }
    
    public var icon: String {
        switch self {
        case .normal: return "arrow.right.square"
        case .emergency: return "exclamationmark.triangle"
        case .endOfDay: return "moon.stars"
        }
    }
    
    public var color: String {
        switch self {
        case .normal: return "green"
        case .emergency: return "red"
        case .endOfDay: return "purple"
        }
    }
}

// MARK: - TaskService Extension

extension TaskService {
    
    /// Fetches tasks required for a site departure checklist
    public func getDepartureChecklistItems(for workerId: String, buildingId: String) async throws -> DepartureChecklist {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        // Get all tasks for today at this building
        let allTasksRows = try await grdbManager.query("""
            SELECT rt.*, b.name as building_name, b.address as building_address
            FROM routine_tasks rt
            LEFT JOIN buildings b ON rt.building_id = b.id
            WHERE (rt.assigned_worker_id = ? OR rt.workerId = ?)
            AND (rt.building_id = ? OR rt.buildingId = ?)
            AND rt.scheduledDate >= ? AND rt.scheduledDate < ?
            ORDER BY rt.urgency DESC, rt.scheduledDate ASC
        """, [
            workerId, workerId,
            buildingId, buildingId,
            today.ISO8601Format(),
            tomorrow.ISO8601Format()
        ])
        
        // Get completed tasks with photo evidence count
        let completedRows = try await grdbManager.query("""
            SELECT rt.*, tc.completion_time, 
                   COUNT(DISTINCT pe.id) as photo_count
            FROM routine_tasks rt
            JOIN task_completions tc ON rt.id = tc.task_id
            LEFT JOIN photo_evidence pe ON tc.id = pe.completion_id
            WHERE (rt.assigned_worker_id = ? OR rt.workerId = ?)
            AND (rt.building_id = ? OR rt.buildingId = ?)
            AND rt.scheduledDate >= ? AND rt.scheduledDate < ?
            GROUP BY rt.id
        """, [
            workerId, workerId,
            buildingId, buildingId,
            today.ISO8601Format(),
            tomorrow.ISO8601Format()
        ])
        
        // Convert to ContextualTask objects
        let allTasks = allTasksRows.compactMap { row in
            convertRowToContextualTask(row, buildingName: row["building_name"] as? String, buildingAddress: row["building_address"] as? String)
        }
        
        // Identify completed tasks
        let completedTaskIds = Set(completedRows.compactMap { $0["id"] as? String })
        let completedTasks = allTasks.filter { completedTaskIds.contains($0.id) }
        let incompleteTasks = allTasks.filter { !completedTaskIds.contains($0.id) }
        
        // Count total photos provided
        let photoCount = completedRows.reduce(0) { total, row in
            total + ((row["photo_count"] as? Int64).map(Int.init) ?? 0)
        }
        
        // Calculate time spent at location
        let clockInTime = try await getClockInTime(workerId: workerId, buildingId: buildingId)
        let timeSpentMinutes = clockInTime.map { Int(Date().timeIntervalSince($0) / 60) }
        
        // Count tasks requiring photos
        let photosRequired = allTasks.filter { task in
            return (task.requiresPhoto ?? false) || 
                   task.category == .sanitation || 
                   task.category == .cleaning
        }
        let requiredPhotoCount = photosRequired.count
        
        return DepartureChecklist(
            allTasks: allTasks,
            completedTasks: completedTasks,
            incompleteTasks: incompleteTasks,
            photoCount: photoCount,
            timeSpentMinutes: timeSpentMinutes,
            requiredPhotoCount: requiredPhotoCount
        )
    }
    
    /// Get the clock-in time for the current session
    private func getClockInTime(workerId: String, buildingId: String) async throws -> Date? {
        let today = Calendar.current.startOfDay(for: Date())
        
        let rows = try await grdbManager.query("""
            SELECT clock_in_time FROM clock_sessions
            WHERE worker_id = ? AND building_id = ?
            AND clock_in_time >= ?
            AND (clock_out_time IS NULL OR clock_out_time = '')
            ORDER BY clock_in_time DESC
            LIMIT 1
        """, [workerId, buildingId, today.ISO8601Format()])
        
        guard let row = rows.first,
              let timeString = row["clock_in_time"] as? String,
              let date = ISO8601DateFormatter().date(from: timeString) else {
            // If no active session, check for any session today
            let anySessionRows = try await grdbManager.query("""
                SELECT clock_in_time FROM clock_sessions
                WHERE worker_id = ? AND building_id = ?
                AND clock_in_time >= ?
                ORDER BY clock_in_time DESC
                LIMIT 1
            """, [workerId, buildingId, today.ISO8601Format()])
            
            guard let row = anySessionRows.first,
                  let timeString = row["clock_in_time"] as? String,
                  let date = ISO8601DateFormatter().date(from: timeString) else {
                return nil
            }
            
            return date
        }
        
        return date
    }
    
    /// Convert database row to ContextualTask
    private func convertRowToContextualTask(_ row: [String: Any], buildingName: String? = nil, buildingAddress: String? = nil) -> CoreTypes.ContextualTask? {
        guard let id = row["id"] as? String,
              let title = row["title"] as? String else {
            return nil
        }
        
        // Handle building info
        let buildingId = (row["building_id"] ?? row["buildingId"]) as? String
        let building: CoreTypes.NamedCoordinate? = buildingId.flatMap { id in
            CoreTypes.NamedCoordinate(
                id: id,
                name: buildingName ?? "Building \(id)",
                address: buildingAddress ?? "",
                latitude: 0,
                longitude: 0
            )
        }
        
        // Parse dates
        let dueDateString = (row["dueDate"] ?? row["due_date"]) as? String
        let dueDate = dueDateString.flatMap { ISO8601DateFormatter().date(from: $0) }
        
        let completedDateString = (row["completedDate"] ?? row["completed_date"]) as? String
        let completedDate = completedDateString.flatMap { ISO8601DateFormatter().date(from: $0) }
        
        // Parse enums
        let categoryString = row["category"] as? String
        let category: CoreTypes.TaskCategory? = categoryString != nil ? CoreTypes.TaskCategory(rawValue: categoryString!) : .maintenance
        
        let urgencyString = row["urgency"] as? String
        let urgency = urgencyString.flatMap { CoreTypes.TaskUrgency(rawValue: $0) } ?? .medium
        
        // Check if completed
        let isCompleted = (row["isCompleted"] as? Int64 ?? 0) > 0 || 
                         (row["isCompleted"] as? Int ?? 0) > 0 ||
                         (row["status"] as? String) == "completed"
        
        // Check if requires photo
        let requiresPhoto = (row["requires_photo"] as? Int64 ?? 0) > 0 || 
                           (row["requires_photo"] as? Int ?? 0) > 0
        
        let status: CoreTypes.TaskStatus = isCompleted ? .completed : .pending
        let scheduledDate = (row["scheduledDate"] ?? row["scheduled_date"]) as? Date
        
        return CoreTypes.ContextualTask(
            id: id,
            title: title,
            description: row["description"] as? String,
            status: status,
            completedAt: completedDate,
            scheduledDate: scheduledDate,
            dueDate: dueDate,
            category: category,
            urgency: urgency,
            building: building,
            buildingId: buildingId,
            assignedWorkerId: (row["assigned_worker_id"] ?? row["workerId"]) as? String,
            requiresPhoto: requiresPhoto,
            estimatedDuration: TimeInterval((row["estimatedDuration"] ?? row["estimated_duration"]) as? Int ?? 0)
        )
    }
    
    /// Get recent departure history for a worker
    public func getRecentDepartures(for workerId: String, days: Int = 7) async throws -> [DepartureLogRecord] {
        return try await SiteLogService.shared.getTodaysDepartures(for: workerId)
    }
    
    /// Check if departure is required before leaving
    public func isDepartureRequired(for workerId: String, buildingId: String) async throws -> Bool {
        // Check if there are any tasks at this building today
        let checklist = try await getDepartureChecklistItems(for: workerId, buildingId: buildingId)
        
        // Departure required if:
        // 1. There are tasks at this building
        // 2. Worker has been at the building for more than 5 minutes
        // 3. Worker hasn't already departed today
        
        guard !checklist.allTasks.isEmpty else { return false }
        guard let timeSpent = checklist.timeSpentMinutes, timeSpent >= 5 else { return false }
        
        let hasAlreadyDeparted = try await SiteLogService.shared.hasWorkerDepartedToday(
            workerId: workerId,
            buildingId: buildingId
        )
        
        return !hasAlreadyDeparted
    }
}
