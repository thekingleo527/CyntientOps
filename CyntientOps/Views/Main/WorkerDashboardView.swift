//
//  WorkerDashboardView.swift  
//  CyntientOps v7.0
//
//  ✅ UNIFIED DESIGN: Matches ClientDashboardView structure and styling
//  ✅ REAL DATA: Shows worker-specific routines and building assignments
//  ✅ RESPONSIVE: Adaptive layout with intelligence panel
//

import SwiftUI
import MapKit

struct WorkerDashboardView: View {
    @StateObject private var viewModel: WorkerDashboardViewModel
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var novaManager: NovaAIManager
    
    // MARK: - Responsive Layout
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    private let container: ServiceContainer
    
    init(container: ServiceContainer) {
        self.container = container
        self._viewModel = StateObject(wrappedValue: WorkerDashboardViewModel(container: container))
    }
    
    // MARK: - Sheet Navigation
    enum WorkerRoute: Identifiable {
        case profile, buildingDetail(String), taskDetail(String), schedule, routes, emergency, settings, novaInteraction
        
        var id: String {
            switch self {
            case .profile: return "profile"
            case .buildingDetail(let id): return "building-\(id)"
            case .taskDetail(let id): return "task-\(id)"
            case .schedule: return "schedule"
            case .routes: return "routes"
            case .emergency: return "emergency"
            case .settings: return "settings"
            case .novaInteraction: return "novaInteraction"
            }
        }
    }
    
    // MARK: - Nova Intelligence Tabs (Mirroring Client Design)
    enum NovaTab: String, CaseIterable {
        case routines = "Routines"
        case portfolio = "Portfolio"
        case analytics = "Analytics"
        case schedule = "Schedule"
        
        var icon: String {
            switch self {
            case .routines: return "checklist"
            case .portfolio: return "building.2"
            case .analytics: return "chart.bar"
            case .schedule: return "calendar"
            }
        }
    }
    
    // MARK: - State
    @State private var heroExpanded = true
    @State private var selectedNovaTab: NovaTab = .routines
    @State private var sheet: WorkerRoute?
    @State private var isPortfolioMapRevealed = false
    
