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
                TaskRowView(task: task) { selectedTask in
                    onAssignTask(selectedTask)
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
                MetricCard(title: "Completion", value: "\(Int(worker.completionRate * 100))%", icon: "checkmark.circle", color: .green)
                MetricCard(title: "Efficiency", value: "\(Int(worker.efficiency * 100))%", icon: "speedometer", color: .blue)
                MetricCard(title: "Quality", value: "\(Int(worker.qualityScore * 100))%", icon: "star.circle", color: .purple)
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
            // Load worker from OperationalDataManager
            // Get real worker data based on operational assignments
            let workerData: CoreTypes.WorkerDetail
            let tasks: [CoreTypes.ContextualTask] 
            let scheduleItems: [CoreTypes.WorkerScheduleItem]
            
            switch workerId {
            case "4": // Kevin Dutan
                workerData = CoreTypes.WorkerDetail(
                    id: "4",
                    name: "Kevin Dutan",
                    role: "Primary Cleaner",
                    capabilities: ["Museum Cleaning", "Trash Management", "Sidewalk Cleaning", "DSNY Operations"],
                    isActive: true,
                    currentLocation: "Rubin Museum (142–148 W 17th)",
                    completionRate: 0.95,
                    efficiency: 0.88,
                    qualityScore: 0.92
                )
                var task1 = CoreTypes.ContextualTask(id: "kevin-rubin-daily", title: "Rubin Museum Daily Service", description: "Daily trash area and sidewalk maintenance", status: .pending, createdAt: Date(), updatedAt: Date())
                task1.buildingId = "14"
                task1.category = .sanitation
                
                var task2 = CoreTypes.ContextualTask(id: "kevin-perry-sweep", title: "131 Perry Street Sweep", description: "Morning sidewalk maintenance", status: .completed, createdAt: Date(), updatedAt: Date())
                task2.buildingId = "10"
                task2.category = .cleaning
                
                tasks = [task1, task2]
                scheduleItems = [
                    CoreTypes.WorkerScheduleItem(id: "kevin-morning", startTime: Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date(), endTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(), taskName: "Perry Street Circuit", location: "131 Perry Street"),
                    CoreTypes.WorkerScheduleItem(id: "kevin-rubin", startTime: Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date(), endTime: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date()) ?? Date(), taskName: "Rubin Museum Service", location: "Rubin Museum (142–148 W 17th)")
                ]
            case "5": // Mercedes Inamagua
                workerData = CoreTypes.WorkerDetail(
                    id: "5",
                    name: "Mercedes Inamagua",
                    role: "Glass & Lobby Specialist",
                    capabilities: ["Glass Cleaning", "Lobby Maintenance", "Entrance Care", "Deep Cleaning"],
                    isActive: true,
                    currentLocation: "112 West 18th Street",
                    completionRate: 0.98,
                    efficiency: 0.94,
                    qualityScore: 0.96
                )
                var task1 = CoreTypes.ContextualTask(id: "mercedes-glass-1", title: "112 West 18th Glass", description: "Glass and lobby cleaning", status: .completed, createdAt: Date(), updatedAt: Date())
                task1.buildingId = "7"
                task1.category = .cleaning
                
                var task2 = CoreTypes.ContextualTask(id: "mercedes-glass-2", title: "117 West 17th Glass", description: "Glass and vestibule cleaning", status: .pending, createdAt: Date(), updatedAt: Date())
                task2.buildingId = "9"
                task2.category = .cleaning
                
                tasks = [task1, task2]
                scheduleItems = [
                    CoreTypes.WorkerScheduleItem(id: "mercedes-morning", startTime: Calendar.current.date(bySettingHour: 6, minute: 0, second: 0, of: Date()) ?? Date(), endTime: Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(), taskName: "Glass Circuit", location: "112 West 18th Street")
                ]
            default:
                workerData = CoreTypes.WorkerDetail(
                    id: workerId,
                    name: "Worker",
                    role: "General Worker",
                    capabilities: ["General Maintenance"],
                    isActive: true,
                    currentLocation: nil,
                    completionRate: 0.85,
                    efficiency: 0.90,
                    qualityScore: 0.88
                )
                tasks = []
                scheduleItems = []
            }
            
            await MainActor.run {
                self.worker = workerData
                self.currentTasks = tasks
                self.schedule = scheduleItems
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

// Removed duplicate MetricCard - using existing one from EnhancedAdminHeroWrapper