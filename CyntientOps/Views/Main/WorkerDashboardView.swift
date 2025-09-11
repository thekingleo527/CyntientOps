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
#if os(iOS)
import UIKit
#endif

struct WorkerDashboardView: View {
    @StateObject private var viewModel: WorkerDashboardViewModel
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var novaManager: NovaAIManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    
    private let container: ServiceContainer
    
    init(container: ServiceContainer) {
        self.container = container
        self._viewModel = StateObject(wrappedValue: WorkerDashboardViewModel(container: container))
    }
    
    @ViewBuilder
    private var mapOverlayContent: some View {
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
                    clockInStatus: viewModel.isClockedIn ? .clockedIn(building: viewModel.currentBuilding?.name ?? "", time: viewModel.clockInTime ?? Date()) : .notClockedIn,
                    showClockButton: true,
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

                        // Weather Hybrid Card (Accordion + deep link)
                        if let s = viewModel.topWeatherSuggestionV2 {
                            WeatherHybridCardV2(
                                suggestion: s,
                                onStart: { sug in viewModel.startWeatherFlow(sug) },
                                onOpenBuilding: { bid in NavigationCoordinator.shared.presentSheet(.buildingDetail(buildingId: bid)) }
                            )
                            .padding(.horizontal, CyntientOpsDesign.Spacing.md)
                            .animatedGlassAppear(delay: 0.3)
                            .overlay(alignment: .topTrailing) {
                                Button(action: { showingThresholds = true }) {
                                    Image(systemName: "gauge")
                                        .font(.system(size: 14, weight: .medium))
                                        .padding(8)
                                        .background(.ultraThinMaterial, in: Circle())
                                }
                                .padding(8)
                                .accessibilityLabel("View weather thresholds")
                            }
                        }
                        

                        // Upcoming Tasks (non-weather items only; weather tasks live under the Weather card)
                        let nonWeatherUpcoming = viewModel.upcoming.filter { $0.chip == nil }
                        if !nonWeatherUpcoming.isEmpty {
                            UpcomingTaskListView(rows: nonWeatherUpcoming) { tapped in
                                sheet = .taskDetail(tapped.taskId)
                            }
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
    @State private var isPortfolioMapRevealed = true
    @State private var heroExpanded = true
    @State private var intelligencePanelExpanded = false
    @State private var selectedNovaTab: IntelligenceTab = .actions
    @State private var showingFullScreenTab: IntelligenceTab? = nil
    @State private var showingSiteDeparture = false
    @State private var siteDepartureVM: SiteDepartureViewModel? = nil
    @State private var showingVendorAccess = false
    @State private var showingQuickNote = false
    @State private var showingCamera = false
    @State private var isClockBusy = false
    @State private var showingHourlyWeather = false
    @State private var showingClockInSheet = false
    @State private var toastMessage: String? = nil
    @State private var showToast: Bool = false
    @State private var showingThresholds = false
    
    // MARK: - Intelligence Tabs
    enum IntelligenceTab: String, CaseIterable {
        case routines = "Routines"
        case portfolio = "Portfolio" 
        case actions = "Actions"
        case siteDeparture = "Site Departure"
        case schedule = "Schedule"
        
        var icon: String {
            switch self {
            case .routines: return "checklist"
            case .portfolio: return "building.2"
            case .actions: return "plus.circle.fill"
            case .siteDeparture: return "door.left.hand.closed"
            case .schedule: return "calendar"
            }
        }
    }
    
    var body: some View {
        // Break the view chain into simpler steps for faster type-checking
        let step1 = mapContainerView.safeAreaInset(edge: .bottom) { intelligenceBar }
        let step2 = step1.navigationBarHidden(true).preferredColorScheme(.dark)

        // Sheets split into smaller closures
        let step3 = step2.sheet(item: $sheet) { route in
            NavigationView { workerSheetContent(for: route) }
        }

        let step4 = step3.sheet(isPresented: $showingSiteDeparture) {
            if let vm = siteDepartureVM {
                NavigationView {
                    SiteDepartureSingleView(viewModel: vm, buttonTitle: "Submit Log & Clock Out") {
                        Task { await viewModel.clockOut() }
                    }
                    .navigationTitle("Site Departure")
                    .navigationBarTitleDisplayMode(.inline)
                }
            } else if let wid = viewModel.worker?.id ?? authManager.workerId {
                let summaries: [WorkerDashboardViewModel.BuildingSummary] = {
                    if !viewModel.pendingDepartures.isEmpty {
                        return viewModel.pendingDepartures
                    } else if !viewModel.visitedToday.isEmpty {
                        return viewModel.visitedToday
                    } else if let current = viewModel.currentBuilding {
                        return [current]
                    } else {
                        return viewModel.assignedBuildings
                    }
                }()
                // DSNY fallback after 8pm: include DSNY circuit buildings for today
                let enrichedSummaries: [WorkerDashboardViewModel.BuildingSummary] = {
                    var enriched = summaries
                    let now = Date()
                    let hour = Calendar.current.component(.hour, from: now)
                    if hour >= 20 { // after 8pm
                        let todaysRoutes = container.routes.today(for: wid, date: now)
                        let dsnyItems = todaysRoutes.filter { $0.icon == "trash.circle" || $0.buildingName.lowercased().contains("dsny") }
                        for item in dsnyItems {
                            if let b = viewModel.assignedBuildings.first(where: { $0.id == item.buildingId }) {
                                if !enriched.contains(where: { $0.id == b.id }) {
                                    enriched.append(b)
                                }
                            }
                        }
                    }
                    return enriched
                }()
                let buildingCoords: [NamedCoordinate] = enrichedSummaries.map { b in
                    NamedCoordinate(
                        id: b.id,
                        name: b.name,
                        address: b.address,
                        latitude: b.coordinate.latitude,
                        longitude: b.coordinate.longitude
                    )
                }
                MultiSiteDepartureSheet(
                    workerId: wid,
                    buildings: buildingCoords,
                    container: container
                ) {
                    Task { await viewModel.clockOut() }
                }
            } else {
                EmptyView()
            }
        }

        let step5 = step4
            .sheet(isPresented: $showingVendorAccess) {
                VendorAccessLogSheetLight(viewModel: viewModel) {
                    showingVendorAccess = false
                }
            }
            .sheet(isPresented: $showingHourlyWeather) {
                if let snap = viewModel.weather {
                    NavigationView {
                        WeatherRibbonView(snapshot: snap)
                            .navigationTitle("Hourly Weather")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                } else {
                    EmptyView()
                }
            }
            .sheet(isPresented: $showingThresholds) {
                NavigationView {
                    WeatherThresholdsView(container: container, currentBuildingId: viewModel.currentBuilding?.id)
                        .navigationTitle("Weather Thresholds")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showingQuickNote) {
                QuickNoteSheet(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CyntientOpsImagePicker(
                    image: .constant(nil),
                    onImagePicked: { image in
                        if let wid = viewModel.worker?.id, let building = viewModel.currentBuilding {
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
            .sheet(isPresented: $showingClockInSheet) {
                if let wid = viewModel.worker?.id ?? authManager.workerId {
                    ClockInSheet(container: container, workerId: wid)
                } else {
                    EmptyView()
                }
            }

        let step6 = step5
            .task { await viewModel.refreshData() }
            .overlay(
                Group {
                    if let fullScreenTab = showingFullScreenTab, fullScreenTab != .portfolio {
                        fullScreenTabContent(for: fullScreenTab)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .zIndex(10)
                    }
                }
            )
            .overlay(alignment: Alignment.bottom) {
                if showToast, let msg = toastMessage {
                    Text(msg)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("WeatherAdvisory"))) { note in
                if let info = note.userInfo as? [String: String], let body = info["body"] {
                    toastMessage = body
                    withAnimation { showToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { showToast = false }
                    }
                }
            }

        return AnyView(step6)
    }

    private var mapContainerView: some View {
        let currentId: String? = viewModel.currentBuilding?.id
        let assignedIds = Set(viewModel.assignedBuildings.map { $0.id })
        let visitedIds = Set((viewModel.visitedToday).map { $0.id })
        return MapRevealContainer(
            buildings: mapBuildings,
            currentBuildingId: currentId,
            assignedBuildingIds: assignedIds,
            visitedBuildingIds: visitedIds,
            forceShowAll: true, // Workers should see full portfolio
            isRevealed: $isPortfolioMapRevealed,
            container: container,
            onBuildingTap: { building in
                sheet = .buildingDetail(building.id)
            }
        ) { AnyView(mapOverlayContent) }
    }

    @ViewBuilder
    private var intelligenceBar: some View {
        // Intelligence Panel with Working Tabs - Simplified for now
        VStack {
            // Last Activity ticker for worker (inside intelligence area)
            let recentActivity: [CoreTypes.DashboardUpdate] = Array(viewModel.recentUpdates.suffix(6))
            if AppFeatures.RecentActivity.enabledForWorkers, !recentActivity.isEmpty {
                LastActivityTickerWorker(updates: recentActivity)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }
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

    // MARK: - Last Activity Ticker (Worker)
    private struct LastActivityTickerWorker: View {
        let updates: [CoreTypes.DashboardUpdate]
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.horizontal.circle")
                        .foregroundColor(.orange)
                    Text(LocalizedStringKey("dashboard.recent_activity"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                ForEach(updates.reversed(), id: \.id) { u in
                    HStack(spacing: 6) {
                        Text(summary(u))
                            .font(.caption2)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        Text(shortTime(u.timestamp))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(6)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        private func summary(_ u: CoreTypes.DashboardUpdate) -> String {
            switch u.type {
            case .taskCompleted: return "Task completed at \(u.data["buildingName"] ?? u.buildingId)"
            case .workerClockedIn: return "Clocked in @ \(u.data["buildingName"] ?? u.buildingId)"
            case .workerClockedOut: return "Clocked out @ \(u.data["buildingName"] ?? u.buildingId)"
            case .criticalUpdate:
                if let action = u.data["action"], action == "urgentPhoto" { return "Urgent photo uploaded" }
                return "Critical update"
            default: return u.type.rawValue
            }
        }
        private func shortTime(_ date: Date) -> String {
            let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date)
        }
    }

    private var mapBuildings: [NamedCoordinate] {
        // Show the full portfolio to workers, not just assigned buildings
        if !viewModel.allBuildings.isEmpty {
            return viewModel.allBuildings.map { building in
                NamedCoordinate(
                    id: building.id,
                    name: building.name,
                    address: building.address,
                    latitude: building.coordinate.latitude,
                    longitude: building.coordinate.longitude
                )
            }
        }
        // Fallback to assigned buildings if portfolio not yet loaded
        return viewModel.assignedBuildings.map { building in
            NamedCoordinate(
                id: building.id,
                name: building.name,
                address: building.address,
                latitude: building.coordinate.latitude,
                longitude: building.coordinate.longitude
            )
        }
    }
    
    // MARK: - Hero Section with Two Glass Cards
    
    @ViewBuilder
    private var heroSection: some View {
        if heroExpanded {
            VStack(spacing: CyntientOpsDesign.Spacing.md) {
                // Route-driven Hero Cards (Now/Next)
                WorkerHeroNowNext(viewModel: viewModel, container: container, onTaskTap: { taskVM in
                    // Handle task tap from hero cards
                    if let buildingId = taskVM.task.buildingId {
                        sheet = .buildingDetail(buildingId)
                    }
                }, onBuildingTap: { buildingId in
                    // Direct building navigation
                    sheet = .buildingDetail(buildingId)
                })
                .padding(.horizontal, CyntientOpsDesign.Spacing.md)
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
            
            // Now task + immediate count summary
            VStack(alignment: .leading, spacing: 8) {
                if let now = getNowTask() {
                    Text("Now")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(now.title)
                                .font(.subheadline)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                                .lineLimit(1)
                            if let due = now.dueDate {
                                Text("Start: \(CoreTypes.DateUtils.timeFormatter.string(from: due))")
                                    .font(.caption2)
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                            }
                        }
                        Spacer()
                        Button("Start") { sheet = .taskDetail(now.id) }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    Text("No current task")
                        .font(.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                HStack(spacing: 6) {
                    Text("\(viewModel.immediateCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    Text("Immediate Tasks")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
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
            
            // Next task details (building-scoped)
            if let next = getNextTask() {
                VStack(alignment: .leading, spacing: 4) {
                    Text(next.title)
                        .font(.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                    if let due = next.dueDate {
                        Text("At: \(CoreTypes.DateUtils.timeFormatter.string(from: due))")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All Clear")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Text("No upcoming tasks")
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
    
    private func getWeatherAffectedTaskItems() -> [WeatherTaskItem]? {
        guard let weather = viewModel.weather else { return nil }
        return WeatherIntelligenceAdvisor.getWeatherAffectedTaskItems(
            tasks: viewModel.todaysTasks,
            weather: weather,
            currentBuildingId: viewModel.currentBuilding?.id
        )
    }
    
    // Removed local weather intelligence helpers in favor of WeatherIntelligenceAdvisor to avoid drift
    
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
        let filtered = viewModel.currentBuilding != nil
            ? viewModel.todaysTasks.filter { $0.buildingId == viewModel.currentBuilding?.id }
            : viewModel.todaysTasks
        return filtered
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

    private func getNowTask() -> WorkerDashboardViewModel.TaskItem? {
        // Prefer an item within a short window around now for the current building
        let now = Date()
        let filtered = viewModel.currentBuilding != nil
            ? viewModel.todaysTasks.filter { $0.buildingId == viewModel.currentBuilding?.id }
            : viewModel.todaysTasks
        let windowBefore: TimeInterval = 30 * 60
        let windowAhead: TimeInterval = 30 * 60
        let candidates = filtered.filter { item in
            guard let due = item.dueDate else { return false }
            return due.addingTimeInterval(-windowBefore) <= now && due.addingTimeInterval(windowAhead) >= now && !item.isCompleted
        }
        if let exact = candidates.sorted(by: { ($0.dueDate ?? now) < ($1.dueDate ?? now) }).first {
            return exact
        }
        // Fallback to next upcoming task
        return getNextTask()
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
            #if os(iOS)
            let haptic = UINotificationFeedbackGenerator()
            haptic.prepare()
            #endif
            isClockBusy = true
            if viewModel.isClockedIn {
                // Always show the consolidated MultiSiteDepartureSheet for all clock-outs
                // This uses the new building-grouped departure flow
                if let wid = viewModel.worker?.id ?? authManager.workerId {
                    // Always use the consolidated departure flow regardless of building count
                    siteDepartureVM = nil  // Clear old single-building VM
                    showingSiteDeparture = true  // Show MultiSiteDepartureSheet
                }
            } else {
                // Present clock-in sheet to choose building
                showingClockInSheet = true
            }
            isClockBusy = false
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
        case .actions:
            // Actions handled in full-screen view
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
            if let building = viewModel.assignedBuildings.first(where: { $0.id == buildingId })
                ?? viewModel.allBuildings.first(where: { $0.id == buildingId }) {
                BuildingDetailView(
                    container: container,
                    buildingId: building.id,
                    buildingName: building.name,
                    buildingAddress: building.address
                )
                .navigationBarTitleDisplayMode(.inline)
            } else {
                EmptyView()
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
                        else {
                EmptyView()
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
    
    /// Handle tab navigation — close current overlay before opening the next one
    private func handleIntelligenceTabNavigation(_ tab: IntelligenceTab) {
        // If tapping the same tab, just close it
        if showingFullScreenTab == tab {
            withAnimation(.easeInOut(duration: 0.25)) {
                showingFullScreenTab = nil
                if tab == .portfolio { isPortfolioMapRevealed = false }
            }
            return
        }

        // Special-case: if Portfolio map is already revealed, tapping Portfolio closes it
        if tab == .portfolio && isPortfolioMapRevealed {
            withAnimation(.easeInOut(duration: 0.25)) {
                isPortfolioMapRevealed = false
            }
            return
        }

        // Close any current overlay first
        if showingFullScreenTab != nil {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingFullScreenTab = nil
            }
            // Open the requested tab after a short delay for a clean transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                openIntelligenceTab(tab)
            }
        } else {
            openIntelligenceTab(tab)
        }
    }

    private func openIntelligenceTab(_ tab: IntelligenceTab) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if tab == .portfolio {
                // Portfolio is map-only; keep overlay cleared and reveal map
                isPortfolioMapRevealed = true
                showingFullScreenTab = nil
            } else {
                isPortfolioMapRevealed = false
                showingFullScreenTab = tab
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
                .allowsHitTesting(tab != .portfolio) // don't block map interactions in portfolio
                .onTapGesture {
                    guard tab != .portfolio else { return }
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
                    EmptyView() // No drawer/list — map remains unobstructed
                case .actions:
                    actionsFullScreenView
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
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        // Attempt to navigate to matching task detail if present
                                        if let match = viewModel.todaysTasks.first(where: { t in
                                            (t.title == op.name) && (t.buildingId == seq.buildingId)
                                        }) {
                                            sheet = .taskDetail(match.id)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else if !viewModel.todaysTasks.isEmpty {
                        // Fallback to task-based routines grouped by building
                        Text("Today's Tasks")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        let tasksByBuilding = Dictionary(grouping: viewModel.todaysTasks) { task in
                            task.buildingId ?? "Unknown"
                        }
                        
                        ForEach(tasksByBuilding.keys.sorted(), id: \.self) { buildingId in
                            if let tasks = tasksByBuilding[buildingId] {
                                let building = viewModel.assignedBuildings.first { $0.id == buildingId }
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(building?.name ?? "Unknown Building")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(tasks.count) tasks")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    ForEach(tasks.prefix(5), id: \.id) { task in
                                        Button(action: {
                                            sheet = .taskDetail(task.id)
                                        }) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(task.title)
                                                        .font(.subheadline)
                                                        .foregroundColor(.white)
                                                    if let desc = task.description, !desc.isEmpty {
                                                        Text(desc)
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                            .lineLimit(2)
                                                    }
                                                }
                                                Spacer()
                                                
                                                VStack(alignment: .trailing, spacing: 2) {
                                                    if let due = task.dueDate {
                                                        Text(CoreTypes.DateUtils.timeFormatter.string(from: due))
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    
                                                    TaskStatusBadge(
                                                        status: task.isCompleted ? .completed : .pending,
                                                        urgency: task.urgency
                                                    )
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(.regularMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    } else {
                        // Empty state with schedule preview
                        VStack(spacing: 16) {
                            Image(systemName: "checklist")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No Routines Today")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            let nextItems = viewModel.nextSchedulePreview(limit: 2)
                            if !nextItems.isEmpty {
                                Text("Here's what's next:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                ForEach(nextItems, id: \.id) { item in
                                    HStack {
                                        Text(item.title)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(CoreTypes.DateUtils.timeFormatter.string(from: item.startTime))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(12)
                                    .background(.regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            } else {
                                Text("All your routine tasks are complete, or no tasks are scheduled for today.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(32)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
    private var actionsFullScreenView: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Text("Quick Actions")
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
            
            // Actions content - larger format for full screen
            ScrollView {
                VStack(spacing: 24) {
                    // Quick actions in a grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        
                        // Vendor Access Log
                        ActionTile(
                            title: "Vendor Access Log",
                            subtitle: "Log vendor visits and access",
                            icon: "person.badge.key.fill",
                            color: .blue
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingFullScreenTab = nil
                            }
                            showingVendorAccess = true
                        }
                        
                        // Take Photo
                        ActionTile(
                            title: "Take Photo",
                            subtitle: "Capture photo evidence",
                            icon: "camera.fill",
                            color: .green
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingFullScreenTab = nil
                            }
                            showingCamera = true
                        }
                        
                        // Quick Note
                        ActionTile(
                            title: "Quick Note",
                            subtitle: "Add notes or observations",
                            icon: "note.text",
                            color: .orange
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingFullScreenTab = nil
                            }
                            showingQuickNote = true
                        }
                        
                        // Report Issue
                        ActionTile(
                            title: "Report Issue",
                            subtitle: "Report problems or concerns",
                            icon: "exclamationmark.triangle.fill",
                            color: .red
                        ) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingFullScreenTab = nil
                            }
                            toastMessage = "Issue reporting feature coming soon"
                            withAnimation { showToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation { showToast = false }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }
            .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 60)
        .task(id: scheduleViewMode) {
            if scheduleViewMode == .month { await loadMonthSchedule() }
        }
        .onChange(of: selectedMonth) { _ in
            if scheduleViewMode == .month { Task { await loadMonthSchedule() } }
        }
    }
    
    @State private var departureChecklistItems: [DepartureChecklistItem] = []
    
    struct DepartureChecklistItem: Identifiable {
        let id = UUID()
        var title: String
        var description: String?
        var isCompleted: Bool
        var isRequired: Bool
        var category: DepartureCategory
        var building: String?
    }
    
    enum DepartureCategory { case tasks
        var icon: String { "checkmark.circle" }
        var color: Color { .blue }
    }

    @ViewBuilder
    private var siteDepartureFullScreenView: some View {
        VStack(spacing: 0) {
            // Enhanced header with status
            VStack(spacing: 12) {
                HStack {
                    Text("Site Departure")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Overall completion status
                    HStack(spacing: 6) {
                        Image(systemName: departureCompletionIcon)
                            .foregroundColor(departureCompletionColor)
                        Text("\(completedDepartureItems)/\(totalDepartureItems)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    
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
                
                // Progress bar
                ProgressView(value: departureProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: departureCompletionColor))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            ScrollView {
                LazyVStack(spacing: 20) {
            // Tasks completion section (only section)
            departureSection(
                title: "Tasks & Work",
                icon: "checkmark.circle.fill",
                color: .blue,
                items: getDepartureItems(for: .tasks)
            )
                    
                    // Final departure button
                    if allRequiredItemsCompleted {
                        Button(action: {
                            finalizeDeparture()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text("Complete Departure")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 60)
        .onAppear {
            initializeDepartureChecklist()
        }
    }
    
    @ViewBuilder
    private func departureSection(title: String, icon: String, color: Color, items: [DepartureChecklistItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Section completion indicator
                let completedCount = items.filter(\.isCompleted).count
                Text("\(completedCount)/\(items.count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            ForEach(items) { item in
                Button(action: {
                    toggleDepartureItem(item)
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundColor(item.isCompleted ? color : .secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(item.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .strikethrough(item.isCompleted)
                                
                                if item.isRequired {
                                    Text("REQUIRED")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.red.opacity(0.2), in: Capsule())
                                }
                                
                                Spacer()
                                // Inline upload button for photos item
                                if item.title.lowercased().contains("photo") {
                                    Button(action: { showingCamera = true }) {
                                        Text("Upload")
                                            .font(.caption)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(.ultraThinMaterial, in: Capsule())
                                    }
                                }
                            }
                            
                            if let description = item.description {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            if let building = item.building {
                                HStack(spacing: 4) {
                                    Image(systemName: "building.2")
                                        .font(.caption2)
                                    Text(building)
                                        .font(.caption2)
                                }
                                .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(item.isCompleted ? color.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func initializeDepartureChecklist() {
        var items: [DepartureChecklistItem] = []
        // Per-building completion checks for buildings worked today
        let buildingsToConfirm: [WorkerDashboardViewModel.BuildingSummary] = !viewModel.visitedToday.isEmpty ? viewModel.visitedToday : (viewModel.currentBuilding.map { [$0] } ?? [])
        for b in buildingsToConfirm {
            items.append(
                DepartureChecklistItem(
                    title: "All assigned tasks complete",
                    description: nil,
                    isCompleted: viewModel.todaysTasks.filter { $0.buildingId == b.id }.allSatisfy { $0.isCompleted },
                    isRequired: true,
                    category: .tasks,
                    building: b.name
                )
            )
        }
        // Photo upload confirmation with inline upload option in UI
        items.append(
            DepartureChecklistItem(
                title: "Task photos uploaded",
                description: "Attach any missing photos before departure",
                isCompleted: false,
                isRequired: true,
                category: .tasks
            )
        )
        departureChecklistItems = items
    }
    
    private func getDepartureItems(for category: DepartureCategory) -> [DepartureChecklistItem] {
        return departureChecklistItems.filter { $0.category == category }
    }
    
    private func toggleDepartureItem(_ item: DepartureChecklistItem) {
        if let index = departureChecklistItems.firstIndex(where: { $0.id == item.id }) {
            departureChecklistItems[index].isCompleted.toggle()
        }
    }
    
    private var completedDepartureItems: Int {
        departureChecklistItems.filter(\.isCompleted).count
    }
    
    private var totalDepartureItems: Int {
        departureChecklistItems.count
    }
    
    private var departureProgress: Double {
        guard totalDepartureItems > 0 else { return 0 }
        return Double(completedDepartureItems) / Double(totalDepartureItems)
    }
    
    private var departureCompletionIcon: String {
        if departureProgress == 1.0 {
            return "checkmark.circle.fill"
        } else if departureProgress > 0.5 {
            return "clock.fill"
        } else {
            return "exclamationmark.circle.fill"
        }
    }
    
    private var departureCompletionColor: Color {
        if departureProgress == 1.0 {
            return .green
        } else if departureProgress > 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var allRequiredItemsCompleted: Bool {
        departureChecklistItems.filter(\.isRequired).allSatisfy(\.isCompleted)
    }
    
    private func finalizeDeparture() {
        // Perform final departure actions
        Task {
            // Clock out if still clocked in
            if viewModel.isClockedIn {
                await viewModel.clockOut()
            }
            
            // Show completion message
            toastMessage = "Site departure completed successfully!"
            withAnimation { showToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { showToast = false }
                showingFullScreenTab = nil
            }
        }
    }
    
    @State private var scheduleViewMode: ScheduleViewMode = .week
    @State private var selectedMonth = Date()
    @State private var expandedScheduleSections: Set<String> = []
    @State private var expandedMonthDays: Set<String> = []
    // Month schedule cache keyed by start-of-day ISO8601 string
    @State private var monthScheduleByDate: [String: [WorkerDashboardViewModel.DaySchedule.ScheduleItem]] = [:]
    @State private var isLoadingMonth: Bool = false
    
    enum ScheduleViewMode {
        case week, month
    }
    
    @ViewBuilder
    private var scheduleFullScreenView: some View {
        VStack(spacing: 0) {
            // Header with controls
            VStack(spacing: 16) {
                HStack {
                    Text("Schedule")
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
                
                // View mode selector and month dropdown
                HStack(spacing: 16) {
                    // Week/Month toggle
                    Picker("View Mode", selection: $scheduleViewMode) {
                        Text("Week").tag(ScheduleViewMode.week)
                        Text("Month").tag(ScheduleViewMode.month)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .colorScheme(.dark)
                    .frame(width: 120)
                    
                    Spacer()
                    
                    // Month selector (only shown in month mode)
                    if scheduleViewMode == .month {
                        Menu {
                            ForEach(generateMonthOptions(), id: \.self) { date in
                                Button(action: {
                                    selectedMonth = date
                                }) {
                                    Text(date.formatted(.dateTime.month(.wide).year()))
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Schedule content
            ScrollView {
                if scheduleViewMode == .week {
                    weekScheduleView
                } else {
                    monthScheduleView
                }
            }
            .background(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.top, 60)
    }
    
    @ViewBuilder
    private var weekScheduleView: some View {
        LazyVStack(spacing: 16) {
            if viewModel.scheduleWeek.isEmpty {
                // Fallback to today's items
                Text("This Week")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                if !viewModel.scheduleForToday.isEmpty {
                    ForEach(viewModel.scheduleForToday, id: \.id) { item in
                        WorkerScheduleRowView(item: item)
                    }
                } else {
                    // Show today's tasks as fallback
                    let today = Calendar.current.startOfDay(for: Date())
                    let todayTasks = viewModel.todaysTasks.filter { task in
                        if let dueDate = task.dueDate {
                            return Calendar.current.isDate(dueDate, inSameDayAs: today)
                        }
                        return false
                    }
                    
                    Text("Today - \(today.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    ForEach(todayTasks.prefix(8), id: \.id) { task in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(task.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                if let buildingName = viewModel.assignedBuildings.first(where: { $0.id == task.buildingId })?.name {
                                    Text(buildingName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                if let dueDate = task.dueDate {
                                    Text(CoreTypes.DateUtils.timeFormatter.string(from: dueDate))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                                
                                TaskStatusBadge(
                                    status: task.isCompleted ? .completed : .pending,
                                    urgency: task.urgency
                                )
                            }
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .onTapGesture {
                            sheet = .taskDetail(task.id)
                        }
                    }
                }
            } else {
                // Show weekly schedule summarized by building with expand/collapse
                ForEach(viewModel.scheduleWeek.indices, id: \.self) { index in
                    let day = viewModel.scheduleWeek[index]
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(day.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(day.items.count) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        let groups = Dictionary(grouping: day.items, by: { $0.buildingId })
                        // Order by: DSNY circuit first (if before 8 PM today), then earliest start time
                        let now = Date()
                        let isToday = Calendar.current.isDateInToday(day.date)
                        let dsnyCutoff = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: day.date) ?? day.date
                        let ordered = groups.map { (bid: $0.key, items: $0.value) }.sorted { lhs, rhs in
                            func rank(_ entry: (bid: String, items: [WorkerDashboardViewModel.DaySchedule.ScheduleItem])) -> (Int, Date) {
                                let minStart = entry.items.map { $0.startTime }.min() ?? day.date
                                let isCircuit = entry.bid == "17th_street_complex"
                                let hasDSNY = entry.items.contains { $0.title.localizedCaseInsensitiveContains("set out") || $0.title.localizedCaseInsensitiveContains("dsny") }
                                let forceTop = isToday && now < dsnyCutoff && isCircuit && hasDSNY
                                return (forceTop ? 0 : 1, minStart)
                            }
                            let (lRank, lTime) = rank(lhs)
                            let (rRank, rTime) = rank(rhs)
                            if lRank != rRank { return lRank < rRank }
                            return lTime < rTime
                        }
                        ForEach(ordered, id: \.bid) { entry in
                            let bid = entry.bid
                            let items = entry.items
                            let building = viewModel.assignedBuildings.first { $0.id == bid }
                            let buildingName: String = {
                                switch bid {
                                case "17th_street_complex":
                                    // If DSNY children present, show DSNY header variant
                                    let hasDSNY = items.contains { $0.title.localizedCaseInsensitiveContains("set out") || $0.title.localizedCaseInsensitiveContains("dsny") }
                                    return hasDSNY ? "Chelsea Circuit — DSNY Set-Out" : "Chelsea Circuit"
                                case "17th_18th_street_buildings":
                                    return "Chelsea Circuit (Weekend Coverage)"
                                default:
                                    return building?.name ?? (CanonicalIDs.Buildings.getName(for: bid) ?? "Unknown Building")
                                }
                            }()
                            let sectionKey = "\(Int(day.date.timeIntervalSince1970))_\(bid)"
                            let count = items.count
                            let totalMinutes = items.reduce(0) { sum, it in sum + Int(it.endTime.timeIntervalSince(it.startTime) / 60) }
                            // Derive time window for Chelsea Circuit
                            let circuitTimeLabel: String? = {
                                guard bid == "17th_street_complex" else { return nil }
                                guard let minStart = items.map({ $0.startTime }).min(), let maxEnd = items.map({ $0.endTime }).max() else { return nil }
                                let tf = DateFormatter()
                                tf.dateFormat = "h:mm a"
                                return "\(tf.string(from: minStart)) – \(tf.string(from: maxEnd))"
                            }()

                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Button(action: {
                                        if expandedScheduleSections.contains(sectionKey) {
                                            expandedScheduleSections.remove(sectionKey)
                                        } else {
                                            expandedScheduleSections.insert(sectionKey)
                                        }
                                    }) {
                                        Image(systemName: expandedScheduleSections.contains(sectionKey) ? "chevron.down" : "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)

                                    Text(circuitTimeLabel != nil ? "\(buildingName) • \(circuitTimeLabel!)" : buildingName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    // Inline badges
                                    HStack(spacing: 6) {
                                        if let elev = BuildingInfrastructureCatalog.elevatorCount(for: bid), elev > 0 {
                                            HStack(spacing: 3) {
                                                Image(systemName: "arrow.up.arrow.down")
                                                    .font(.caption2)
                                                Text("\(elev)")
                                                    .font(.caption2)
                                            }
                                            .foregroundColor(.secondary)
                                        }
                                        // DSNY badges for this day
                                        let weekday = Calendar.current.component(.weekday, from: day.date)
                                        let cday = CollectionDay.from(weekday: weekday)
                                        let setOutToday = DSNYCollectionSchedule.getBuildingsForBinSetOut(on: cday).contains { $0.buildingId == bid }
                                        let retrievalToday = DSNYCollectionSchedule.getBuildingsForBinRetrieval(on: cday).contains { $0.buildingId == bid }
                                        if setOutToday {
                                            Image(systemName: "trash.circle.fill")
                                                .foregroundColor(.green)
                                                .font(.caption2)
                                                .help("DSNY set‑out tonight")
                                        }
                                        if retrievalToday {
                                            Image(systemName: "tray.and.arrow.down.fill")
                                                .foregroundColor(.blue)
                                                .font(.caption2)
                                                .help("Bin retrieval today")
                                        }
                                    }
                                    Spacer()
                                    HStack(spacing: 6) {
                                        Text("\(count)")
                                            .font(.caption2)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(.blue, in: Capsule())
                                        Text("\(totalMinutes) min")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                if expandedScheduleSections.contains(sectionKey) {
                                    ForEach(items, id: \.id) { si in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(si.title)
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.white)
                                                Text("\(CoreTypes.DateUtils.timeFormatter.string(from: si.startTime)) – \(CoreTypes.DateUtils.timeFormatter.string(from: si.endTime))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Text("\(si.taskCount)")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(.regularMaterial, in: Capsule())
                                                .foregroundColor(.white)
                                        }
                                        .padding(10)
                                        .background(.regularMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                            .padding(10)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var monthScheduleView: some View {
        LazyVStack(spacing: 20) {
            Text("Month View - \(selectedMonth.formatted(.dateTime.month(.wide).year()))")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            // Calendar grid for the month
            let calendar = Calendar.current
            let monthRange = calendar.range(of: .day, in: .month, for: selectedMonth)!
            let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
            let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // Day headers
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(height: 30)
                }
                
                // Empty cells for days before month starts
                ForEach(0..<firstWeekday, id: \.self) { _ in
                    Text("")
                        .frame(height: 40)
                }
                
                // Month days
                ForEach(1...monthRange.count, id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)!
                    let hasSchedule = hasScheduleForDate(date)
                    let isToday = calendar.isDate(date, inSameDayAs: Date())
                    let key = calendar.startOfDay(for: date).ISO8601Format()
                    
                    VStack(spacing: 2) {
                        Text("\(day)")
                            .font(.subheadline)
                            .fontWeight(isToday ? .bold : .medium)
                            .foregroundColor(isToday ? .blue : .white)
                        
                        if hasSchedule {
                            Circle()
                                .fill(.blue)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isToday ? .blue.opacity(0.2) : .clear)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if expandedMonthDays.contains(key) {
                            expandedMonthDays.remove(key)
                        } else {
                            expandedMonthDays.insert(key)
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Expanded day details (summarized by building with expand/collapse per building)
            let expandedDates: [Date] = expandedMonthDays.compactMap { ISO8601DateFormatter().date(from: $0) }.sorted()
            ForEach(expandedDates, id: \.self) { date in
                let dayKey = Calendar.current.startOfDay(for: date).ISO8601Format()
                let dayItems: [WorkerDashboardViewModel.DaySchedule.ScheduleItem] = monthScheduleByDate[dayKey] ?? []
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(dayItems.count) items")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    let groups = Dictionary(grouping: dayItems, by: { $0.buildingId })
                    // Order groups similar to week view
                    let now = Date()
                    let isToday = Calendar.current.isDateInToday(date)
                    let dsnyCutoff = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: date) ?? date
                    let ordered = groups.map { (bid: $0.key, items: $0.value) }.sorted { lhs, rhs in
                        func rank(_ entry: (bid: String, items: [WorkerDashboardViewModel.DaySchedule.ScheduleItem])) -> (Int, Date) {
                            let minStart = entry.items.map { $0.startTime }.min() ?? date
                            let isCircuit = entry.bid == "17th_street_complex"
                            let hasDSNY = entry.items.contains { $0.title.localizedCaseInsensitiveContains("set out") || $0.title.localizedCaseInsensitiveContains("dsny") }
                            let forceTop = isToday && now < dsnyCutoff && isCircuit && hasDSNY
                            return (forceTop ? 0 : 1, minStart)
                        }
                        let (lRank, lTime) = rank(lhs)
                        let (rRank, rTime) = rank(rhs)
                        if lRank != rRank { return lRank < rRank }
                        return lTime < rTime
                    }
                    ForEach(ordered, id: \.bid) { entry in
                        let bid = entry.bid
                        let items = entry.items
                        let building = viewModel.assignedBuildings.first { $0.id == bid }
                        let buildingName: String = {
                            switch bid {
                            case "17th_street_complex":
                                let hasDSNY = items.contains { $0.title.localizedCaseInsensitiveContains("set out") || $0.title.localizedCaseInsensitiveContains("dsny") }
                                return hasDSNY ? "Chelsea Circuit — DSNY Set-Out" : "Chelsea Circuit"
                            case "17th_18th_street_buildings":
                                return "Chelsea Circuit (Weekend Coverage)"
                            default:
                                return building?.name ?? (CanonicalIDs.Buildings.getName(for: bid) ?? "Unknown Building")
                            }
                        }()
                        let sectionKey = "m_\(Int(date.timeIntervalSince1970))_\(bid)"
                        let count = items.count
                        let totalMinutes = items.reduce(0) { sum, it in sum + Int(it.endTime.timeIntervalSince(it.startTime) / 60) }
                        // Derive time window for Chelsea Circuit
                        let circuitTimeLabel: String? = {
                            guard bid == "17th_street_complex" else { return nil }
                            guard let minStart = items.map({ $0.startTime }).min(), let maxEnd = items.map({ $0.endTime }).max() else { return nil }
                            let tf = DateFormatter()
                            tf.dateFormat = "h:mm a"
                            return "\(tf.string(from: minStart)) – \(tf.string(from: maxEnd))"
                        }()

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Button(action: {
                                    if expandedScheduleSections.contains(sectionKey) {
                                        expandedScheduleSections.remove(sectionKey)
                                    } else {
                                        expandedScheduleSections.insert(sectionKey)
                                    }
                                }) {
                                    Image(systemName: expandedScheduleSections.contains(sectionKey) ? "chevron.down" : "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)

                                Text(circuitTimeLabel != nil ? "\(buildingName) • \(circuitTimeLabel!)" : buildingName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                // Inline badges
                                HStack(spacing: 6) {
                                    if let elev = BuildingInfrastructureCatalog.elevatorCount(for: bid), elev > 0 {
                                        HStack(spacing: 3) {
                                            Image(systemName: "arrow.up.arrow.down")
                                                .font(.caption2)
                                            Text("\(elev)")
                                                .font(.caption2)
                                        }
                                        .foregroundColor(.secondary)
                                    }
                                    let weekday = Calendar.current.component(.weekday, from: date)
                                    let cday = CollectionDay.from(weekday: weekday)
                                    let setOutToday = DSNYCollectionSchedule.getBuildingsForBinSetOut(on: cday).contains { $0.buildingId == bid }
                                    let retrievalToday = DSNYCollectionSchedule.getBuildingsForBinRetrieval(on: cday).contains { $0.buildingId == bid }
                                    if setOutToday {
                                        Image(systemName: "trash.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption2)
                                            .help("DSNY set‑out tonight")
                                    }
                                    if retrievalToday {
                                        Image(systemName: "tray.and.arrow.down.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption2)
                                            .help("Bin retrieval today")
                                    }
                                }
                                Spacer()
                                HStack(spacing: 6) {
                                    Text("\(count)")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.blue, in: Capsule())
                                    Text("\(totalMinutes) min")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            if expandedScheduleSections.contains(sectionKey) {
                                ForEach(items, id: \.id) { si in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(si.title)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.white)
                                            Text("\(CoreTypes.DateUtils.timeFormatter.string(from: si.startTime)) – \(CoreTypes.DateUtils.timeFormatter.string(from: si.endTime))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text("\(si.taskCount)")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(.regularMaterial, in: Capsule())
                                            .foregroundColor(.white)
                                    }
                                    .padding(10)
                                    .background(.regularMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Summary for selected month
            Text("Monthly Summary")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Total Tasks This Month:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(getTotalTasksForMonth())")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Days with Schedule:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(getDaysWithScheduleForMonth())")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Buildings Assigned:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(viewModel.assignedBuildings.count)")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
    
    private func generateMonthOptions() -> [Date] {
        let calendar = Calendar.current
        let currentDate = Date()
        var months: [Date] = []
        
        // Add last 2 months, current month, and next 3 months
        for i in -2...3 {
            if let date = calendar.date(byAdding: .month, value: i, to: currentDate) {
                months.append(date)
            }
        }
        
        return months
    }
    
    private func hasScheduleForDate(_ date: Date) -> Bool {
        // Prefer month schedule cache when available
        let key = Calendar.current.startOfDay(for: date).ISO8601Format()
        if let items = monthScheduleByDate[key], !items.isEmpty { return true }
        // Fallback to today's tasks (legacy behavior)
        return viewModel.todaysTasks.contains { task in
            if let dueDate = task.dueDate { return Calendar.current.isDate(dueDate, inSameDayAs: date) }
            return false
        }
    }
    
    private func getTotalTasksForMonth() -> Int {
        // Sum from month schedule cache when available
        let calendar = Calendar.current
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let range = calendar.range(of: .day, in: .month, for: selectedMonth)!
        var total = 0
        for d in range {
            if let date = calendar.date(byAdding: .day, value: d - 1, to: firstOfMonth) {
                let key = calendar.startOfDay(for: date).ISO8601Format()
                total += monthScheduleByDate[key]?.count ?? 0
            }
        }
        return total
    }
    
    private func getDaysWithScheduleForMonth() -> Int {
        let calendar = Calendar.current
        let monthRange = calendar.range(of: .day, in: .month, for: selectedMonth)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        return monthRange.reduce(0) { acc, d in
            guard let date = calendar.date(byAdding: .day, value: d - 1, to: firstOfMonth) else { return acc }
            let key = calendar.startOfDay(for: date).ISO8601Format()
            return acc + ((monthScheduleByDate[key]?.isEmpty == false) ? 1 : 0)
        }
    }

    // Populate month schedule cache using OperationalDataManager (no time filtering)
    private func loadMonthSchedule() async {
        guard let workerId = viewModel.worker?.workerId else { return }
        isLoadingMonth = true
        defer { isLoadingMonth = false }

        let calendar = Calendar.current
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let monthRange = calendar.range(of: .day, in: .month, for: selectedMonth)!

        var dict: [String: [WorkerDashboardViewModel.DaySchedule.ScheduleItem]] = [:]
        for d in monthRange {
            guard let date = calendar.date(byAdding: .day, value: d - 1, to: firstOfMonth) else { continue }
            do {
                let sched = try await container.operationalData.getWorkerScheduleForDate(workerId: workerId, date: date, skipTimeFiltering: true)
                let mapped = sched.map { s in
                    WorkerDashboardViewModel.DaySchedule.ScheduleItem(
                        id: s.id,
                        startTime: s.startTime,
                        endTime: s.endTime,
                        buildingId: s.buildingId,
                        title: s.title,
                        taskCount: 1
                    )
                }
                dict[calendar.startOfDay(for: date).ISO8601Format()] = mapped
            } catch {
                // Skip this day on error
            }
        }
        monthScheduleByDate = dict
    }
}

// MARK: - Now + Next Card removed (duplicated hero responsibility)

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

// MARK: - Action Tile (for full-screen Actions tab)

struct ActionTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                // Text content
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Interactive Card Button Style

struct InteractiveCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Task Status Badge

struct TaskStatusBadge: View {
    enum Status {
        case pending, completed, overdue
    }
    
    let status: Status
    let urgency: WorkerDashboardViewModel.TaskItem.TaskUrgency
    
    var body: some View {
        Text(statusText)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor, in: Capsule())
    }
    
    private var statusText: String {
        switch status {
        case .pending:
            switch urgency {
            case .urgent, .emergency, .critical: return "URGENT"
            case .high: return "HIGH"
            case .normal: return "NORMAL"
            case .low: return "LOW"
            }
        case .completed: return "DONE"
        case .overdue: return "OVERDUE"
        }
    }
    
    private var backgroundColor: Color {
        switch status {
        case .completed: return .green
        case .overdue: return .red
        case .pending:
            switch urgency {
            case .urgent, .emergency, .critical: return .red
            case .high: return .orange
            case .normal: return .blue
            case .low: return .gray
            }
        }
    }
    
    private var textColor: Color {
        .white
    }
}

// MARK: - Building Portfolio Card

struct BuildingPortfolioCard: View {
    let building: WorkerDashboardViewModel.BuildingSummary
    let isCurrent: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Building status indicator
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    if isCurrent {
                        ZStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            // Star badge for current building
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                                .offset(x: 15, y: -15)
                        }
                    } else {
                        Image(systemName: buildingIcon)
                            .font(.title2)
                            .foregroundColor(statusColor)
                    }
                }
                
                if isCurrent {
                    Text("Current")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            
            // Building details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(building.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if building.todayTaskCount > 0 {
                        HStack(spacing: 4) {
                            Text("\(building.todayTaskCount)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(taskCountColor, in: Capsule())
                            
                            Text("tasks")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Text(building.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Building-specific info from BuildingInfrastructureCatalog
                if let info = buildingInfo {
                    HStack(spacing: 16) {
                        if let elevators = info.elevators, elevators > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("\(elevators) elevator\(elevators > 1 ? "s" : "")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let floors = info.floors {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Text("\(floors) floors")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrent ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
    
    private var buildingInfo: BuildingInfrastructureCatalog.Info? {
        BuildingInfrastructureCatalog.map[building.id]
    }
    
    private var statusColor: Color {
        switch building.status {
        case .current: return .green
        case .assigned: return .blue
        case .available: return .gray
        case .unavailable: return .red
        case .coverage: return .orange
        }
    }
    
    private var taskCountColor: Color {
        if building.todayTaskCount >= 5 {
            return .red
        } else if building.todayTaskCount >= 3 {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var buildingIcon: String {
        let name = building.name.lowercased()
        if name.contains("museum") || name.contains("rubin") {
            return "building.columns"
        } else if name.contains("park") || name.contains("cove") {
            return "leaf"
        } else if name.contains("perry") || name.contains("elizabeth") {
            return "house"
        } else {
            return "building.2"
        }
    }
}