    var body: some View {
        ZStack {
            // Map as underlay (prevents layout conflicts)
            MapRevealContainer(
                buildings: viewModel.assignedBuildings.map { building in
                    CoreTypes.NamedCoordinate(
                        id: building.id,
                        name: building.name,
                        address: building.address,
                        latitude: building.coordinate.latitude,
                        longitude: building.coordinate.longitude
                    )
                },
                currentBuildingId: viewModel.currentBuilding?.id,
                isRevealed: $isPortfolioMapRevealed,
                onBuildingTap: { building in
                    sheet = .buildingDetail(building.id)
                }
            ) {
                EmptyView()
            }
            .ignoresSafeArea()
            
            // Main content layer
            VStack(spacing: 0) {
                // Unified Header (CyntientOps branding + Nova avatar + worker pill)
                WorkerHeaderWithNova(
                    workerName: viewModel.worker?.name ?? authManager.currentUser?.name ?? "Worker",
                    workerInitials: getWorkerInitials(),
                    isClockedIn: viewModel.isClockedIn,
                    currentBuilding: viewModel.currentBuilding?.name,
                    onNovaInteraction: { sheet = .novaInteraction },
                    onProfileTap: { sheet = .profile },
                    onClockAction: handleClockIn
                )
                
                // Weather-based task suggestions (slim, intelligent)
                if let weather = viewModel.weatherData {
                    WeatherBasedTaskSuggestions(
                        weather: weather,
                        todaysTasks: viewModel.todaysTasks,
                        onTaskSelect: { taskId in
                            Task { await viewModel.prioritizeTask(taskId) }
                        }
                    )
                }
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 16) {
                        // Hero Card - Assigned Buildings with real-time data
                        WorkerHeroCard(
                            assignedBuildings: viewModel.assignedBuildings,
                            currentBuilding: viewModel.currentBuilding,
                            nextTask: viewModel.todaysTasks.first { !$0.isCompleted },
                            isClockedIn: viewModel.isClockedIn,
                            completionRate: viewModel.completionRate,
                            onBuildingTap: { buildingId in
                                sheet = .buildingDetail(buildingId)
                            },
                            onViewAllBuildings: {
                                withAnimation(.spring()) {
                                    isPortfolioMapRevealed.toggle()
                                }
                            },
                            onStartNext: {
                                if let nextTask = viewModel.todaysTasks.first(where: { !$0.isCompleted }) {
                                    Task { await viewModel.startTask(nextTask.id) }
                                }
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .refreshable {
                    await viewModel.refreshData()
                }
            }
            .background(CyntientOpsDesign.DashboardColors.baseBackground)
        }
        .safeAreaInset(edge: .bottom) {
            // Intelligence Panel as safe area inset (prevents scroll conflicts)
            WorkerNovaIntelligencePanel(
                selectedTab: $selectedNovaTab,
                todaysTasks: viewModel.todaysTasks,
                weeklySchedule: viewModel.scheduleWeek,
                assignedBuildings: viewModel.assignedBuildings,
                completionRate: viewModel.completionRate,
                onTabTap: handleNovaTabTap,
                onScheduleExpand: { sheet = .schedule },
                onMapToggle: {
                    withAnimation(.spring()) {
                        isPortfolioMapRevealed.toggle()
                    }
                },
                viewModel: viewModel
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: "en_US"))
        .sheet(item: $sheet) { route in
            NavigationView {
                workerSheetContent(for: route)
            }
        }
        .task {
            await viewModel.refreshData()
        }
    }
    
    // MARK: - Helper Methods
    
    private func getFirstName() -> String {
        guard let fullName = viewModel.worker?.name else { return "Worker" }
        return fullName.components(separatedBy: " ").first ?? "Worker"
    }
    
    private func getWorkerInitials() -> String {
        guard let fullName = viewModel.worker?.name else { return "W" }
        let components = fullName.components(separatedBy: " ")
        let firstInitial = components.first?.prefix(1) ?? "W"
        let lastInitial = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return "\(firstInitial)\(lastInitial)".uppercased()
    }
    
    private func hasUrgentTasks() -> Bool {
        return viewModel.todaysTasks.contains { task in
            task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency
        }
    }
    
    private func hasUrgentItems() -> Bool {
        return hasUrgentTasks() || 
               getOverdueCount() > 0 || 
               (!viewModel.isClockedIn && shouldBeWorking())
    }
    
    private func getUrgentTasks() -> [WorkerDashboardViewModel.TaskItem] {
        return viewModel.todaysTasks.filter { task in
            task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency
        }
    }
    
    private func getOverdueCount() -> Int {
        return viewModel.todaysTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < Date() && !task.isCompleted
        }.count
    }
    
    private func shouldBeWorking() -> Bool {
        // Check if it's during working hours (7 AM - 5 PM)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        return hour >= 7 && hour < 17
    }
    
    private func handleBuildingTap() {
        if let currentBuilding = viewModel.currentBuilding {
            sheet = .buildingDetail(currentBuilding.id)
        } else {
            // Show building selection if not clocked in
            selectedNovaTab = .portfolio
        }
    }
    
    private func getIntelligencePanelTotalHeight() -> CGFloat {
        let contentHeight = getIntelligencePanelContentHeight()
        let tabBarHeight: CGFloat = 65
        return contentHeight + tabBarHeight + 20
    }
    
    private func getIntelligencePanelContentHeight() -> CGFloat {
        switch selectedNovaTab {
        case .portfolio:
            return 240 // Map needs more height
        case .analytics:
            return 180 // Analytics and performance data
        case .schedule:
            return 180 // Schedule and time management
        case .routines:
            return 140 // Daily routines and workflows
        }
    }
    
    // MARK: - Navigation Handlers
    
    private func handleHeaderRoute(_ route: WorkerHeaderRoute) {
        switch route {
        case .profile: 
            sheet = .profile
        case .mainMenu: 
            // CyntientOps logo - no action
            break
        case .clockAction: 
            // Clock action - handle clock in/out
            break
        case .novaChat: 
            sheet = .novaInteraction
        }
    }
    
    private func handleNovaTabTap(_ tab: NovaTab) {
        switch tab {
        case .portfolio:
            // Interactive map showing today's route - reveal the map
            withAnimation(.spring()) {
                isPortfolioMapRevealed = true
            }
        case .analytics:
            // Analytics and performance data
            break
        case .schedule:
            // Schedule and time management
            break
        case .routines:
            // Daily routines and workflows
            sheet = .novaInteraction
        }
    }
    
    private func handleTaskAction(_ action: WorkerTaskAction) {
        switch action {
        case .completeTask(let taskId):
            Task {
                await viewModel.completeTask(taskId)
            }
        case .startTask(let taskId):
            Task {
                await viewModel.startTask(taskId)
            }
        case .viewDetails(let taskId):
            sheet = .taskDetail(taskId)
        }
    }
    
    // MARK: - Sheet Content
    
    @ViewBuilder
    private func workerSheetContent(for route: WorkerRoute) -> some View {
        switch route {
        case .profile:
            WorkerProfileView(workerId: viewModel.worker?.id ?? "")
                .navigationTitle("Profile")
                .navigationBarTitleDisplayMode(.large)
                
        case .buildingDetail(let buildingId):
            if let building = viewModel.assignedBuildings.first(where: { $0.id == buildingId }) {
                BuildingDetailView(
                    buildingId: building.id,
                    buildingName: building.name,
                    buildingAddress: building.address
                )
                .navigationTitle(building.name)
                .navigationBarTitleDisplayMode(.inline)
            }
            
        case .taskDetail(let taskId):
            if let task = viewModel.todaysTasks.first(where: { $0.id == taskId }) {
                UnifiedTaskDetailView(
                    task: task.asContextualTask,
                    mode: .worker
                )
                .navigationTitle(task.title)
                .navigationBarTitleDisplayMode(.inline)
            }
            
        case .schedule:
            WorkerScheduleView(
                weeklySchedule: viewModel.scheduleWeek,
                assignedBuildings: viewModel.assignedBuildings
            )
            .navigationTitle("My Schedule")
            .navigationBarTitleDisplayMode(.large)
            
        case .routes:
            WorkerRoutesView(
                assignedBuildings: viewModel.assignedBuildings,
                currentBuilding: viewModel.currentBuilding
            )
            .navigationTitle("My Routes")
            .navigationBarTitleDisplayMode(.large)
            
        case .emergency:
            EmergencyContactsSheet()
                .navigationTitle("Emergency Contacts")
                .navigationBarTitleDisplayMode(.inline)
                
        case .settings:
            WorkerPreferencesView(workerId: viewModel.worker?.id ?? "")
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
                
        case .novaInteraction:
            NovaInteractionView()
                .environmentObject(container.novaManager)
                .navigationTitle("Nova Assistant")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Helper Properties and Functions
    
    // MARK: - New Action-Focused Helpers
    
    enum WorkflowState {
        case needsClockIn
        case atBuilding
        case betweenBuildings  
        case endOfDay
    }
    
    struct TimeBlock {
        let building: String
        let startTime: Date
        let endTime: Date
        let remainingTime: TimeInterval
    }
    
    private func getCurrentTimeBlock() -> TimeBlock? {
        guard let currentBuilding = viewModel.currentBuilding else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let _ = calendar.startOfDay(for: now)
        
        // Find current time block from real scheduleWeek data (compiled from RRULE patterns)
        guard let todaySchedule = viewModel.scheduleWeek.first(where: { 
            calendar.isDate($0.date, inSameDayAs: now) 
        }) else {
            return nil
        }
        
        // Find the current time block from real schedule items
        let currentScheduleItem = todaySchedule.items.first { item in
            return now >= item.startTime && now <= item.endTime && 
                   item.buildingId == currentBuilding.id
        }
        
        if let scheduleItem = currentScheduleItem {
            // Use real RRULE-compiled schedule data
            let remainingTime = scheduleItem.endTime.timeIntervalSince(now)
            
            return TimeBlock(
                building: currentBuilding.name,
                startTime: scheduleItem.startTime,
                endTime: scheduleItem.endTime,
                remainingTime: max(0, remainingTime)
            )
        }
        
        return nil
    }
    
    private func getWorkflowState() -> WorkflowState {
        if !viewModel.isClockedIn {
            return .needsClockIn
        }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        
        if hour >= 16 { // 4 PM or later
            return .endOfDay
        } else if viewModel.currentBuilding != nil {
            return .atBuilding
        } else {
            return .betweenBuildings
        }
    }
    
    private func handleClockIn() {
        // Handle clock in logic
        Task {
            if let building = viewModel.currentBuilding {
                let coordinate = CoreTypes.NamedCoordinate(
                    id: building.id,
                    name: building.name,
                    latitude: building.coordinate.latitude,
                    longitude: building.coordinate.longitude
                )
                await viewModel.clockIn(at: coordinate)
            }
        }
    }
    
    private func handleNavigateToBuilding() {
        if let nextTask = viewModel.todaysTasks.first(where: { !$0.isCompleted }),
           let buildingId = nextTask.buildingId {
            sheet = .buildingDetail(buildingId)
        }
    }
}

// MARK: - Worker Header Component


// MARK: - Worker Next Action Hero Card (Redesigned)

struct WorkerNextActionHeroCard: View {
    @Binding var isExpanded: Bool
    let currentBuilding: WorkerDashboardViewModel.BuildingSummary?
    let nextTask: WorkerDashboardViewModel.TaskItem?
    let upcomingTasks: [WorkerDashboardViewModel.TaskItem]
    let currentTimeBlock: WorkerDashboardView.TimeBlock?
    let isClockedIn: Bool
    let workflowState: WorkerDashboardView.WorkflowState
    let onStartTask: (String) -> Void
    let onViewDetails: (String) -> Void
    let onSkipTask: (String) -> Void
    let onClockIn: () -> Void
    let onNavigateToBuilding: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // Expanded Next Action Card
                VStack(spacing: 16) {
                    // Current Location & Time Block
                    if let timeBlock = currentTimeBlock {
                        CurrentLocationTimeBlock(timeBlock: timeBlock, isClockedIn: isClockedIn)
                    }
                    
                    // Immediate Task - BIG & CLEAR
                    if let nextTask = nextTask {
                        ImmediateTaskCard(
                            task: nextTask,
                            workflowState: workflowState,
                            onStartTask: onStartTask,
                            onViewDetails: onViewDetails,
                            onSkipTask: onSkipTask
                        )
                    } else {
                        NoTasksCard(workflowState: workflowState, onClockIn: onClockIn)
                    }
                    
                    // Next 2 Tasks Preview
                    if !upcomingTasks.isEmpty {
                        UpcomingTasksPreview(tasks: upcomingTasks)
                    }
                    
                    // Collapse Button
                    CollapseButton {
                        withAnimation(CyntientOpsDesign.Animations.spring) {
                            isExpanded = false
                        }
                    }
                }
                .padding(16)
                .francoDarkCardBackground(cornerRadius: 12)
            } else {
                // Collapsed Next Action Summary (80px)
                Button(action: {
                    withAnimation(CyntientOpsDesign.Animations.spring) {
                        isExpanded = true
                    }
                }) {
                    HStack(spacing: 16) {
                        // Workflow Status Indicator
                        WorkflowStatusIndicator(state: workflowState, isClockedIn: isClockedIn)
                        
                        // Next Action Summary
                        VStack(alignment: .leading, spacing: 2) {
                            if let nextTask = nextTask {
                                Text(nextTask.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                                    .lineLimit(1)
                                
                                if let building = currentBuilding {
                                    Text("at \(building.name)")
                                        .font(.caption)
                                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                                }
                            } else {
                                Text(getEmptyStateMessage())
                                    .font(.subheadline)
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        // Quick Action Button
                        if let nextTask = nextTask {
                            Button("START") {
                                onStartTask(nextTask.id)
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(CyntientOpsDesign.DashboardColors.workerPrimary)
                            .cornerRadius(12)
                        }
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .francoDarkCardBackground(cornerRadius: 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func getEmptyStateMessage() -> String {
        switch workflowState {
        case .needsClockIn: return "Clock in to start"
        case .atBuilding: return "All tasks complete"
        case .betweenBuildings: return "Travel to next building"
        case .endOfDay: return "Day complete"
        }
    }
}

struct WorkerRealTimeHeroCard: View {
    @Binding var isExpanded: Bool
    let currentBuilding: WorkerDashboardViewModel.BuildingSummary?
    let todaysTasks: [WorkerDashboardViewModel.TaskItem]
    let completedTasksCount: Int
    let isClockedIn: Bool
    let clockInTime: Date?
    let weather: CoreTypes.WeatherData?
    let onBuildingTap: () -> Void
    let onScheduleTap: () -> Void
    let onTasksTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // Full Hero Card with Real-time Worker Data
                VStack(spacing: 16) {
                    // Top Row - Current Status
                    HStack(spacing: 12) {
                        WorkerMetricTile(
                            title: "Current Building",
                            value: currentBuilding?.name ?? "Not Assigned",
                            subtitle: isClockedIn ? "Clocked In" : "Clock In Required",
                            color: buildingStatusColor,
                            onTap: onBuildingTap
                        )
                        
                        WorkerMetricTile(
                            title: "Today's Tasks",
                            value: "\(completedTasksCount)/\(todaysTasks.count)",
                            subtitle: completionSubtitle,
                            color: tasksStatusColor,
                            onTap: onTasksTap
                        )
                    }
                    
                    // Middle Row - Progress and Schedule
                    HStack(spacing: 12) {
                        WorkerMetricTile(
                            title: "Completion Rate",
                            value: "\(completionPercentage)%",
                            subtitle: "\(todaysTasks.count - completedTasksCount) Remaining",
                            color: completionRateColor,
                            onTap: onTasksTap
                        )
                        
                        WorkerMetricTile(
                            title: "Schedule",
                            value: formatTime(),
                            subtitle: scheduleSubtitle,
                            color: CyntientOpsDesign.DashboardColors.info,
                            onTap: onScheduleTap
                        )
                    }
                    
                    // Weather Strip (if available)
                    if let weather = weather {
                        WorkerWeatherStrip(weather: weather)
                    }
                    
                    // Urgent Tasks Alert (if any)
                    if hasUrgentTasks() {
                        WorkerUrgentAlert(
                            urgentCount: urgentTasksCount(),
                            onTap: onTasksTap
                        )
                    }
                    
                    // Collapse Button
                    Button(action: {
                        withAnimation(CyntientOpsDesign.Animations.spring) {
                            isExpanded = false
                        }
                    }) {
                        HStack {
                            Text("Show Less")
                                .font(.caption)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                            
                            Image(systemName: "chevron.up")
                                .font(.caption)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(16)
                .francoDarkCardBackground(cornerRadius: 12)
            } else {
                // Collapsed Hero Card with Real-time Status
                Button(action: {
                    withAnimation(CyntientOpsDesign.Animations.spring) {
                        isExpanded = true
                    }
                }) {
                    HStack(spacing: 16) {
                        // Real-time status indicator
                        HStack(spacing: 6) {
                            Circle()
                                .fill(liveStatusColor)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isClockedIn ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isClockedIn)
                            
                            Text(isClockedIn ? "Live" : "Offline")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(liveStatusColor)
                        }
                        
                        // Quick metrics
                        HStack(spacing: 12) {
                            WorkerMetricPill(
                                value: currentBuilding?.name ?? "No Building",
                                label: "",
                                color: buildingStatusColor
                            )
                            
                            WorkerMetricPill(
                                value: "\(completedTasksCount)/\(todaysTasks.count)",
                                label: "Tasks",
                                color: tasksStatusColor
                            )
                            
                            WorkerMetricPill(
                                value: "\(completionPercentage)%",
                                label: "Complete",
                                color: completionRateColor
                            )
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .francoDarkCardBackground(cornerRadius: 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var completionPercentage: Int {
        guard todaysTasks.count > 0 else { return 0 }
        return Int((Double(completedTasksCount) / Double(todaysTasks.count)) * 100)
    }
    
    private var buildingStatusColor: Color {
        if isClockedIn {
            return CyntientOpsDesign.DashboardColors.success
        } else if shouldBeWorking() {
            return CyntientOpsDesign.DashboardColors.warning
        }
        return CyntientOpsDesign.DashboardColors.secondaryText
    }
    
    private var tasksStatusColor: Color {
        if completionPercentage >= 80 {
            return CyntientOpsDesign.DashboardColors.success
        } else if completionPercentage >= 50 {
            return CyntientOpsDesign.DashboardColors.warning
        }
        return CyntientOpsDesign.DashboardColors.critical
    }
    
    private var completionRateColor: Color {
        if completionPercentage >= 80 {
            return CyntientOpsDesign.DashboardColors.success
        } else if completionPercentage >= 60 {
            return CyntientOpsDesign.DashboardColors.warning
        }
        return CyntientOpsDesign.DashboardColors.critical
    }
    
    private var liveStatusColor: Color {
        if hasUrgentTasks() {
            return CyntientOpsDesign.DashboardColors.critical
        } else if isClockedIn {
            return CyntientOpsDesign.DashboardColors.success
        }
        return CyntientOpsDesign.DashboardColors.secondaryText
    }
    
    private var completionSubtitle: String {
        let remaining = todaysTasks.count - completedTasksCount
        if remaining == 0 {
            return "All Complete!"
        } else if remaining == 1 {
            return "1 Remaining"
        } else {
            return "\(remaining) Remaining"
        }
    }
    
    private func hasUrgentTasks() -> Bool {
        return todaysTasks.contains { task in
            task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency
        }
    }
    
    private func urgentTasksCount() -> Int {
        return todaysTasks.filter { task in
            task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency
        }.count
    }
    
    private func formatTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    private var scheduleSubtitle: String {
        if let clockInTime = clockInTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Since \(formatter.string(from: clockInTime))"
        }
        return "Not Clocked In"
    }
    
    private func shouldBeWorking() -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        return hour >= 7 && hour < 17
    }
}

// MARK: - Supporting Components (to be continued...)

// Extension interfaces matching client dashboard patterns
extension WorkerDashboardViewModel.TaskItem: Identifiable {
    var asContextualTask: CoreTypes.ContextualTask {
        let urgency: CoreTypes.TaskUrgency? = {
            switch self.urgency {
            case .low: return .low
            case .normal: return .normal  
            case .high: return .high
            case .urgent: return .urgent
            case .critical: return .critical
            case .emergency: return .critical
            }
        }()
        
        return CoreTypes.ContextualTask(
            id: self.id,
            title: self.title,
            description: self.description,
            status: self.isCompleted ? .completed : .pending,
            scheduledDate: self.dueDate,
            dueDate: self.dueDate,
            category: CoreTypes.TaskCategory(rawValue: self.category.lowercased()),
            urgency: urgency,
            buildingId: self.buildingId,
            buildingName: nil,
            requiresPhoto: self.requiresPhoto,
            estimatedDuration: 30
        )
    }
}

enum WorkerTaskAction {
    case completeTask(String)
    case startTask(String)
    case viewDetails(String)
}

// MARK: - Placeholder Components (to be implemented)

struct WorkerMetricTile: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Spacer()
                    
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                }
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkerMetricPill: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            if !label.isEmpty {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
        }
    }
}

struct WorkerWeatherStrip: View {
    let weather: CoreTypes.WeatherData
    
    var body: some View {
        HStack {
            Image(systemName: "cloud.sun.fill")
                .font(.title3)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(weather.temperature))°F")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text(weather.condition.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            Text("Today")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CyntientOpsDesign.DashboardColors.info.opacity(0.1))
        .cornerRadius(8)
    }
}

struct WorkerUrgentAlert: View {
    let urgentCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
                
                Text("\(urgentCount) urgent task\(urgentCount == 1 ? "" : "s") require immediate attention")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(CyntientOpsDesign.DashboardColors.critical.opacity(0.15))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Placeholder Views (to be implemented)

struct WorkerTasksGrid: View {
    let tasks: [WorkerDashboardViewModel.TaskItem]
    let onTaskTap: (WorkerDashboardViewModel.TaskItem) -> Void
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(tasks) { task in
                Button(action: { onTaskTap(task) }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: task.requiresPhoto ? "camera.fill" : "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(task.isCompleted ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.info)
                            
                            Spacer()
                            
                            if task.urgency == .urgent || task.urgency == .critical {
                                Circle()
                                    .fill(CyntientOpsDesign.DashboardColors.critical)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        Text(task.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        if let dueDate = task.dueDate {
                            Text(dueDate, style: .time)
                                .font(.caption)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .francoDarkCardBackground(cornerRadius: 10)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct WorkerUrgentItemsSection: View {
    let urgentTasks: [WorkerDashboardViewModel.TaskItem]
    let overdueCount: Int
    let clockInRequired: Bool
    let onUrgentTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
                
                Text("Urgent Items")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                if clockInRequired {
                    WorkerUrgentItem(
                        icon: "clock.fill",
                        title: "Clock In Required",
                        subtitle: "You should be clocked in during working hours",
                        color: CyntientOpsDesign.DashboardColors.warning
                    )
                }
                
                if !urgentTasks.isEmpty {
                    WorkerUrgentItem(
                        icon: "exclamationmark.shield.fill",
                        title: "Urgent Tasks",
                        subtitle: "\(urgentTasks.count) urgent task\(urgentTasks.count == 1 ? "" : "s") require immediate attention",
                        color: CyntientOpsDesign.DashboardColors.critical
                    )
                }
                
                if overdueCount > 0 {
                    WorkerUrgentItem(
                        icon: "clock.badge.exclamationmark.fill",
                        title: "Overdue Tasks",
                        subtitle: "\(overdueCount) task\(overdueCount == 1 ? " is" : "s are") past due",
                        color: CyntientOpsDesign.DashboardColors.critical
                    )
                }
            }
        }
        .padding(16)
        .francoDarkCardBackground(cornerRadius: 12)
    }
}

struct WorkerUrgentItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct WorkerNovaIntelligencePanel: View {
    @Binding var selectedTab: WorkerDashboardView.NovaTab
    let todaysTasks: [WorkerDashboardViewModel.TaskItem]
    let weeklySchedule: [WorkerDashboardViewModel.DaySchedule]
    let assignedBuildings: [WorkerDashboardViewModel.BuildingSummary]
    let completionRate: Double
    let onTabTap: (WorkerDashboardView.NovaTab) -> Void
    let onScheduleExpand: () -> Void
    let onMapToggle: () -> Void
    @ObservedObject var viewModel: WorkerDashboardViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Intelligence Content Panel with Dynamic Height
            intelligenceContentPanel
                .frame(height: getIntelligencePanelHeight())
                .animation(CyntientOpsDesign.Animations.spring, value: selectedTab)
            
            // Tab Bar with Proper Spacing
            HStack(spacing: 0) {
                ForEach(WorkerDashboardView.NovaTab.allCases, id: \.self) { tab in
                    WorkerNovaTabButton(
                        tab: tab,
                        isSelected: selectedTab == tab,
                        badgeCount: getBadgeCount(for: tab),
                        action: {
                            withAnimation(CyntientOpsDesign.Animations.spring) {
                                selectedTab = tab
                                onTabTap(tab)
                            }
                        }
                    )
                }
            }
            .frame(height: 65)
            .francoDarkCardBackground(cornerRadius: 0)
        }
        .francoGlassBackground()
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Dynamic Panel Height
    
    private func getIntelligencePanelHeight() -> CGFloat {
        switch selectedTab {
        case .routines:
            return min(CGFloat(todaysTasks.count * 60 + 120), 260)
        case .analytics:
            return 240
        case .portfolio:
            return assignedBuildings.count > 3 ? 200 : 160
        case .schedule:
            return 140
        }
    }
    
    @ViewBuilder
    private var intelligenceContentPanel: some View {
        ScrollView {
            VStack(spacing: 16) {
                switch selectedTab {
                case .portfolio:
                    WorkerPortfolioContent(
                        assignedBuildings: assignedBuildings,
                        onMapToggle: onMapToggle
                    )
                    
                case .analytics:
                    WorkerAnalyticsContent(
                        completionRate: completionRate,
                        todaysTasks: todaysTasks,
                        weeklySchedule: weeklySchedule
                    )
                    
                case .schedule:
                    WorkerScheduleContent(
                        todaysTasks: todaysTasks,
                        weeklySchedule: weeklySchedule,
                        onExpandSchedule: onScheduleExpand
                    )
                    
                case .routines:
                    WorkerRoutinesContent(
                        todaysTasks: todaysTasks,
                        completionRate: completionRate,
                        onExpandSchedule: onScheduleExpand
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.5))
    }
    
    private func getBadgeCount(for tab: WorkerDashboardView.NovaTab) -> Int {
        switch tab {
        case .portfolio:
            return assignedBuildings.count // Show total buildings for today
        case .analytics:
            return 0 // No badge for analytics
        case .schedule:
            return getScheduleItemsCount() // Count of scheduled items
        case .routines:
            return 0 // No badge for quick actions
        }
    }
    
    private func getScheduleItemsCount() -> Int {
        return weeklySchedule.flatMap { $0.items }.count
    }
    
    private func getSupplyWarnings() -> Int {
        // Placeholder - would check inventory for supplies needed for today's tasks
        return 0
    }
    
    private func getLiveUpdatesCount() -> Int {
        // Count active alerts: schedule changes, emergency alerts, weather warnings
        let count = 0
        
        // Weather urgency (would need to access through viewModel)
        // if let weather = viewModel.weatherData,
        //    (weather.condition == .rain || weather.condition == .snow) {
        //     count += 1
        // }
        
        // Task reassignments (placeholder)
        // count += taskReassignments.count
        
        // Emergency alerts (placeholder)  
        // count += emergencyAlerts.count
        
        return count
    }
}

// MARK: - Worker Nova Tab Button

struct WorkerNovaTabButton: View {
    let tab: WorkerDashboardView.NovaTab
    let isSelected: Bool
    let badgeCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? CyntientOpsDesign.DashboardColors.workerPrimary : CyntientOpsDesign.DashboardColors.tertiaryText)
                    
                    if badgeCount > 0 {
                        Text("\(badgeCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(CyntientOpsDesign.DashboardColors.critical)
                            .clipShape(Capsule())
                            .offset(x: 12, y: -8)
                    }
                }
                
                Text(tab.rawValue)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? CyntientOpsDesign.DashboardColors.workerPrimary : CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Weather Guidance Strip

struct WeatherGuidanceStrip: View {
    let weather: CoreTypes.WeatherData
    let nextTask: WorkerDashboardViewModel.TaskItem?
    let workflowState: WorkerDashboardView.WorkflowState
    
    var body: some View {
        HStack(spacing: 8) {
            // Weather Icon & Temp
            HStack(spacing: 4) {
                Image(systemName: getWeatherIcon())
                    .font(.caption)
                    .foregroundColor(getWeatherColor())
                
                Text("\(Int(weather.temperature))°F")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            }
            
            Text("|")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            
            // Specific Actionable Guidance
            Text(getActionableGuidance())
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                .lineLimit(1)
            
            Spacer()
            
            // Urgency Indicator
            if isUrgent() {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(getBackgroundColor())
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    private func getWeatherIcon() -> String {
        switch weather.condition {
        case .clear: return "sun.max"
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .overcast: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "snowflake"
        case .snowy: return "cloud.snow.fill"
        case .storm: return "cloud.bolt.fill"
        case .fog: return "cloud.fog"
        case .foggy: return "cloud.fog.fill"
        case .windy: return "wind"
        case .hot: return "thermometer.sun"
        case .cold: return "thermometer.snowflake"
        }
    }
    
    private func getWeatherColor() -> Color {
        switch weather.condition {
        case .clear: return .yellow
        case .sunny: return .orange
        case .cloudy: return .gray
        case .overcast: return .gray
        case .rain: return .blue
        case .snow: return .white
        case .snowy: return .cyan
        case .storm: return .purple
        case .fog: return .gray
        case .foggy: return .gray
        case .windy: return .green
        case .hot: return .red
        case .cold: return .blue
        }
    }
    
    private func getActionableGuidance() -> String {
        let temp = weather.temperature
        let isRaining = weather.condition == .rain
        let isSnowing = weather.condition == .snow
        
        if isRaining {
            if let nextTask = nextTask, nextTask.title.lowercased().contains("roof") || nextTask.title.lowercased().contains("drain") {
                return "Rain starting ~2PM | PRIORITY: Complete roof drains before 1:30 PM"
            } else {
                return "Rain expected | Move indoor tasks to afternoon"
            }
        } else if isSnowing {
            return "Snow conditions | Prioritize heating checks, use caution on stairs"
        } else if temp < 40 {
            return "Cold weather | Check heating systems, indoor tasks first"
        } else if temp > 85 {
            return "Hot weather | Schedule outdoor tasks early, stay hydrated"
        } else {
            return "Good conditions | All task types suitable"
        }
    }
    
    private func isUrgent() -> Bool {
        let temp = weather.temperature
        return weather.condition == .rain || 
               weather.condition == .snow || 
               temp < 32 || 
               temp > 90
    }
    
    private func getBackgroundColor() -> Color {
        if isUrgent() {
            return CyntientOpsDesign.DashboardColors.critical.opacity(0.1)
        } else {
            return CyntientOpsDesign.DashboardColors.info.opacity(0.05)
        }
    }
}

// MARK: - Next Action Hero Supporting Components

struct CurrentLocationTimeBlock: View {
    let timeBlock: WorkerDashboardView.TimeBlock
    let isClockedIn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Location Icon
            Circle()
                .fill(CyntientOpsDesign.DashboardColors.success)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                    
                    Text(timeBlock.building)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text("| \(formatTimeRange(timeBlock.startTime, timeBlock.endTime))")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                if timeBlock.remainingTime > 0 {
                    Text("\(formatDuration(timeBlock.remainingTime)) remaining at this location")
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CyntientOpsDesign.DashboardColors.success.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formatTimeRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}

struct ImmediateTaskCard: View {
    let task: WorkerDashboardViewModel.TaskItem
    let workflowState: WorkerDashboardView.WorkflowState
    let onStartTask: (String) -> Void
    let onViewDetails: (String) -> Void
    let onSkipTask: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Task Header
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text(task.description ?? "No description")
                        .font(.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            // Task Requirements & Estimate
            HStack(spacing: 16) {
                if task.requiresPhoto {
                    Label("Photo Required", systemImage: "camera.fill")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
                }
                
                Label("Est: \(getTaskEstimate()) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                
                Spacer()
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("START TASK") {
                    onStartTask(task.id)
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(CyntientOpsDesign.DashboardColors.workerPrimary)
                .cornerRadius(8)
                
                Button("DETAILS") {
                    onViewDetails(task.id)
                }
                .font(.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(CyntientOpsDesign.DashboardColors.cardBackground)
                .cornerRadius(8)
                
                Button("SKIP") {
                    onSkipTask(task.id)
                }
                .font(.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                .frame(width: 60)
                .padding(.vertical, 12)
                .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.5))
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    private func getTaskEstimate() -> Int {
        // Context-aware time estimates based on task type
        if task.title.lowercased().contains("drain") { return 25 }
        if task.title.lowercased().contains("trash") { return 10 }
        if task.title.lowercased().contains("glass") { return 45 }
        return 20 // Default
    }
}

struct UpcomingTasksPreview: View {
    let tasks: [WorkerDashboardViewModel.TaskItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Tasks")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            ForEach(tasks.prefix(2)) { task in
                HStack(spacing: 8) {
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.tertiaryText)
                        .frame(width: 4, height: 4)
                    
                    Text(task.title)
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Text("→ \(getEstimate(task)) min")
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 12)
    }
    
    private func getEstimate(_ task: WorkerDashboardViewModel.TaskItem) -> Int {
        if task.title.lowercased().contains("drain") { return 25 }
        if task.title.lowercased().contains("trash") { return 10 }
        if task.title.lowercased().contains("glass") { return 45 }
        return 20
    }
}

struct NoTasksCard: View {
    let workflowState: WorkerDashboardView.WorkflowState
    let onClockIn: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: getIcon())
                .font(.largeTitle)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            Text(getMessage())
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                .multilineTextAlignment(.center)
            
            if workflowState == .needsClockIn {
                Button("CLOCK IN") {
                    onClockIn()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(CyntientOpsDesign.DashboardColors.workerPrimary)
                .cornerRadius(8)
            }
        }
        .padding(24)
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.3))
        .cornerRadius(12)
    }
    
    private func getIcon() -> String {
        switch workflowState {
        case .needsClockIn: return "clock"
        case .atBuilding: return "checkmark.circle.fill"
        case .betweenBuildings: return "arrow.right.circle"
        case .endOfDay: return "moon.stars.fill"
        }
    }
    
    private func getMessage() -> String {
        switch workflowState {
        case .needsClockIn: return "Ready to start your day"
        case .atBuilding: return "All tasks completed at this building"
        case .betweenBuildings: return "Travel to next location"
        case .endOfDay: return "Excellent work today!"
        }
    }
}

struct WorkflowStatusIndicator: View {
    let state: WorkerDashboardView.WorkflowState
    let isClockedIn: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(statusColor)
                .frame(width: 24, height: 24)
            
            Image(systemName: statusIcon)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
    
    private var statusColor: Color {
        switch state {
        case .needsClockIn: return CyntientOpsDesign.DashboardColors.warning
        case .atBuilding: return CyntientOpsDesign.DashboardColors.success
        case .betweenBuildings: return CyntientOpsDesign.DashboardColors.info
        case .endOfDay: return CyntientOpsDesign.DashboardColors.success
        }
    }
    
    private var statusIcon: String {
        switch state {
        case .needsClockIn: return "clock"
        case .atBuilding: return "building.2.fill"
        case .betweenBuildings: return "arrow.right"
        case .endOfDay: return "checkmark"
        }
    }
}

struct CollapseButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Time-Based Progressive Disclosure

struct TimeBasedContentSection: View {
    let todaysTasks: [WorkerDashboardViewModel.TaskItem]
    let workflowState: WorkerDashboardView.WorkflowState
    let isHeroExpanded: Bool
    let onTaskTap: (String) -> Void
    let onTaskAction: (WorkerTaskAction) -> Void
    
    var body: some View {
        if isHeroExpanded {
            VStack(spacing: 16) {
                switch workflowState {
                case .needsClockIn:
                    // Morning: Show full day overview
                    DayOverviewSection(tasks: todaysTasks, onTaskTap: onTaskTap)
                    
                case .atBuilding:
                    // At building: Show building-specific tasks
                    BuildingTasksSection(tasks: getCurrentBuildingTasks(), onTaskAction: onTaskAction)
                    
                case .betweenBuildings:
                    // Between buildings: Show next building tasks
                    NextBuildingPreview(tasks: getNextBuildingTasks(), onTaskTap: onTaskTap)
                    
                case .endOfDay:
                    // End of day: Show completion summary + tomorrow preview
                    EndOfDaySection(tasks: todaysTasks)
                }
            }
        }
    }
    
    private func getCurrentBuildingTasks() -> [WorkerDashboardViewModel.TaskItem] {
        // Filter tasks for current building
        return todaysTasks.filter { !$0.isCompleted }
    }
    
    private func getNextBuildingTasks() -> [WorkerDashboardViewModel.TaskItem] {
        // Get tasks for next building in route
        return Array(todaysTasks.filter { !$0.isCompleted }.prefix(3))
    }
}

struct DayOverviewSection: View {
    let tasks: [WorkerDashboardViewModel.TaskItem]
    let onTaskTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Plan")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
                
                Text("\(tasks.filter { !$0.isCompleted }.count) tasks")
                    .font(.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            // Show overview grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(tasks.filter { !$0.isCompleted }.prefix(6)) { task in
                    TaskOverviewCard(task: task, onTap: { onTaskTap(task.id) })
                }
            }
        }
        .francoDarkCardBackground()
    }
}

struct BuildingTasksSection: View {
    let tasks: [WorkerDashboardViewModel.TaskItem]
    let onTaskAction: (WorkerTaskAction) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tasks at This Building")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            ForEach(tasks.prefix(4)) { task in
                QuickTaskActionRow(task: task, onAction: onTaskAction)
            }
        }
        .francoDarkCardBackground()
    }
}

struct NextBuildingPreview: View {
    let tasks: [WorkerDashboardViewModel.TaskItem]
    let onTaskTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                
                Text("Next Building Tasks")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
            }
            
            ForEach(tasks) { task in
                Button(action: { onTaskTap(task.id) }) {
                    HStack {
                        Text(task.title)
                            .font(.subheadline)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.2))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .francoDarkCardBackground()
    }
}

struct EndOfDaySection: View {
    let tasks: [WorkerDashboardViewModel.TaskItem]
    
    var body: some View {
        VStack(spacing: 16) {
            // Completion summary
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                
                Text("Great Work Today!")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                let completed = tasks.filter { $0.isCompleted }.count
                let total = tasks.count
                Text("\(completed)/\(total) tasks completed")
                    .font(.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            // Tomorrow preview (placeholder)
            VStack(alignment: .leading, spacing: 8) {
                Text("Tomorrow Preview")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text("• Early start at Rubin Museum (8 AM)")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                
                Text("• Focus on glass cleaning tasks")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
        }
        .francoDarkCardBackground()
    }
}

struct TaskOverviewCard: View {
    let task: WorkerDashboardViewModel.TaskItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    if task.requiresPhoto {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
                    }
                    
                    Spacer()
                    
                    Text(getPriorityText())
                        .font(.caption2)
                        .foregroundColor(getPriorityColor())
                }
            }
            .padding(8)
            .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.3))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getPriorityText() -> String {
        switch task.urgency {
        case .emergency: return "EMERGENCY"
        case .critical: return "URGENT"
        case .urgent: return "High"
        case .high: return "High"
        case .normal: return "Normal"
        case .low: return "Low"
        }
    }
    
    private func getPriorityColor() -> Color {
        switch task.urgency {
        case .emergency: return CyntientOpsDesign.DashboardColors.critical
        case .critical: return CyntientOpsDesign.DashboardColors.critical
        case .urgent: return CyntientOpsDesign.DashboardColors.warning
        case .high: return CyntientOpsDesign.DashboardColors.warning
        case .normal: return CyntientOpsDesign.DashboardColors.secondaryText
        case .low: return CyntientOpsDesign.DashboardColors.tertiaryText
        }
    }
}

struct QuickTaskActionRow: View {
    let task: WorkerDashboardViewModel.TaskItem
    let onAction: (WorkerTaskAction) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                if task.requiresPhoto {
                    Label("Photo required", systemImage: "camera.fill")
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
                }
            }
            
            Spacer()
            
            // Quick action buttons
            HStack(spacing: 8) {
                Button("Start") {
                    onAction(.startTask(task.id))
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(CyntientOpsDesign.DashboardColors.workerPrimary)
                .foregroundColor(.white)
                .cornerRadius(6)
                
                Button("✓") {
                    onAction(.completeTask(task.id))
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(CyntientOpsDesign.DashboardColors.success)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.2))
        .cornerRadius(6)
    }
}

// MARK: - Worker Intelligence Content Components (Redesigned)

struct WorkerRouteMapContent: View {
    let currentBuilding: WorkerDashboardViewModel.BuildingSummary?
    let assignedBuildings: [WorkerDashboardViewModel.BuildingSummary]
    let todaysTasks: [WorkerDashboardViewModel.TaskItem]
    let onBuildingTap: (String) -> Void
    let isMapRevealed: Bool
    let onRevealMap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Route Map Header with Map Toggle
            HStack {
                Text("Today's Route")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
                
                Button(isMapRevealed ? "Hide Map" : "Show Map") {
                    onRevealMap()
                }
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.1))
                .cornerRadius(6)
            }
            
            if isMapRevealed {
                // Map is shown - provide map controls and current building focus
                MapControlsPanel(
                    currentBuilding: currentBuilding,
                    totalBuildings: assignedBuildings.count,
                    onFocusCurrentBuilding: {
                        if let current = currentBuilding {
                            onBuildingTap(current.id)
                        }
                    }
                )
            } else {
                // Map hidden - show route list
                ForEach(getRouteBuildings(), id: \.id) { building in
                    RouteMapBuildingRow(
                        building: building,
                        isCurrent: building.id == currentBuilding?.id,
                        taskCount: getTaskCount(for: building),
                        estimatedTime: getEstimatedTime(for: building),
                        onTap: { onBuildingTap(building.id) }
                    )
                }
                
                // Route summary
                RouteOptimizationSummary(
                    totalBuildings: assignedBuildings.count,
                    totalTasks: todaysTasks.filter { !$0.isCompleted }.count,
                    estimatedDuration: getTotalEstimatedTime()
                )
            }
        }
    }
    
    private func getRouteBuildings() -> [WorkerDashboardViewModel.BuildingSummary] {
        // Optimize route based on task priority and location
        return assignedBuildings.sorted { building1, building2 in
            let tasks1 = todaysTasks.filter { $0.buildingId == building1.id && !$0.isCompleted }
            let tasks2 = todaysTasks.filter { $0.buildingId == building2.id && !$0.isCompleted }
            
            // Prioritize buildings with urgent tasks
            let urgentTasks1 = tasks1.filter { $0.urgency == .urgent || $0.urgency == .critical }
            let urgentTasks2 = tasks2.filter { $0.urgency == .urgent || $0.urgency == .critical }
            
            if urgentTasks1.count != urgentTasks2.count {
                return urgentTasks1.count > urgentTasks2.count
            }
            
            return tasks1.count > tasks2.count
        }
    }
    
    private func getTaskCount(for building: WorkerDashboardViewModel.BuildingSummary) -> Int {
        return todaysTasks.filter { $0.buildingId == building.id && !$0.isCompleted }.count
    }
    
    private func getEstimatedTime(for building: WorkerDashboardViewModel.BuildingSummary) -> Int {
        let tasks = todaysTasks.filter { $0.buildingId == building.id && !$0.isCompleted }
        return tasks.reduce(0) { total, task in
            total + getTaskEstimate(task)
        }
    }
    
    private func getTaskEstimate(_ task: WorkerDashboardViewModel.TaskItem) -> Int {
        if task.title.lowercased().contains("drain") { return 25 }
        if task.title.lowercased().contains("trash") { return 10 }
        if task.title.lowercased().contains("glass") { return 45 }
        return 20
    }
    
    private func getTotalEstimatedTime() -> Int {
        let allTasks = todaysTasks.filter { !$0.isCompleted }
        return allTasks.reduce(0) { total, task in
            total + getTaskEstimate(task)
        }
    }
}

struct RouteOptimizationSummary: View {
    let totalBuildings: Int
    let totalTasks: Int
    let estimatedDuration: Int
    
    var body: some View {
        VStack(spacing: 6) {
            Text("Route Summary")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            HStack(spacing: 16) {
                SummaryItem(icon: "building.2", value: "\(totalBuildings)", label: "Buildings")
                SummaryItem(icon: "list.bullet", value: "\(totalTasks)", label: "Tasks")
                SummaryItem(icon: "clock", value: "\(estimatedDuration/60)h \(estimatedDuration%60)m", label: "Est. Time")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CyntientOpsDesign.DashboardColors.info.opacity(0.05))
        .cornerRadius(6)
    }
}

struct SummaryItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.info)
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
    }
}

struct MapControlsPanel: View {
    let currentBuilding: WorkerDashboardViewModel.BuildingSummary?
    let totalBuildings: Int
    let onFocusCurrentBuilding: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Map Controls")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            // Current building focus
            if let building = currentBuilding {
                Button(action: onFocusCurrentBuilding) {
                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Focus Current Location")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            
                            Text(building.name)
                                .font(.caption)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                    .padding(12)
                    .background(CyntientOpsDesign.DashboardColors.success.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Map legend
            VStack(alignment: .leading, spacing: 6) {
                Text("Map Legend")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                HStack(spacing: 16) {
                    LegendItem(color: CyntientOpsDesign.DashboardColors.success, label: "Current")
                    LegendItem(color: CyntientOpsDesign.DashboardColors.info, label: "Assigned")
                    LegendItem(color: CyntientOpsDesign.DashboardColors.warning, label: "Urgent")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.2))
            .cornerRadius(6)
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
    }
}

struct WorkerLiveUpdatesContent: View {
    let weather: CoreTypes.WeatherData?
    let todaysTasks: [WorkerDashboardViewModel.TaskItem]
    let currentBuilding: WorkerDashboardViewModel.BuildingSummary?
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Live Updates")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            // Weather alerts
            if let weather = weather, isWeatherUrgent(weather) {
                LiveUpdateCard(
                    type: .weather,
                    title: "Weather Alert",
                    message: getWeatherAlertMessage(weather),
                    timestamp: Date(),
                    priority: .high
                )
            }
            
            // Schedule changes (placeholder)
            LiveUpdateCard(
                type: .schedule,
                title: "Schedule Update",
                message: "Elevator maintenance moved to 3 PM at Rubin Museum",
                timestamp: Date().addingTimeInterval(-1800), // 30 min ago
                priority: .medium
            )
            
            // Task reassignments (placeholder)
            if currentBuilding != nil {
                LiveUpdateCard(
                    type: .task,
                    title: "Task Priority Change",
                    message: "Roof drain cleaning now URGENT due to rain forecast",
                    timestamp: Date().addingTimeInterval(-600), // 10 min ago
                    priority: .high
                )
            }
            
            // Emergency alerts (placeholder)
            LiveUpdateCard(
                type: .emergency,
                title: "Building Notice",
                message: "Visitor event at Museum - use service elevator only",
                timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
                priority: .low
            )
        }
    }
    
    private func isWeatherUrgent(_ weather: CoreTypes.WeatherData) -> Bool {
        return weather.condition == .rain || 
               weather.condition == .snow || 
               weather.temperature < 32 || 
               weather.temperature > 90
    }
    
    private func getWeatherAlertMessage(_ weather: CoreTypes.WeatherData) -> String {
        if weather.condition == .rain {
            return "Rain starting soon - prioritize outdoor tasks"
        } else if weather.temperature < 32 {
            return "Freezing temperatures - check heating systems"
        } else if weather.temperature > 90 {
            return "Extreme heat - take frequent breaks, stay hydrated"
        } else {
            return "Weather conditions changed"
        }
    }
}

struct LiveUpdateCard: View {
    let type: LiveUpdateType
    let title: String
    let message: String
    let timestamp: Date
    let priority: LiveUpdatePriority
    
    enum LiveUpdateType {
        case weather, schedule, task, emergency
        
        var icon: String {
            switch self {
            case .weather: return "cloud.rain.fill"
            case .schedule: return "calendar.badge.clock"
            case .task: return "list.bullet.clipboard"
            case .emergency: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .weather: return .blue
            case .schedule: return CyntientOpsDesign.DashboardColors.info
            case .task: return CyntientOpsDesign.DashboardColors.warning
            case .emergency: return CyntientOpsDesign.DashboardColors.critical
            }
        }
    }
    
    enum LiveUpdatePriority {
        case low, medium, high
        
        var color: Color {
            switch self {
            case .low: return CyntientOpsDesign.DashboardColors.tertiaryText
            case .medium: return CyntientOpsDesign.DashboardColors.secondaryText
            case .high: return CyntientOpsDesign.DashboardColors.critical
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: type.icon)
                .font(.subheadline)
                .foregroundColor(type.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Spacer()
                    
                    Text(formatTimestamp())
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .lineLimit(2)
            }
            
            // Priority indicator
            Circle()
                .fill(priority.color)
                .frame(width: 8, height: 8)
        }
        .padding(12)
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(type.color.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(8)
    }
    
    private func formatTimestamp() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

struct WorkerBuildingIntelContent: View {
    let currentBuilding: WorkerDashboardViewModel.BuildingSummary?
    let assignedBuildings: [WorkerDashboardViewModel.BuildingSummary]
    let onBuildingTap: (String) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            if let building = currentBuilding {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Building Intel")
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    BuildingIntelCard(building: building)
                }
            } else {
                Text("Building Information")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                ForEach(assignedBuildings.prefix(3), id: \.id) { building in
                    Button(action: { onBuildingTap(building.id) }) {
                        BuildingQuickInfoRow(building: building)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct WorkerSupplyCheckContent: View {
    let todaysTasks: [WorkerDashboardViewModel.TaskItem]
    let currentBuilding: WorkerDashboardViewModel.BuildingSummary?
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Supply Check")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            // Supplies needed for today's tasks
            let neededSupplies = getNeededSupplies()
            ForEach(neededSupplies, id: \.self) { supply in
                SupplyCheckRow(supply: supply)
            }
            
            // Quick request button
            Button("Request Supplies") {
                // Handle supply request
            }
            .font(.subheadline)
            .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func getNeededSupplies() -> [String] {
        var supplies: [String] = []
        
        for task in todaysTasks.filter({ !$0.isCompleted }) {
            if task.title.lowercased().contains("trash") {
                supplies.append("Trash bags")
            }
            if task.title.lowercased().contains("glass") || task.title.lowercased().contains("window") {
                supplies.append("Glass cleaner")
                supplies.append("Microfiber cloths")
            }
            if task.title.lowercased().contains("drain") {
                supplies.append("Work gloves")
                supplies.append("Drain snake")
            }
        }
        
        return Array(Set(supplies)) // Remove duplicates
    }
}

struct WorkerNovaAssistContent: View {
    let currentBuilding: WorkerDashboardViewModel.BuildingSummary?
    let nextTask: WorkerDashboardViewModel.TaskItem?
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            // Context-aware quick actions
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                if let building = currentBuilding {
                    WorkerQuickActionButton(
                        title: "Report Issue",
                        subtitle: "at \(building.name)",
                        icon: "exclamationmark.triangle",
                        color: CyntientOpsDesign.DashboardColors.critical
                    ) {
                        // Handle report issue
                    }
                }
                
                WorkerQuickActionButton(
                    title: "Request Backup",
                    subtitle: "Heavy lifting",
                    icon: "person.2.fill",
                    color: CyntientOpsDesign.DashboardColors.info
                ) {
                    // Handle backup request
                }
                
                WorkerQuickActionButton(
                    title: "Task History",
                    subtitle: "Similar tasks",
                    icon: "clock.arrow.circlepath",
                    color: CyntientOpsDesign.DashboardColors.success
                ) {
                    // Show task history
                }
                
                WorkerQuickActionButton(
                    title: "Emergency",
                    subtitle: "Contacts",
                    icon: "phone.fill",
                    color: CyntientOpsDesign.DashboardColors.critical
                ) {
                    // Open emergency contacts
                }
            }
        }
    }
}

// Supporting components for new intelligence tabs

struct RouteMapBuildingRow: View {
    let building: WorkerDashboardViewModel.BuildingSummary
    let isCurrent: Bool
    let taskCount: Int
    let estimatedTime: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(isCurrent ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.tertiaryText)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(building.name)
                        .font(.subheadline)
                        .fontWeight(isCurrent ? .semibold : .medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text("\(taskCount) tasks • \(estimatedTime) min")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                if isCurrent {
                    Text("CURRENT")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CyntientOpsDesign.DashboardColors.success)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isCurrent ? CyntientOpsDesign.DashboardColors.success.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BuildingIntelCard: View {
    let building: WorkerDashboardViewModel.BuildingSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                Text(building.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                Spacer()
            }
            
            // Context-specific intel
            VStack(alignment: .leading, spacing: 4) {
                IntelRow(title: "Access", value: getAccessInfo())
                IntelRow(title: "Special Notes", value: getSpecialNotes())
                IntelRow(title: "Vendors Today", value: getVendorInfo())
            }
        }
        .padding(12)
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.3))
        .cornerRadius(8)
    }
    
    private func getAccessInfo() -> String {
        // Context-aware access information
        if building.name.lowercased().contains("museum") {
            return "Staff entrance, security check required"
        } else {
            return "Main entrance, key code: #1234"
        }
    }
    
    private func getSpecialNotes() -> String {
        if building.name.lowercased().contains("museum") {
            return "Quiet hours: 10 AM - 4 PM"
        } else {
            return "Standard protocols"
        }
    }
    
    private func getVendorInfo() -> String {
        return "Elevator tech scheduled 2 PM"
    }
}

struct SupplyCheckRow: View {
    let supply: String
    
    var body: some View {
        HStack {
            Image(systemName: getSupplyIcon())
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            Text(supply)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Spacer()
            
            Text("✓ In van")
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.success)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private func getSupplyIcon() -> String {
        if supply.lowercased().contains("bag") { return "trash" }
        if supply.lowercased().contains("clean") { return "sparkles" }
        if supply.lowercased().contains("glove") { return "hand.raised" }
        return "shippingbox"
    }
}

struct WorkerQuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.3))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BuildingQuickInfoRow: View {
    let building: WorkerDashboardViewModel.BuildingSummary
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(building.name)
                    .font(.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text("\(building.todayTaskCount) tasks")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.2))
        .cornerRadius(6)
    }
}

