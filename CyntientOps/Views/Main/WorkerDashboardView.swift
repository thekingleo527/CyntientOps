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
    @StateObject private var contextEngine: WorkerContextEngine
    
    // MARK: - Responsive Layout
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    private let container: ServiceContainer
    
    init(container: ServiceContainer) {
        self.container = container
        self._viewModel = StateObject(wrappedValue: WorkerDashboardViewModel(container: container))
        self._contextEngine = StateObject(wrappedValue: WorkerContextEngine.shared)
    }
    
    // MARK: - Sheet Navigation
    enum WorkerRoute: Identifiable {
        case profile, buildingDetail(String), taskDetail(String), schedule, routes, emergency, settings
        
        var id: String {
            switch self {
            case .profile: return "profile"
            case .buildingDetail(let id): return "building-\(id)"
            case .taskDetail(let id): return "task-\(id)"
            case .schedule: return "schedule"
            case .routes: return "routes"
            case .emergency: return "emergency"
            case .settings: return "settings"
            }
        }
    }
    
    // MARK: - Nova Intelligence Tabs
    enum NovaTab: String, CaseIterable {
        case todaysTasks = "Today's Tasks"
        case weeklySchedule = "Weekly Schedule"
        case buildingInfo = "Building Info"
        case chat = "Chat"
        
        var icon: String {
            switch self {
            case .todaysTasks: return "list.bullet.clipboard"
            case .weeklySchedule: return "calendar.badge.clock"
            case .buildingInfo: return "building.2.fill"
            case .chat: return "brain.head.profile"
            }
        }
    }
    
    // MARK: - State
    @State private var heroExpanded = true
    @State private var selectedNovaTab: NovaTab = .todaysTasks
    @State private var sheet: WorkerRoute?
    
    var body: some View {
        ZStack {
            // Dark Background
            CyntientOpsDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                WorkerHeaderV3B(
                    name: viewModel.worker?.name ?? "Worker",
                    initials: String((viewModel.worker?.name ?? "W").prefix(2)).uppercased(),
                    photoURL: nil,
                    nextTaskName: viewModel.heroNextTask?.title,
                    showClockPill: viewModel.isClockedIn,
                    isNovaProcessing: false,
                    onRoute: handleHeaderRoute
                )
                .zIndex(100)
                
                // Scrollable Content with Dynamic Bottom Padding
                ScrollView {
                    VStack(spacing: 16) {
                        // Collapsible Worker Real-time Hero Card
                        WorkerRealTimeHeroCard(
                            isExpanded: $heroExpanded,
                            currentBuilding: viewModel.currentBuilding,
                            todaysTasks: viewModel.todaysTasks,
                            completedTasksCount: viewModel.completedTasksCount,
                            isClockedIn: viewModel.isClockedIn,
                            clockInTime: viewModel.clockInTime,
                            weather: viewModel.weatherData,
                            onBuildingTap: handleBuildingTap,
                            onScheduleTap: { sheet = .schedule },
                            onTasksTap: { selectedNovaTab = .todaysTasks }
                        )
                        
                        // Today's Tasks Grid (when hero expanded and has tasks)
                        if heroExpanded && !viewModel.todaysTasks.isEmpty {
                            WorkerTasksGrid(
                                tasks: Array(viewModel.todaysTasks.prefix(6)),
                                onTaskTap: { task in
                                    sheet = .taskDetail(task.id)
                                }
                            )
                        }
                        
                        // Urgent Items Section (worker-specific)
                        if hasUrgentItems() {
                            WorkerUrgentItemsSection(
                                urgentTasks: getUrgentTasks(),
                                overdueCount: getOverdueCount(),
                                clockInRequired: !viewModel.isClockedIn && shouldBeWorking(),
                                onUrgentTap: { selectedNovaTab = .todaysTasks }
                            )
                        }
                        
                        // Dynamic spacer for intelligence panel
                        Spacer(minLength: getIntelligencePanelTotalHeight())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
                .refreshable {
                    await viewModel.refreshData()
                }
                
                // Nova Worker Intelligence Bar
                WorkerNovaIntelligenceBar(
                    selectedTab: $selectedNovaTab,
                    todaysTasks: viewModel.todaysTasks,
                    weeklySchedule: viewModel.scheduleWeek,
                    currentBuilding: viewModel.currentBuilding,
                    assignedBuildings: viewModel.assignedBuildings,
                    allBuildings: viewModel.allBuildings,
                    onTabTap: handleNovaTabTap,
                    onTaskAction: handleTaskAction
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
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
            selectedNovaTab = .buildingInfo
        }
    }
    
    private func getIntelligencePanelTotalHeight() -> CGFloat {
        let contentHeight = getIntelligencePanelContentHeight()
        let tabBarHeight: CGFloat = 65
        return contentHeight + tabBarHeight + 20
    }
    
    private func getIntelligencePanelContentHeight() -> CGFloat {
        switch selectedNovaTab {
        case .todaysTasks:
            return min(CGFloat(viewModel.todaysTasks.count * 50 + 100), 240)
        case .weeklySchedule:
            return 220
        case .buildingInfo:
            return viewModel.assignedBuildings.count > 3 ? 200 : 160
        case .chat:
            return 140
        }
    }
    
    // MARK: - Navigation Handlers
    
    private func handleHeaderRoute(_ route: WorkerHeaderRoute) {
        switch route {
        case .profile: sheet = .profile
        case .mainMenu: sheet = .profile // Main menu opens profile for now
        case .clockAction: sheet = .profile // Clock action opens profile for now
        case .novaChat: sheet = .profile // Nova chat opens profile for now
        }
    }
    
    private func handleNovaTabTap(_ tab: NovaTab) {
        switch tab {
        case .todaysTasks:
            // Tasks content shows in intelligence panel
            break
        case .weeklySchedule:
            // Schedule content shows in intelligence panel
            break
        case .buildingInfo:
            // Building info shows in intelligence panel
            break
        case .chat:
            // Nova chat functionality
            break
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
                weeklySchedule: viewModel.weeklySchedule,
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
            WorkerPreferencesView()
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Helper Properties and Functions
    
    private func getFirstName() -> String {
        guard let fullName = viewModel.worker?.name else {
            return "Worker"
        }
        return String(fullName.split(separator: " ").first ?? "Worker")
    }
    
    private func handleHeaderRoute(_ route: WorkerHeaderRoute) {
        switch route {
        case .profile:
            sheet = .profile
        case .schedule:
            sheet = .schedule
        case .routes:
            sheet = .routes
        case .emergency:
            sheet = .emergency
        }
    }
    
    private func hasUrgentTasks() -> Bool {
        return viewModel.todaysTasks.contains { task in
            task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency
        }
    }
    
    private var urgentTasksCount: Int {
        return viewModel.todaysTasks.filter { task in
            task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency
        }.count
    }
    
    private func formatTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    private func shouldBeWorking() -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        return hour >= 7 && hour < 17
    }
}

// MARK: - Worker Header Component


// MARK: - Worker Real-time Hero Card

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
                    if hasUrgentTasks {
                        WorkerUrgentAlert(
                            urgentCount: urgentTasksCount,
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
        if hasUrgentTasks {
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

// MARK: - Worker Nova Intelligence Bar

struct WorkerNovaIntelligenceBar: View {
    @Binding var selectedTab: WorkerDashboardView.NovaTab
    let todaysTasks: [WorkerDashboardViewModel.TaskItem]
    let weeklySchedule: [String] // Will be updated with real schedule data
    let currentBuilding: WorkerDashboardViewModel.BuildingSummary?
    let assignedBuildings: [WorkerDashboardViewModel.BuildingSummary]
    let allBuildings: [WorkerDashboardViewModel.BuildingSummary] // For coverage
    let onTabTap: (WorkerDashboardView.NovaTab) -> Void
    let onTaskAction: (WorkerTaskAction) -> Void
    
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
        case .todaysTasks:
            return min(CGFloat(todaysTasks.count * 60 + 120), 260)
        case .weeklySchedule:
            return 240
        case .buildingInfo:
            return assignedBuildings.count > 3 ? 200 : 160
        case .chat:
            return 140
        }
    }
    
    @ViewBuilder
    private var intelligenceContentPanel: some View {
        ScrollView {
            VStack(spacing: 16) {
                switch selectedTab {
                case .todaysTasks:
                    WorkerTodaysTasksContent(
                        tasks: todaysTasks,
                        onTaskAction: onTaskAction
                    )
                    
                case .weeklySchedule:
                    WorkerWeeklyScheduleContent(
                        currentBuilding: currentBuilding,
                        assignedBuildings: assignedBuildings,
                        weeklySchedule: weeklySchedule
                    )
                    
                case .buildingInfo:
                    WorkerBuildingInfoContent(
                        currentBuilding: currentBuilding,
                        assignedBuildings: assignedBuildings,
                        allBuildings: allBuildings
                    )
                    
                case .chat:
                    WorkerNovaChat()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.5))
    }
    
    private func getBadgeCount(for tab: WorkerDashboardView.NovaTab) -> Int {
        switch tab {
        case .todaysTasks:
            return todaysTasks.filter { !$0.isCompleted }.count
        case .weeklySchedule:
            return 0 // Could show days remaining in week
        case .buildingInfo:
            return assignedBuildings.count
        case .chat:
            return 0
        }
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

// MARK: - Worker Intelligence Content Components

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
    let weeklySchedule: [String]
    
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
                
                ForEach(getDaysOfWeek(), id: \.self) { day in
                    WorkerScheduleRow(
                        day: day,
                        buildings: getAssignedBuildingsForDay(day),
                        isToday: isToday(day)
                    )
                }
            }
            .padding(.top, 8)
        }
    }
    
    private func getDaysOfWeek() -> [String] {
        return ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    }
    
    private func getAssignedBuildingsForDay(_ day: String) -> [String] {
        // In real implementation, this would fetch from OperationalDataManager
        // For now, return sample data based on assigned buildings
        switch day {
        case "Monday", "Wednesday", "Friday":
            return Array(assignedBuildings.prefix(2)).map { $0.name }
        case "Tuesday", "Thursday":
            return Array(assignedBuildings.suffix(2)).map { $0.name }
        default:
            return []
        }
    }
    
    private func isToday(_ day: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date()) == day
    }
}

struct WorkerBuildingInfoContent: View {
    let currentBuilding: WorkerDashboardViewModel.BuildingSummary?
    let assignedBuildings: [WorkerDashboardViewModel.BuildingSummary]
    let allBuildings: [WorkerDashboardViewModel.BuildingSummary] // For coverage purposes
    
    var body: some View {
        VStack(spacing: 12) {
            // Current Building Status
            if let currentBuilding = currentBuilding {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Location")
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    WorkerCurrentBuildingCard(building: currentBuilding)
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
                                isCurrentLocation: building.id == currentBuilding?.id
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
                                isCurrentLocation: building.id == currentBuilding?.id
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
                        icon: "map.fill",
                        title: "View Routes",
                        color: CyntientOpsDesign.DashboardColors.info
                    )
                    
                    WorkerQuickActionButton(
                        icon: "clock.fill",
                        title: "Clock In/Out",
                        color: CyntientOpsDesign.DashboardColors.workerPrimary
                    )
                    
                    WorkerQuickActionButton(
                        icon: "exclamationmark.triangle.fill",
                        title: "Report Issue",
                        color: CyntientOpsDesign.DashboardColors.critical
                    )
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
    
    var body: some View {
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
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CyntientOpsDesign.DashboardColors.success.opacity(0.1))
        .cornerRadius(8)
    }
}

struct WorkerBuildingChip: View {
    let building: WorkerDashboardViewModel.BuildingSummary
    let isCurrentLocation: Bool
    
    var body: some View {
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

struct WorkerQuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        Button(action: {
            // Handle action
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .francoDarkCardBackground(cornerRadius: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkerCoverageBuildingChip: View {
    let building: WorkerDashboardViewModel.BuildingSummary
    let isAssigned: Bool
    let isCurrentLocation: Bool
    
    var body: some View {
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
}

// MARK: - Worker Schedule View

struct WorkerScheduleView: View {
    let weeklySchedule: [String]
    let assignedBuildings: [WorkerDashboardViewModel.BuildingSummary]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(getDaysOfWeek(), id: \.self) { day in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(day)
                                .font(.headline)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            
                            Spacer()
                            
                            if isToday(day) {
                                Text("Today")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(CyntientOpsDesign.DashboardColors.workerAccent)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        
                        // Buildings for this day
                        if !getAssignedBuildingsForDay(day).isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(getAssignedBuildingsForDay(day), id: \.self) { buildingName in
                                    HStack {
                                        Circle()
                                            .fill(CyntientOpsDesign.DashboardColors.workerAccent)
                                            .frame(width: 8, height: 8)
                                        
                                        Text(buildingName)
                                            .font(.subheadline)
                                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                                        
                                        Spacer()
                                        
                                        Text("9:00 AM - 5:00 PM")
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
    
    private func getDaysOfWeek() -> [String] {
        return ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    }
    
    private func getAssignedBuildingsForDay(_ day: String) -> [String] {
        // Real implementation would get data from OperationalDataManager
        switch day {
        case "Monday", "Wednesday", "Friday":
            return Array(assignedBuildings.prefix(2)).map { $0.name }
        case "Tuesday", "Thursday":
            return Array(assignedBuildings.suffix(2)).map { $0.name }
        default:
            return []
        }
    }
    
    private func isToday(_ day: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date()) == day
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
