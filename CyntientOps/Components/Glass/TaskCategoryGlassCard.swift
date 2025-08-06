//
//  TaskCategoryGlassCard.swift
//  CyntientOps v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Integrated with CyntientOpsDesign color system
//  ✅ IMPROVED: Glass effects and animations
//  ✅ OPTIMIZED: Better visual hierarchy and contrast
//

import Foundation
import SwiftUI

struct TaskCategoryGlassCard: View {
    let title: String
    let icon: String
    let tasks: [MaintenanceTask]
    let categoryColor: Color
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onTaskTap: (MaintenanceTask) -> Void
    let onTaskComplete: (MaintenanceTask) -> Void
    
    @State private var expandedTasks: Set<String> = []
    
    var pendingTasks: [MaintenanceTask] {
        tasks.filter { task in
            task.status != .completed
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section
            categoryHeader
            
            // Tasks content (expandable)
            if isExpanded && !pendingTasks.isEmpty {
                VStack(spacing: 12) {
                    ForEach(pendingTasks.prefix(5)) { task in
                        TaskRowGlassView(
                            task: task,
                            isExpanded: expandedTasks.contains(task.id),
                            isToday: isScheduledForToday(task),
                            onToggleExpand: { toggleTaskExpanded(task) },
                            onComplete: { onTaskComplete(task) },
                            onTap: { onTaskTap(task) }
                        )
                    }
                    
                    // Show more button if there are additional tasks
                    if pendingTasks.count > 5 {
                        showMoreButton
                    }
                }
                .padding(.top, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Empty state
            else if isExpanded && pendingTasks.isEmpty {
                emptyStateView
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(20)
        .francoDarkCardBackground(cornerRadius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .animation(CyntientOpsDesign.Animations.spring, value: isExpanded)
        .onAppear {
            // Auto-expand today's tasks
            for task in pendingTasks {
                if isScheduledForToday(task) {
                    expandedTasks.insert(task.id)
                }
            }
        }
    }
    
    // MARK: - Sub-components
    
    private var categoryHeader: some View {
        Button(action: onToggleExpand) {
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(categoryColor)
                }
                
                // Title and count
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    HStack(spacing: 12) {
                        Text("\(pendingTasks.count) pending")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        
                        if getTodayTasksCount() > 0 {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(CyntientOpsDesign.DashboardColors.warning)
                                    .frame(width: 6, height: 6)
                                
                                Text("\(getTodayTasksCount()) today")
                                    .font(.caption)
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
                            }
                        }
                        
                        if getOverdueTasksCount() > 0 {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(CyntientOpsDesign.DashboardColors.critical)
                                    .frame(width: 6, height: 6)
                                
                                Text("\(getOverdueTasksCount()) overdue")
                                    .font(.caption)
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Expand/collapse indicator
                VStack(spacing: 4) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        .rotationEffect(.degrees(isExpanded ? 0 : 0))
                        .animation(CyntientOpsDesign.Animations.spring, value: isExpanded)
                    
                    if pendingTasks.count > 0 {
                        Text("\(pendingTasks.count)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(categoryColor.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var showMoreButton: some View {
        Button(action: {
            // In a real implementation, this would navigate to a full task list
            if let firstTask = pendingTasks.first {
                onTaskTap(firstTask)
            }
        }) {
            HStack {
                Text("View all \(pendingTasks.count) tasks")
                    .font(.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(CyntientOpsDesign.DashboardColors.glassOverlay)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CyntientOpsDesign.DashboardColors.glassOverlay, lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(CyntientOpsDesign.DashboardColors.success)
            
            Text("All tasks completed!")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text("No pending tasks in this category")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Helper Methods
    
    private func toggleTaskExpanded(_ task: MaintenanceTask) {
        withAnimation(CyntientOpsDesign.Animations.spring) {
            if expandedTasks.contains(task.id) {
                expandedTasks.remove(task.id)
            } else {
                expandedTasks.insert(task.id)
            }
        }
    }
    
    private func isScheduledForToday(_ task: MaintenanceTask) -> Bool {
        guard let dueDate = task.dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    private func getTodayTasksCount() -> Int {
        pendingTasks.filter { isScheduledForToday($0) }.count
    }
    
    private func getOverdueTasksCount() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return pendingTasks.filter {
            guard let dueDate = $0.dueDate else { return false }
            return dueDate < today
        }.count
    }
}

// MARK: - TaskRowGlassView

struct TaskRowGlassView: View {
    let task: MaintenanceTask
    let isExpanded: Bool
    let isToday: Bool
    let onToggleExpand: () -> Void
    let onComplete: () -> Void
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main task row
            Button(action: onToggleExpand) {
                HStack(spacing: 12) {
                    // Task status indicator
                    taskStatusIndicator
                    
                    // Task content
                    taskContent
                    
                    Spacer()
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isToday ?
                        CyntientOpsDesign.DashboardColors.warning.opacity(0.1) :
                        CyntientOpsDesign.DashboardColors.glassOverlay
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isToday ?
                                CyntientOpsDesign.DashboardColors.warning.opacity(0.3) :
                                Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            
            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(CyntientOpsDesign.Animations.spring, value: isExpanded)
    }
    
    // MARK: - Sub-components
    
    private var taskContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                .multilineTextAlignment(.leading)
            
            HStack(spacing: 8) {
                // Time or duration
                if let dueDate = task.dueDate {
                    Text(formatTime(dueDate))
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                } else {
                    Text(formatDuration(task.estimatedDuration))
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                // Priority badge
                priorityBadge
                
                if isToday {
                    Text("TODAY")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(CyntientOpsDesign.DashboardColors.warning.opacity(0.2))
                        .cornerRadius(6)
                }
            }
        }
    }
    
    private var taskStatusIndicator: some View {
        ZStack {
            Circle()
                .stroke(urgencyColor, lineWidth: 2)
                .frame(width: 20, height: 20)
            
            if task.status == .completed {
                Circle()
                    .fill(CyntientOpsDesign.DashboardColors.success)
                    .frame(width: 12, height: 12)
            } else {
                Circle()
                    .fill(urgencyColor.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
        }
    }
    
    private var priorityBadge: some View {
        Text(task.urgency.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(urgencyColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(urgencyColor.opacity(0.2))
            .cornerRadius(6)
    }
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Description
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                // View details button
                Button(action: onTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                        Text("Details")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(CyntientOpsDesign.DashboardColors.glassOverlay)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Complete button
                Button(action: onComplete) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.caption)
                        Text("Complete")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(CyntientOpsDesign.DashboardColors.success)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 12)
        .background(CyntientOpsDesign.DashboardColors.glassOverlay.opacity(0.5))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var urgencyColor: Color {
        switch task.urgency {
        case .low:
            return CyntientOpsDesign.DashboardColors.success
        case .normal:
            return CyntientOpsDesign.DashboardColors.secondaryText
        case .medium:
            return Color.orange // Amber
        case .high:
            return CyntientOpsDesign.DashboardColors.warning
        case .critical, .emergency:
            return CyntientOpsDesign.DashboardColors.critical
        case .urgent:
            return Color.purple // Purple
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview

struct TaskCategoryGlassCard_Previews: PreviewProvider {
    static var sampleTasks: [MaintenanceTask] {
        [
            MaintenanceTask(
                title: "Clean Lobby Windows",
                description: "Clean all glass surfaces in the main lobby area",
                category: .cleaning,
                urgency: .medium,
                buildingId: "15",
                assignedWorkerId: "2",
                dueDate: Date()
            ),
            MaintenanceTask(
                title: "Vacuum Common Areas",
                description: "Vacuum all carpeted areas including hallways and lobby",
                category: .cleaning,
                urgency: .low,
                buildingId: "15",
                assignedWorkerId: "2",
                dueDate: Date()
            ),
            MaintenanceTask(
                title: "Emergency Light Check",
                description: "Test all emergency lighting systems",
                category: .inspection,
                urgency: .urgent,
                buildingId: "15",
                assignedWorkerId: "1",
                dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            )
        ]
    }
    
    static var previews: some View {
        ZStack {
            CyntientOpsDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    TaskCategoryGlassCard(
                        title: "Cleaning Routine",
                        icon: "sparkles",
                        tasks: sampleTasks,
                        categoryColor: CyntientOpsDesign.DashboardColors.info,
                        isExpanded: true,
                        onToggleExpand: {},
                        onTaskTap: { _ in },
                        onTaskComplete: { _ in }
                    )
                    
                    TaskCategoryGlassCard(
                        title: "Sanitation & Garbage",
                        icon: "trash",
                        tasks: [],
                        categoryColor: CyntientOpsDesign.DashboardColors.success,
                        isExpanded: true,
                        onToggleExpand: {},
                        onTaskTap: { _ in },
                        onTaskComplete: { _ in }
                    )
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }
}
