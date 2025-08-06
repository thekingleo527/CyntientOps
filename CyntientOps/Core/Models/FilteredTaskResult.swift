//
//  FilteredTaskResult.swift
//  CyntientOps
//
//  ✅ FIXED: urgencyLevel -> urgency property access
//  ✅ Clean FilteredTaskResult definition only
//

import Foundation

struct FilteredTaskResult {
    let tasks: [ContextualTask]
    let totalCount: Int
    let overdueCount: Int
    let completedCount: Int
    let currentCount: Int
    let upcomingCount: Int
    let contextBuildingName: String?
    let contextBuildingId: String?
    let isFilteredByBuilding: Bool
    
    init(
        tasks: [ContextualTask],
        totalCount: Int = 0,
        overdueCount: Int = 0,
        completedCount: Int = 0,
        currentCount: Int = 0,
        upcomingCount: Int = 0,
        contextBuildingName: String? = nil,
        contextBuildingId: String? = nil,
        isFilteredByBuilding: Bool = false
    ) {
        self.tasks = tasks
        self.totalCount = totalCount > 0 ? totalCount : tasks.count
        self.overdueCount = overdueCount
        self.completedCount = completedCount
        self.currentCount = currentCount
        self.upcomingCount = upcomingCount
        self.contextBuildingName = contextBuildingName
        self.contextBuildingId = contextBuildingId
        self.isFilteredByBuilding = isFilteredByBuilding
    }
}

// MARK: - Convenience Extensions

extension FilteredTaskResult {
    /// Quick access to filtered tasks by status
    var pendingTasks: [ContextualTask] {
        tasks.filter { !$0.isCompleted }
    }
    
    var completedTasks: [ContextualTask] {
        tasks.filter { $0.isCompleted }
    }
    
    /// Get tasks by urgency level - FIXED: use urgency instead of urgencyLevel
    var urgentTasks: [ContextualTask] {
        tasks.filter {
            if let urgency = $0.urgency {
                return urgency.rawValue.lowercased() == "urgent" ||
                       urgency.rawValue.lowercased() == "high" ||
                       urgency.rawValue.lowercased() == "critical"
            }
            return false
        }
    }
    
    /// Check if there are any urgent tasks
    var hasUrgentTasks: Bool {
        !urgentTasks.isEmpty
    }
    
    /// Progress percentage (0.0 to 1.0)
    var progressPercentage: Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(completedCount) / Double(totalCount)
    }
    
    /// Context summary for UI display
    var contextSummary: String {
        if isFilteredByBuilding {
            return contextBuildingName ?? "Building Context"
        } else {
            return "All Buildings"
        }
    }
    
    /// Get task counts summary for display
    var taskCountSummary: String {
        if isFilteredByBuilding {
            return "\(tasks.count) tasks • \(contextBuildingName ?? "Building")"
        } else {
            return "\(tasks.count) tasks • All buildings"
        }
    }
    
    /// Check if context is empty (no tasks)
    var isEmpty: Bool {
        tasks.isEmpty
    }
    
    /// Get remaining tasks count
    var remainingCount: Int {
        max(0, totalCount - completedCount)
    }
}
