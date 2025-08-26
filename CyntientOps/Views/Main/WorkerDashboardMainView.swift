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
    @EnvironmentObject private var session: CoreTypes.Session
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    
    // MARK: - State Management
    @State private var showingTaskDetail = false
    @State private var selectedTask: CoreTypes.ContextualTask?
    @State private var showingBuildingSelector = false
    @State private var showingProfile = false
    @State private var showingCamera = false
    @State private var currentPhotoTaskId: String?
    @State private var showingErrorAlert = false
    @State private var isHeroCardExpanded = true
    @State private var isIntelligencePanelExpanded = false

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
                WorkerHeaderV3B(
                    name: viewModel.workerProfile?.name ?? "Worker",
                    initials: String((viewModel.workerProfile?.name ?? "W").prefix(2)).uppercased(),
                    photoURL: nil,
                    nextTaskName: viewModel.todaysTasks.first?.title,
                    showClockPill: false, // Only profile pill on right
                    isNovaProcessing: false,
                    onRoute: { route in
                        switch route {
                        case .mainMenu:
                            showingProfile = true
                        case .profile:
                            showingProfile = true
                        case .clockAction:
                            showingProfile = true
                        case .novaChat:
                            showingProfile = true
                        }
                    }
                )
                .frame(height: 60)
                .frame(height: 60)
                
                // Worker Hero Card (simplified for MainView)
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good Morning, \(viewModel.workerProfile?.name ?? "Worker")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Current: \(viewModel.currentBuilding?.name ?? "Not Clocked In")")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: handleClockAction) {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.isCurrentlyClockedIn ? "clock.fill" : "clock")
                                    .font(.system(size: 14))
                                Text(viewModel.isCurrentlyClockedIn ? "Clock Out" : "Clock In")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Progress bar
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Today's Progress")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("\(Int(calculateTodaysProgress() * 100))%")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        
                        ProgressView(value: calculateTodaysProgress())
                            .progressViewStyle(LinearProgressViewStyle(tint: CyntientOpsDesign.DashboardColors.workerSecondary))
                    }
                }
                .padding()
                .cyntientOpsDarkCardBackground()
                
                Spacer()
            }
            
            // Worker Intelligence Panel
            if isIntelligencePanelExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Intelligence")
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    if viewModel.insights.isEmpty {
                        Text("No insights yet").font(.caption).foregroundColor(.gray)
                    } else {
                        ForEach(viewModel.insights) { insight in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(insight.title).font(.subheadline).foregroundColor(.white)
                                if let message = insight.message, !message.isEmpty {
                                    Text(message).font(.caption).foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                            Divider().background(Color.white.opacity(0.1))
                        }
                    }
                }
                .padding()
                .cyntientOpsDarkCardBackground()
                .transition(.move(edge: .bottom).combined(with: .opacity))
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
                NavigationView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(task.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(task.description ?? "No description provided")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        
                        if let urgency = task.urgency {
                            HStack {
                                Circle()
                                    .fill(urgency == .critical ? .red : urgency == .urgent ? .orange : .blue)
                                    .frame(width: 8, height: 8)
                                Text(urgency.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            if !task.isCompleted {
                                Button("Start Task") {
                                    Task {
                                        await viewModel.startTask(task)
                                        showingTaskDetail = false
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("Complete") {
                                    let evidence = CoreTypes.ActionEvidence(
                                        description: "Task completed",
                                        photoURLs: [],
                                        timestamp: Date()
                                    )
                                    Task {
                                        await viewModel.completeTask(task, evidence: evidence)
                                        showingTaskDetail = false
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(CyntientOpsDesign.DashboardColors.baseBackground)
                    .navigationTitle("Task Details")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .overlay(
                        Button("Done") {
                            showingTaskDetail = false
                        }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .padding()
                        , alignment: .topTrailing
                    )
                }
                .preferredColorScheme(.dark)
            }
        }
        .sheet(isPresented: $showingBuildingSelector) {
            NavigationView {
                List(viewModel.assignedBuildings, id: \.id) { building in
                    Button(action: {
                        Task {
                            await viewModel.clockIn(to: building)
                            showingBuildingSelector = false
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(building.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(building.address)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(PlainListStyle())
                .background(CyntientOpsDesign.DashboardColors.baseBackground)
                .navigationTitle("Select Building")
                .navigationBarTitleDisplayMode(.inline)
                .overlay(
                    Button("Cancel") {
                        showingBuildingSelector = false
                    }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .padding()
                    , alignment: .topTrailing
                )
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingProfile) {
            NavigationView {
                VStack(alignment: .leading, spacing: 20) {
                    if let profile = viewModel.workerProfile {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(profile.name)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Role: \(profile.role.rawValue.capitalized)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("Employee ID: \(profile.id)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Divider()
                            .background(.gray)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's Activity")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("Hours Worked:")
                                Spacer()
                                Text(String(format: "%.1f hours", viewModel.hoursWorkedToday))
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text("Tasks Completed:")
                                Spacer()
                                Text("\(viewModel.todaysTasks.filter { $0.isCompleted }.count)")
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(CyntientOpsDesign.DashboardColors.baseBackground)
                .navigationTitle("Worker Profile")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .overlay(
                    Button("Done") {
                        showingProfile = false
                    }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .padding()
                    , alignment: .topTrailing
                )
            }
            .preferredColorScheme(.dark)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CyntientOpsImagePicker(
                image: .constant(nil),
                onImagePicked: { image in
                    // Handle photo capture for task using PhotoEvidenceService
                    if let taskId = currentPhotoTaskId,
                       let task = viewModel.todaysTasks.first(where: { $0.id == taskId }) {
                        Task {
                            do {
                                if let profile = viewModel.workerProfile {
                                    let photoEvidence = try await container.photos.captureQuick(
                                        image: image,
                                        category: CoreTypes.CyntientOpsPhotoCategory.duringWork,
                                        buildingId: task.buildingId ?? "",
                                        workerId: profile.id,
                                        notes: "Task completion photo for \(task.title)"
                                    )
                                    
                                    let evidence = CoreTypes.ActionEvidence(
                                        description: "Photo evidence for \(task.title)",
                                        photoURLs: [photoEvidence.filePath],
                                        timestamp: Date()
                                    )
                                    
                                    // Convert TaskItem to CoreTypes.ContextualTask
                                    let contextualTask = CoreTypes.ContextualTask(
                                        id: task.id,
                                        title: task.title,
                                        description: task.description ?? "",
                                        status: task.isCompleted ? .completed : .pending,
                                        dueDate: task.dueDate,
                                        category: CoreTypes.TaskCategory(rawValue: task.category) ?? .administrative,
                                        urgency: convertTaskUrgencyToCore(task.urgency),
                                        buildingId: task.buildingId
                                    )
                                    await viewModel.completeTask(contextualTask, evidence: evidence)
                                }
                            } catch {
                                print("Failed to capture photo evidence: \(error)")
                                // Show error to user
                            }
                        }
                    }
                    showingCamera = false
                    currentPhotoTaskId = nil
                },
                sourceType: .camera
            )
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleClockIn() {
        if viewModel.assignedBuildings.count == 1 {
            // Auto clock-in if only one building
            Task {
                await viewModel.clockIn(to: viewModel.assignedBuildings[0])
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
        context["overdueTasks"] = viewModel.todaysTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < Date() && !task.isCompleted
        }.count
        
        // Performance metrics
        context["todaysProgress"] = calculateTodaysProgress()
        context["hoursWorked"] = viewModel.hoursWorkedToday
        
        return context
    }
    
    // MARK: - Helper Methods
    
    private func convertTaskUrgencyToCore(_ urgency: WorkerDashboardViewModel.TaskItem.TaskUrgency) -> CoreTypes.TaskUrgency {
        switch urgency {
        case .low: return .low
        case .normal: return .normal
        case .high: return .high
        case .urgent: return .urgent
        case .critical: return .critical
        case .emergency: return .emergency
        }
    }
}