struct IntelRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title + ":")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            Text(value)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Spacer()
        }
    }
}

struct WorkerGuidanceContent: View {
    let tasks: [WorkerDashboardViewModel.TaskItem]
    let currentBuilding: WorkerDashboardViewModel.BuildingSummary?
    let weather: CoreTypes.WeatherData?
    let onTaskAction: (WorkerTaskAction) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Guidance")
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text("Prioritized tasks and safety reminders")
                        .font(.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
            }
            .padding(.horizontal, 12)
            
            // Weather-based guidance
            if let weather = weather {
                WeatherGuidanceCard(weather: weather, tasks: tasks)
            }
            
            // Priority tasks
            let priorityTasks = tasks.filter { !$0.isCompleted && ($0.urgency == .urgent || $0.urgency == .critical) }
            if !priorityTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Priority Tasks")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    ForEach(priorityTasks.prefix(3)) { task in
                        PriorityTaskRow(task: task, onAction: onTaskAction)
                    }
                }
            }
            
            // Safety reminders for current building
            if let building = currentBuilding {
                BuildingSafetyCard(building: building)
            }
        }
    }
}

struct WeatherGuidanceCard: View {
    let weather: CoreTypes.WeatherData
    let tasks: [WorkerDashboardViewModel.TaskItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .foregroundColor(.blue)
                Text("\(Int(weather.temperature))°F - \(weather.condition.rawValue.capitalized)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                Spacer()
            }
            
            Text(getWeatherGuidance())
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
        .padding(12)
        .background(CyntientOpsDesign.DashboardColors.info.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func getWeatherGuidance() -> String {
        if weather.temperature < 40 {
            return "Cold weather: Prioritize indoor tasks. Check heating systems."
        } else if weather.temperature > 85 {
            return "Hot weather: Schedule outdoor tasks early. Stay hydrated."
        } else {
            return "Good conditions for all task types."
        }
    }
}

struct PriorityTaskRow: View {
    let task: WorkerDashboardViewModel.TaskItem
    let onAction: (WorkerTaskAction) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
                .font(.caption)
            
            Text(task.title)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Spacer()
            
            Button("Start") {
                onAction(.startTask(task.id))
            }
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(CyntientOpsDesign.DashboardColors.critical)
            .foregroundColor(.white)
            .cornerRadius(6)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(CyntientOpsDesign.DashboardColors.critical.opacity(0.1))
        .cornerRadius(6)
    }
}

struct BuildingSafetyCard: View {
    let building: WorkerDashboardViewModel.BuildingSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                Text("Safety Reminder - \(building.name)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                Spacer()
            }
            
