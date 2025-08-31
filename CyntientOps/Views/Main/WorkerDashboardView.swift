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
    @State private var showingFullScreenTab: IntelligenceTab? = nil
    @State private var showingSiteDeparture = false
    @State private var siteDepartureVM: SiteDepartureViewModel? = nil
    
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
            container: container,
            onBuildingTap: { building in
                sheet = .buildingDetail(building.id)
            }
        ) {
            ZStack {
                // Dark Background
                CyntientOpsDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Role-specific header (simple, focused)
                    WorkerSimpleHeader(
                        workerName: getWorkerName(),
                        workerId: viewModel.workerProfile?.id ?? "",
                        isNovaProcessing: false,
                        clockInStatus: viewModel.isClockedIn ? .clockedIn(building: viewModel.currentBuilding?.name ?? "", time: viewModel.clockedInAt ?? Date()) : .notClockedIn,
                        onLogoTap: { /* Optional: show menu or map */ },
                        onNovaPress: { sheet = .novaChat },
                        onProfileTap: { sheet = .profile },
                        onClockAction: { handleClockAction() }
                    )
                    .zIndex(100)
                    
                    // Main Content with Dynamic Bottom Padding
                    ScrollView {
                        VStack(spacing: CyntientOpsDesign.Spacing.md) {
                            // Hero Section: Two Glass Cards
                            heroSection
                            
                            // Weather Ribbon (compact, expandable)
                            if let weatherSnapshot = viewModel.weather {
                                WeatherRibbonView(snapshot: weatherSnapshot)
                                    .padding(.horizontal, CyntientOpsDesign.Spacing.md)
                                    .animatedGlassAppear(delay: 0.3)
                            }
                            
                            // Upcoming Tasks (weather-aware, intelligent ordering)
                            if !viewModel.upcoming.isEmpty {
                                UpcomingTaskListView(rows: viewModel.upcoming)
                                    .padding(.horizontal, CyntientOpsDesign.Spacing.md)
                                    .animatedGlassAppear(delay: 0.4)
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
                            handleIntelligenceTabNavigation(tab)
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
        .sheet(isPresented: $showingSiteDeparture) {
            if let vm = siteDepartureVM {
                SiteDepartureSheet(viewModel: vm) {
                    Task { await viewModel.clockOut() }
                }
            }
        }
        .sheet(isPresented: $showingVendorAccess) {
            VendorAccessLogSheetLight(viewModel: viewModel) {
                showingVendorAccess = false
            }
        }
        .sheet(isPresented: $showingQuickNote) {
            QuickNoteSheet(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CyntientOpsImagePicker(
                image: .constant(nil),
                onImagePicked: { image in
                    // Store quick photo as after-work note for current building
                    if let wid = viewModel.worker?.id,
                       let building = viewModel.currentBuilding {
                        Task {
                            _ = try? await container.photos.captureQuick(
                                image: image,
                                category: .afterWork,
                                buildingId: building.id,
                                workerId: wid,
                                notes: "Quick photo captured from dashboard"
                            )
                        }
                    }
                    showingCamera = false
                },
                sourceType: .camera
            )
        }
        .task {
            await viewModel.refreshData()
        }
        .overlay(
            // Full-screen tab content overlay
            Group {
                if let fullScreenTab = showingFullScreenTab {
                    fullScreenTabContent(for: fullScreenTab)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }
            }
        )
        .overlay(alignment: .trailing) {
            // Persistent quick actions rail
            VStack(spacing: 12) {
                Button(action: { handleClockAction() }) {
                    Image(systemName: viewModel.isClockedIn ? "clock.fill" : "clock")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Button(action: { showingVendorAccess = true }) {
                    Image(systemName: "person.badge.key.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Button(action: { showingCamera = true }) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Button(action: { showingQuickNote = true }) {
                    Image(systemName: "note.text")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding(.trailing, 12)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Hero Section with Two Glass Cards
    
    @ViewBuilder
    private var heroSection: some View {
        if heroExpanded {
            VStack(spacing: CyntientOpsDesign.Spacing.md) {
                HStack(spacing: CyntientOpsDesign.Spacing.md) {
                    // Card 1: Immediate Routine/Tasks for Assigned Building
                    Button(action: {
                        if let buildingId = viewModel.currentBuilding?.id {
                            sheet = .buildingDetail(buildingId)
                        }
                    }) {
                        GlassCard(
                            intensity: .regular,
                            cornerRadius: CyntientOpsDesign.CornerRadius.glassCard,
                            padding: CyntientOpsDesign.Spacing.cardPadding
                        ) {
                            immediateRoutineCard
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Card 2: Immediate Next Tasks
                    Button(action: {
                        if let nextTask = getNextTask() {
                            sheet = .taskDetail(nextTask.id)
                        }
                    }) {
                        GlassCard(
                            intensity: .regular,
                            cornerRadius: CyntientOpsDesign.CornerRadius.glassCard,
                            padding: CyntientOpsDesign.Spacing.cardPadding
                        ) {
                            immediateNextTasksCard
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
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
                    
                    Text(viewModel.currentBuildingName)
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
                Text("\(viewModel.immediateCount)")
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
                    
                    Text(viewModel.nextPriorityTitle)
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
            if let nextTime = viewModel.nextPriorityTime {
                VStack(alignment: .leading, spacing: 4) {
                    Text(CoreTypes.DateUtils.timeFormatter.string(from: nextTime))
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
                
                Text("\(viewModel.immediateCount) immediate tasks")
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
    
    // Header route handler removed; WorkerSimpleHeader uses explicit actions
    
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

    private func sequenceTimeRange(_ seq: RouteSequence) -> String {
        let start = CoreTypes.DateUtils.timeFormatter.string(from: seq.arrivalTime)
        let end = CoreTypes.DateUtils.timeFormatter.string(from: seq.arrivalTime.addingTimeInterval(seq.estimatedDuration))
        return "\(start) – \(end)"
    }
    
    private func getNextTaskTitle() -> String {
        return getNextTask()?.title ?? "No urgent tasks"
    }
    
    private func hasUrgentTasks() -> Bool {
        return viewModel.todaysTasks.contains { task in
            !task.isCompleted && (task.urgency == .urgent || task.urgency == .critical || task.urgency == .emergency)
        }
    }

    
    private func formatDurationMinutes(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        return "\(minutes) min"
    }
private func handleClockAction() {
        Task {
            if viewModel.isClockedIn {
                if let wid = viewModel.worker?.id ?? authManager.workerId,
                   let cb = viewModel.currentBuilding {
                    let named = NamedCoordinate(
                        id: cb.id,
                        name: cb.name,
                        address: cb.address,
                        latitude: cb.coordinate.latitude,
                        longitude: cb.coordinate.longitude
                    )
                    siteDepartureVM = SiteDepartureViewModel(
                        workerId: wid,
                        currentBuilding: named,
                        container: container
                    )
                    showingSiteDeparture = true
                } else {
                    await viewModel.clockOut()
                }
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
            WorkerProfileView(workerId: viewModel.worker?.id ?? "", container: container)
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
            NovaInteractionView(container: container)
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
    
    // MARK: - Enhanced Intelligence Panel Navigation
    
    /// Handle tab navigation - opens full-screen views while maintaining panel
    private func handleIntelligenceTabNavigation(_ tab: IntelligenceTab) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if showingFullScreenTab == tab {
                // If same tab clicked, close full-screen view
                showingFullScreenTab = nil
                
                // Special handling for portfolio tab
                if tab == .portfolio {
                    isPortfolioMapRevealed = false
                }
            } else {
                // Open new full-screen view
                showingFullScreenTab = tab
                
                // Special handling for portfolio tab - reveal map
                if tab == .portfolio {
                    isPortfolioMapRevealed = true
                }
            }
        }
    }
    
    /// Full-screen content for each intelligence tab
    @ViewBuilder
    private func fullScreenTabContent(for tab: IntelligenceTab) -> some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingFullScreenTab = nil
                        if tab == .portfolio {
                            isPortfolioMapRevealed = false
                        }
                    }
                }
            
            VStack(spacing: 0) {
                // Full-screen content area
                switch tab {
                case .routines:
                    routinesFullScreenView
                case .portfolio:
                    portfolioFullScreenView
                case .analytics:
                    analyticsFullScreenView
                case .siteDeparture:
                    siteDepartureFullScreenView
                case .schedule:
                    scheduleFullScreenView
                }
                
                // Keep space for intelligence panel at bottom
                Spacer()
                    .frame(height: 80) // Height of intelligence panel
            }
        }
    }
    
    // MARK: - Full-Screen Tab Views
    
    @ViewBuilder
    private var routinesFullScreenView: some View {
        VStack {
            // Header with close button
            HStack {
                Text("Today's Routines")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingFullScreenTab = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Routines list based on today's route sequences
            ScrollView {
                VStack(spacing: 14) {
                    let workerId = viewModel.worker?.id ?? authManager.workerId ?? ""
                    if let route = container.routes.getCurrentRoute(for: workerId) {
                        ForEach(route.sequences, id: \.id) { seq in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(seq.buildingName)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(sequenceTimeRange(seq))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                ForEach(seq.operations, id: \.id) { op in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(op.name)
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                            if let notes = op.instructions, !notes.isEmpty {
                                                Text(notes)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Text(formatDurationMinutes(op.estimatedDuration))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(8)
                                    .background(.regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
                        Text("No route available for today")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 60) // Below status bar
    }
    
    @ViewBuilder
    private var portfolioFullScreenView: some View {
        VStack {
            // Header
            HStack {
                Text("Building Portfolio")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingFullScreenTab = nil
                        isPortfolioMapRevealed = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Map is handled by MapRevealContainer - this just provides the overlay UI
            Text("Map is now full-screen")
                .font(.title3)
                .foregroundColor(.white)
                .padding()
                .background(.ultraThinMaterial)
        }
        .padding(.horizontal)
        .padding(.top, 60)
    }
    
    @ViewBuilder
    private var analyticsFullScreenView: some View {
        VStack {
            HStack {
                Text("Performance Analytics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingFullScreenTab = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Analytics content
            ScrollView {
                VStack(spacing: 20) {
                    // Real NYC Compliance Metrics
                    HStack(spacing: 15) {
                        WorkerDashboardMetricCard(title: "Active Violations", value: "\(viewModel.getTotalActiveViolations())", icon: "exclamationmark.triangle.fill")
                        WorkerDashboardMetricCard(title: "Buildings Served", value: "\(viewModel.assignedBuildings.count)", icon: "building.2.fill")
                        WorkerDashboardMetricCard(title: "Tasks Today", value: "\(viewModel.todaysTasks.count)", icon: "list.bullet")
                    }
                    
                    // Task Completion Status
                    HStack(spacing: 20) {
                        WorkerDashboardMetricCard(title: "Completed", value: "\(viewModel.completedTasksCount)", icon: "checkmark.circle.fill")
                        WorkerDashboardMetricCard(title: "Remaining", value: "\(viewModel.todaysTasks.count - viewModel.completedTasksCount)", icon: "clock.fill")
                    }
                    
                    // Real Building Compliance Status
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Building Compliance Status")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(viewModel.assignedBuildings.prefix(5), id: \.id) { building in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(building.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Text(viewModel.getBuildingComplianceStatus(building))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(viewModel.getBuildingViolationCount(building))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(viewModel.getBuildingViolationCount(building) > 5 ? .red : .green)
                                    
                                    Text("violations")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 60)
    }
    
    @ViewBuilder
    private var siteDepartureFullScreenView: some View {
        VStack {
            HStack {
                Text("Site Departure")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingFullScreenTab = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Departure Checklist")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    WorkerChecklistItem(title: "All tasks completed", isCompleted: viewModel.todaysTasks.allSatisfy { $0.isCompleted })
                    WorkerChecklistItem(title: "Equipment secured", isCompleted: false)
                    WorkerChecklistItem(title: "Site cleaned", isCompleted: false)
                    WorkerChecklistItem(title: "Photos uploaded", isCompleted: false)
                    WorkerChecklistItem(title: "Next day prepared", isCompleted: false)
                }
                .padding()
            }
            .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 60)
    }
    
    @ViewBuilder
    private var scheduleFullScreenView: some View {
        VStack {
            HStack {
                Text("Weekly Schedule")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingFullScreenTab = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.scheduleForToday, id: \.id) { item in
                        WorkerScheduleRowView(item: item)
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 60)
    }
}

// MARK: - Helper Views for Full-Screen Tabs

struct WorkerTaskRowView: View {
    let task: WorkerDashboardViewModel.TaskItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(task.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if task.requiresPhoto {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.blue)
                }
                
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .secondary)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct WorkerDashboardMetricCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct WorkerChecklistItem: View {
    let title: String
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .secondary)
            
            Text(title)
                .foregroundColor(.white)
                .strikethrough(isCompleted)
            
            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct WorkerScheduleRowView: View {
    let item: WorkerDashboardViewModel.ScheduledItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(CoreTypes.DateUtils.timeFormatter.string(from: item.startTime))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(item.location.name)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("\(item.taskCount) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(item.duration) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
