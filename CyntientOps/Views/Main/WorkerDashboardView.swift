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

// MARK: - WorkerRoute Definition
enum WorkerRoute: Identifiable {
    case routeMap
    case schedule
    case addNote(buildingId: String?)
    case reportIssue(buildingId: String?)
    case emergency
    case buildingDetail(String)
    case taskDetail(String)
    
    var id: String { 
        switch self {
        case .routeMap: return "routeMap"
        case .schedule: return "schedule"
        case .addNote(let id): return "addNote_\(id ?? "nil")"
        case .reportIssue(let id): return "reportIssue_\(id ?? "nil")"
        case .emergency: return "emergency"
        case .buildingDetail(let id): return "buildingDetail_\(id)"
        case .taskDetail(let id): return "taskDetail_\(id)"
        }
    }
}

struct WorkerDashboardView: View {
    @StateObject var viewModel: WorkerDashboardViewModel
    @ObservedObject private var contextEngine = WorkerContextEngine.shared
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var novaEngine: NovaAIManager // From ServiceContainer
    
    private let container: ServiceContainer
    
    // Single route state for all navigation
    @State private var route: WorkerRoute?
    
    // Access DashboardSyncService through container
    private var dashboardSync: DashboardSyncService {
        container.dashboardSync
    }
    
    init(container: ServiceContainer) {
        self.container = container
        self._viewModel = StateObject(wrappedValue: WorkerDashboardViewModel(container: container))
    }
    
    // MARK: - State Variables
    @State private var heroState: HeroState = .expanded
    @State private var refreshID = UUID()
    @State private var isMapRevealed = false
    @State private var showBuildingSelection = false
    
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
    
