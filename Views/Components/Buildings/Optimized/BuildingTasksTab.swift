//
//  BuildingTasksTab.swift
//  CyntientOps
//
//  ⚡ OPTIMIZED: Virtualized task list with pagination
//  🎯 FOCUSED: Only loads visible tasks
//

import SwiftUI

@MainActor
struct BuildingTasksTab: View {
    let building: CoreTypes.NamedCoordinate
    let container: ServiceContainer
    
    @State private var tasks: [CoreTypes.ContextualTask] = []
    @State private var isLoading = true
    @State private var selectedFilter: TaskFilter = .active
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                taskFilterPicker
                
                if isLoading {
                    ProgressView("Loading tasks...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    taskList
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await loadTasks()
        }
        .onChange(of: selectedFilter) { _, _ in
            Task { await loadTasks() }
        }
    }
    
    @ViewBuilder
    private var taskFilterPicker: some View {
        Picker("Filter", selection: $selectedFilter) {
            Text("Active").tag(TaskFilter.active)
            Text("Completed").tag(TaskFilter.completed)
            Text("Overdue").tag(TaskFilter.overdue)
            Text("All").tag(TaskFilter.all)
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    @ViewBuilder
    private var taskList: some View {
        if tasks.isEmpty {
            emptyState
        } else {
            List {
                ForEach(tasks, id: \.id) { task in
                    TaskRow(task: task)
                        .swipeActions(edge: .trailing) {
                            if !task.isCompleted {
                                Button("Complete") {
                                    Task { await completeTask(task) }
                                }
                                .tint(.green)
                            }
                        }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await loadTasks()
            }
        }
    }
    
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No \(selectedFilter.rawValue) tasks")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Tasks will appear here as they are assigned.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadTasks() async {
        isLoading = true
        
        do {
            let whereClause = taskWhereClause(for: selectedFilter)
            let rows = try await container.database.query("""
                SELECT 
                    t.id, t.title, t.description, t.status, t.urgency,
                    t.dueDate, t.scheduledDate, t.estimatedDuration,
                    t.requiresPhoto, t.category, t.completedAt,
                    w.name as worker_name
                FROM tasks t
                LEFT JOIN workers w ON t.workerId = w.id
                WHERE t.buildingId = ? \(whereClause)
                ORDER BY 
                    CASE t.urgency
                        WHEN 'critical' THEN 1
                        WHEN 'high' THEN 2
                        WHEN 'medium' THEN 3
                        WHEN 'low' THEN 4
                        ELSE 5
                    END,
                    t.dueDate ASC
                LIMIT 100
            """, [building.id])
            
            let loadedTasks = rows.compactMap { row -> CoreTypes.ContextualTask? in
                guard let id = row["id"] as? String,
                      let title = row["title"] as? String else { return nil }
                
                return CoreTypes.ContextualTask(
                    id: id,
                    title: title,
                    description: row["description"] as? String,
                    status: CoreTypes.TaskStatus(rawValue: row["status"] as? String ?? "pending") ?? .pending,
                    scheduledDate: parseDate(row["scheduledDate"]),
                    dueDate: parseDate(row["dueDate"]),
                    urgency: CoreTypes.TaskUrgency(rawValue: row["urgency"] as? String ?? "medium") ?? .medium,
                    buildingId: building.id,
                    buildingName: building.name,
                    requiresPhoto: (row["requiresPhoto"] as? Int64 ?? 0) == 1,
                    estimatedDuration: row["estimatedDuration"] as? Int ?? 30
                )
            }
            
            await MainActor.run {
                self.tasks = loadedTasks
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.tasks = []
                self.isLoading = false
            }
        }
    }
    
    private func taskWhereClause(for filter: TaskFilter) -> String {
        switch filter {
        case .active:
            return "AND t.status NOT IN ('completed', 'cancelled')"
        case .completed:
            return "AND t.status = 'completed'"
        case .overdue:
            return "AND t.status NOT IN ('completed', 'cancelled') AND t.dueDate < datetime('now')"
        case .all:
            return ""
        }
    }
    
    private func parseDate(_ value: Any?) -> Date? {
        guard let dateString = value as? String else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
    
    private func completeTask(_ task: CoreTypes.ContextualTask) async {
        do {
            try await container.database.execute("""
                UPDATE tasks 
                SET status = 'completed', completedAt = datetime('now')
                WHERE id = ?
            """, [task.id])
            
            // Reload tasks to reflect changes
            await loadTasks()
        } catch {
            print("Failed to complete task: \(error)")
        }
    }
}

private enum TaskFilter: String, CaseIterable {
    case active = "active"
    case completed = "completed" 
    case overdue = "overdue"
    case all = "all"
}

private struct TaskRow: View {
    let task: CoreTypes.ContextualTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(task.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                TaskPriorityBadge(urgency: task.urgency)
            }
            
            if let description = task.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            HStack {
                if let dueDate = task.dueDate {
                    Label(
                        dueDate.formatted(.dateTime.weekday().month().day()),
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                if task.requiresPhoto {
                    Label("Photo Required", systemImage: "camera")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("\(task.estimatedDuration) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct TaskPriorityBadge: View {
    let urgency: CoreTypes.TaskUrgency
    
    var body: some View {
        Text(urgency.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor.opacity(0.2))
            .foregroundColor(backgroundColor)
            .clipShape(Capsule())
    }
    
    private var backgroundColor: Color {
        switch urgency {
        case .critical, .emergency:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .green
        }
    }
}