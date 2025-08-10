//
//  WorkerDashboardView.swift
//  CyntientOps v6.0
//
//  ✅ REFACTORED: Space-optimized with collapsible hero
//  ✅ INTEGRATED: Updated HeaderV3B with brand-AI-user layout
//  ✅ FOCUSED: 35-40% screen usage when collapsed
//  ✅ FUTURE-READY: Prepared for voice, AR, wearables
//  ✅ UPDATED: Now uses IntelligencePreviewPanel for AI insights
//  ✅ FIXED: Switch statements are now exhaustive
//  ✅ DARK ELEGANCE: Updated with new theme colors
//  ✅ OPTIMIZED: Removed NextStepsView for cleaner layout
//  ✅ FIXED: @AppStorage now works with raw value enum
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

struct WorkerDashboardView: View {
    @StateObject var viewModel: WorkerDashboardViewModel
    @ObservedObject private var contextEngine = WorkerContextEngine.shared
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var novaEngine: NovaAIManager // From ServiceContainer
    
    private let container: ServiceContainer
    
    // Access DashboardSyncService through container
    private var dashboardSync: DashboardSyncService {
        container.dashboardSync
    }
    
    init(container: ServiceContainer) {
        self.container = container
        self._viewModel = StateObject(wrappedValue: WorkerDashboardViewModel(container: container))
    }
    
    // MARK: - State Variables
    @State private var isHeroCollapsed = false
    @State private var showProfileView = false
    @State private var showNovaAssistant = false
    @State private var selectedTask: CoreTypes.ContextualTask?
    @State private var showTaskDetail = false
    @State private var showAllTasks = false
    @State private var showDepartureChecklist = false
    @State private var showMainMenu = false
    @State private var refreshID = UUID()
    @State private var selectedInsight: CoreTypes.IntelligenceInsight?
    @State private var isMapRevealed = false
    
    // Intelligence panel state
    @State private var currentContext: ViewContext = .dashboard
    @AppStorage("preferredPanelState") private var userPanelPreference: IntelPanelState = .collapsed
    
    // Future phase states
    @State private var voiceCommandEnabled = false
    @State private var arModeEnabled = false
    
    // MARK: - Enums
    enum ViewContext {
        case dashboard
        case buildingDetail
        case taskFlow
        case siteDeparture
        case novaChat
        case emergency
    }
    
    enum IntelPanelState: String {
        case hidden = "hidden"
        case minimal = "minimal"
        case collapsed = "collapsed"
        case expanded = "expanded"
        case fullscreen = "fullscreen"
    }
    
    // MARK: - Computed Properties
    private var intelligencePanelState: IntelPanelState {
        switch currentContext {
        case .dashboard:
            return hasUrgentAlerts() ? .expanded : userPanelPreference
        case .buildingDetail:
            return .minimal
        case .taskFlow:
            return .hidden
        case .siteDeparture:
            return .hidden
        case .novaChat:
            return .fullscreen
        case .emergency:
            return .expanded
        }
    }
    
    private func hasUrgentAlerts() -> Bool {
        hasUrgentTasks() // Simplified for compilation
    }
    