            Text(getSafetyReminder())
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
        .padding(8)
        .background(CyntientOpsDesign.DashboardColors.success.opacity(0.1))
        .cornerRadius(6)
    }
    
    private func getSafetyReminder() -> String {
        // Context-aware safety reminders based on building type
        if building.name.lowercased().contains("museum") {
            return "Museum environment: Handle exhibits with care, report any visitor incidents immediately."
        } else if building.name.lowercased().contains("residential") {
            return "Residential building: Respect tenant privacy, announce presence when entering units."
        } else {
            return "Follow standard safety protocols. Report any hazards immediately."
        }
    }
}

struct WorkerTodaysTasksContent: View {
    let tasks: [WorkerDashboardViewModel.TaskItem]
    let onTaskAction: (WorkerTaskAction) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with Progress Summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Tasks")
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    let completed = tasks.filter { $0.isCompleted }.count
                    Text("\(completed) of \(tasks.count) completed")
                        .font(.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                // Progress Circle
                WorkerTaskProgressCircle(
                    completed: tasks.filter { $0.isCompleted }.count,
                    total: tasks.count
                )
                .frame(width: 50, height: 50)
            }
            .padding(.horizontal, 12)
            
            // Task List
            if tasks.isEmpty {
                WorkerEmptyTasksView()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(tasks.enumerated().prefix(4)), id: \.element.id) { index, task in
                        WorkerTaskRow(
                            task: task,
                            isLast: index == min(tasks.count, 4) - 1,
                            onAction: onTaskAction
                        )
                    }
                    
