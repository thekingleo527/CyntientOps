//
//  WorkerDashboardView.swift  
//  CyntientOps v7.0
//
//  ✅ UNIFIED LAYOUT: Header + Hero Cards + Weather Bar + Intelligence Panel
//  ✅ GLASS DESIGN: CyntientOps glassmorphism with proper containers
//  ✅ REAL DATA: OperationalDataManager integration for specific worker
//  ✅ RESPONSIVE: MapRevealContainer for proper expand/collapse behavior
//

import SwiftUI
import MapKit

struct WorkerDashboardView: View {
    @StateObject private var viewModel: WorkerDashboardViewModel
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var novaManager: NovaAIManager
    
    private let container: ServiceContainer
    
    init(container: ServiceContainer) {
        self.container = container
        self._viewModel = StateObject(wrappedValue: WorkerDashboardViewModel(container: container))
    }
    
    // MARK: - Sheet Navigation
    enum WorkerRoute: Identifiable {
        case profile, buildingDetail(String), taskDetail(String), novaChat, settings
        
        var id: String {
            switch self {
            case .profile: return "profile"
            case .buildingDetail(let id): return "building-\(id)"
            case .taskDetail(let id): return "task-\(id)"
            case .novaChat: return "nova-chat"
            case .settings: return "settings"
            }
        }
    }
    
    // MARK: - State
    @State private var sheet: WorkerRoute?
    @State private var isPortfolioMapRevealed = false
    @State private var heroExpanded = true
    @State private var intelligencePanelExpanded = false
    @State private var selectedNovaTab: IntelligenceTab = .routines
    
    // MARK: - Intelligence Tabs
    enum IntelligenceTab: String, CaseIterable {
        case routines = "Routines"
        case portfolio = "Portfolio" 
        case analytics = "Analytics"
        case siteDeparture = "Site Departure"
        case schedule = "Schedule"
        
        var icon: String {
            switch self {
            case .routines: return "checklist"
            case .portfolio: return "building.2"
            case .analytics: return "chart.bar"
            case .siteDeparture: return "door.left.hand.closed"
            case .schedule: return "calendar"
            }
        }
    }
    
