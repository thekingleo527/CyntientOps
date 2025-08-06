//
//  WorkerTodaysTasksSection.swift
//  CyntientOps Phase 4
//
//  Today's tasks section showing all tasks for the current day
//

import SwiftUI

struct WorkerTodaysTasksSection: View {
    let tasks: [CoreTypes.ContextualTask]
    let completedTasks: [CoreTypes.ContextualTask]
    let onTaskTap: (CoreTypes.ContextualTask) -> Void
    let requiresPhoto: Bool
    
    @State private var showCompleted = false
    
    private var pendingTasks: [CoreTypes.ContextualTask] {
        tasks.filter { !$0.isCompleted }
    }
    
    private var overdueTasks: [CoreTypes.ContextualTask] {
        pendingTasks.filter { $0.isOverdue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text("Today's Tasks")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                StatusPill(
                    text: "\(completedTasks.count)/\(tasks.count)",
                    color: completedTasks.count == tasks.count ? .green : .blue,
                    style: .outlined
                )
                
                Spacer()
                
                // Toggle for completed tasks
                if !completedTasks.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            showCompleted.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(showCompleted ? "Hide" : "Show")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text("Completed")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            
            // Overdue Tasks (if any)
            if !overdueTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock.badge.exclamationmark")
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                        
                        Text("Overdue")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        
                        StatusPill(text: "\(overdueTasks.count)", color: .red, style: .filled)
                    }
                    
                    ForEach(overdueTasks) { task in
                        WorkerTaskCard(
                            task: task,
                            style: .overdue,
                            requiresPhoto: requiresPhoto,
                            onTap: { onTaskTap(task) }
                        )
                    }
                }
            }
            
            // Pending Tasks
            if !pendingTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if !overdueTasks.isEmpty {
                        HStack {
                            Text("Remaining Tasks")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            StatusPill(
                                text: "\(pendingTasks.count - overdueTasks.count)", 
                                color: .gray,
                                style: .outlined
                            )
                        }
                    }
                    
                    ForEach(pendingTasks.filter { !$0.isOverdue }) { task in
                        WorkerTaskCard(
                            task: task,
                            style: .pending,
                            requiresPhoto: requiresPhoto,
                            onTap: { onTaskTap(task) }
                        )
                    }
                }
            }
            
            // Completed Tasks (collapsible)
            if showCompleted && !completedTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14))
                        
                        Text("Completed Today")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        StatusPill(text: "\(completedTasks.count)", color: .green, style: .filled)
                    }
                    
                    ForEach(completedTasks) { task in
                        WorkerTaskCard(
                            task: task,
                            style: .completed,
                            requiresPhoto: requiresPhoto,
                            onTap: { onTaskTap(task) }
                        )
                    }
                }
            }
            
            // Empty state
            if tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("No tasks assigned for today")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Check with your supervisor if you need additional assignments")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct WorkerTaskCard: View {
    let task: CoreTypes.ContextualTask
    let style: TaskCardStyle
    let requiresPhoto: Bool
    let onTap: () -> Void
    
    enum TaskCardStyle {
        case pending, overdue, completed
        
        var backgroundColor: Color {
            switch self {
            case .pending: return Color.white.opacity(0.05)
            case .overdue: return Color.red.opacity(0.1)
            case .completed: return Color.green.opacity(0.1)
            }
        }
        
        var borderColor: Color {
            switch self {
            case .pending: return Color.white.opacity(0.1)
            case .overdue: return Color.red.opacity(0.3)
            case .completed: return Color.green.opacity(0.3)
            }
        }
        
        var iconColor: Color {
            switch self {
            case .pending: return .gray
            case .overdue: return .red
            case .completed: return .green
            }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status Icon
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(style.iconColor)
                
                // Task Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 8) {
                        if let building = task.building {
                            Label(building.name, systemImage: "building.2")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        
                        if let urgency = task.urgency, urgency != .low {
                            Text(urgency.rawValue.capitalized)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(urgencyColor(urgency))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(urgencyColor(urgency).opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                // Action Indicators
                HStack(spacing: 8) {
                    if task.requiresPhoto == true || requiresPhoto {
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            
                            Text("Photo")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(6)
                    }
                    
                    if task.isOverdue && !task.isCompleted {
                        VStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                            
                            Text("Late")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(6)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(style.backgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func urgencyColor(_ urgency: CoreTypes.TaskUrgency) -> Color {
        switch urgency {
        case .emergency: return .red
        case .critical: return .red
        case .urgent: return .orange
        case .high: return .orange
        case .normal: return .green
        case .medium: return .blue
        case .low: return .gray
        }
    }
}

#if DEBUG
struct WorkerTodaysTasksSection_Previews: PreviewProvider {
    static var previews: some View {
        let building = CoreTypes.NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            address: "150 W 17th St",
            latitude: 40.7408,
            longitude: -73.9971,
            type: .educational
        )
        
        let allTasks = [
            CoreTypes.ContextualTask(
                id: "1",
                title: "Clean gallery floors - Level 2",
                description: "Daily cleaning routine",
                status: .completed,
                urgency: .medium,
                building: building,
                requiresPhoto: true
            ),
            CoreTypes.ContextualTask(
                id: "2",
                title: "Vacuum lobby carpets - Main entrance",
                description: "Morning lobby cleaning",
                dueDate: Date().addingTimeInterval(-3600),
                urgency: .high,
                building: building,
                requiresPhoto: true
            ),
            CoreTypes.ContextualTask(
                id: "3",
                title: "Empty waste receptacles - All floors",
                description: "Daily waste collection",
                urgency: .medium,
                building: building,
                requiresPhoto: false
            )
        ]
        
        let completedTasks = allTasks.filter { $0.isCompleted }
        
        WorkerTodaysTasksSection(
            tasks: allTasks,
            completedTasks: completedTasks,
            onTaskTap: { _ in },
            requiresPhoto: true
        )
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif