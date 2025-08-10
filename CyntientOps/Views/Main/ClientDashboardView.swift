//
//  ClientDashboardView.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: Matches Worker/Admin dashboard structure
//  ✅ SIMPLIFIED: Broken down complex expressions
//  ✅ UNIFIED: Same component hierarchy and data flow
//  ✅ CLEAN: Removed all duplicate declarations
//

import SwiftUI
import MapKit
import CoreLocation

struct ClientDashboardView: View {
    // MARK: - View Models & Services (matching Worker/Admin pattern)
    @StateObject private var viewModel: ClientDashboardViewModel
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var novaEngine: NovaAIManager // From ServiceContainer
    
    private let container: ServiceContainer
    
    // Access DashboardSyncService through container
    private var dashboardSync: DashboardSyncService {
        container.dashboardSync
    }
    
    init(container: ServiceContainer) {
        self.container = container
        self._viewModel = StateObject(wrappedValue: ClientDashboardViewModel(container: container))
    }
    
    // MARK: - Enums
    enum Tab {
        case dashboard
        case buildings
        case compliance
        case reports
    }
    enum ViewContext {
        case dashboard
        case buildingDetail
        case compliance
        case reports
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

    // MARK: - State Variables
    @State private var selectedTab: Tab = .dashboard
    @State private var isHeroCollapsed = false
    @State private var showProfileView = false
    @State private var showNovaAssistant = false
    @State private var selectedBuilding: CoreTypes.NamedCoordinate?
    @State private var showBuildingDetail = false
    @State private var showAllBuildings = false
    @State private var showComplianceReport = false
    @State private var showMainMenu = false
    @State private var refreshID = UUID()
    @State private var selectedInsight: CoreTypes.IntelligenceInsight?
    
    // Intelligence panel state
    @State private var currentContext: ViewContext = .dashboard
    @AppStorage("clientPanelPreference") private var userPanelPreference: IntelPanelState = .collapsed
    
    // Future phase states
    @State private var voiceCommandEnabled = false
    @State private var arModeEnabled = false
    
    // Map reveal functionality
    @State private var isMapRevealed = false
    
    // MARK: - Computed Properties
    private var intelligencePanelState: IntelPanelState {
        switch currentContext {
        case .dashboard:
            return hasUrgentAlerts() ? .expanded : userPanelPreference
        case .buildingDetail:
            return .minimal
        case .compliance:
            return .minimal
        case .reports:
            return .hidden
        case .novaChat:
            return .fullscreen
        case .emergency:
            return .expanded
        }
    }
    
    private func hasUrgentAlerts() -> Bool {
        let hasCriticalInsights = novaEngine.currentInsights.contains { $0.priority == .critical }
        // TODO: Replace contextEngine with appropriate ServiceContainer intelligence services
        let hasCriticalViolations = false // Temporarily disabled - needs proper intelligence service integration
        let hasBehindSchedule = false // Temporarily disabled - needs proper routine metrics integration
        return hasCriticalInsights || hasCriticalViolations || hasBehindSchedule
    }
    
    var body: some View {
        // WRAP IN MapRevealContainer - MATCHING PATTERN!
        MapRevealContainer(
            buildings: viewModel.buildingsList,
            currentBuildingId: selectedBuilding?.id,
            focusBuildingId: selectedBuilding?.id,
            isRevealed: $isMapRevealed,
            onBuildingTap: { building in
                selectedBuilding = building
                showBuildingDetail = true
            }
        ) {
            ZStack {
                // Dark Elegance Background
                CyntientOpsDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // HeaderV3B - Client variant
                    clientHeader
                        .zIndex(100)
                    
                    // Main content area with TabView
                    TabView(selection: $selectedTab) {
                        ScrollView {
                            VStack(spacing: 16) {
                                // Collapsible Client Hero Card
                                CollapsibleClientHeroWrapper(
                                    isCollapsed: $isHeroCollapsed,
                                    routineMetrics: viewModel.realtimeRoutineMetrics,
                                    activeWorkers: viewModel.activeWorkerStatus,
                                    complianceStatus: viewModel.complianceOverview,
                                    monthlyMetrics: viewModel.monthlyMetrics,
                                    syncStatus: getSyncStatus(),
                                    onBuildingsTap: { showAllBuildings = true },
                                    onComplianceTap: { showComplianceReport = true },
                                    onBudgetTap: { /* Show financial details */ },
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
                        .tag(Tab.dashboard)

                        ClientBuildingsListView(
                            buildings: viewModel.buildingsList,
                            performanceMap: [:], // TODO: Add buildingPerformanceMap to viewModel
                            onSelectBuilding: { building in
                                selectedBuilding = building
                                showBuildingDetail = true
                            }
                        )
                        .tag(Tab.buildings)

                        ClientComplianceOverview(
                            complianceOverview: viewModel.complianceOverview,
                            issues: viewModel.complianceIssues,
                            selectedIssue: nil
                        )
                        .tag(Tab.compliance)

                        Text("Reports Tab")
                        .tag(Tab.reports)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Nova Client Intelligence Bar  
                    if intelligencePanelState != .hidden && hasIntelligenceToShow() {
                        NovaClientIntelligenceBar(
                            container: container,
                            clientContext: generateClientContext(),
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
            ClientProfileView()  // Using the correct name
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
        .sheet(isPresented: $showBuildingDetail) {
            if let building = selectedBuilding {
                BuildingDetailView(
                    buildingId: building.id,
                    buildingName: building.name,
                    buildingAddress: building.address
                )
                .onAppear { currentContext = .buildingDetail }
                .onDisappear {
                    currentContext = .dashboard
                    Task { await viewModel.refreshData() }
                }
            }
        }
        .sheet(isPresented: $showAllBuildings) {
            NavigationView {
                ClientBuildingsListView(
                    buildings: viewModel.buildingsList,
                    performanceMap: [:], // TODO: Add buildingPerformanceMap to viewModel
                    onSelectBuilding: { building in
                        selectedBuilding = building
                        showBuildingDetail = true
                        showAllBuildings = false
                    }
                )
                .navigationTitle("My Properties")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showAllBuildings = false
                        }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    }
                }
                .background(CyntientOpsDesign.DashboardColors.baseBackground)
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showComplianceReport) {
            NavigationView {
                ClientComplianceOverview(
                    complianceOverview: viewModel.complianceOverview,
                    issues: viewModel.complianceIssues,
                    selectedIssue: nil
                )
                .navigationTitle("Compliance Report")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showComplianceReport = false
                        }
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    }
                }
                .background(CyntientOpsDesign.DashboardColors.baseBackground)
            }
            .preferredColorScheme(.dark)
            .onAppear { currentContext = .compliance }
            .onDisappear { currentContext = .dashboard }
        }
        .sheet(isPresented: $showMainMenu) {
            ClientMainMenuViewV6()  // Using the correct name from ClientMainMenuView.swift
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            checkFeatureFlags()
        }
        .task {
            await viewModel.refreshData()
        }
    }
    
    // MARK: - Header Component (broken out for simplicity)
    private var clientHeader: some View {
        HeaderV3B(
            workerName: "Client", // TODO: Add clientProfile to viewModel
            nextTaskName: getMostCriticalItem()?.title,
            showClockPill: false,
            isNovaProcessing: isNovaProcessing,
            onProfileTap: { showProfileView = true },
            onNovaPress: { showNovaAssistant = true },
            onNovaLongPress: { handleNovaQuickAction() },
            onLogoTap: { showMainMenu = true },
            onClockAction: nil,
            onVoiceCommand: voiceCommandEnabled ? handleVoiceCommand : nil,
            onARModeToggle: arModeEnabled ? handleARMode : nil,
            onWearableSync: nil
        )
    }
    
    private var isNovaProcessing: Bool {
        switch novaEngine.novaState {
        case .idle: return false
        default: return true
        }
    }
    
    // MARK: - Intelligence Methods
    
    private func getCurrentInsights() -> [CoreTypes.IntelligenceInsight] {
        var insights = novaEngine.currentInsights
        
        // Behind schedule buildings
        if viewModel.realtimeRoutineMetrics.behindScheduleCount > 0 {
            let affectedBuildings = viewModel.realtimeRoutineMetrics.buildingStatuses
                .filter { $0.value.isBehindSchedule }
                .map { $0.key }
            
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "\(viewModel.realtimeRoutineMetrics.behindScheduleCount) properties behind schedule",
                description: "Service delays detected. Immediate attention recommended.",
                type: .operations,
                priority: .high,
                actionRequired: true,
                recommendedAction: "Contact operations team",
                affectedBuildings: affectedBuildings
            ))
        }
        
        // Compliance issues
        if viewModel.complianceOverview.criticalViolations > 0 {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "\(viewModel.complianceOverview.criticalViolations) compliance violations",
                description: "Critical violations require immediate resolution",
                type: .compliance,
                priority: .critical,
                actionRequired: true,
                recommendedAction: "View compliance report",
                affectedBuildings: [] // TODO: Add buildingsWithViolations to viewModel
            ))
        }
        
