//
//  WorkerDashboardMainView.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: Type reference errors for UrgencyLevel and DashboardSource
//  ✅ FIXED: Using correct types from CoreTypes
//  ✅ FIXED: TaskUrgency instead of UrgencyLevel
//  ✅ FIXED: DashboardUpdate.Source instead of DashboardSource
//

import SwiftUI
import Combine
import CoreLocation

struct WorkerDashboardMainView: View {
    // MARK: - ServiceContainer Integration
    let container: ServiceContainer
    
    // MARK: - ViewModels
    @StateObject private var viewModel: WorkerDashboardViewModel
    @StateObject private var locationManager = LocationManager.shared
    
    // MARK: - Environment Objects
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    
    // MARK: - State Management
    @State private var selectedTab = 0
    @State private var showingTaskDetail = false
    @State private var selectedTask: CoreTypes.ContextualTask?
    @State private var showingBuildingSelector = false
    @State private var showingProfile = false
    @State private var showingCamera = false
    @State private var currentPhotoTaskId: String?
    @State private var showingErrorAlert = false
    
    // MARK: - App Storage
    @AppStorage("workerPreferredLanguage") private var preferredLanguage = "en"
    @AppStorage("workerSimplifiedMode") private var simplifiedMode = false
    
    // MARK: - Initialization
    
