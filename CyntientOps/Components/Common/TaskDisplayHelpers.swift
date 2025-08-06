//
//  TaskDisplayHelpers.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: Proper optional unwrapping for urgency
//  ✅ FIXED: Exhaustive switch statements
//  ✅ FIXED: Removed non-existent estimatedDuration property
//  ✅ FIXED: Removed dependency on deleted ContextualTaskIntelligence extension
//  ✅ FIXED: Building name now uses actual ContextualTask properties
//  ✅ FIXED: Preview section - using completedAt instead of completedDate
//
//  Note: ContextualTask actual properties:
//  - id: String
//  - title: String (not 'name')
//  - description: String?
//  - isCompleted: Bool (computed property, not a parameter)
//  - completedAt: Date? (stored property)
//  - completedDate: Date? (computed property that returns completedAt)
//  - dueDate: Date? (not 'scheduledDate')
//  - category: TaskCategory?
//  - urgency: TaskUrgency?
//  - building: NamedCoordinate?
//  - worker: WorkerProfile?
//  - buildingId: String?
//  - priority: TaskUrgency?
//

import SwiftUI
import Foundation

// MARK: - Task Display Helpers

/// Helper functions for displaying tasks in various UI components
public struct TaskDisplayHelpers {
    
    // MARK: - Status Display
    
    /// Get appropriate color for task status
    public static func statusColor(for task: ContextualTask) -> Color {
        if task.isCompleted {
            return .green
        } else if let dueDate = task.dueDate, dueDate < Date() {
            return .red // Overdue
        } else if let urgency = task.urgency {
            // Use the same color logic as in TaskRowView
            switch urgency {
            case .low: return .green
            case .normal: return .blue
            case .medium: return .orange
            case .high: return .red
            case .critical, .urgent, .emergency: return .purple
            }
        } else {
            return .gray // Default when no urgency
        }
    }
    
    /// Get status icon for task
    public static func statusIcon(for task: ContextualTask) -> String {
        if task.isCompleted {
            return "checkmark.circle.fill"
        } else if let dueDate = task.dueDate, dueDate < Date() {
            return "exclamationmark.triangle.fill"
        } else {
            return "circle"
        }
    }
    
    /// Get status text for task
    public static func statusText(for task: ContextualTask) -> String {
        if task.isCompleted {
            return "Completed"
        } else if let dueDate = task.dueDate, dueDate < Date() {
            return "Overdue"
        } else {
            return "Pending"
        }
    }
    
    // MARK: - Time Display
    
    /// Get formatted start time for task
    public static func startTimeText(for task: ContextualTask) -> String {
        // Use dueDate as scheduled date is not in the actual model
        guard let dueDate = task.dueDate else {
            return "No scheduled time"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }
    
    /// Get relative time description
    public static func relativeTimeText(for task: ContextualTask) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        
        if let dueDate = task.dueDate {
            return formatter.localizedString(for: dueDate, relativeTo: Date())
        } else {
            return "No time set"
        }
    }
    
    // MARK: - Worker Assignment
    
    /// Get assigned worker ID for display
    public static func assignedWorkerIdText(for task: ContextualTask) -> String {
        // Note: ContextualTask doesn't have assignedWorkerId property
        // Using worker.id if available
        return task.worker?.id ?? "Unassigned"
    }
    
    /// Get assigned worker name for display
    public static func assignedWorkerName(for task: ContextualTask) -> String {
        if let worker = task.worker {
            return worker.name
        } else {
            return "Unassigned"
        }
    }
    
    // MARK: - Priority Display
    