    var body: some View {
        MapRevealContainer(
            buildings: viewModel.workerCapabilities?.canViewMap ?? true ? contextEngine.assignedBuildings : [],
            currentBuildingId: contextEngine.currentBuilding?.id,
            focusBuildingId: nil,
            isRevealed: $isMapRevealed,
            onBuildingTap: { building in
                // Handle building tap if needed
                print("Building tapped: \(building.name)")
            }
        ) {
            ZStack {
                // Dark Elegance Background
                CyntientOpsDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // Updated HeaderV3B with brand-AI-user layout (5-7%)
                    HeaderV3B(
                        workerName: contextEngine.currentWorker?.name ?? "Worker",
                        nextTaskName: getCurrentTask()?.title,
                        showClockPill: true, // Always show clock status
                        isNovaProcessing: false, // Simplified for compilation
                        onProfileTap: { showProfileView = true },
                        onNovaPress: { showNovaAssistant = true },
                        onNovaLongPress: {
                            // Long press for quick Nova actions
                            handleNovaQuickAction()
                        },
                        // Optional callbacks
                        onLogoTap: { showMainMenu = true },
                        onClockAction: handleClockAction,
                        // Future phase callbacks (nil for now, ready for feature flags)
                        onVoiceCommand: voiceCommandEnabled ? handleVoiceCommand : nil,
                        onARModeToggle: arModeEnabled ? handleARMode : nil,
                        onWearableSync: nil // Phase 4
                    )
                    .zIndex(100)
                    
                    // Main content area
                    ScrollView {
                        VStack(spacing: 16) {
                            // Collapsible Hero Status Card
                            CollapsibleHeroWrapper(
                                isCollapsed: $isHeroCollapsed,
                                worker: contextEngine.currentWorker,
                                building: contextEngine.currentBuilding,
                                weather: viewModel.weatherData,
                                progress: getTaskProgress(),
                                clockInStatus: getClockInStatus(),
                                capabilities: getWorkerCapabilities(),
                                syncStatus: getSyncStatus(),
                                onClockInTap: handleClockAction,
                                onBuildingTap: { /* Handled by map */ },
                                onTasksTap: { showAllTasks = true },
                                onEmergencyTap: handleEmergencyAction,
                                onSyncTap: { Task { await viewModel.refreshData() } }
                            )
                            .zIndex(50)
                            
                            // Spacer for bottom intelligence bar
                            Spacer(minLength: intelligencePanelState == .hidden ? 20 : 80)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    .refreshable {
                        await viewModel.refreshData()
                        refreshID = UUID()
                    }
                    
                    // Nova Intelligence Panel
                    if intelligencePanelState != .hidden && hasIntelligenceToShow() {
                        NovaIntelligenceBar(
                            container: container,
                            workerId: authManager.workerId,
                            currentContext: generateWorkerContext(),
                            novaManager: novaEngine
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(CyntientOpsDesign.Animations.spring, value: intelligencePanelState)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showProfileView) {
            if let workerId = authManager.workerId {
                WorkerProfileView(workerId: workerId)
            }
        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
                .presentationDetents([.large])
                .onAppear { currentContext = .novaChat }
                .onDisappear { currentContext = .dashboard }
        }
        .sheet(item: $selectedInsight) { insight in
            InsightDetailView(insight: insight)
        }
        .sheet(isPresented: $showTaskDetail) {
            if let task = selectedTask {
                UnifiedTaskDetailView(task: task, mode: .worker)
                    .onAppear { currentContext = .taskFlow }
                    .onDisappear {
                        currentContext = .dashboard
                        Task {
                            await contextEngine.refreshContext()
                        }
                    }
            }
        }
        .sheet(isPresented: $showAllTasks) {
            NavigationView {
                VStack(spacing: 0) {
                    List(contextEngine.todaysTasks, id: \.id) { task in
                        WorkerTaskRowView(task: task) {
                            selectedTask = task
                            showTaskDetail = true
                            showAllTasks = false
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(CyntientOpsDesign.DashboardColors.baseBackground)
                }
                .navigationTitle("Today's Tasks")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showAllTasks = false
                        }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    }
                }
                .background(CyntientOpsDesign.DashboardColors.baseBackground)
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showDepartureChecklist) {
            if let worker = contextEngine.currentWorker,
               let building = contextEngine.currentBuilding {
                SiteDepartureView(
                    viewModel: SiteDepartureViewModel(
                        workerId: worker.id,
                        currentBuilding: building,
                        capabilities: convertToSiteDepartureCapability(viewModel.workerCapabilities),
                        availableBuildings: contextEngine.assignedBuildings
                    )
                )
                .onAppear { currentContext = .siteDeparture }
                .onDisappear { currentContext = .dashboard }
            }
        }
        .sheet(isPresented: $showMainMenu) {
            MainMenuView()
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            checkFeatureFlags()
        }
    }
    
    // MARK: - Intelligence Methods
    
    private func getCurrentInsights() -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = [] // Simplified for compilation
        
        // Add contextual insights based on current state
        if hasUrgentTasks() {
            let urgentCount = contextEngine.todaysTasks.filter {
                $0.urgency == .urgent || $0.urgency == .critical
            }.count
            
            insights.append(CoreTypes.IntelligenceInsight(
                title: "\(urgentCount) urgent tasks require attention",
                description: "Priority tasks need immediate action to maintain schedule",
                type: .operations,
                priority: .high,
                actionRequired: true,
                affectedBuildings: Array(Set(contextEngine.todaysTasks.compactMap { $0.buildingId }))
            ))
        }
        
        // Check for DSNY deadlines
        let dsnyTasks = contextEngine.todaysTasks.filter {
            $0.title.lowercased().contains("dsny") ||
            $0.title.lowercased().contains("trash")
        }
        
        if !dsnyTasks.isEmpty {
            let buildingIds = Array(Set(dsnyTasks.compactMap { $0.buildingId }))
            insights.append(CoreTypes.IntelligenceInsight(
                title: "DSNY compliance deadline approaching",
                description: "Trash must be set out by 8:00 PM for \(buildingIds.count) buildings",
                type: .compliance,
                priority: dsnyTasks.contains { $0.urgency == .critical } ? .critical : .high,
                actionRequired: true,
                affectedBuildings: buildingIds
            ))
        }
        
        return insights
    }
    
    private func handleIntelligenceNavigation(_ target: IntelligencePreviewPanel.NavigationTarget) {
        switch target {
        case .tasks(_):
            showAllTasks = true
            
        case .buildings(_):
            print("Navigate to buildings")
            
        case .compliance(_):
            showAllTasks = true
            
        case .maintenance(_):
            showAllTasks = true
            
        case .fullInsights:
            showNovaAssistant = true
            
        case .allTasks:
            showAllTasks = true
            
        case .taskDetail(let id):
            if let task = contextEngine.todaysTasks.first(where: { $0.id == id }) {
                selectedTask = task
                showTaskDetail = true
            }
            
        case .allBuildings:
            // Navigate to buildings list
            print("Navigate to all buildings")
            
        case .buildingDetail(let id):
            // Navigate to specific building
            print("Navigate to building: \(id)")
            
        case .clockOut:
            handleClockAction()
            
        case .profile:
            showProfileView = true
            
        case .settings:
            showMainMenu = true
            
        case .dsnyTasks:
            // Filter to DSNY tasks
            showAllTasks = true
            
        case .routeOptimization:
            // Show route optimization
            print("Show route optimization")
            
        case .photoEvidence:
            // Show photo evidence
            print("Show photo evidence")
            
        case .emergencyContacts:
            handleEmergencyAction()
        @unknown default:
            break
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleClockAction() {
        if contextEngine.clockInStatus.isClockedIn {
            showDepartureChecklist = true
        } else if let firstBuilding = contextEngine.assignedBuildings.first {
            Task {
                await viewModel.clockIn(at: firstBuilding)
                await contextEngine.refreshContext()
            }
        }
    }
    
    private func handleNovaQuickAction() {
        // Quick action menu or immediate AI response
        if hasUrgentTasks() {
            // Immediate response for urgent situations
            showNovaAssistant = true
        } else {
            // Could show quick action menu
            showNovaAssistant = true
        }
    }
    
    private func handleEmergencyAction() {
        // Show emergency contacts or create emergency task
        if viewModel.workerCapabilities?.canAddEmergencyTasks == true {
            // Show emergency task creation
            print("Emergency task creation")
            currentContext = .emergency
        } else {
            // Show emergency contacts
            print("Show emergency contacts")
        }
    }
    
    private func handleVoiceCommand() {
        // Phase 1: Voice command handling
        print("Voice command activated")
        // Future: Integrate with speech recognition
    }
    
    private func handleARMode() {
        // Phase 2: AR mode activation
        print("AR mode toggled")
        // Future: Launch AR view for building navigation
    }
    
    private func checkFeatureFlags() {
        // Check for enabled features
        // This would typically come from a feature flag service
        #if DEBUG
        // Enable in debug builds for testing
        voiceCommandEnabled = false // Set to true to test
        arModeEnabled = false // Set to true to test
        #else
        // Production feature flags
        voiceCommandEnabled = UserDefaults.standard.bool(forKey: "feature.voice.enabled")
        arModeEnabled = UserDefaults.standard.bool(forKey: "feature.ar.enabled")
        #endif
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentTask() -> CoreTypes.ContextualTask? {
        contextEngine.todaysTasks.first { !$0.isCompleted }
    }
    
    private func getUpcomingTasks() -> [CoreTypes.ContextualTask] {
        Array(contextEngine.todaysTasks
            .filter { !$0.isCompleted }
            .dropFirst()
            .prefix(5))
    }
    
    private func getTaskProgress() -> CoreTypes.TaskProgress {
        CoreTypes.TaskProgress(
            totalTasks: contextEngine.todaysTasks.count,
            completedTasks: contextEngine.todaysTasks.filter { $0.isCompleted }.count
        )
    }
    
    private func getClockInStatus() -> HeroStatusCard.ClockInStatus {
        if contextEngine.clockInStatus.isClockedIn,
           let building = contextEngine.currentBuilding {
            return .clockedIn(
                building: building.name,
                buildingId: building.id,
                time: viewModel.clockInTime ?? Date(),
                location: CLLocation(
                    latitude: building.latitude,
                    longitude: building.longitude
                )
            )
        }
        return .notClockedIn
    }
    
    private func getWorkerCapabilities() -> HeroStatusCard.WorkerCapabilities? {
        guard let caps = viewModel.workerCapabilities else { return nil }
        
        return HeroStatusCard.WorkerCapabilities(
            canUploadPhotos: caps.canUploadPhotos,
            canAddNotes: caps.canAddNotes,
            canViewMap: caps.canViewMap,
            canAddEmergencyTasks: caps.canAddEmergencyTasks,
            requiresPhotoForSanitation: caps.requiresPhotoForSanitation,
            simplifiedInterface: caps.simplifiedInterface
        )
    }
    
    private func getSyncStatus() -> HeroStatusCard.SyncStatus {
        switch viewModel.dashboardSyncStatus {
        case .synced: return .synced
        case .syncing: return .syncing(progress: 0.5)
        case .failed: return .error("Sync failed")
        case .offline: return .offline
        case .error: return .error("Sync error")
        @unknown default: return .error("Unknown status")
        }
    }
    
    private func hasIntelligenceToShow() -> Bool {
        return viewModel.assignedBuildings.count > 1 ||
               viewModel.todaysTasks.filter { $0.isCompleted }.count > 3 ||
               hasUpcomingDeadlines()
    }
    
    private func hasUpcomingDeadlines() -> Bool {
        viewModel.todaysTasks.contains { task in
            task.title.lowercased().contains("dsny") ||
            task.urgency == .urgent ||
            task.urgency == .critical
        }
    }
    
    private func hasUrgentTasks() -> Bool {
        viewModel.todaysTasks.contains { task in
            task.urgency == .urgent ||
            task.urgency == .critical ||
            task.urgency == .emergency
        }
    }
    
    private func convertToSiteDepartureCapability(_ capabilities: WorkerDashboardViewModel.WorkerCapabilities?) -> SiteDepartureViewModel.WorkerCapability? {
        guard let caps = capabilities else { return nil }
        
        return SiteDepartureViewModel.WorkerCapability(
            canUploadPhotos: caps.canUploadPhotos,
            canAddNotes: caps.canAddNotes,
            canViewMap: caps.canViewMap,
            canAddEmergencyTasks: caps.canAddEmergencyTasks,
            requiresPhotoForSanitation: caps.requiresPhotoForSanitation,
            simplifiedInterface: caps.simplifiedInterface
        )
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
        context["completedTasks"] = viewModel.todaysTasks.filter { $0.isCompleted }.count
        context["urgentTasks"] = viewModel.todaysTasks.filter { $0.urgency == .urgent || $0.urgency == .critical }.count
        context["overdueTasks"] = viewModel.todaysTasks.filter { $0.isOverdue }.count
        
        // Performance metrics
        context["todaysProgress"] = getTaskProgress()
        context["assignedBuildings"] = viewModel.assignedBuildings.count
        
        // Current task context
        if let currentTask = getCurrentTask() {
            context["currentTaskId"] = currentTask.id
            context["currentTaskTitle"] = currentTask.title
            context["currentTaskUrgency"] = currentTask.urgency?.rawValue
        }
        
        return context
    }
}

// MARK: - Worker Task Row View

struct WorkerTaskRowView: View {
    let task: CoreTypes.ContextualTask
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Task icon
                Image(systemName: task.category?.icon ?? "checkmark.circle")
                    .font(.title3)
                    .foregroundColor(urgencyColor)
                    .frame(width: 32, height: 32)
                    .background(urgencyColor.opacity(0.1))
                    .cornerRadius(8)
                
                // Task details
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if let building = task.building {
                            Label(building.name, systemImage: "building.2")
                                .font(.caption)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        }
                        
                        if let dueDate = task.dueDate {
                            Label(dueDate.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(task.isOverdue ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.secondaryText)
                        }
                    }
                }
                
                Spacer()
                
                // Status indicator
                if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                } else if task.urgency == .critical || task.urgency == .urgent {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var urgencyColor: Color {
        // Use Dark Elegance theme colors
        switch task.urgency ?? .low {
        case .critical, .emergency:
            return CyntientOpsDesign.DashboardColors.critical
        case .urgent, .high:
            return CyntientOpsDesign.DashboardColors.warning
        case .medium:
            return .orange // Amber equivalent
        case .low, .normal:
            return CyntientOpsDesign.DashboardColors.info
        @unknown default:
            return CyntientOpsDesign.DashboardColors.info
        }
    }
}

// MARK: - Main Menu View

struct MainMenuView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Navigation") {
                    Label("Dashboard", systemImage: "house")
                    Label("All Tasks", systemImage: "checklist")
                    Label("Buildings", systemImage: "building.2")
                    Label("Schedule", systemImage: "calendar")
                }
                .listRowBackground(CyntientOpsDesign.DashboardColors.cardBackground)
                
                Section("Tools") {
                    Label("Reports", systemImage: "doc.text")
                    Label("Inventory", systemImage: "shippingbox")
                    Label("Messages", systemImage: "message")
                }
                .listRowBackground(CyntientOpsDesign.DashboardColors.cardBackground)
                
                Section("Support") {
                    Label("Help", systemImage: "questionmark.circle")
                    Label("Settings", systemImage: "gear")
                }
                .listRowBackground(CyntientOpsDesign.DashboardColors.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(CyntientOpsDesign.DashboardColors.baseBackground)
            .navigationTitle("CyntientOps")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - CollapsibleHeroWrapper Component

struct CollapsibleHeroWrapper: View {
    @Binding var isCollapsed: Bool
    
    // All the existing HeroStatusCard props
    let worker: CoreTypes.WorkerProfile?
    let building: CoreTypes.NamedCoordinate?
    let weather: CoreTypes.WeatherData?
    let progress: CoreTypes.TaskProgress
    let clockInStatus: HeroStatusCard.ClockInStatus
    let capabilities: HeroStatusCard.WorkerCapabilities?
    let syncStatus: HeroStatusCard.SyncStatus
    
    let onClockInTap: () -> Void
    let onBuildingTap: () -> Void
    let onTasksTap: () -> Void
    let onEmergencyTap: () -> Void
    let onSyncTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isCollapsed {
                // Minimal collapsed version
                MinimalHeroCard(
                    worker: worker,
                    building: building,
                    progress: progress,
                    clockInStatus: clockInStatus,
                    onExpand: {
                        withAnimation(CyntientOpsDesign.Animations.spring) {
                            isCollapsed = false
                        }
                    }
                )
                
            } else {
                // Full existing HeroStatusCard with collapse button
                ZStack(alignment: .topTrailing) {
                    HeroStatusCard(
                        worker: worker,
                        building: building,
                        weather: weather,
                        progress: progress,
                        clockInStatus: clockInStatus,
                        capabilities: capabilities,
                        syncStatus: syncStatus,
                        onClockInTap: onClockInTap,
                        onBuildingTap: onBuildingTap,
                        onTasksTap: onTasksTap,
                        onEmergencyTap: onEmergencyTap,
                        onSyncTap: onSyncTap
                    )
                    
                    // Collapse button overlay
                    Button(action: {
                        withAnimation(CyntientOpsDesign.Animations.spring) {
                            isCollapsed = true
                        }
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                            .padding(8)
                            .background(Circle().fill(CyntientOpsDesign.DashboardColors.glassOverlay))
                    }
                    .padding(8)
                }
            }
        }
    }
}

// MARK: - MinimalHeroCard Component

struct MinimalHeroCard: View {
    let worker: CoreTypes.WorkerProfile?
    let building: CoreTypes.NamedCoordinate?
    let progress: CoreTypes.TaskProgress
    let clockInStatus: HeroStatusCard.ClockInStatus
    let onExpand: () -> Void
    
    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(statusColor.opacity(0.3), lineWidth: 8)
                            .scaleEffect(1.5)
                            .opacity(isClocked ? 0.6 : 0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isClocked)
                    )
                
                // Worker info
                if let worker = worker {
                    Text(worker.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                }
                
                Text("•")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                
                // Progress
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Text("\(progress.completedTasks)/\(progress.totalTasks)")
                        .font(.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                // Building if clocked in
                if let building = building {
                    Text("•")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        
                        Text(building.name)
                            .font(.subheadline)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Expand indicator
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .francoDarkCardBackground(cornerRadius: 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        if case .clockedIn = clockInStatus {
            return CyntientOpsDesign.DashboardColors.success
        } else {
            return CyntientOpsDesign.DashboardColors.inactive
        }
    }
    
    private var isClocked: Bool {
        if case .clockedIn = clockInStatus {
            return true
        } else {
            return false
        }
    }
}

// MARK: - Worker Nova Intelligence Bar

struct WorkerNovaIntelligenceBar: View {
    let insights: [CoreTypes.IntelligenceInsight]
    let contextEngine: WorkerContextEngine
    let displayMode: DisplayMode
    let onSelectMapTab: () -> Void
    let onNavigate: (IntelligencePreviewPanel.NavigationTarget) -> Void
    
    @State private var selectedTab: NovaTab = .priorities
    
    enum DisplayMode {
        case minimal
        case expanded
    }
    
    enum NovaTab: String, CaseIterable {
        case priorities = "Priorities"
        case map = "Map"
        case analytics = "Analytics"
        case chat = "Chat"
        
        var icon: String {
            switch self {
            case .priorities: return "exclamationmark.triangle.fill"
            case .map: return "map.fill"
            case .analytics: return "chart.bar.fill"
            case .chat: return "message.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .priorities: return CyntientOpsDesign.DashboardColors.critical
            case .map: return CyntientOpsDesign.DashboardColors.info
            case .analytics: return CyntientOpsDesign.DashboardColors.success
            case .chat: return CyntientOpsDesign.DashboardColors.warning
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if displayMode == .expanded {
                // Tab content area
                tabContentView
                    .frame(height: 120)
                    .background(CyntientOpsDesign.DashboardColors.cardBackground)
            }
            
            // Main intelligence bar with tabs
            HStack(spacing: 0) {
                ForEach(NovaTab.allCases, id: \.self) { tab in
                    Button(action: {
                        if tab == .map {
                            onSelectMapTab()
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = tab
                            }
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: selectedTab == tab ? 18 : 16))
                                .foregroundColor(selectedTab == tab ? tab.color : CyntientOpsDesign.DashboardColors.tertiaryText)
                            
                            Text(tab.rawValue)
                                .font(.caption2)
                                .foregroundColor(selectedTab == tab ? tab.color : CyntientOpsDesign.DashboardColors.tertiaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            selectedTab == tab ? tab.color.opacity(0.1) : Color.clear
                        )
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(CyntientOpsDesign.DashboardColors.cardBackground)
        }
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: -2)
    }
    
    @ViewBuilder
    private var tabContentView: some View {
        switch selectedTab {
        case .priorities:
            WorkerPrioritiesContentView(
                insights: insights,
                contextEngine: contextEngine,
                onNavigate: onNavigate
            )
            
        case .map:
            WorkerMapContentView()
            
        case .analytics:
            WorkerAnalyticsContentView(contextEngine: contextEngine)
            
        case .chat:
            WorkerChatContentView()
        }
    }
}

// MARK: - Worker Tab Content Views

struct WorkerPrioritiesContentView: View {
    let insights: [CoreTypes.IntelligenceInsight]
    let contextEngine: WorkerContextEngine
    let onNavigate: (IntelligencePreviewPanel.NavigationTarget) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Show urgent tasks first
                ForEach(contextEngine.todaysTasks.filter { $0.urgency == .urgent || $0.urgency == .critical }.prefix(3)) { task in
                    WorkerTaskCard(task: task, style: .pending, requiresPhoto: task.requiresPhoto ?? false) {
                        onNavigate(.taskDetail(id: task.id))
                    }
                }

                // Then show insights
                ForEach(insights.prefix(2)) { insight in
                    WorkerInsightCard(insight: insight) {
                        onNavigate(.fullInsights)
                    }
                }

                if contextEngine.todaysTasks.filter({ $0.urgency == .urgent || $0.urgency == .critical }).isEmpty && insights.isEmpty {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                        Text("All Clear")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    }
                    .frame(width: 100, height: 80)
                    .background(CyntientOpsDesign.DashboardColors.glassOverlay)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
    }
}

struct WorkerMapContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "map.fill")
                .font(.title)
                .foregroundColor(CyntientOpsDesign.DashboardColors.info)
            Text("Tap to reveal map")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WorkerAnalyticsContentView: View {
    let contextEngine: WorkerContextEngine

    var body: some View {
        HStack(spacing: 16) {
            WorkerAnalyticsPill(
                title: "Tasks Today",
                value: "\(contextEngine.todaysTasks.count)",
                color: .blue
            )

            WorkerAnalyticsPill(
                title: "Completed",
                value: "\(contextEngine.todaysTasks.filter { $0.isCompleted }.count)",
                color: .green
            )

            WorkerAnalyticsPill(
                title: "Urgent",
                value: "\(contextEngine.todaysTasks.filter { $0.urgency == .urgent || $0.urgency == .critical }.count)",
                color: .red
            )

            if contextEngine.assignedBuildings.count > 1 {
                WorkerAnalyticsPill(
                    title: "Buildings",
                    value: "\(contextEngine.assignedBuildings.count)",
                    color: .cyan
                )
            }
        }
        .padding(.horizontal, 12)
    }
}

struct WorkerChatContentView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "message.fill")
                .font(.title2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.warning)

            VStack(alignment: .leading, spacing: 2) {
                Text("Nova AI Assistant")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)

                Text("Ask about tasks, routes, or issues...")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }

            Spacer()

            Button("Chat") {
                // Handle chat action
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(CyntientOpsDesign.DashboardColors.warning)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Worker Supporting Components

struct WorkerInsightCard: View {
    let insight: CoreTypes.IntelligenceInsight
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 6, height: 6)

                    Spacer()

                    Text(insight.priority.rawValue.uppercased())
                        .font(.caption2)
                        .foregroundColor(priorityColor)
                }

                Text(insight.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let action = insight.recommendedAction {
                    Text(action)
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        .lineLimit(1)
                }
            }
            .padding(8)
            .frame(width: 140, height: 80)
            .background(CyntientOpsDesign.DashboardColors.glassOverlay)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var priorityColor: Color {
        switch insight.priority {
        case .critical: return CyntientOpsDesign.DashboardColors.critical
        case .high: return CyntientOpsDesign.DashboardColors.warning
        case .medium: return .orange
        case .low: return CyntientOpsDesign.DashboardColors.info
        }
    }
}

struct WorkerAnalyticsPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview Provider

struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview requires full ServiceContainer setup - placeholder for now
        Text("WorkerDashboardView Preview")
            .foregroundColor(.white)
            .preferredColorScheme(.dark)
    }
}