    init(container: ServiceContainer) {
        self.container = container
        self._viewModel = StateObject(wrappedValue: WorkerDashboardViewModel(container: container))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Main Content
            VStack(spacing: 0) {
                // Header (60px) - Fixed
                WorkerDashboardHeader(
                    workerName: viewModel.workerProfile?.name ?? "Worker",
                    totalTasks: viewModel.todaysTasks.count,
                    completedTasks: viewModel.completedTasksCount,
                    currentBuilding: viewModel.currentBuilding?.name
                )
                .frame(height: 60)
                
                // Scrollable Content
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Hero Card (280px → 80px on scroll)
                        WorkerHeroCard(
                            workerProfile: viewModel.workerProfile,
                            currentBuilding: viewModel.currentBuilding,
                            todaysProgress: calculateTodaysProgress(),
                            clockedIn: viewModel.isCurrentlyClockedIn,
                            onClockAction: handleClockAction
                        )
                        .frame(height: 280) // Will compress on scroll
                        
                        // Urgent Tasks Section
                        if !viewModel.urgentTasks.isEmpty {
                            WorkerUrgentTasksSection(
                                tasks: viewModel.urgentTasks,
                                onTaskTap: handleTaskTap
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        
                        // Current Building Section
                        if let currentBuilding = viewModel.currentBuilding {
                            WorkerCurrentBuildingSection(
                                building: currentBuilding,
                                buildingTasks: viewModel.currentBuildingTasks,
                                onTaskTap: handleTaskTap,
                                onBuildingTap: { showingBuildingSelector = true }
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        
                        // Today's Tasks Section
                        WorkerTodaysTasksSection(
                            tasks: viewModel.todaysTasks,
                            completedTasks: viewModel.completedTasks,
                            onTaskTap: handleTaskTap,
                            requiresPhoto: viewModel.workerCapabilities?.requiresPhotoForSanitation ?? false
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        // Bottom spacing for Nova bar
                        Spacer()
                            .frame(height: 80)
                    }
                }
            }
            
            // Nova Intelligence Bar (60px → 300px expanded)
            VStack {
                Spacer()
                NovaIntelligenceBar(
                    container: container,
                    workerId: viewModel.workerProfile?.id,
                    currentContext: generateWorkerContext()
                )
                .frame(height: 60) // Expandable to 300px
            }
        }
        .task {
            await viewModel.loadInitialData()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
            Button("Retry") {
                Task { await viewModel.refreshData() }
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showingTaskDetail) {
            if let task = selectedTask {
                TaskDetailSheet(
                    task: task,
                    canAddNotes: viewModel.workerCapabilities?.canAddNotes ?? true,
                    requiresPhoto: viewModel.workerCapabilities?.requiresPhotoForSanitation ?? false,
                    onComplete: { evidence in
                        Task {
                            await viewModel.completeTask(task, evidence: evidence)
                            showingTaskDetail = false
                        }
                    },
                    onStart: {
                        Task {
                            await viewModel.startTask(task)
                            showingTaskDetail = false
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingBuildingSelector) {
            BuildingClockInSheet(
                buildings: viewModel.assignedBuildings,
                onSelect: { building in
                    Task {
                        await viewModel.clockIn(at: building)
                        showingBuildingSelector = false
                    }
                }
            )
        }
        .sheet(isPresented: $showingProfile) {
            WorkerProfileSheet(
                profile: viewModel.workerProfile,
                capabilities: viewModel.workerCapabilities,
                hoursWorkedToday: viewModel.hoursWorkedToday
            )
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView { image in
                // Handle photo capture for task
                if let taskId = currentPhotoTaskId,
                   let task = viewModel.todaysTasks.first(where: { $0.id == taskId }) {
                    Task {
                        let evidence = CoreTypes.ActionEvidence(
                            description: "Photo evidence for \(task.title)",
                            photoURLs: ["local://temp/\(UUID().uuidString).jpg"], // Would save image
                            timestamp: Date()
                        )
                        await viewModel.completeTask(task, evidence: evidence)
                    }
                }
                showingCamera = false
                currentPhotoTaskId = nil
            }
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleClockIn() {
        if viewModel.assignedBuildings.count == 1 {
            // Auto clock-in if only one building
            Task {
                await viewModel.clockIn(at: viewModel.assignedBuildings[0])
            }
        } else {
            // Show building selector
            showingBuildingSelector = true
        }
    }
    
    private func handleClockOut() {
        Task {
            await viewModel.clockOut()
        }
    }
    
    private func handleTaskTap(_ task: CoreTypes.ContextualTask) {
        selectedTask = task
        showingTaskDetail = true
    }
    
    private func handleCameraTap(for taskId: String) {
        if viewModel.workerCapabilities?.canUploadPhotos ?? true {
            currentPhotoTaskId = taskId
            showingCamera = true
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateTodaysProgress() -> Double {
        guard !viewModel.todaysTasks.isEmpty else { return 0.0 }
        let completedCount = viewModel.todaysTasks.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(viewModel.todaysTasks.count)
    }
    
    private func handleClockAction() {
        if viewModel.isCurrentlyClockedIn {
            handleClockOut()
        } else {
            handleClockIn()
        }
    }
    
    private func generateWorkerContext() -> [String: Any] {
        var context: [String: Any] = [:]
        
        // Worker info
        if let profile = viewModel.workerProfile {
            context["workerId"] = profile.id
            context["workerName"] = profile.name
            context["role"] = profile.role.rawValue
        }
        
        // Current status
        context["isClockedIn"] = viewModel.isCurrentlyClockedIn
        context["currentBuilding"] = viewModel.currentBuilding?.name
        
        // Task progress
        context["totalTasks"] = viewModel.todaysTasks.count
        context["completedTasks"] = viewModel.completedTasksCount
        context["urgentTasks"] = viewModel.urgentTasks.count
        context["overdueTasks"] = viewModel.todaysTasks.filter { $0.isOverdue }.count
        
        // Performance metrics
        context["todaysProgress"] = calculateTodaysProgress()
        context["hoursWorked"] = viewModel.hoursWorkedToday
        
        return context
    }
}

// MARK: - Standard Worker Dashboard
struct StandardWorkerDashboard: View {
    @ObservedObject var viewModel: WorkerDashboardViewModel
    @Binding var selectedTab: Int
    let onClockIn: () -> Void
    let onClockOut: () -> Void
    let onTaskTap: (CoreTypes.ContextualTask) -> Void
    let onCameraTap: (String) -> Void
    let onProfileTap: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 10/255, green: 14/255, blue: 39/255),
                    Color(red: 28/255, green: 30/255, blue: 51/255)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with Clock In/Out
                WorkerMainHeaderView(
                    profile: viewModel.workerProfile,
                    isClockedIn: viewModel.isClockedIn,
                    currentBuilding: viewModel.currentBuilding,
                    syncStatus: viewModel.dashboardSyncStatus,
                    onClockAction: viewModel.isClockedIn ? onClockOut : onClockIn,
                    onProfileTap: onProfileTap
                )
                
                // Weather Alert (if risky conditions)
                if viewModel.outdoorWorkRisk == .high || viewModel.outdoorWorkRisk == .extreme {
                    WeatherAlertBanner(
                        weather: viewModel.weatherData,
                        risk: viewModel.outdoorWorkRisk
                    )
                }
                
                // Hero Performance Card
                WorkerStatsCard(
                    taskProgress: viewModel.taskProgress,
                    completionRate: viewModel.completionRate,
                    hoursWorked: viewModel.hoursWorkedToday,
                    efficiency: viewModel.todaysEfficiency,
                    nextTask: viewModel.todaysTasks.first { !$0.isCompleted }
                )
                .padding()
                
                // Tab Selector
                WorkerTabSelector(selectedTab: $selectedTab)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    // Tasks Tab
                    TasksTabView(
                        tasks: viewModel.todaysTasks,
                        capabilities: viewModel.workerCapabilities,
                        onTaskTap: onTaskTap,
                        onCameraTap: onCameraTap
                    )
                    .tag(0)
                    
                    // Buildings Tab
                    BuildingsTabView(
                        assignedBuildings: viewModel.assignedBuildings,
                        currentBuilding: viewModel.currentBuilding,
                        buildingMetrics: viewModel.buildingMetrics,
                        canViewMap: viewModel.workerCapabilities?.canViewMap ?? true
                    )
                    .tag(1)
                    
                    // Activity Tab
                    ActivityTabView(
                        recentUpdates: viewModel.recentUpdates,
                        completionRate: viewModel.completionRate,
                        weeklyPerformance: viewModel.weeklyPerformance
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }
}

// MARK: - Simplified Worker Dashboard
struct SimplifiedWorkerDashboard: View {
    @ObservedObject var viewModel: WorkerDashboardViewModel
    let onClockIn: () -> Void
    let onClockOut: () -> Void
    let onTaskTap: (CoreTypes.ContextualTask) -> Void
    let onCameraTap: (String) -> Void
    
    var body: some View {
        ZStack {
            // Simple Background
            Color(red: 26/255, green: 26/255, blue: 26/255)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Simplified Header
                SimplifiedHeaderView(
                    workerName: viewModel.workerProfile?.name ?? "Worker",
                    isClockedIn: viewModel.isClockedIn,
                    buildingName: viewModel.currentBuilding?.name
                )
                
                if !viewModel.isClockedIn {
                    // Big Clock In Button
                    BigClockInButton(
                        buildings: viewModel.assignedBuildings,
                        onClockIn: onClockIn
                    )
                    .padding()
                    
                    Spacer()
                } else {
                    // Simple Task List
                    ScrollView {
                        VStack(spacing: 12) {
                            // Task Count
                            SimplifiedTaskCounter(
                                completed: viewModel.taskProgress?.completedTasks ?? 0,
                                total: viewModel.taskProgress?.totalTasks ?? 0
                            )
                            .padding(.horizontal)
                            
                            // Tasks
                            ForEach(viewModel.todaysTasks) { task in
                                SimplifiedTaskCard(
                                    task: task,
                                    requiresPhoto: viewModel.workerCapabilities?.requiresPhotoForSanitation ?? false,
                                    onTap: { onTaskTap(task) },
                                    onCameraTap: task.requiresPhoto ?? false ? {
                                        onCameraTap(task.id)
                                    } : nil
                                )
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    
                    // Big Clock Out Button
                    BigClockOutButton(onTap: onClockOut)
                        .padding()
                }
            }
        }
    }
}

// MARK: - Worker Main Header View
struct WorkerMainHeaderView: View {
    let profile: CoreTypes.WorkerProfile?
    let isClockedIn: Bool
    let currentBuilding: CoreTypes.NamedCoordinate?
    let syncStatus: CoreTypes.DashboardSyncStatus
    let onClockAction: () -> Void
    let onProfileTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(profile?.name ?? "Worker")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let building = currentBuilding {
                    Text(building.name)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // Clock Button
            Button(action: onClockAction) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(isClockedIn ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    
                    Text(isClockedIn ? "Clock Out" : "Clock In")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
            }
            
            // Profile
            Button(action: onProfileTap) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color(red: 28/255, green: 30/255, blue: 51/255))
    }
}

// MARK: - Worker Hero Card
struct WorkerStatsCard: View {
    let taskProgress: CoreTypes.TaskProgress?
    let completionRate: Double
    let hoursWorked: Double
    let efficiency: Double
    let nextTask: CoreTypes.ContextualTask?
    
    var completionPercentage: Int {
        Int(completionRate * 100)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 12)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: completionRate)
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(taskProgress?.completedTasks ?? 0)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("of \(taskProgress?.totalTasks ?? 0)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Stats Row
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("\(String(format: "%.1f", hoursWorked))h")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("Hours Today")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 4) {
                    Text("\(completionPercentage)%")
                        .font(.headline)
                        .foregroundColor(.cyan)
                    
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack(spacing: 4) {
                    Text("\(Int(efficiency * 100))%")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("Efficiency")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // Next Task Preview
            if let nextTask = nextTask {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Task")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(nextTask.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                            
                            if let building = nextTask.building {
                                Text(building.name)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        if let urgency = nextTask.urgency {
                            Text(urgency.rawValue)
                                .font(.caption2)
                                .foregroundColor(urgencyColor(urgency))
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // FIXED: Using TaskUrgency instead of UrgencyLevel
    func urgencyColor(_ urgency: CoreTypes.TaskUrgency) -> Color {
        switch urgency {
        case .emergency: return .red
        case .critical: return .red
        case .urgent: return .orange
        case .high: return .orange
        case .medium: return .blue
        case .low: return .gray
        }
    }
}

// MARK: - Weather Alert Banner
struct WeatherAlertBanner: View {
    let weather: CoreTypes.WeatherData?
    let risk: CoreTypes.OutdoorWorkRisk
    
    var riskColor: Color {
        switch risk {
        case .extreme: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(riskColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Weather Alert")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(weather?.condition.rawValue ?? "Extreme conditions") - \(weather?.temperature ?? 0)°F")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text(risk.rawValue)
                .font(.caption)
                .foregroundColor(riskColor)
        }
        .padding()
        .background(riskColor.opacity(0.2))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(riskColor.opacity(0.5)),
            alignment: .bottom
        )
    }
}

// MARK: - Tab Views

struct TasksTabView: View {
    let tasks: [CoreTypes.ContextualTask]
    let capabilities: WorkerDashboardViewModel.WorkerCapabilities?
    let onTaskTap: (CoreTypes.ContextualTask) -> Void
    let onCameraTap: (String) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(tasks) { task in
                    TaskCard(
                        task: task,
                        showPhotoButton: (capabilities?.canUploadPhotos ?? true) && (task.requiresPhoto ?? false),
                        onTap: { onTaskTap(task) },
                        onCameraTap: { onCameraTap(task.id) }
                    )
                }
            }
            .padding()
        }
    }
}

struct BuildingsTabView: View {
    let assignedBuildings: [CoreTypes.NamedCoordinate]
    let currentBuilding: CoreTypes.NamedCoordinate?
    let buildingMetrics: [String: CoreTypes.BuildingMetrics]
    let canViewMap: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(assignedBuildings) { building in
                    BuildingCard(
                        building: building,
                        metrics: buildingMetrics[building.id],
                        isCurrent: currentBuilding?.id == building.id,
                        showMap: canViewMap
                    )
                }
            }
            .padding()
        }
    }
}

struct ActivityTabView: View {
    let recentUpdates: [CoreTypes.DashboardUpdate]
    let completionRate: Double
    let weeklyPerformance: CoreTypes.TrendDirection
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Performance Summary
                PerformanceSummaryCard(
                    completionRate: completionRate,
                    weeklyTrend: weeklyPerformance
                )
                
                // Recent Activity
                if !recentUpdates.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent Activity")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(recentUpdates) { update in
                            ActivityRow(update: update)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Components

struct WorkerTabSelector: View {
    @Binding var selectedTab: Int
    @Namespace private var animation
    
    let tabs = ["Tasks", "Buildings", "Activity"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.system(size: 14, weight: selectedTab == index ? .semibold : .regular))
                            .foregroundColor(selectedTab == index ? .white : .gray)
                        
                        if selectedTab == index {
                            Capsule()
                                .fill(Color.blue)
                                .frame(height: 3)
                                .matchedGeometryEffect(id: "tab", in: animation)
                        } else {
                            Capsule()
                                .fill(Color.clear)
                                .frame(height: 3)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
        .background(Color(red: 28/255, green: 30/255, blue: 51/255))
    }
}

struct TaskCard: View {
    let task: CoreTypes.ContextualTask
    let showPhotoButton: Bool
    let onTap: () -> Void
    let onCameraTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Status Icon
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(task.isCompleted ? .green : .gray)
                
                // Task Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if let building = task.building {
                            Label(building.name, systemImage: "building.2")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if task.isOverdue {
                            Label("Overdue", systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                // Photo Button
                if showPhotoButton && !task.isCompleted {
                    Button(action: onCameraTap) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
    }
}

struct BuildingCard: View {
    let building: CoreTypes.NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    let isCurrent: Bool
    let showMap: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(building.address)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isCurrent {
                    Text("CURRENT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            if let metrics = metrics {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(metrics.completionRate * 100))%")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Complete")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(metrics.activeWorkers)")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Workers")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    if metrics.overdueTasks > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(metrics.overdueTasks)")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Text("Overdue")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            if showMap {
                HStack {
                    Image(systemName: "map")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    Text("View on Map")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(isCurrent ? Color.blue.opacity(0.1) : Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrent ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

struct PerformanceSummaryCard: View {
    let completionRate: Double
    let weeklyTrend: CoreTypes.TrendDirection
    
    var trendColor: Color {
        switch weeklyTrend {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        case .unknown: return .gray
        default: return .gray
        }
    }
    
    var trendIcon: String {
        switch weeklyTrend {
        case .improving: return "arrow.up.right"
        case .stable: return "minus"
        case .declining: return "arrow.down.right"
        case .unknown: return "questionmark"
        default: return "questionmark"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Summary")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(completionRate * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Today's Completion")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: trendIcon)
                            .font(.system(size: 16))
                        Text(weeklyTrend.rawValue)
                            .font(.caption)
                    }
                    .foregroundColor(trendColor)
                    
                    Text("Weekly Trend")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let update: CoreTypes.DashboardUpdate
    
    var body: some View {
        HStack {
            Circle()
                .fill(sourceColor(update.source))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(update.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text(update.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // FIXED: Using DashboardUpdate.Source instead of DashboardSource
    func sourceColor(_ source: CoreTypes.DashboardUpdate.Source) -> Color {
        switch source {
        case .worker: return .green
        case .admin: return .blue
        case .client: return .purple
        case .system: return .gray
        }
    }
}

// MARK: - Simplified Components

struct SimplifiedHeaderView: View {
    let workerName: String
    let isClockedIn: Bool
    let buildingName: String?
    
    var body: some View {
        VStack(spacing: 8) {
            Text(workerName)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                Circle()
                    .fill(isClockedIn ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(isClockedIn ? "WORKING" : "NOT WORKING")
                    .font(.headline)
                    .foregroundColor(isClockedIn ? .green : .red)
            }
            
            if let building = buildingName {
                Text(building)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(red: 42/255, green: 42/255, blue: 42/255))
    }
}

struct SimplifiedTaskCounter: View {
    let completed: Int
    let total: Int
    
    var body: some View {
        HStack {
            Text("Tasks Today")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("\(completed) / \(total)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(completed == total ? .green : .orange)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SimplifiedTaskCard: View {
    let task: CoreTypes.ContextualTask
    let requiresPhoto: Bool
    let onTap: () -> Void
    let onCameraTap: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Big Status Icon
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 36))
                    .foregroundColor(task.isCompleted ? .green : .gray)
                
                // Task Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if let building = task.building {
                        Text(building.name)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Camera Button (if needed)
                if requiresPhoto && !task.isCompleted, let onCameraTap = onCameraTap {
                    Button(action: onCameraTap) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                            .padding(12)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

struct BigClockInButton: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let onClockIn: () -> Void
    
    var body: some View {
        Button(action: onClockIn) {
            VStack(spacing: 16) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                Text("CLOCK IN")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if buildings.count == 1 {
                    Text("at \(buildings[0].name)")
                        .font(.body)
                        .foregroundColor(.gray)
                } else {
                    Text("Select Building")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .background(
                LinearGradient(
                    colors: [Color.green, Color.green.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(20)
        }
    }
}

struct BigClockOutButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 24))
                
                Text("CLOCK OUT")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [Color.red, Color.red.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(15)
        }
    }
}

// MARK: - Sheet Views

struct TaskDetailSheet: View {
    let task: CoreTypes.ContextualTask
    let canAddNotes: Bool
    let requiresPhoto: Bool
    let onComplete: (CoreTypes.ActionEvidence) -> Void
    let onStart: () -> Void
    @State private var notes = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Task Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let description = task.description {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    
                    if let building = task.building {
                        Label(building.name, systemImage: "building.2")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Divider()
                
                // Notes (if allowed)
                if canAddNotes {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                        
                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // Photo Requirement
                if requiresPhoto {
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.blue)
                        Text("Photo evidence required")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 12) {
                    if !task.isCompleted {
                        Button(action: {
                            onStart()
                            dismiss()
                        }) {
                            Text("Start Task")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            let evidence = CoreTypes.ActionEvidence(
                                photoUrl: nil,
                                notes: notes.isEmpty ? "Task completed" : notes,
                                taskId: task.id,
                                workerId: ""  // Would be filled from auth
                            )
                            onComplete(evidence)
                            dismiss()
                        }) {
                            Text("Complete")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Task Details")
            .navigationBarItems(trailing: Button("Close") { dismiss() })
        }
    }
}

struct BuildingClockInSheet: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let onSelect: (CoreTypes.NamedCoordinate) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(buildings) { building in
                Button(action: {
                    onSelect(building)
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(building.name)
                            .font(.headline)
                        Text(building.address)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Select Building")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
}

struct WorkerProfileSheet: View {
    let profile: CoreTypes.WorkerProfile?
    let capabilities: WorkerDashboardViewModel.WorkerCapabilities?
    let hoursWorkedToday: Double
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Profile Header
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(profile?.name ?? "Worker")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(profile?.email ?? "")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                
                // Today's Stats
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Stats")
                        .font(.headline)
                    
                    HStack {
                        Label("\(String(format: "%.1f", hoursWorkedToday)) hours worked", systemImage: "clock")
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // Capabilities
                if let capabilities = capabilities {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Permissions")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            WorkerCapabilityRow(title: "Upload Photos", enabled: capabilities.canUploadPhotos)
                            WorkerCapabilityRow(title: "Add Notes", enabled: capabilities.canAddNotes)
                            WorkerCapabilityRow(title: "View Map", enabled: capabilities.canViewMap)
                            WorkerCapabilityRow(title: "Emergency Tasks", enabled: capabilities.canAddEmergencyTasks)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct WorkerCapabilityRow: View {
    let title: String
    let enabled: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
            Spacer()
            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(enabled ? .green : .gray)
        }
    }
}

// MARK: - Camera View Placeholder
struct CameraView: View {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        // This would be replaced with actual camera implementation
        VStack {
            Text("Camera View")
                .font(.title)
            
            Button("Simulate Photo Capture") {
                // Simulate capturing a photo
                onCapture(UIImage())
                dismiss()
            }
            
            Button("Cancel") {
                dismiss()
            }
        }
    }
}

// MARK: - Loading View
struct LoadingDashboardView: View {
    @State private var loadingProgress: Double = 0.0
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 10/255, green: 14/255, blue: 39/255),
                    Color(red: 28/255, green: 30/255, blue: 51/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 10)
                
                Text("Loading Your Dashboard")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                ProgressView(value: loadingProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(.blue)
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                    .frame(width: 200)
                
                Text("Please wait...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0)) {
                loadingProgress = 1.0
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct WorkerDashboardMainView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Standard Dashboard
            WorkerDashboardMainView()
                .environmentObject(NewAuthManager.shared)
                .environmentObject(DashboardSyncService.shared)
                .preferredColorScheme(.dark)
                .previewDisplayName("Standard Dashboard")
            
            // Simplified Dashboard
            WorkerDashboardMainView()
                .environmentObject(NewAuthManager.shared)
                .environmentObject(DashboardSyncService.shared)
                .preferredColorScheme(.dark)
                .onAppear {
                    UserDefaults.standard.set(true, forKey: "workerSimplifiedMode")
                }
                .previewDisplayName("Simplified Dashboard")
        }
    }
}
#endif