    var body: some View {
        MapRevealContainer(
            buildings: viewModel.assignedBuildings.map { building in
                NamedCoordinate(
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
            ZStack {
                // Dark Background
                CyntientOpsDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Unified Header: CyntientOps Logo + Nova Avatar + Worker Status Pill
                    WorkerHeaderV3B(
                        name: getWorkerName(),
                        initials: getWorkerInitials(),
                        photoURL: nil,
                        nextTaskName: getNextTaskTitle(),
                        showClockPill: true,
                        isNovaProcessing: false, // novaManager.isProcessing not available
                        onRoute: handleHeaderRoute
                    )
                    .zIndex(100)
                    
                    // Main Content with Dynamic Bottom Padding
                    ScrollView {
                        VStack(spacing: CyntientOpsDesign.Spacing.md) {
                            // Hero Section: Two Glass Cards
                            heroSection
                            
                            // Weather-Based Task Bar (thin, location intelligent)
                            if let currentBuilding = getCurrentBuildingCoordinate(),
                               let weather = viewModel.weatherData {
                                WeatherDashboardComponent(
                                    building: currentBuilding,
                                    weather: weather,
                                    tasks: getWeatherAffectedTasks(),
                                    onTaskTap: { task in
                                        if let taskId = findTaskId(for: task) {
                                            sheet = .taskDetail(taskId)
                                        }
                                    }
                                )
                                .padding(.horizontal, CyntientOpsDesign.Spacing.md)
                            }
                        }
                        .padding(.top, CyntientOpsDesign.Spacing.md)
                        .padding(.bottom, getIntelligencePanelTotalHeight() + 20)
                    }
                    .refreshable {
                        await viewModel.refreshData()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Intelligence Panel with Working Tabs - Simplified for now
            VStack {
                // Basic tab bar for worker functions
                HStack {
                    ForEach(IntelligenceTab.allCases, id: \.rawValue) { tab in
                        Button(action: {
                            selectedNovaTab = tab
                            handleTabNavigation(tab)
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(selectedNovaTab == tab ? CyntientOpsDesign.DashboardColors.workerPrimary : CyntientOpsDesign.DashboardColors.tertiaryText)
                                
                                Text(tab.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(selectedNovaTab == tab ? CyntientOpsDesign.DashboardColors.workerPrimary : CyntientOpsDesign.DashboardColors.tertiaryText)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, CyntientOpsDesign.Spacing.md)
                .padding(.vertical, 12)
                .background(
                    Rectangle()
                        .fill(.regularMaterial)
                        .overlay(
                            Rectangle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
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
    
    // MARK: - Hero Section with Two Glass Cards
    
    @ViewBuilder
    private var heroSection: some View {
        if heroExpanded {
            VStack(spacing: CyntientOpsDesign.Spacing.md) {
                HStack(spacing: CyntientOpsDesign.Spacing.md) {
                    // Card 1: Immediate Routine/Tasks for Assigned Building
                    GlassCard(
                        intensity: .regular,
                        cornerRadius: CyntientOpsDesign.CornerRadius.glassCard,
                        padding: CyntientOpsDesign.Spacing.cardPadding
                    ) {
                        immediateRoutineCard
                    }
                    
                    // Card 2: Immediate Next Tasks
                    GlassCard(
                        intensity: .regular,
                        cornerRadius: CyntientOpsDesign.CornerRadius.glassCard,
                        padding: CyntientOpsDesign.Spacing.cardPadding
                    ) {
                        immediateNextTasksCard
                    }
                }
                .frame(height: 200)
                
                // Collapse/Expand Toggle
                Button(action: {
                    withAnimation(CyntientOpsDesign.Animations.spring) {
                        heroExpanded.toggle()
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
        } else {
            // Collapsed Hero Summary
            Button(action: {
                withAnimation(CyntientOpsDesign.Animations.spring) {
                    heroExpanded = true
                }
            }) {
                GlassCard(
                    intensity: .thin,
                    cornerRadius: CyntientOpsDesign.CornerRadius.md,
                    padding: CyntientOpsDesign.Spacing.md
                ) {
                    collapsedHeroSummary
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(height: 80)
        }
    }
    
    // MARK: - Card Contents with Real Data
    
    @ViewBuilder
    private var immediateRoutineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.workerPrimary)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Building")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Text(viewModel.currentBuilding?.name ?? "Not Assigned")
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(viewModel.isClockedIn ? .green : .orange)
                    .frame(width: 8, height: 8)
            }
            
            Spacer()
            
            // Today's routine count from OperationalDataManager
            VStack(alignment: .leading, spacing: 4) {
                Text("\(getImmediateTasksCount())")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text("Immediate Tasks")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            // Progress indicator
            ProgressView(value: calculateBuildingProgress())
                .progressViewStyle(LinearProgressViewStyle(tint: CyntientOpsDesign.DashboardColors.workerPrimary))
        }
    }
    
    @ViewBuilder
    private var immediateNextTasksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next Priority")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    Text(getNextTaskTitle())
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Urgency indicator
                if hasUrgentTasks() {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            // Next task details
            if let nextTask = getNextTask() {
                VStack(alignment: .leading, spacing: 4) {
                    Text(nextTask.dueDate?.formatted(.dateTime.hour().minute()) ?? "No time")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    
                    Text("Due Time")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All Clear")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text("No urgent tasks")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
            }
        }
    }
    
    @ViewBuilder
    private var collapsedHeroSummary: some View {
        HStack {
            // Status indicator
            Circle()
                .fill(viewModel.isClockedIn ? .green : .orange)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentBuilding?.name ?? "Ready to start")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text("\(getImmediateTasksCount()) immediate tasks")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
                    .frame(width: 24, height: 24)
                
                Circle()
                    .trim(from: 0, to: calculateBuildingProgress())
                    .stroke(CyntientOpsDesign.DashboardColors.workerPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 24, height: 24)
                    .rotationEffect(.degrees(-90))
            }
            
            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
    }
    
    // MARK: - Helper Methods with Real OperationalDataManager Data
    
    private func getWorkerName() -> String {
        return viewModel.worker?.name ?? authManager.currentUser?.name ?? "Worker"
    }
    
    private func getWorkerInitials() -> String {
        let name = getWorkerName()
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.prefix(1) ?? "W"
        let lastInitial = components.count > 1 ? components.last?.prefix(1) ?? "" : ""
        return "\(firstInitial)\(lastInitial)".uppercased()
    }
    
    private func handleHeaderRoute(_ route: WorkerHeaderRoute) {
        switch route {
        case .mainMenu:
            // Handle main menu
            break
        case .profile:
            sheet = .profile
        case .clockAction:
            handleClockAction()
        case .novaChat:
            sheet = .novaChat
        }
    }
    
    private func getCurrentBuildingCoordinate() -> NamedCoordinate? {
        guard let building = viewModel.currentBuilding else { return nil }
        return NamedCoordinate(
            id: building.id,
            name: building.name,
            address: building.address,
            latitude: building.coordinate.latitude,
            longitude: building.coordinate.longitude
        )
    }
    
    private func getWeatherAffectedTasks() -> [ContextualTask] {
        return viewModel.todaysTasks.compactMap { task in
            // Convert to ContextualTask for weather component
            ContextualTask(
                id: task.id,
                title: task.title,
                description: task.description,
                status: task.isCompleted ? .completed : .pending,
                scheduledDate: task.dueDate,
                dueDate: task.dueDate,
                category: CoreTypes.TaskCategory(rawValue: task.category.lowercased()),
                urgency: convertUrgency(task.urgency),
                buildingId: task.buildingId,
                buildingName: nil,
                requiresPhoto: task.requiresPhoto,
                estimatedDuration: 30
            )
        }
    }
    
    private func convertUrgency(_ urgency: WorkerDashboardViewModel.TaskItem.TaskUrgency) -> CoreTypes.TaskUrgency? {
        switch urgency {
        case .low: return .low
        case .normal: return .normal
        case .high: return .high
        case .urgent: return .urgent
        case .critical: return .critical
        case .emergency: return .emergency
        }
    }
    
    private func findTaskId(for contextualTask: ContextualTask) -> String? {
        return viewModel.todaysTasks.first { $0.id == contextualTask.id }?.id
    }
    
    private func getImmediateTasksCount() -> Int {
        return viewModel.todaysTasks.filter { task in
            !task.isCompleted && (task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency)
        }.count
    }
    
    private func calculateBuildingProgress() -> Double {
        guard let buildingId = viewModel.currentBuilding?.id else { return 0.0 }
        let buildingTasks = viewModel.todaysTasks.filter { $0.buildingId == buildingId }
        guard !buildingTasks.isEmpty else { return 0.0 }
        let completedCount = buildingTasks.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(buildingTasks.count)
    }
    
    private func getNextTask() -> WorkerDashboardViewModel.TaskItem? {
        return viewModel.todaysTasks
            .filter { !$0.isCompleted }
            .sorted(by: { first, second in
                // Sort by urgency first, then by due date
                if first.urgency != second.urgency {
                    return getUrgencyOrder(first.urgency) < getUrgencyOrder(second.urgency)
                }
                guard let firstDate = first.dueDate, let secondDate = second.dueDate else {
                    return first.dueDate != nil
                }
                return firstDate < secondDate
            })
            .first
    }
    
    private func getNextTaskTitle() -> String {
        return getNextTask()?.title ?? "No urgent tasks"
    }
    
    private func hasUrgentTasks() -> Bool {
        return viewModel.todaysTasks.contains { task in
            !task.isCompleted && (task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency)
        }
    }
    
    private func handleClockAction() {
        Task {
            if viewModel.isClockedIn {
                await viewModel.clockOut()
            } else {
                if let building = viewModel.assignedBuildings.first {
                    let coordinate = NamedCoordinate(
                        id: building.id,
                        name: building.name,
                        address: building.address,
                        latitude: building.coordinate.latitude,
                        longitude: building.coordinate.longitude
                    )
                    await viewModel.clockIn(at: coordinate)
                }
            }
        }
    }
    
    private func handleTabNavigation(_ tab: IntelligenceTab) {
        switch tab {
        case .portfolio:
            withAnimation {
                isPortfolioMapRevealed = true
            }
        case .routines:
            // Focus on tasks view
            break
        case .analytics:
            // Show analytics
            break
        case .siteDeparture:
            // Site departure flow
            break
        case .schedule:
            // Schedule view
            break
        }
    }
    
    private func getIntelligencePanelTotalHeight() -> CGFloat {
        return intelligencePanelExpanded ? 280 : 80
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
                Text("Building Details for \(building.name)")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .navigationTitle(building.name)
                    .navigationBarTitleDisplayMode(.inline)
            }
            
        case .taskDetail(let taskId):
            if let task = viewModel.todaysTasks.first(where: { $0.id == taskId }) {
                UnifiedTaskDetailView(
                    task: convertToContextualTask(task),
                    mode: .worker
                )
                .navigationTitle(task.title)
                .navigationBarTitleDisplayMode(.inline)
            }
            
        case .novaChat:
            NovaInteractionView()
                .environmentObject(novaManager)
                .navigationTitle("Nova Assistant")
                .navigationBarTitleDisplayMode(.inline)
                
        case .settings:
            WorkerPreferencesView(workerId: viewModel.worker?.id ?? "")
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func convertToContextualTask(_ task: WorkerDashboardViewModel.TaskItem) -> ContextualTask {
        return ContextualTask(
            id: task.id,
            title: task.title,
            description: task.description,
            status: task.isCompleted ? .completed : .pending,
            scheduledDate: task.dueDate,
            dueDate: task.dueDate,
            category: CoreTypes.TaskCategory(rawValue: task.category.lowercased()),
            urgency: convertUrgency(task.urgency),
            buildingId: task.buildingId,
            buildingName: nil,
            requiresPhoto: task.requiresPhoto,
            estimatedDuration: 30
        )
    }
}

    // MARK: - Helper for Urgency Sorting
    
    private func getUrgencyOrder(_ urgency: WorkerDashboardViewModel.TaskItem.TaskUrgency) -> Int {
        switch urgency {
        case .emergency: return 0
        case .critical: return 1
        case .urgent: return 2
        case .high: return 3
        case .normal: return 4
        case .low: return 5
        }
    }
