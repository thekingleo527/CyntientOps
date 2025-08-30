//
//  WeeklyScheduleView.swift
//  CyntientOps
//
//  Weekly schedule view showing real routine schedules from OperationalDataManager
//  Displays worker's actual building assignments and task schedules
//

import SwiftUI
import MapKit

public struct WeeklyScheduleView: View {
    
    @StateObject private var viewModel: WorkerProfileViewModel
    @State private var selectedDay: String? = nil
    @State private var showingTaskDetails = false
    @State private var selectedTask: OperationalDataTaskAssignment? = nil
    
    public init(viewModel: WorkerProfileViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Header
            headerView
            
            // Schedule Grid
            if viewModel.weeklySchedule.isEmpty {
                emptyStateView
            } else {
                scheduleGridView
            }
            
            // Selected Day Details
            if let selectedDay = selectedDay {
                dayDetailsView(for: selectedDay)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .onAppear {
            // Auto-select today
            let today = DateFormatter().string(from: Date())
            if let todaySchedule = viewModel.weeklySchedule.first(where: { $0.dayOfWeek.contains(today) }) {
                selectedDay = todaySchedule.dayOfWeek
            }
        }
        .sheet(isPresented: $showingTaskDetails) {
            if let task = selectedTask {
                TaskDetailSheet(task: task)
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weekly Schedule")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let worker = viewModel.currentWorker {
                    Text("\(worker.name)'s Routine")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Summary Stats
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(viewModel.assignedBuildings.count) Buildings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(viewModel.workerAssignments.count) Tasks")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Schedule Data")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Worker assignments and schedules will appear here once loaded from the operational data.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 32)
    }
    
    private var scheduleGridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(viewModel.weeklySchedule, id: \.dayOfWeek) { scheduleItem in
                DayScheduleCard(
                    scheduleItem: scheduleItem,
                    isSelected: selectedDay == scheduleItem.dayOfWeek,
                    onTap: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDay = selectedDay == scheduleItem.dayOfWeek ? nil : scheduleItem.dayOfWeek
                        }
                    }
                )
            }
        }
    }
    
    private func dayDetailsView(for day: String) -> some View {
        guard let scheduleItem = viewModel.weeklySchedule.first(where: { $0.dayOfWeek == day }) else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(day) Details")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Close") {
                        withAnimation {
                            selectedDay = nil
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                // Schedule Summary
                HStack(spacing: 16) {
                    ScheduleSummaryItem(
                        icon: "clock",
                        title: "Time Range",
                        value: "\(scheduleItem.startTime) - \(scheduleItem.endTime)"
                    )
                    
                    ScheduleSummaryItem(
                        icon: "building.2",
                        title: "Buildings",
                        value: "\(scheduleItem.buildingsCount)"
                    )
                    
                    ScheduleSummaryItem(
                        icon: "list.bullet",
                        title: "Tasks",
                        value: "\(scheduleItem.tasks.count)"
                    )
                }
                
                // Task List
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(scheduleItem.tasks, id: \.taskName) { task in
                            TaskCard(task: task) {
                                selectedTask = task
                                showingTaskDetails = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        )
    }
}

// MARK: - Supporting Views

private struct DayScheduleCard: View {
    let scheduleItem: WorkerProfileViewModel.WeeklyScheduleItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Day Header
                HStack {
                    Text(scheduleItem.dayOfWeek)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Spacer()
                    
                    if scheduleItem.tasks.isEmpty {
                        Image(systemName: "circle")
                            .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                            .font(.caption)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(isSelected ? .white : .green)
                            .font(.caption)
                    }
                }
                
                // Schedule Info
                if scheduleItem.tasks.isEmpty {
                    Text("No tasks")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text("\(scheduleItem.startTime) - \(scheduleItem.endTime)")
                                .font(.caption)
                        }
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        
                        HStack {
                            Image(systemName: "building.2")
                                .font(.caption2)
                            Text("\(scheduleItem.buildingsCount) buildings")
                                .font(.caption)
                        }
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        
                        HStack {
                            Image(systemName: "list.bullet")
                                .font(.caption2)
                            Text("\(scheduleItem.tasks.count) tasks")
                                .font(.caption)
                        }
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct ScheduleSummaryItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
    }
}

private struct TaskCard: View {
    let task: OperationalDataTaskAssignment
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Task Header
                HStack {
                    Text(task.taskName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // Priority indicator
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 8, height: 8)
                }
                
                // Building
                HStack {
                    Image(systemName: "building.2")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(task.building)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Duration
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(task.estimatedDuration) min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(width: 140)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var priorityColor: Color {
        switch task.skillLevel.lowercased() {
        case "high", "expert":
            return .red
        case "medium", "intermediate":
            return .orange
        default:
            return .green
        }
    }
}

// MARK: - Task Detail Sheet

private struct TaskDetailSheet: View {
    let task: OperationalDataTaskAssignment
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Task Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.taskName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(task.building)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Task Details
                    VStack(alignment: .leading, spacing: 12) {
                        WorkerDetailRow(title: "Category", value: task.category)
                        WorkerDetailRow(title: "Skill Level", value: task.skillLevel)
                        WorkerDetailRow(title: "Recurrence", value: task.recurrence)
                        WorkerDetailRow(title: "Estimated Duration", value: "\(task.estimatedDuration) minutes")
                        
                        if let startHour = task.startHour, let endHour = task.endHour {
                            WorkerDetailRow(title: "Time Window", value: String(format: "%02d:00 - %02d:00", startHour, endHour))
                        }
                        
                        if let daysOfWeek = task.daysOfWeek {
                            WorkerDetailRow(title: "Days", value: daysOfWeek)
                        }
                        
                        WorkerDetailRow(title: "Photo Required", value: task.requiresPhoto ? "Yes" : "No")
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct WorkerDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - PRODUCTION BUILD - No Previews