                    // Show more indicator if there are more than 4 tasks
                    if tasks.count > 4 {
                        Button(action: {
                            // Handle view all tasks
                        }) {
                            HStack {
                                Text("View all \(tasks.count) tasks")
                                    .font(.subheadline)
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

struct WorkerWeeklyScheduleContent: View {
    let currentBuilding: WorkerDashboardViewModel.BuildingSummary?
    let assignedBuildings: [WorkerDashboardViewModel.BuildingSummary]
    let weeklySchedule: [WorkerDashboardViewModel.DaySchedule]
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Weekly Schedule")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
                
                Text("This Week")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            // Current Day Schedule
            if let currentBuilding = currentBuilding {
                WorkerCurrentDaySchedule(building: currentBuilding)
            }
            
            // Week Overview
            VStack(spacing: 8) {
                Text("Week Overview")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(getScheduleDays(), id: \.date) { daySchedule in
                    WorkerScheduleRow(
                        day: formatDayName(daySchedule.date),
                        buildings: getAssignedBuildingsForDay(daySchedule),
                        isToday: isToday(daySchedule)
                    )
                }
            }
            .padding(.top, 8)
        }
    }
    
    private func getScheduleDays() -> [WorkerDashboardViewModel.DaySchedule] {
        return weeklySchedule.prefix(5).map { $0 }  // Workweek only
    }
    
    private func getAssignedBuildingsForDay(_ daySchedule: WorkerDashboardViewModel.DaySchedule) -> [String] {
        // Extract building names from schedule items
        let buildingNames = Set(daySchedule.items.compactMap { item in
            assignedBuildings.first { $0.id == item.buildingId }?.name
        })
        return Array(buildingNames)
    }
    
    private func isToday(_ daySchedule: WorkerDashboardViewModel.DaySchedule) -> Bool {
        return Calendar.current.isDateInToday(daySchedule.date)
    }
    
    private func formatDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}

struct WorkerBuildingInfoContent: View {
    let currentBuilding: WorkerDashboardViewModel.BuildingSummary?
    let assignedBuildings: [WorkerDashboardViewModel.BuildingSummary]
    let allBuildings: [WorkerDashboardViewModel.BuildingSummary] // For coverage purposes
    let onBuildingTap: (String) -> Void // Database navigation callback
    
    var body: some View {
        VStack(spacing: 12) {
            // Current Building Status
            if let currentBuilding = currentBuilding {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Location")
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    WorkerCurrentBuildingCard(
                        building: currentBuilding,
                        onTap: { onBuildingTap(currentBuilding.id) }
                    )
                }
            }
            
            // Assigned Buildings
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("My Buildings")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Spacer()
                    
                    Text("\(assignedBuildings.count) assigned")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(assignedBuildings, id: \.id) { building in
                            WorkerBuildingChip(
                                building: building,
                                isCurrentLocation: building.id == currentBuilding?.id,
                                onTap: { onBuildingTap(building.id) }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // All Buildings (for coverage purposes)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("All Properties")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Spacer()
                    
                    Text("\(allBuildings.count) total")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    
                    Text("Coverage Support")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(allBuildings, id: \.id) { building in
                            let isAssigned = assignedBuildings.contains { $0.id == building.id }
                            WorkerCoverageBuildingChip(
                                building: building,
                                isAssigned: isAssigned,
                                isCurrentLocation: building.id == currentBuilding?.id,
                                onTap: { onBuildingTap(building.id) }
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Quick Actions
            VStack(spacing: 8) {
                Text("Quick Actions")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 12) {
                    WorkerQuickActionButton(
                        title: "View Routes",
                        subtitle: "Navigate",
                        icon: "map.fill",
                        color: CyntientOpsDesign.DashboardColors.info
                    ) { }
                    
                    WorkerQuickActionButton(
                        title: "Clock In/Out",
                        subtitle: "Time tracking",
                        icon: "clock.fill",
                        color: CyntientOpsDesign.DashboardColors.workerPrimary
                    ) { }
                    
                    WorkerQuickActionButton(
                        title: "Report Issue",
                        subtitle: "Emergency",
                        icon: "exclamationmark.triangle.fill",
                        color: CyntientOpsDesign.DashboardColors.critical
                    ) { }
                }
            }
        }
    }
}

struct WorkerNovaChat: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                
                Text("Nova Assistant")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
            }
            
            Text("Ask Nova about your tasks, schedule, building information, or get help with any work-related questions.")
                .font(.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                .multilineTextAlignment(.leading)
            
            Button("Start Chat") {
                // Handle chat start
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(CyntientOpsDesign.DashboardColors.workerPrimary)
            .cornerRadius(16)
        }
        .padding()
        .francoDarkCardBackground(cornerRadius: 8)
    }
}

// MARK: - Supporting Components

struct WorkerTaskProgressCircle: View {
    let completed: Int
    let total: Int
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(CyntientOpsDesign.DashboardColors.tertiaryText.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    progress >= 0.8 ? CyntientOpsDesign.DashboardColors.success :
                    progress >= 0.5 ? CyntientOpsDesign.DashboardColors.warning :
                    CyntientOpsDesign.DashboardColors.critical,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        }
    }
}

struct WorkerEmptyTasksView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(CyntientOpsDesign.DashboardColors.success)
            
