//
//
//  TimeBasedTaskFilter.swift
//  CyntientOps
//
//  ✅ FIXED: Updated to use dueDate instead of scheduledDate
//  ✅ FIXED: Corrected filter syntax for overdue tasks
//  ✅ ALIGNED: With ContextualTask properties
//

import Foundation

public struct TimeBasedTaskFilter {
    
    // Filter tasks based on timeframe
    static func filterTasksForTimeframe(_ tasks: [ContextualTask], timeframe: FilterTimeframe) -> [ContextualTask] {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeframe {
        case .today:
            return tasks.filter { task in
                // ✅ FIXED: Use dueDate instead of scheduledDate
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: now)
            }
        case .thisWeek:
            return tasks.filter { task in
                // ✅ FIXED: Use dueDate instead of scheduledDate
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDate(dueDate, equalTo: now, toGranularity: .weekOfYear)
            }
        case .thisMonth:
            return tasks.filter { task in
                // ✅ FIXED: Use dueDate instead of scheduledDate
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDate(dueDate, equalTo: now, toGranularity: .month)
            }
        case .overdue:
            // ✅ FIXED: Proper filter syntax
            return tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return dueDate < now && !task.isCompleted
            }
        }
    }
    
    public static func formatTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // Calculate time until task is due
    static func timeUntilTask(_ task: ContextualTask) -> String {
        // ✅ FIXED: Use dueDate instead of scheduledDate
        guard let dueDate = task.dueDate else { return "No time set" }
        
        let timeInterval = dueDate.timeIntervalSinceNow
        if timeInterval < 0 {
            return "Overdue"
        }
        
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // Additional helper methods
    
    /// Get tasks due within the next N hours
    public static func tasksWithinHours(_ tasks: [ContextualTask], hours: Int) -> [ContextualTask] {
        let now = Date()
        let deadline = now.addingTimeInterval(TimeInterval(hours * 3600))
        
        return tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= now && dueDate <= deadline && !task.isCompleted
        }
    }
    
    /// Get urgent tasks (high priority or due soon)
    public static func urgentTasks(_ tasks: [ContextualTask]) -> [ContextualTask] {
        let now = Date()
        let urgentDeadline = now.addingTimeInterval(7200) // 2 hours
        
        return tasks.filter { task in
            guard !task.isCompleted else { return false }
            
            // Check if high priority
            if let urgency = task.urgency,
               (urgency == .high || urgency == .critical || urgency == .urgent) {
                return true
            }
            
            // Check if due soon
            if let dueDate = task.dueDate {
                return dueDate <= urgentDeadline
            }
            
            return false
        }
    }
    
    /// Group tasks by due date
    public static func groupTasksByDate(_ tasks: [ContextualTask]) -> [Date: [ContextualTask]] {
        let calendar = Calendar.current
        
        return Dictionary(grouping: tasks) { task in
            guard let dueDate = task.dueDate else {
                // Return a far future date for tasks without due dates
                return Date.distantFuture
            }
            // Normalize to start of day
            return calendar.startOfDay(for: dueDate)
        }
    }
}

public enum FilterTimeframe: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case overdue = "Overdue"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .today:
            return "calendar.day.timeline.today"
        case .thisWeek:
            return "calendar.week"
        case .thisMonth:
            return "calendar.month"
        case .overdue:
            return "exclamationmark.triangle"
        }
    }
}