    /// Get priority badge view
    public static func priorityBadge(for task: ContextualTask) -> some View {
        let urgencyColor: Color = {
            if let urgency = task.urgency {
                switch urgency {
                case .low: return .green
                case .normal: return .blue
                case .medium: return .orange
                case .high: return .red
                case .critical, .urgent, .emergency: return .purple
                }
            }
            return .gray
        }()
        
        return HStack(spacing: 4) {
            Circle()
                .fill(urgencyColor)
                .frame(width: 8, height: 8)
            
            Text(task.urgency?.rawValue ?? "Normal")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    // MARK: - Duration Calculations
    
    /// Calculate estimated duration for task
    public static func estimatedDurationText(for task: ContextualTask) -> String {
        // Estimate duration based on urgency and category
        let baseDuration: TimeInterval
        
        // First check urgency for time-sensitive tasks
        if let urgency = task.urgency {
            switch urgency {
            case .critical, .emergency:
                baseDuration = 3600 // 1 hour
            case .high, .urgent:
                baseDuration = 2700 // 45 minutes
            case .medium:
                baseDuration = 1800 // 30 minutes
            case .normal:
                baseDuration = 1200 // 20 minutes
            case .low:
                baseDuration = 900  // 15 minutes
            }
        } else {
            // Then check category for typical durations
            if let category = task.category {
                switch category {
                case .cleaning:
                    baseDuration = 1800 // 30 minutes
                case .maintenance:
                    baseDuration = 3600 // 1 hour
                case .repair:
                    baseDuration = 5400 // 1.5 hours
                case .inspection:
                    baseDuration = 1200 // 20 minutes
                case .sanitation:
                    baseDuration = 2400 // 40 minutes
                case .landscaping:
                    baseDuration = 7200 // 2 hours
                case .security:
                    baseDuration = 900  // 15 minutes
                case .emergency:
                    baseDuration = 3600 // 1 hour
                case .installation:
                    baseDuration = 7200 // 2 hours
                case .utilities:
                    baseDuration = 2700 // 45 minutes
                case .renovation:
                    baseDuration = 10800 // 3 hours
                case .administrative:
                    baseDuration = 1800 // 30 minutes
                }
            } else {
                baseDuration = 1800 // Default 30 minutes
            }
        }
        
        return formatDuration(baseDuration)
    }
    
    private static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Progress Indicators
    
    /// Get progress indicator for task
    public static func progressIndicator(for task: ContextualTask) -> some View {
        Group {
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if let dueDate = task.dueDate, dueDate < Date() {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Category Display
    
    /// Get category badge for task
    public static func categoryBadge(for task: ContextualTask) -> some View {
        let categoryText = task.title.lowercased().contains("clean") ? "Cleaning" :
                          task.title.lowercased().contains("maintenance") ? "Maintenance" :
                          task.title.lowercased().contains("repair") ? "Repair" : "General"
        
        let categoryColor: Color = {
            switch categoryText {
            case "Cleaning": return .blue
            case "Maintenance": return .orange
            case "Repair": return .red
            default: return .gray
            }
        }()
        
        return Text(categoryText)
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(categoryColor)
            .cornerRadius(8)
    }
    
    // MARK: - Building Display
    
    /// Get building name for task
    public static func buildingName(for task: ContextualTask) -> String {
        if let building = task.building {
            return building.name
        } else if let buildingId = task.buildingId, !buildingId.isEmpty {
            // Just show the building ID if we can't resolve the name
            // Don't try to access MainActor-isolated properties from here
            return "Building \(buildingId)"
        } else {
            return "Unknown Building"
        }
    }
    
    /// Get building short name for compact display
    public static func buildingShortName(for task: ContextualTask) -> String {
        // Get the full name first
        let name = buildingName(for: task)
        
        // Extract short name from building name
        if name.contains("Street") {
            let components = name.components(separatedBy: " ")
            return components.prefix(2).joined(separator: " ")
        } else {
            return name
        }
    }
    
    // MARK: - Completion Display
    
    /// Get completion status view
    public static func completionStatusView(for task: ContextualTask) -> some View {
        HStack(spacing: 4) {
            progressIndicator(for: task)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(statusText(for: task))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor(for: task))
                
                if let completedDate = task.completedDate {
                    Text("Completed \(RelativeDateTimeFormatter().localizedString(for: completedDate, relativeTo: Date()))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - SwiftUI View Extensions

extension View {
    /// Apply task status styling
    func taskStatusStyle(for task: ContextualTask) -> some View {
        self
            .foregroundColor(TaskDisplayHelpers.statusColor(for: task))
            .opacity(task.isCompleted ? 0.7 : 1.0)
    }
    
    /// Apply task priority styling
    func taskPriorityStyle(for task: ContextualTask) -> some View {
        let urgencyColor: Color = {
            if let urgency = task.urgency {
                switch urgency {
                case .low: return .green
                case .normal: return .blue
                case .medium: return .orange
                case .high: return .red
                case .critical, .urgent, .emergency: return .purple
                }
            }
            return .gray
        }()
        
        return self
            .overlay(
                Rectangle()
                    .fill(urgencyColor)
                    .frame(width: 3)
                    .cornerRadius(1.5),
                alignment: .leading
            )
    }
}

// MARK: - Preview Support

#if DEBUG
struct TaskDisplayHelpers_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // ✅ FIXED: Using completedAt instead of completedDate
            let sampleTask = ContextualTask(
                id: "preview-task",
                title: "Clean Lobby",
                description: "Daily lobby cleaning",
                completedAt: nil,  // This makes isCompleted false
                dueDate: Date().addingTimeInterval(3600),
                category: .cleaning,
                urgency: .high,
                building: nil,
                worker: nil,
                buildingId: "123 Main Street",
                priority: .high
            )
            
            let completedTask = ContextualTask(
                id: "preview-task-2",
                title: "Replace Light Bulbs",
                description: "Replace bulbs in hallway",
                completedAt: Date(),  // This makes isCompleted true
                dueDate: Date().addingTimeInterval(-3600),
                category: .maintenance,
                urgency: .medium,
                building: nil,
                worker: nil,
                buildingId: "456 Park Ave",
                priority: .medium
            )
            
            VStack(alignment: .leading, spacing: 16) {
                // Pending task
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pending Task").font(.caption).foregroundColor(.secondary)
                    HStack(spacing: 12) {
                        TaskDisplayHelpers.priorityBadge(for: sampleTask)
                        TaskDisplayHelpers.categoryBadge(for: sampleTask)
                    }
                    TaskDisplayHelpers.completionStatusView(for: sampleTask)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                
                // Completed task
                VStack(alignment: .leading, spacing: 8) {
                    Text("Completed Task").font(.caption).foregroundColor(.secondary)
                    HStack(spacing: 12) {
                        TaskDisplayHelpers.priorityBadge(for: completedTask)
                        TaskDisplayHelpers.categoryBadge(for: completedTask)
                    }
                    TaskDisplayHelpers.completionStatusView(for: completedTask)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}
#endif