            Text("All Caught Up!")
                .font(.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text("No tasks scheduled for today")
                .font(.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
        .padding(.vertical, 20)
    }
}

struct WorkerTaskRow: View {
    let task: WorkerDashboardViewModel.TaskItem
    let isLast: Bool
    let onAction: (WorkerTaskAction) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Task Status Icon
            Button(action: {
                onAction(task.isCompleted ? .viewDetails(task.id) : .completeTask(task.id))
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.isCompleted ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Task Info
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .strikethrough(task.isCompleted)
                
                HStack(spacing: 8) {
                    if let dueDate = task.dueDate {
                        Text(dueDate, style: .time)
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                    
                    if task.requiresPhoto {
                        HStack(spacing: 2) {
                            Image(systemName: "camera.fill")
                                .font(.caption2)
                            Text("Photo Required")
                                .font(.caption2)
                        }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                    }
                    
                    if task.urgency == .urgent || task.urgency == .critical {
                        HStack(spacing: 2) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text("Urgent")
                                .font(.caption2)
                        }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
                    }
                }
            }
            
            Spacer()
            
            // Action Button
            if !task.isCompleted {
                Button(action: {
                    onAction(.startTask(task.id))
                }) {
                    Text("Start")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(CyntientOpsDesign.DashboardColors.workerPrimary)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(task.isCompleted ? Color.clear : CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.5))
        .cornerRadius(8)
        
        if !isLast {
            Divider()
                .opacity(0.3)
        }
    }
}

struct WorkerCurrentDaySchedule: View {
    let building: WorkerDashboardViewModel.BuildingSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text("7:00 AM - 3:00 PM")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                Circle()
                    .fill(CyntientOpsDesign.DashboardColors.success)
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(CyntientOpsDesign.DashboardColors.success.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct WorkerScheduleRow: View {
    let day: String
    let buildings: [String]
    let isToday: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Day
            Text(day.prefix(3))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isToday ? CyntientOpsDesign.DashboardColors.workerPrimary : CyntientOpsDesign.DashboardColors.secondaryText)
                .frame(width: 30, alignment: .leading)
            
            // Buildings
            VStack(alignment: .leading, spacing: 2) {
                ForEach(buildings.prefix(2), id: \.self) { building in
                    Text(building)
                        .font(.caption)
                        .foregroundColor(isToday ? CyntientOpsDesign.DashboardColors.primaryText : CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                if buildings.count > 2 {
                    Text("+\(buildings.count - 2) more")
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
            }
            
            Spacer()
            
            // Status indicator
            Circle()
                .fill(isToday ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.tertiaryText)
                .frame(width: 6, height: 6)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isToday ? CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
}

struct WorkerCurrentBuildingCard: View {
    let building: WorkerDashboardViewModel.BuildingSummary
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.success)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(building.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text(building.address)
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .lineLimit(1)
                
                Text("Currently clocked in")
                    .font(.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.success)
            }
            
            Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CyntientOpsDesign.DashboardColors.success.opacity(0.1))
        .cornerRadius(8)
    }
}

struct WorkerBuildingChip: View {
    let building: WorkerDashboardViewModel.BuildingSummary
    let isCurrentLocation: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                Text(building.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .lineLimit(1)
                
                Spacer()
                
                if isCurrentLocation {
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.success)
                        .frame(width: 6, height: 6)
                }
            }
            
