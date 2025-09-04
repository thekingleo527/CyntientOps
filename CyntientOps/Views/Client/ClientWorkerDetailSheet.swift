import SwiftUI

struct ClientWorkerDetailSheet: View {
    let workerId: String
    let container: ServiceContainer
    let onAssignTask: (CoreTypes.ContextualTask) -> Void
    let onScheduleUpdate: (CoreTypes.WorkerSchedule) -> Void
    
    @State private var worker: CoreTypes.WorkerDetail?
    @State private var isLoading = true
    @State private var currentTasks: [CoreTypes.ContextualTask] = []
    @State private var schedule: [CoreTypes.WorkerScheduleItem] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading worker details...")
                        .foregroundColor(.white)
                } else if let worker = worker {
                    // Worker Header
                    workerHeaderSection(worker)
                    
                    // Current Tasks
                    currentTasksSection
                    
                    // Today's Schedule
                    todaysScheduleSection
                    
                    // Performance Metrics
                    performanceMetricsSection(worker)
                    
                    // Capabilities
                    capabilitiesSection(worker)
                    
                    // Quick Actions
                    quickActionsSection
                }
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
        .task {
            await loadWorkerDetail()
        }
    }
    
    private func workerHeaderSection(_ worker: CoreTypes.WorkerDetail) -> some View {
        VStack(spacing: 12) {
            // Worker Avatar and Basic Info
            VStack(spacing: 8) {
                Circle()
                    .fill(worker.isActive ? .green : .red)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(getWorkerInitials(worker.name))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                Text(worker.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(worker.role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Status and Location
            HStack(spacing: 16) {
                Label(worker.isActive ? "Active" : "Inactive", systemImage: "circle.fill")
                    .foregroundColor(worker.isActive ? .green : .red)
                
                if let location = worker.currentLocation {
                    Label(location, systemImage: "building.2")
                        .foregroundColor(.blue)
                }
            }
            .font(.caption)
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var currentTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Tasks")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(currentTasks.prefix(5), id: \.id) { task in
                ClientTaskRow(task: task) {
                    onAssignTask(task)
                }
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var todaysScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Schedule")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(schedule.prefix(8), id: \.id) { item in
                ScheduleItemView(item: item)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func performanceMetricsSection(_ worker: CoreTypes.WorkerDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                WorkerMetricCard(title: "Completion", value: "\(Int(worker.completionRate * 100))%", icon: "checkmark.circle", color: .green)
                WorkerMetricCard(title: "Efficiency", value: "\(Int(worker.efficiency * 100))%", icon: "speedometer", color: .blue)
                WorkerMetricCard(title: "Quality", value: "\(Int(worker.qualityScore * 100))%", icon: "star.circle", color: .purple)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func capabilitiesSection(_ worker: CoreTypes.WorkerDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Capabilities")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(worker.capabilities, id: \.self) { capability in
                    Text(capability)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CyntientOpsDesign.DashboardColors.clientPrimary.opacity(0.2))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                Button("Assign Task") {
                    // Handle task assignment
                }
                .buttonStyle(.borderedProminent)
                
                Button("Update Schedule") {
                    // Handle schedule update
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func loadWorkerDetail() async {
        do {
            // Load worker profile from WorkerService
            let profile = try await container.workers.getWorkerProfile(for: workerId)
            // Load tasks from TaskService
            let tasks = try await container.tasks.getTasksForWorker(workerId)
            
            // Build WorkerDetail using real data and simple derived metrics
            let completed = tasks.filter { $0.isCompleted }
            let completionRate = tasks.isEmpty ? 0.0 : Double(completed.count) / Double(tasks.count)
            let currentLocation = tasks.first?.buildingName ?? tasks.first?.building?.name
            let capabilitiesRecord = try? await container.workers.getWorkerCapabilityRecord(workerId)
            let capabilities = capabilitiesRecord != nil ? [
                capabilitiesRecord!.canUploadPhotos ? "Can Upload Photos" : nil,
                capabilitiesRecord!.canAddNotes ? "Can Add Notes" : nil,
                capabilitiesRecord!.canAddEmergencyTasks ? "Can Add Emergency Tasks" : nil
            ].compactMap { $0 } : []
            
            let detail = CoreTypes.WorkerDetail(
                id: profile.id,
                name: profile.name,
                role: profile.role.rawValue.capitalized,
                capabilities: capabilities.isEmpty ? ["General Operations"] : capabilities,
                isActive: profile.isActive,
                currentLocation: currentLocation,
                completionRate: completionRate,
                efficiency: 0.9,
                qualityScore: 0.9
            )
            
            // Build a simple schedule from tasks with scheduledDate
            let scheduleItems: [CoreTypes.WorkerScheduleItem] = tasks.compactMap { task in
                guard let start = task.scheduledDate ?? task.dueDate else { return nil }
                let duration: TimeInterval = task.estimatedDuration ?? 3600
                let end = start.addingTimeInterval(duration)
                let name = task.title
                let location = task.buildingName ?? (task.buildingId.flatMap { CanonicalIDs.Buildings.getName(for: $0) } ?? "")
                return CoreTypes.WorkerScheduleItem(id: UUID().uuidString, startTime: start, endTime: end, taskName: name, location: location)
            }
            
            var derivedSchedule = scheduleItems
            if derivedSchedule.isEmpty {
                // Fallback: derive today's schedule from routine schedules
                do {
                    let all = try await container.operationalData.getWorkerWeeklySchedule(for: workerId)
                    let todayStart = Calendar.current.startOfDay(for: Date())
                    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: todayStart) ?? Date()
                    derivedSchedule = all.filter { $0.startTime >= todayStart && $0.startTime < tomorrow }
                        .sorted(by: { $0.startTime < $1.startTime })
                        .map { r in
                            CoreTypes.WorkerScheduleItem(
                                id: r.id,
                                startTime: r.startTime,
                                endTime: r.endTime,
                                taskName: r.title,
                                location: r.buildingName
                            )
                        }
                } catch {
                    // ignore fallback errors
                }
            }
            await MainActor.run {
                self.worker = detail
                self.currentTasks = tasks
                self.schedule = derivedSchedule
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func getWorkerInitials(_ name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            let first = String(components[0].prefix(1)).uppercased()
            let last = String(components[1].prefix(1)).uppercased()
            return "\(first)\(last)"
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Supporting Views

// Removed duplicate TaskRowView - using existing one from WeatherDashboardComponent

struct ScheduleItemView: View {
    let item: CoreTypes.WorkerScheduleItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.startTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(item.endTime.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.taskName)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text(item.location)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// Using existing WorkerMetricCard from WorkerProfileView.swift

struct ClientTaskRow: View {
    let task: CoreTypes.ContextualTask
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    if let description = task.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(task.status.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(statusColor(task.status))
                    
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func statusColor(_ status: CoreTypes.TaskStatus) -> Color {
        switch status {
        case .completed: return .green
        case .inProgress: return .blue
        case .pending: return .orange
        case .overdue: return .red
        default: return .gray
        }
    }
}