        // Budget alerts
        if viewModel.monthlyMetrics.budgetUtilization > 1.0 {
            let utilizationPercent = viewModel.monthlyMetrics.budgetUtilization * 100
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "Monthly spending over budget",
                description: String(format: "Current spending at %.0f%% of budget", utilizationPercent),
                type: .cost,
                priority: .medium,
                actionRequired: false,
                recommendedAction: "Review cost analysis"
            ))
        }
        
        // Cost savings - TODO: Add estimatedMonthlySavings to viewModel
        // Placeholder for cost savings insights
        
        return insights.sorted { $0.priority.priorityValue > $1.priority.priorityValue }
    }
    
    private func handleIntelligenceNavigation(_ target: IntelligencePreviewPanel.NavigationTarget) {
        switch target {
        case .buildings(_):
            showAllBuildings = true
            
        case .buildingDetail(let id):
            if let building = viewModel.buildingsList.first(where: { $0.id == id }) {
                selectedBuilding = building
                showBuildingDetail = true
            }
            
        case .compliance:
            showComplianceReport = true
            
        case .fullInsights:
            showNovaAssistant = true
            
        case .allBuildings:
            showAllBuildings = true
            
        case .taskDetail, .allTasks:
            // Not applicable for client dashboard
            break
            
        default:
            // Handle other cases as needed
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMostCriticalItem() -> (title: String, urgency: CoreTypes.AIPriority)? {
        if let criticalInsight = novaEngine.currentInsights.first(where: { $0.priority == .critical }) {
            return (criticalInsight.title, criticalInsight.priority)
        }
        
        if viewModel.complianceOverview.criticalViolations > 0 {
            return ("\(viewModel.complianceOverview.criticalViolations) compliance violations", .critical)
        }
        
        if viewModel.realtimeRoutineMetrics.behindScheduleCount > 0 {
            return ("\(viewModel.realtimeRoutineMetrics.behindScheduleCount) buildings behind", .high)
        }
        
        return nil
    }
    
    private func getSyncStatus() -> CollapsibleClientHeroWrapper.SyncStatus {
        switch viewModel.dashboardSyncStatus {
        case .synced: return .synced
        case .syncing: return .syncing(progress: 0.5)
        case .failed: return .error("Sync failed")
        case .offline: return .offline
        default: return .synced
        }
    }
    
    private func hasIntelligenceToShow() -> Bool {
        let hasBuildings = viewModel.buildingsList.count > 5
        let hasViolations = viewModel.complianceOverview.criticalViolations > 0
        let hasBehindSchedule = viewModel.realtimeRoutineMetrics.behindScheduleCount > 0
        let hasSavings = false // TODO: Add estimatedMonthlySavings to viewModel
        let hasInsights = !novaEngine.currentInsights.isEmpty
        
        return hasBuildings || hasViolations || hasBehindSchedule || hasSavings || hasInsights
    }
    
    private func handleNovaQuickAction() {
        showNovaAssistant = true
    }
    
    private func handleVoiceCommand() {
        print("Client voice command activated")
    }
    
    private func handleARMode() {
        print("Client AR mode toggled")
    }
    
    private func checkFeatureFlags() {
        #if DEBUG
        voiceCommandEnabled = false
        arModeEnabled = false
        #else
        voiceCommandEnabled = UserDefaults.standard.bool(forKey: "feature.voice.enabled")
        arModeEnabled = UserDefaults.standard.bool(forKey: "feature.ar.enabled")
        #endif
    }
    
    private func generateClientContext() -> [String: Any] {
        var context: [String: Any] = [:]
        
        // Portfolio metrics
        context["totalBuildings"] = viewModel.buildingsList.count
        context["activeWorkers"] = viewModel.activeWorkerStatus.totalActive
        context["complianceScore"] = Int(viewModel.complianceOverview.overallScore * 100)
        context["behindScheduleCount"] = viewModel.realtimeRoutineMetrics.behindScheduleCount
        context["criticalViolations"] = viewModel.complianceOverview.criticalViolations
        
        // Financial metrics
        context["budgetUtilization"] = viewModel.monthlyMetrics.budgetUtilization
        context["monthlySpend"] = viewModel.monthlyMetrics.currentSpend
        context["monthlyBudget"] = viewModel.monthlyMetrics.monthlyBudget
        
        // Performance trends
        context["routineCompletion"] = viewModel.realtimeRoutineMetrics.overallCompletion
        context["syncStatus"] = viewModel.dashboardSyncStatus.rawValue
        
        return context
    }
}

// MARK: - Collapsible Wrapper

struct CollapsibleClientHeroWrapper: View {
    @Binding var isCollapsed: Bool
    
    let routineMetrics: CoreTypes.RealtimeRoutineMetrics
    let activeWorkers: CoreTypes.ActiveWorkerStatus
    let complianceStatus: CoreTypes.ComplianceOverview
    let monthlyMetrics: CoreTypes.MonthlyMetrics
    let syncStatus: SyncStatus
    
    let onBuildingsTap: () -> Void
    let onComplianceTap: () -> Void
    let onBudgetTap: () -> Void
    let onSyncTap: () -> Void
    
    enum SyncStatus {
        case synced
        case syncing(progress: Double)
        case error(String)
        case offline
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isCollapsed {
                MinimalClientHeroCard(
                    totalBuildings: routineMetrics.buildingStatuses.count,
                    behindSchedule: routineMetrics.behindScheduleCount,
                    completionRate: routineMetrics.overallCompletion,
                    activeWorkers: activeWorkers.totalActive,
                    complianceScore: complianceStatus.overallScore,
                    budgetUtilization: monthlyMetrics.budgetUtilization,
                    onExpand: {
                        withAnimation(CyntientOpsDesign.Animations.spring) {
                            isCollapsed = false
                        }
                    }
                )
            } else {
                ZStack(alignment: .topTrailing) {
                    ClientHeroCard(
                        routineMetrics: routineMetrics,
                        activeWorkers: activeWorkers,
                        complianceStatus: complianceStatus,
                        monthlyMetrics: monthlyMetrics,
                        onBuildingTap: { _ in onBuildingsTap() }
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

// MARK: - Minimal Hero Card

struct MinimalClientHeroCard: View {
    let totalBuildings: Int
    let behindSchedule: Int
    let completionRate: Double
    let activeWorkers: Int
    let complianceScore: Double
    let budgetUtilization: Double
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
                            .opacity(hasCritical ? 0.6 : 0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: hasCritical)
                    )
                
                // Portfolio summary
                HStack(spacing: 16) {
                    ClientMetricPill(
                        value: "\(totalBuildings)",
                        label: "Properties",
                        color: CyntientOpsDesign.DashboardColors.info
                    )
                    
                    if behindSchedule > 0 {
                        ClientMetricPill(
                            value: "\(behindSchedule)",
                            label: "Behind",
                            color: CyntientOpsDesign.DashboardColors.warning
                        )
                    }
                    
                    ClientMetricPill(
                        value: "\(Int(completionRate * 100))%",
                        label: "Complete",
                        color: completionColor
                    )
                    
                    if budgetUtilization > 1.0 {
                        ClientMetricPill(
                            value: "\(Int(budgetUtilization * 100))%",
                            label: "Budget",
                            color: CyntientOpsDesign.DashboardColors.critical
                        )
                    }
                    
                    ClientMetricPill(
                        value: "\(activeWorkers)",
                        label: "Active",
                        color: CyntientOpsDesign.DashboardColors.success
                    )
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
        if behindSchedule > 0 || complianceScore < 0.7 {
            return CyntientOpsDesign.DashboardColors.critical
        } else if completionRate < 0.7 || budgetUtilization > 0.9 {
            return CyntientOpsDesign.DashboardColors.warning
        } else {
            return CyntientOpsDesign.DashboardColors.success
        }
    }
    
    private var hasCritical: Bool {
        behindSchedule > 0 || complianceScore < 0.7 || budgetUtilization > 1.0
    }
    
    private var completionColor: Color {
        if completionRate > 0.8 {
            return CyntientOpsDesign.DashboardColors.success
        } else if completionRate > 0.6 {
            return CyntientOpsDesign.DashboardColors.warning
        } else {
            return CyntientOpsDesign.DashboardColors.critical
        }
    }
}

// MARK: - Client Metric Pill

struct ClientMetricPill: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
    }
}

// MARK: - Client Profile View (Placeholder - should be defined elsewhere)

struct ClientProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Client Profile")
                    .font(.largeTitle)
                    .padding()
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(CyntientOpsDesign.DashboardColors.baseBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.clientPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

struct ClientDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview requires a ServiceContainer - would need proper mock container
        Text("ClientDashboardView Preview")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .preferredColorScheme(.dark)
    }
}