            Text(building.address)
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                .lineLimit(2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 120, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            isCurrentLocation ? 
            CyntientOpsDesign.DashboardColors.success.opacity(0.1) :
            CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.3)
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isCurrentLocation ? 
                    CyntientOpsDesign.DashboardColors.success.opacity(0.3) : 
                    Color.clear, 
                    lineWidth: 1
                )
        )
    }
}


struct WorkerCoverageBuildingChip: View {
    let building: WorkerDashboardViewModel.BuildingSummary
    let isAssigned: Bool
    let isCurrentLocation: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(building.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .lineLimit(1)
                
                Spacer()
                
                if isCurrentLocation {
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.success)
                        .frame(width: 6, height: 6)
                } else if isAssigned {
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.workerPrimary)
                        .frame(width: 6, height: 6)
                }
            }
            
            Text(building.address)
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                .lineLimit(2)
            
            // Coverage indicator
            HStack(spacing: 4) {
                if isAssigned {
                    Text("Assigned")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                } else {
                    Text("Coverage")
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 120, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            isCurrentLocation ? 
            CyntientOpsDesign.DashboardColors.success.opacity(0.1) :
            isAssigned ?
            CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.1) :
            CyntientOpsDesign.DashboardColors.info.opacity(0.05)
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    isCurrentLocation ? 
                    CyntientOpsDesign.DashboardColors.success.opacity(0.3) :
                    isAssigned ?
                    CyntientOpsDesign.DashboardColors.workerPrimary.opacity(0.3) :
                    CyntientOpsDesign.DashboardColors.info.opacity(0.2), 
                    lineWidth: 1
                )
        )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Worker Schedule View

struct WorkerScheduleView: View {
    let weeklySchedule: [WorkerDashboardViewModel.DaySchedule]
    let assignedBuildings: [WorkerDashboardViewModel.BuildingSummary]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(weeklySchedule.prefix(5), id: \.date) { daySchedule in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(formatDayName(daySchedule.date))
                                .font(.headline)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            
                            Spacer()
                            
                            if Calendar.current.isDateInToday(daySchedule.date) {
                                Text("Today")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(CyntientOpsDesign.DashboardColors.workerAccent)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        
                        // Schedule items for this day
                        if !daySchedule.items.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(daySchedule.items, id: \.id) { item in
                                    HStack {
                                        Circle()
                                            .fill(CyntientOpsDesign.DashboardColors.workerAccent)
                                            .frame(width: 8, height: 8)
                                        
                                        Text(item.title)
                                            .font(.subheadline)
                                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                                        
                                        Spacer()
                                        
                                        Text("\(formatTime(item.startTime)) - \(formatTime(item.endTime))")
                                            .font(.caption)
                                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                                    }
                                }
                            }
                        } else {
                            Text("No scheduled work")
                                .font(.subheadline)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                                .italic()
                        }
                    }
                    .padding(16)
                    .francoDarkCardBackground()
                }
            }
            .padding(16)
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
    }
    
    private func formatDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Worker Routes View

