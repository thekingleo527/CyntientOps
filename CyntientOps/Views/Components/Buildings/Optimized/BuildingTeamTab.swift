//
//  BuildingTeamTab.swift
//  CyntientOps
//
//  👥 TEAM FOCUSED: Worker assignments and schedules
//  📊 DATA EFFICIENT: Minimal queries with maximum info
//

import SwiftUI

@MainActor
struct BuildingTeamTab: View {
    let building: CoreTypes.NamedCoordinate
    let container: ServiceContainer
    
    @State private var workers: [WorkerAssignment] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading team...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if workers.isEmpty {
                    emptyTeamState
                } else {
                    workerList
                }
            }
            .navigationTitle("Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Worker", systemImage: "person.badge.plus") {
                        // Handle adding worker
                    }
                }
            }
        }
        .task {
            await loadTeamMembers()
        }
    }
    
    @ViewBuilder
    private var emptyTeamState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Team Assigned")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Assign workers to this building to see their schedules and tasks.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var workerList: some View {
        List {
            ForEach(workers, id: \.workerId) { worker in
                WorkerRowView(worker: worker)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await loadTeamMembers()
        }
    }
    
    private func loadTeamMembers() async {
        isLoading = true
        
        do {
            let rows = try await container.database.query("""
                SELECT 
                    w.id, w.name, w.email, w.role,
                    wba.schedule_type, wba.start_time, wba.end_time,
                    COUNT(DISTINCT t.id) as active_tasks,
                    MAX(t.completedAt) as last_completion,
                    AVG(CASE WHEN t.status = 'completed' THEN 1.0 ELSE 0.0 END) as completion_rate
                FROM workers w
                INNER JOIN worker_building_assignments wba ON w.id = wba.worker_id
                LEFT JOIN tasks t ON w.id = t.workerId AND t.buildingId = ?
                WHERE wba.building_id = ? AND w.isActive = 1
                GROUP BY w.id, wba.schedule_type, wba.start_time, wba.end_time
                ORDER BY w.name
            """, [building.id, building.id])
            
            let loadedWorkers = rows.compactMap { row -> WorkerAssignment? in
                guard let id = row["id"] as? String,
                      let name = row["name"] as? String,
                      let email = row["email"] as? String else { return nil }
                
                return WorkerAssignment(
                    workerId: id,
                    name: name,
                    email: email,
                    role: row["role"] as? String ?? "worker",
                    scheduleType: row["schedule_type"] as? String ?? "daily",
                    startTime: row["start_time"] as? String,
                    endTime: row["end_time"] as? String,
                    activeTasks: row["active_tasks"] as? Int64 ?? 0,
                    completionRate: row["completion_rate"] as? Double ?? 0.0,
                    lastCompletion: parseDate(row["last_completion"])
                )
            }
            
            await MainActor.run {
                self.workers = loadedWorkers
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.workers = []
                self.isLoading = false
            }
        }
    }
    
    private func parseDate(_ value: Any?) -> Date? {
        guard let dateString = value as? String else { return nil }
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString)
    }
}

private struct WorkerAssignment {
    let workerId: String
    let name: String
    let email: String
    let role: String
    let scheduleType: String
    let startTime: String?
    let endTime: String?
    let activeTasks: Int64
    let completionRate: Double
    let lastCompletion: Date?
}

private struct WorkerRowView: View {
    let worker: WorkerAssignment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(worker.name)
                        .font(.headline)
                    
                    Text(worker.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                RoleBadge(role: worker.role)
            }
            
            // Schedule Info
            if let startTime = worker.startTime, let endTime = worker.endTime {
                HStack {
                    Label("\(startTime) - \(endTime)", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(worker.scheduleType.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
            
            // Performance Stats
            HStack(spacing: 20) {
                StatItem(
                    label: "Active Tasks",
                    value: "\(worker.activeTasks)"
                )
                
                StatItem(
                    label: "Completion Rate",
                    value: "\(Int(worker.completionRate * 100))%"
                )
                
                if let lastCompletion = worker.lastCompletion {
                    StatItem(
                        label: "Last Completion",
                        value: lastCompletion.formatted(.relative(presentation: .numeric))
                    )
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
}

private struct RoleBadge: View {
    let role: String
    
    var body: some View {
        Text(role.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(roleColor.opacity(0.2))
            .foregroundColor(roleColor)
            .clipShape(Capsule())
    }
    
    private var roleColor: Color {
        switch role.lowercased() {
        case "manager", "admin":
            return .purple
        case "supervisor":
            return .orange
        case "worker":
            return .blue
        default:
            return .gray
        }
    }
}

private struct StatItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}