    @ViewBuilder
    private var contextAwareContent: some View {
        VStack(spacing: 16) {
            if hasUrgentTasks() {
                // Show urgent task cards
                urgentTasksSection
            }
            
            if viewModel.isCurrentlyClockedIn {
                // Current building details and active task list
                currentBuildingSection
            } else {
                // Clock in prompt and assigned buildings list
                clockInPromptSection
            }
        }
    }
    
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
            buildings: viewModel.workerCapabilities?.canViewMap ?? true ? 
                viewModel.buildingsForMap.map { pin in
                    CoreTypes.NamedCoordinate(
                        id: pin.id, 
                        name: pin.name, 
                        latitude: pin.coordinate.latitude, 
                        longitude: pin.coordinate.longitude
                    )
                } : [],
            currentBuildingId: viewModel.currentBuilding?.id,
            focusBuildingId: nil,
            isRevealed: $isMapRevealed,
            onBuildingTap: { building in
                // Use the new route system
                route = .buildingDetail(building.id)
                providePreciseHapticFeedback()
            }
        ) {
            ZStack {
                // Dark Elegance Background
                CyntientOpsDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // WorkerHeaderV3B - Fixed header with authenticated user
                    WorkerHeaderV3B(
                        name: authManager.currentUser?.name ?? "Worker",
                        initials: getInitials(from: authManager.currentUser?.name),
                        photoURL: nil, // CoreTypes.User doesn't have photoURL property
                        nextTaskName: getCurrentTask()?.title,
                        showClockPill: true,
                        isNovaProcessing: novaEngine.isThinking,
                        onRoute: { headerRoute in
                            handleHeaderRoute(headerRoute)
                            providePreciseHapticFeedback()
                        }
                    )
                    .zIndex(100)
                    
                    // Main content area
                    ScrollView {
                        VStack(spacing: 16) {
                            // WorkerHeroCard - Single hero card with two tiles
                            WorkerHeroCard(
                                state: $heroState,
                                currentBuildingTitle: viewModel.currentBuilding?.name ?? "Select Building",
                                todaySummary: "\(viewModel.todaysTasks.count) tasks today",
                                firstName: authManager.currentUser?.name.components(separatedBy: " ").first ?? "Worker",
                                openBuilding: {
                                    if let buildingId = viewModel.currentBuilding?.id {
                                        route = .buildingDetail(buildingId)
                                    } else {
                                        showBuildingSelection = true
                                    }
                                    providePreciseHapticFeedback()
                                },
                                openSchedule: {
                                    route = .schedule
                                    providePreciseHapticFeedback()
                                }
                            )
                            .padding(.horizontal)
                            .zIndex(50)
                            
                            // Context-aware content loading
                            contextAwareContent
                            
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
                            onRoute: { novaRoute in
                                handleNovaRoute(novaRoute)
                                providePreciseHapticFeedback()
                            },
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
        .sheet(item: $viewModel.sheet) { sheet in
            switch sheet {
            case .routes:
                RoutesSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                    
            case .schedule:
                ScheduleSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                    
            case .building(let building):
                BuildingDetailSheet(building: building)
                    .presentationDetents([.medium, .large])
                    
            case .tasks:
                TasksSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                    
            case .photos:
                PhotosSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                    
            case .settings:
                if let workerId = authManager.workerId {
                    WorkerProfileView(workerId: workerId)
                }
            }
        }
        // New single sheet router (Per Design Brief)
        .sheet(item: $route) { route in
            switch route {
            case .routeMap:
                RoutesSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                
            case .schedule:
                ScheduleSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                
            case .addNote(let buildingId):
                TasksSheet(viewModel: viewModel)
                    .presentationDetents([.medium])
                
            case .reportIssue(let buildingId):
                TasksSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                
            case .emergency:
                TasksSheet(viewModel: viewModel)
                    .presentationDetents([.large])
                
            case .buildingDetail(let buildingId):
                if let building = viewModel.assignedBuildings.first(where: { $0.id == buildingId }) {
                    BuildingDetailSheet(building: building)
                        .presentationDetents([.medium, .large])
                }
                
            case .taskDetail(let taskId):
                TasksSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
        }
        .onAppear {
            checkFeatureFlags()
            
            // Load worker context when view appears
            if authManager.workerId != nil {
                Task {
                    await contextEngine.refreshContext()
                    await viewModel.refreshData()
                }
            }
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
            viewModel.sheet = .tasks
            
        case .buildings(_):
            // Show routes sheet to display all affected buildings
            viewModel.sheet = .routes
            
        case .compliance(_):
            viewModel.sheet = .tasks
            
        case .maintenance(_):
            viewModel.sheet = .tasks
            
        case .fullInsights:
            // Trigger haptic feedback and provide visual feedback
            providePreciseHapticFeedback()
            // For now, show tasks sheet as a placeholder
            viewModel.sheet = .tasks
            
        case .allTasks:
            viewModel.sheet = .tasks
            
        case .taskDetail(_):
            viewModel.sheet = .tasks
            
        case .allBuildings:
            viewModel.sheet = .routes
            
        case .buildingDetail(let id):
            if let building = contextEngine.assignedBuildings.first(where: { $0.id == id }) {
                viewModel.sheet = .building(building)
            }
            
        case .clockOut:
            handleClockAction()
            
        case .profile:
            viewModel.sheet = .settings
            
        case .settings:
            viewModel.sheet = .settings
            
        case .dsnyTasks:
            viewModel.sheet = .tasks
            
        case .routeOptimization:
            viewModel.sheet = .routes
            
        case .photoEvidence:
            viewModel.sheet = .photos
            
        case .emergencyContacts:
            handleEmergencyAction()
        @unknown default:
            break
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleHeaderRoute(_ headerRoute: WorkerHeaderRoute) {
        switch headerRoute {
        case .mainMenu:
            // TODO: Implement main menu
            break
        case .profile:
            viewModel.sheet = .settings
        case .clockAction:
            handleClockAction()
        case .novaChat:
            // TODO: Implement Nova chat
            break
        }
    }
    
    private func handleClockAction() {
        if contextEngine.clockInStatus.isClockedIn {
            // Show departure checklist
            viewModel.sheet = .schedule
        } else if let firstBuilding = contextEngine.assignedBuildings.first {
            Task {
                await viewModel.clockIn(at: firstBuilding)
                await contextEngine.refreshContext()
            }
        }
        providePreciseHapticFeedback()
    }
    
    private func handleNovaQuickAction() {
        // Quick action menu or immediate AI response
        // TODO: Implement Nova AI interaction
        print("Nova quick action triggered")
        providePreciseHapticFeedback()
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
    
    private func handleNovaRoute(_ novaRoute: NovaRoute) {
        switch novaRoute {
        case .priorities:
            // Show urgent tasks
            route = .schedule
        case .tasks:
            route = .schedule
        case .analytics:
            // Navigate to performance/analytics view
            print("Navigate to analytics")
        case .chat:
            // Open Nova chat
            currentContext = .novaChat
        case .map:
            // Open route map
            route = .routeMap
        }
    }
    
    private func getInitials(from name: String?) -> String {
        guard let name = name else { return "W" }
        let components = name.components(separatedBy: " ")
        let first = components.first?.first ?? "W"
        let last = components.count > 1 ? components.last?.first : nil
        
        if let last = last {
            return "\(first)\(last)".uppercased()
        } else {
            return String(first).uppercased()
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
    
    // MARK: - Haptic Feedback
    
    private func providePreciseHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
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
        // Always show for now to debug display issues
        return true
        // TODO: Restore proper conditions later:
        // return viewModel.assignedBuildings.count > 1 ||
        //        viewModel.todaysTasks.filter { $0.isCompleted }.count > 3 ||
        //        hasUpcomingDeadlines()
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
    
    // MARK: - Context-Aware Content Sections
    
    @ViewBuilder
    private var urgentTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🚨 Urgent Tasks")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            ForEach(viewModel.todaysTasks.filter { $0.urgency == .urgent || $0.urgency == .critical }.prefix(3), id: \.id) { task in
                Button(action: {
                    viewModel.sheet = .tasks
                    providePreciseHapticFeedback()
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        
                        VStack(alignment: .leading) {
                            Text(task.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            
                            if let building = task.building {
                                Text(building.name)
                                    .font(.caption)
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                    .padding()
                    .background(CyntientOpsDesign.DashboardColors.cardBackground)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    @ViewBuilder
    private var currentBuildingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let building = contextEngine.currentBuilding {
                Text("📍 Current Location: \(building.name)")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text("Active Tasks")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                ForEach(viewModel.todaysTasks.filter { !$0.isCompleted }.prefix(5), id: \.id) { task in
                    WorkerTaskRowView(task: task) {
                        viewModel.sheet = .tasks
                        providePreciseHapticFeedback()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var clockInPromptSection: some View {
        VStack(spacing: 16) {
            Text("📲 Ready to Start Your Day?")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text("Select a building to clock in")
                .font(.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(contextEngine.assignedBuildings.prefix(4), id: \.id) { building in
                    Button(action: {
                        Task {
                            await viewModel.clockIn(at: building)
                            await contextEngine.refreshContext()
                        }
                        providePreciseHapticFeedback()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "building.2.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text(building.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                        .background(CyntientOpsDesign.DashboardColors.cardBackground)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
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

    // Computed property to get urgent tasks
    private var urgentTasks: [CoreTypes.ContextualTask] {
        contextEngine.todaysTasks.filter { $0.urgency == .urgent || $0.urgency == .critical }
    }
    
    private var hasNoUrgentContent: Bool {
        urgentTasks.isEmpty && insights.isEmpty
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Show urgent tasks first
                urgentTasksContent
                
                // Then show insights
                insightsContent
                
                // Show "All Clear" if no urgent content
                if hasNoUrgentContent {
                    allClearContent
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var urgentTasksContent: some View {
        ForEach(Array(urgentTasks.prefix(3))) { task in
            urgentTaskCard(for: task)
        }
    }
    
    @ViewBuilder
    private var insightsContent: some View {
        ForEach(Array(insights.prefix(2))) { insight in
            WorkerInsightCard(insight: insight) {
                onNavigate(.fullInsights)
            }
        }
    }
    
    private var allClearContent: some View {
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
    
    // MARK: - Task Card Builder
    
    private func urgentTaskCard(for task: CoreTypes.ContextualTask) -> some View {
        Button(action: { onNavigate(.taskDetail(id: task.id)) }) {
            taskCardContent(for: task)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func taskCardContent(for task: CoreTypes.ContextualTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            taskCardHeader(for: task)
            
            if let description = task.description {
                taskCardDescription(description)
            }
        }
        .padding(12)
        .frame(width: 180)
        .background(taskCardBackground)
    }
    
    private func taskCardHeader(for task: CoreTypes.ContextualTask) -> some View {
        HStack {
            Circle()
                .fill(CyntientOpsDesign.DashboardColors.critical)
                .frame(width: 6, height: 6)
            
            Text(task.title)
                .francoTypography(CyntientOpsDesign.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                .lineLimit(1)
            
            Spacer()
        }
    }
    
    private func taskCardDescription(_ description: String) -> some View {
        Text(description)
            .francoTypography(CyntientOpsDesign.Typography.caption2)
            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            .lineLimit(2)
    }
    
    private var taskCardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(CyntientOpsDesign.DashboardColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CyntientOpsDesign.DashboardColors.critical.opacity(0.3), lineWidth: 1)
            )
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

// MARK: - Sheet Views

struct RoutesSheet: View {
    let viewModel: WorkerDashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            routeContent
                .navigationTitle("Today's Route")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
                .background(CyntientOpsDesign.DashboardColors.baseBackground)
        }
        .preferredColorScheme(.dark)
    }
    
    private var routeContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.routeForToday, id: \.id) { stop in
                    RouteStopCard(stop: stop) {
                        handleRouteStopSelection(stop)
                    }
                }
            }
            .padding()
        }
    }
    
    private func handleRouteStopSelection(_ stop: WorkerDashboardViewModel.RouteStop) {
        if let building = viewModel.assignedBuildingsToday.first(where: { $0.id == stop.building.id }) {
            Task {
                await viewModel.clockIn(at: building)
            }
            dismiss()
        }
    }
}

struct ScheduleSheet: View {
    let viewModel: WorkerDashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            scheduleContent
                .navigationTitle("Today's Schedule")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
                .background(CyntientOpsDesign.DashboardColors.baseBackground)
        }
        .preferredColorScheme(.dark)
    }
    
    private var scheduleContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.scheduleForToday, id: \.id) { item in
                    ScheduleItemCard(item: item) {
                        handleScheduleItemSelection(item)
                    }
                }
            }
            .padding()
        }
    }
    
    private func handleScheduleItemSelection(_ item: WorkerDashboardViewModel.ScheduledItem) {
        if let building = viewModel.assignedBuildingsToday.first(where: { $0.id == item.location.id }) {
            Task {
                await viewModel.clockIn(at: building)
            }
            dismiss()
        }
    }
}

struct TasksSheet: View {
    let viewModel: WorkerDashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.todaysTasks) { task in
                        EnhancedTaskCard(task: task) {
                            // Handle task selection - could show task detail
                            print("Task selected: \(task.title)")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Today's Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .background(CyntientOpsDesign.DashboardColors.baseBackground)
        }
        .preferredColorScheme(.dark)
    }
}

struct PhotosSheet: View {
    let viewModel: WorkerDashboardViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Photo Evidence")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .padding()
                
                Spacer()
                
                // TODO: Implement photo evidence view
                Text("Photo evidence functionality will be implemented here")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Photos")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .background(CyntientOpsDesign.DashboardColors.baseBackground)
        }
        .preferredColorScheme(.dark)
    }
}

struct BuildingDetailSheet: View {
    let building: CoreTypes.NamedCoordinate
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Building header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(building.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        
                        if !building.address.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                                Text(building.address)
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                            }
                        }
                    }
                    .padding()
                    .background(CyntientOpsDesign.DashboardColors.cardBackground)
                    .cornerRadius(12)
                    
                    // Quick actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        
                        // TODO: Add building-specific actions
                        Text("Building actions will be available here")
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                    .padding()
                    .background(CyntientOpsDesign.DashboardColors.cardBackground)
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Building Details")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .background(CyntientOpsDesign.DashboardColors.baseBackground)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Supporting Card Components

struct RouteStopCard: View {
    let stop: WorkerDashboardViewModel.RouteStop
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(stop.building.name)
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    HStack(spacing: 16) {
                        Label(stop.estimatedArrival.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                        Label("\(String(format: "%.1f", stop.distance))km", systemImage: "location")
                    }
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                if stop.status == .current {
                    Text("CURRENT")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CyntientOpsDesign.DashboardColors.success)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            .padding()
            .background(CyntientOpsDesign.DashboardColors.cardBackground)
            .cornerRadius(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        switch stop.status {
        case .completed: return CyntientOpsDesign.DashboardColors.success
        case .current: return CyntientOpsDesign.DashboardColors.warning
        case .pending: return CyntientOpsDesign.DashboardColors.secondaryText
        }
    }
}

struct ScheduleItemCard: View {
    let item: WorkerDashboardViewModel.ScheduledItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Time indicator
                VStack(spacing: 4) {
                    Text(item.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text("\(item.duration / 60)h")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text(item.location.name)
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    HStack(spacing: 12) {
                        Label("\(item.taskCount) tasks", systemImage: "checkmark.circle")
                        
                        if item.priority == .high {
                            Label("High Priority", systemImage: "exclamationmark.triangle")
                                .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .padding()
            .background(CyntientOpsDesign.DashboardColors.cardBackground)
            .cornerRadius(12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedTaskCard: View {
    let task: CoreTypes.ContextualTask
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Priority indicator
                VStack {
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 8, height: 8)
                    
                    if task.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                    } else {
                        Rectangle()
                            .fill(priorityColor.opacity(0.3))
                            .frame(width: 2, height: 20)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(2)
                    
                    if let description = task.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 12) {
                        if let building = task.building {
                            Label(building.name, systemImage: "building.2")
                        }
                        
                        if let dueDate = task.dueDate {
                            Label(dueDate.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                                .foregroundColor(task.isOverdue ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.secondaryText)
                        }
                        
                        if let urgency = task.urgency, urgency == .urgent || urgency == .critical {
                            Label("URGENT", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .padding()
            .background(CyntientOpsDesign.DashboardColors.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(priorityColor.opacity(task.urgency == .urgent || task.urgency == .critical ? 0.5 : 0.1), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var priorityColor: Color {
        switch task.urgency {
        case .critical, .emergency:
            return CyntientOpsDesign.DashboardColors.critical
        case .urgent, .high:
            return CyntientOpsDesign.DashboardColors.warning
        case .medium:
            return .orange
        case .low, .normal, .none:
            return CyntientOpsDesign.DashboardColors.info
        }
    }
}

// MARK: - CO Design Tokens for WorkerDashboard
private enum CO {
    static let primary = CyntientOpsDesign.DashboardColors.primaryText
    static let secondary = CyntientOpsDesign.DashboardColors.secondaryText
    static let tertiary = CyntientOpsDesign.DashboardColors.tertiaryText
    static let blue = CyntientOpsDesign.DashboardColors.workerPrimary
    static let surface = Color.clear // Will use .regularMaterial
    static let hair = CyntientOpsDesign.DashboardColors.borderSubtle
    static let padding: CGFloat = 16
    static let radius: CGFloat = CyntientOpsDesign.CornerRadius.md
}

// MARK: - TimeOfDay Helper
private enum DashboardTimeOfDay {
    static var now: DashboardTimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<22: return .evening
        default: return .night
        }
    }
    
    case morning, afternoon, evening, night
    
    var greeting: String {
        switch self {
        case .morning: return "morning"
        case .afternoon: return "afternoon"
        case .evening: return "evening"
        case .night: return "evening"
        }
    }
}

// MARK: - HeroState Enum
enum HeroState { 
    case expanded, collapsed 
}

// MARK: - WorkerHeroCard Component (Per Design Brief)

struct WorkerHeroCard: View {
    @Binding var state: HeroState
    let currentBuildingTitle: String
    let todaySummary: String
    let firstName: String
    var openBuilding: () -> Void
    var openSchedule: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Good \(DashboardTimeOfDay.now.greeting), \(firstName)")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(CO.primary)
                Spacer()
                Button { 
                    withAnimation(.easeInOut(duration: 0.18)) { 
                        state = state == .expanded ? .collapsed : .expanded 
                    } 
                } label: {
                    Image(systemName: state == .expanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(CO.secondary)
                        .font(.system(size: 16, weight: .medium))
                }
                .buttonStyle(.plain)
            }
            
            if state == .expanded {
                HStack(spacing: 12) {
                    HeroTile(
                        title: "Current Building",
                        subtitle: currentBuildingTitle,
                        icon: "building.2",
                        action: openBuilding
                    )
                    
                    HeroTile(
                        title: "Today",
                        subtitle: todaySummary,
                        icon: "calendar.badge.clock",
                        action: openSchedule
                    )
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(CO.padding)
        .background(.ultraThinMaterial)
        .overlay(RoundedRectangle(cornerRadius: CO.radius).stroke(CO.hair, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: CO.radius))
        .padding(.horizontal, 16)
    }
}

// MARK: - HeroTile Component

private struct HeroTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(CO.blue)
                        .font(.system(size: 20, weight: .medium))
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(CO.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(CO.tertiary)
                        .font(.system(size: 12))
                }
                Text(subtitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(CO.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .background(.regularMaterial)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(CO.hair, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
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