struct WorkerRoutesView: View {
    let assignedBuildings: [WorkerDashboardViewModel.BuildingSummary]
    let currentBuilding: WorkerDashboardViewModel.BuildingSummary?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let currentBuilding = currentBuilding {
                    // Current Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Location")
                            .font(.headline)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        
                        BuildingRouteCard(
                            building: currentBuilding,
                            isCurrent: true
                        )
                    }
                    .padding(.bottom, 8)
                }
                
                // Assigned Buildings
                Text("My Assigned Buildings")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(assignedBuildings, id: \.id) { building in
                    BuildingRouteCard(
                        building: building,
                        isCurrent: building.id == currentBuilding?.id
                    )
                }
            }
            .padding(16)
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
    }
}

struct BuildingRouteCard: View {
    let building: WorkerDashboardViewModel.BuildingSummary
    let isCurrent: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(building.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
                
                if isCurrent {
                    Text("Current")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CyntientOpsDesign.DashboardColors.success)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            
            Text(building.address)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            HStack {
                Text("\(building.todayTaskCount) tasks today")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                
                Spacer()
                
                Button("View Details") {
                    // TODO: Navigate to building detail
                }
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.workerAccent)
            }
        }
        .padding(12)
        .francoDarkCardBackground()
    }
}

// MARK: - New Worker Dashboard Components (Mirroring Client Design)

struct WorkerHeaderWithNova: View {
    let workerName: String
    let workerInitials: String
    let isClockedIn: Bool
    let currentBuilding: String?
    let onNovaInteraction: () -> Void
    let onProfileTap: () -> Void
    let onClockAction: () -> Void
    
    var body: some View {
        HStack {
            // CyntientOps branding (left)
            Text("CyntientOps")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            // Nova Avatar (center-right)
            Button(action: onNovaInteraction) {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 18))
                            .foregroundColor(.purple)
                    )
            }
            
            // Worker Profile Pill (right)
            Button(action: onProfileTap) {
                HStack(spacing: 8) {
                    // Worker initials circle
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.workerAccent)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(workerInitials)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    
                    // Clock status
                    VStack(alignment: .leading, spacing: 2) {
                        Text(getFirstName(from: workerName))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text(isClockedIn ? "On Duty" : "Off Duty")
                            .font(.caption2)
                            .foregroundColor(isClockedIn ? .green : .orange)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.3))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
    }
    
    private func getFirstName(from fullName: String) -> String {
        return fullName.components(separatedBy: " ").first ?? "Worker"
    }
}

struct WeatherBasedTaskSuggestions: View {
    let weather: CoreTypes.WeatherData
    let todaysTasks: [WorkerDashboardViewModel.TaskItem]
    let onTaskSelect: (String) -> Void
    
    var body: some View {
        if let suggestedTask = getWeatherBasedSuggestion() {
            HStack(spacing: 12) {
                // Weather icon
                Image(systemName: getWeatherIcon())
                    .font(.system(size: 16))
                    .foregroundColor(getWeatherColor())
                
                // Suggestion text
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weather Suggestion")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(suggestedTask.title)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Action button
                Button("Prioritize") {
                    onTaskSelect(suggestedTask.id)
                }
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.2))
        }
    }
    
    private func getWeatherBasedSuggestion() -> WorkerDashboardViewModel.TaskItem? {
        // Prioritize outdoor tasks on good weather, indoor on bad weather
        let isGoodWeather = weather.temperature > 50 && (weather.condition == .clear || weather.condition == .sunny || weather.condition == .cloudy)
        
        if isGoodWeather {
            return todaysTasks.first { task in
                task.title.lowercased().contains("exterior") || 
                task.title.lowercased().contains("roof") ||
                task.title.lowercased().contains("window")
            }
        } else {
            return todaysTasks.first { task in
                task.title.lowercased().contains("interior") ||
                task.title.lowercased().contains("hvac") ||
                task.title.lowercased().contains("plumbing")
            }
        }
    }
    
    private func getWeatherIcon() -> String {
        if weather.condition == .rain {
            return "cloud.rain.fill"
        } else if weather.condition == .snow {
            return "cloud.snow.fill"
        } else if weather.temperature > 70 {
            return "sun.max.fill"
        } else {
            return "cloud.sun.fill"
        }
    }
    
    private func getWeatherColor() -> Color {
        if weather.condition == .rain {
            return .blue
        } else if weather.temperature > 70 {
            return .orange
        } else {
            return .yellow
        }
    }
}

struct WorkerHeroCard: View {
    let assignedBuildings: [WorkerDashboardViewModel.BuildingSummary]
    let currentBuilding: WorkerDashboardViewModel.BuildingSummary?
    let nextTask: WorkerDashboardViewModel.TaskItem?
    let isClockedIn: Bool
    let completionRate: Double
    let onBuildingTap: (String) -> Void
    let onViewAllBuildings: () -> Void
    let onStartNext: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assigned Buildings")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(assignedBuildings.count) properties • \(Int(completionRate * 100))% complete today")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button("View All") {
                    onViewAllBuildings()
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .clipShape(Capsule())
            }
            
            // Current building highlight
            if let current = currentBuilding {
                HStack(spacing: 12) {
                    // Building icon
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.workerAccent)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "building.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Location")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(current.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button(action: { onBuildingTap(current.id) }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.workerAccent)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
            }
            
            // Immediate next steps
            if let next = nextTask {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Immediate Next Steps")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 12) {
                        // Task urgency indicator
                        Circle()
                            .fill(getUrgencyColor(next.urgency))
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(next.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            if let buildingName = getBuildingName(for: next.buildingId) {
                                Text(buildingName)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        
                        Spacer()
                        
                        if isClockedIn {
                            Button("Start") {
                                onStartNext()
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(CyntientOpsDesign.DashboardColors.workerAccent)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
            }
        }
        .padding()
        .francoDarkCardBackground(cornerRadius: 16)
    }
    
    private func getBuildingName(for buildingId: String?) -> String? {
        guard let buildingId = buildingId else { return nil }
        return assignedBuildings.first { $0.id == buildingId }?.name
    }
    
    private func getUrgencyColor(_ urgency: WorkerDashboardViewModel.TaskItem.TaskUrgency) -> Color {
        switch urgency {
        case .emergency, .critical: return .red
        case .urgent: return .orange
        case .high: return .yellow
        case .normal: return .green
        case .low: return .blue
        }
    }
}


// MARK: - Intelligence Panel Content Components

struct WorkerRoutinesContent: View {
    let todaysTasks: [WorkerDashboardViewModel.TaskItem]
    let completionRate: Double
    let onExpandSchedule: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Day progress summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Progress")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("\(completedTasksCount()) of \(todaysTasks.count) tasks completed")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text("\(Int(completionRate * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.workerAccent)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            
            // Next routines preview
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Upcoming Routines")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Button("Full Schedule") {
                        onExpandSchedule()
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                }
                
                ForEach(getNextRoutines().prefix(3), id: \.id) { task in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(getUrgencyColor(task.urgency))
                            .frame(width: 6, height: 6)
                        
                        Text(task.title)
                            .font(.caption)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let dueDate = task.dueDate {
                            Text(formatTime(dueDate))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func completedTasksCount() -> Int {
        return todaysTasks.filter { $0.isCompleted }.count
    }
    
    private func getNextRoutines() -> [WorkerDashboardViewModel.TaskItem] {
        return todaysTasks.filter { !$0.isCompleted }.sorted { 
            ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
        }
    }
    
    private func getUrgencyColor(_ urgency: WorkerDashboardViewModel.TaskItem.TaskUrgency) -> Color {
        switch urgency {
        case .emergency, .critical: return .red
        case .urgent: return .orange
        case .high: return .yellow
        case .normal: return .green
        case .low: return .blue
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct WorkerPortfolioContent: View {
    let assignedBuildings: [WorkerDashboardViewModel.BuildingSummary]
    let onMapToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Portfolio overview
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Portfolio")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("\(assignedBuildings.count) buildings assigned")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button("Map View") {
                    onMapToggle()
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .clipShape(Capsule())
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            
            // Building list preview
            ForEach(assignedBuildings.prefix(3), id: \.id) { building in
                HStack(spacing: 12) {
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.workerAccent)
                        .frame(width: 8, height: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(building.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text(building.address)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct WorkerAnalyticsContent: View {
    let completionRate: Double
    let todaysTasks: [WorkerDashboardViewModel.TaskItem]
    let weeklySchedule: [WorkerDashboardViewModel.DaySchedule]
    
    var body: some View {
        VStack(spacing: 12) {
            // Daily progress summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Performance Analytics")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Daily completion rate")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text("\(Int(completionRate * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(getPerformanceColor())
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            
            // Weekly summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(Int(completionRate * Double(todaysTasks.count))) tasks completed")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("\(getWeeklyEfficiency())%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func getPerformanceColor() -> Color {
        if completionRate >= 0.9 { return .green }
        else if completionRate >= 0.7 { return .yellow }
        else { return .orange }
    }
    
    private func getWeeklyScheduleItemsCount() -> Int {
        return weeklySchedule.flatMap { (day: WorkerDashboardViewModel.DaySchedule) in day.items }.count
    }
    
    private func getWeeklyEfficiency() -> Int {
        let totalScheduledItems = getWeeklyScheduleItemsCount()
        // Use the completion rate from tasks instead of schedule items
        return Int(completionRate * 100)
    }
}

struct WorkerScheduleContent: View {
    let todaysTasks: [WorkerDashboardViewModel.TaskItem]
    let weeklySchedule: [WorkerDashboardViewModel.DaySchedule]
    let onExpandSchedule: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Schedule overview
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day Route Optimization")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("\(todaysTasks.count) tasks scheduled")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button("Full Schedule") {
                    onExpandSchedule()
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .clipShape(Capsule())
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            
            // Next tasks preview
            ForEach(getNextScheduledTasks().prefix(4), id: \.id) { task in
                HStack(spacing: 8) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 6, height: 6)
                    
                    Text(task.title)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let dueDate = task.dueDate {
                        Text(formatTime(dueDate))
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func getNextScheduledTasks() -> [WorkerDashboardViewModel.TaskItem] {
        return todaysTasks.filter { !$0.isCompleted }.sorted {
            ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// These views are imported from their respective files:
// - WorkerProfileView from Views/Main/WorkerProfileView.swift
// - WorkerPreferencesView from Views/Main/WorkerPreferencesView.swift
// - BuildingDetailView from Views/Components/Buildings/BuildingDetailView.swift
// - UnifiedTaskDetailView from Views/Main/UnifiedTaskDetailView.swift
// - EmergencyContactsSheet from Components/Sheets/EmergencyContactsSheet.swift

// MARK: - Preview

struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        Text("WorkerDashboardView Preview")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .preferredColorScheme(.dark)
    }
}
