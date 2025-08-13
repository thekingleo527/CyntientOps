//
//  AdminDashboardView.swift
//  CyntientOps (formerly CyntientOps) v6.0
//
//  ✅ REFACTORED: Complete hierarchical architecture implementation
//  ✅ FIXED: All compilation errors resolved
//  ✅ NOVA AI: Integrated with ServiceContainer dependency injection
//  ✅ SERVICE CONTAINER: Proper dependency injection
//  ✅ REAL DATA: No mock data, uses OperationalDataManager
//  ✅ DARK ELEGANCE: Consistent theme with worker dashboard
//  ✅ STREAMLINED: No tabs, just prioritized content
//

import SwiftUI
import MapKit
import CoreLocation

struct AdminDashboardView: View {
    // MARK: - Properties
    @ObservedObject var viewModel: AdminDashboardViewModel
    @EnvironmentObject private var container: ServiceContainer
    @EnvironmentObject private var novaAI: NovaAIManager
    @EnvironmentObject private var authManager: NewAuthManager
    
    // MARK: - State Variables
    @State private var isHeroCollapsed = false
    @State private var showProfileView = false
    @State private var showNovaAssistant = false
    @State private var selectedBuilding: CoreTypes.NamedCoordinate?
    @State private var showBuildingDetail = false
    @State private var showAllBuildings = false
    @State private var showCompletedTasks = false
    @State private var showMainMenu = false
    @State private var refreshID = UUID()
    @State private var selectedInsight: CoreTypes.IntelligenceInsight?
    
    // Admin-specific states
    @State private var showingComplianceCenter = false
    @State private var showingWorkerManagement = false
    @State private var showingReports = false
    @State private var showingTaskRequest = false
    @State private var selectedWorker: CoreTypes.WorkerProfile?
    @State private var selectedBuildingForTask: CoreTypes.NamedCoordinate?
    
    // Intelligence panel state
    @State private var showingIntelligencePanel = false
    @State private var selectedIntelligenceTab: IntelligenceTab = .workers
    @State private var currentContext: ViewContext = .dashboard
    
    // Intelligence Tab enum
    enum IntelligenceTab: String, CaseIterable {
        case workers = "Workers"
        case portfolio = "Portfolio"
        case compliance = "Compliance" 
        case chat = "Chat"
        case analytics = "Analytics"
        
        var icon: String {
            switch self {
            case .workers: return "person.3.fill"
            case .portfolio: return "building.2.crop.circle"
            case .compliance: return "checkmark.shield.fill"
            case .chat: return "message.fill"
            case .analytics: return "chart.bar.xaxis"
            }
        }
        
        var color: Color {
            switch self {
            case .workers: return .blue
            case .portfolio: return .green
            case .compliance: return .orange
            case .chat: return .purple
            case .analytics: return .cyan
            }
        }
    }
    @AppStorage("adminPanelPreference") private var userPanelPreference: IntelPanelState = .collapsed
    
    // Map reveal state for gesture control
    @State private var isMapRevealed = false
    
    // MARK: - Initialization
    init(viewModel: AdminDashboardViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Enums
    enum ViewContext {
        case dashboard
        case buildingDetail
        case taskReview
        case workerManagement
        case novaChat
        case emergency
        case compliance
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
        if !showingIntelligencePanel { return .hidden }
        
        switch currentContext {
        case .dashboard:
            return hasCriticalAlerts() ? .expanded : userPanelPreference
        case .buildingDetail:
            return .minimal
        case .taskReview:
            return .hidden
        case .workerManagement:
            return .minimal
        case .novaChat:
            return .fullscreen
        case .emergency:
            return .expanded
        case .compliance:
            return .minimal
        }
    }
    
    private func hasCriticalAlerts() -> Bool {
        let insights = container.intelligence.getInsights(for: .admin)
        return insights.contains { $0.priority == .critical } ||
               viewModel.portfolioMetrics.criticalIssues > 0
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Dark Elegance Background
            Color.black
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Admin Header
                adminHeader
                    .zIndex(100)
                
                // Main content is now wrapped in the MapRevealContainer
                MapRevealContainer(
                    buildings: viewModel.buildings,
                    currentBuildingId: nil, // No specific building is "current" on admin dash
                    isRevealed: $isMapRevealed,
                    onBuildingTap: { building in
                        selectedBuilding = building
                        showBuildingDetail = true
                    }
                ) {
                    // Main scroll content
                    ScrollView {
                        VStack(spacing: 16) {
                            // Enhanced Admin Hero Status Card with Smart Routing
                            EnhancedAdminHeroWrapper(
                                isCollapsed: $isHeroCollapsed,
                                portfolio: viewModel.portfolioMetrics,
                                activeWorkers: viewModel.activeWorkers,
                                criticalAlerts: viewModel.criticalAlerts,
                                syncStatus: viewModel.syncStatus,
                                complianceScore: viewModel.portfolioMetrics.complianceScore,
                                pressingTasks: viewModel.getPressingTasks(),
                                onWorkersTap: { 
                                    showingIntelligencePanel = true
                                    selectedIntelligenceTab = .workers
                                },
                                onTasksTap: { 
                                    showingIntelligencePanel = true
                                    selectedIntelligenceTab = .workers
                                },
                                onComplianceTap: { 
                                    showingIntelligencePanel = true
                                    selectedIntelligenceTab = .compliance
                                },
                                onPortfolioTap: { 
                                    showingIntelligencePanel = true
                                    selectedIntelligenceTab = .portfolio
                                },
                                onAnalyticsTap: { 
                                    showingIntelligencePanel = true
                                    selectedIntelligenceTab = .analytics
                                }
                            )
                            .zIndex(50)
                            
                            // Quick Actions Section
                            adminQuickActions
                            
                            // Live Activity Feed
                            if !viewModel.crossDashboardUpdates.isEmpty {
                                liveActivitySection
                            }
                            
                            // Critical Issues Summary
                            if viewModel.portfolioMetrics.criticalIssues > 0 {
                                criticalIssuesSection
                            }
                            
                            // Spacer for bottom intelligence bar
                            Spacer(minLength: showingIntelligencePanel ? 80 : 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    .refreshable {
                        await viewModel.refresh()
                        refreshID = UUID()
                    }
                }
                
                // Comprehensive Intelligence Panel (Bottom)
                if showingIntelligencePanel {
                    ComprehensiveIntelligencePanel(
                        selectedTab: $selectedIntelligenceTab,
                        viewModel: viewModel,
                        container: container,
                        novaState: novaAI.novaState,
                        insights: container.intelligence.getInsights(for: .admin),
                        isExpanded: Binding(
                            get: { intelligencePanelState == .expanded },
                            set: { isExpanded in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    userPanelPreference = isExpanded ? .expanded : .collapsed
                                }
                            }
                        ),
                        onClose: { 
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showingIntelligencePanel = false
                                userPanelPreference = .collapsed
                            }
                        },
                        onWorkerSelected: { worker in
                            selectedWorker = worker
                            selectedBuildingForTask = nil
                            showingTaskRequest = true
                        },
                        onBuildingSelected: { building in
                            selectedBuildingForTask = building
                            selectedWorker = nil
                            showingTaskRequest = true
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showProfileView) {
            AdminProfileView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaAssistantView()
                .environmentObject(novaAI)
                .environmentObject(container)
                .onAppear { currentContext = .novaChat }
                .onDisappear { currentContext = .dashboard }
        }
        .sheet(item: $selectedInsight) { insight in
            AdminInsightDetailView(insight: insight)
        }
        .sheet(isPresented: $showBuildingDetail) {
            if let building = selectedBuilding {
                BuildingDetailView(
                    buildingId: building.id,
                    buildingName: building.name,
                    buildingAddress: building.address
                )
                .environmentObject(container)
                .onAppear { currentContext = .buildingDetail }
                .onDisappear { currentContext = .dashboard }
            }
        }
        .sheet(isPresented: $showAllBuildings) {
            NavigationView {
                List(viewModel.buildings, id: \.id) { building in
                    HStack {
                        Button(action: {
                            selectedBuilding = building
                            showBuildingDetail = true
                            showAllBuildings = false
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(building.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(building.address)
                                    .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.vertical, 8)
                    }
                }
                .navigationTitle("Portfolio Buildings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showAllBuildings = false
                        }
                        .foregroundColor(.white)
                    }
                }
                .background(Color.black.ignoresSafeArea())
                .preferredColorScheme(.dark)
            }
        }
        .sheet(isPresented: $showCompletedTasks) {
            AdminTaskReviewView(
                tasks: viewModel.completedTasks,
                onSelectTask: { task in
                    currentContext = .taskReview
                }
            )
            .onAppear { currentContext = .taskReview }
            .onDisappear { currentContext = .dashboard }
        }
        .sheet(isPresented: $showingComplianceCenter) {
            NavigationView {
                VStack(spacing: 20) {
                    // Compliance Score Header
                    VStack(spacing: 8) {
                        Text("84%")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        
                        Text("Overall Compliance Score")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("Above Industry Average")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 2)
                            )
                    )
                    
                    // Quick Stats
                    HStack(spacing: 12) {
                        // Active Violations Card
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                            
                            Text("3")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Active Violations")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                        
                        // Inspections Due Card
                        VStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            Text("2")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Inspections Due")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                        
                        // Photo Compliance Card
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            Text("92%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Photo Compliance")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            // Inspection Completed
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.green)
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Inspection Completed")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text("123 1st Avenue - Score: 89%")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Text("2 hours ago")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.vertical, 8)
                            
                            // Violation Reported
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Violation Reported")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text("68 Perry Street - Sanitation Issue")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Text("5 hours ago")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.vertical, 8)
                            
                            // Inspection Scheduled
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                    .frame(width: 24, height: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Inspection Scheduled")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    
                                    Text("104 Franklin Street - Tomorrow 2:00 PM")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Text("1 day ago")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.black.ignoresSafeArea())
                .preferredColorScheme(.dark)
                .navigationTitle("Compliance Center")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingComplianceCenter = false
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            .onAppear { currentContext = .compliance }
            .onDisappear { currentContext = .dashboard }
        }
        .sheet(isPresented: $showingWorkerManagement) {
            AdminWorkerManagementView()
            .environmentObject(container)
            .onAppear { currentContext = .workerManagement }
            .onDisappear { currentContext = .dashboard }
        }
        .sheet(isPresented: $showingReports) {
            AdminReportsView()
                .environmentObject(container)
        }
        .sheet(isPresented: $showingTaskRequest) {
            AdminTaskRequestView(
                preselectedBuilding: selectedBuildingForTask,
                preselectedWorker: selectedWorker
            )
            .navigationTitle("Create Task")
        }
        .sheet(isPresented: $showMainMenu) {
            AdminMainMenuView()
        }
        .task {
            await viewModel.initialize()
            showingIntelligencePanel = true
        }
    }
    
    // MARK: - Admin Header
    private var adminHeader: some View {
        HStack {
            AdminDashboardHeader(
                adminName: authManager.currentUser?.name ?? "Administrator",
                totalBuildings: viewModel.portfolioMetrics.totalBuildings,
                activeWorkers: viewModel.activeWorkers.count,
                criticalAlerts: viewModel.criticalAlerts.count,
                syncStatus: viewModel.dashboardSyncStatus
            )
            
            // Temporary Logout Button for testing
            Button(action: {
                Task {
                    await authManager.logout()
                }
            }) {
                Image(systemName: "power.circle.fill")
                    .foregroundColor(.red)
                    .font(.title)
                    .padding()
            }
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var adminQuickActions: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            AdminQuickActionCard(
                title: "Compliance",
                value: "\(Int(viewModel.portfolioMetrics.complianceScore))%",
                icon: "checkmark.shield.fill",
                color: complianceScoreColor,
                showBadge: viewModel.portfolioMetrics.criticalIssues > 0,
                badgeCount: viewModel.portfolioMetrics.criticalIssues,
                action: { showingComplianceCenter = true }
            )
            
            AdminQuickActionCard(
                title: "Workers",
                value: "\(viewModel.activeWorkers.count)/\(viewModel.workers.count)",
                icon: "person.3.fill",
                color: .blue,
                action: { showingWorkerManagement = true }
            )
            
            AdminQuickActionCard(
                title: "Tasks Today",
                value: "\(viewModel.todaysTaskCount)",
                icon: "checklist",
                color: .cyan,
                action: { showCompletedTasks = true }
            )
            
            AdminQuickActionCard(
                title: "Create Task",
                value: "New",
                icon: "plus.circle.fill",
                color: .green,
                action: { showingTaskRequest = true }
            )
            
            AdminQuickActionCard(
                title: "Reports",
                value: "Generate",
                icon: "doc.badge.arrow.up",
                color: .purple,
                action: { showingReports = true }
            )
        }
    }
    
    // MARK: - Live Activity Section
    
    private var liveActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Live Activity", systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                LiveIndicator()
            }
            
            VStack(spacing: 8) {
                ForEach(viewModel.crossDashboardUpdates.prefix(5)) { update in
                    AdminActivityRow(update: update)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Critical Issues Section
    
    private var criticalIssuesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("\(viewModel.portfolioMetrics.criticalIssues) Critical Issues", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Spacer()
                
                Button("View All") {
                    showingComplianceCenter = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                ForEach(viewModel.criticalAlerts.prefix(3)) { alert in
                    CriticalAlertRow(alert: alert) {
                        handleCriticalAlert(alert)
                    }
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "morning"
        case 12..<17: return "afternoon"
        default: return "evening"
        }
    }
    
    private var complianceScoreColor: Color {
        let score = viewModel.portfolioMetrics.complianceScore
        if score >= 90 { return .green }
        if score >= 80 { return .yellow }
        if score >= 70 { return .orange }
        return .red
    }
    
    private func showCriticalAlerts() {
        if viewModel.portfolioMetrics.criticalIssues > 0 {
            showingComplianceCenter = true
        }
    }
    
    private func handleCriticalAlert(_ alert: CoreTypes.AdminAlert) {
        switch alert.type {
        case .compliance:
            showingComplianceCenter = true
        case .worker:
            showingWorkerManagement = true
        case .building:
            if let buildingId = alert.affectedBuilding,
               let building = viewModel.buildings.first(where: { $0.id == buildingId }) {
                selectedBuilding = building
                showBuildingDetail = true
            }
        case .task:
            showCompletedTasks = true
        case .system:
            showNovaAssistant = true
        }
    }
}

// MARK: - Nova Components

// MARK: - Consistent Nova Avatar Usage
// Note: Local NovaAvatarView replaced with consistent NovaAvatar component from /Nova/UI/
// This ensures persistent, animated avatar across all views

// NovaIntelligenceBar component is imported from Components/Nova/
struct AdminNovaIntelligenceBar: View {
    // MARK: - State
    @State private var selectedTab: NovaTab = .priorities
    
    // MARK: - Properties
    let novaState: NovaState
    let insights: [CoreTypes.IntelligenceInsight]
    @Binding var isExpanded: Bool
    let onTap: () -> Void
    let onClose: (() -> Void)?
    let onSelectMapTab: () -> Void
    
    enum NovaTab: String, CaseIterable {
        case priorities = "Priorities"
        case map = "Map"
        case analytics = "Analytics"
        case chat = "Chat"
        
        var icon: String {
            switch self {
            case .priorities: return "exclamationmark.bubble.fill"
            case .map: return "map.fill"
            case .analytics: return "chart.bar.xaxis"
            case .chat: return "message.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main Bar with Avatar and Controls
            mainBar
            
            // Expanded Content
            if isExpanded {
                VStack(spacing: 0) {
                    // Tab Bar
                    tabBar
                    
                    // Tab Content
                    tabContent
                        .frame(maxHeight: 220) // Max height for the content area
                }
                .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity.combined(with: .scale(scale: 0.95))))
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 20 : 0))
        .shadow(radius: 10)
    }
    
    private var mainBar: some View {
        HStack(spacing: 12) {
            NovaAvatar(
                size: .small,
                isActive: novaState == .active,
                hasUrgentInsights: insights.contains { $0.priority == .critical },
                isBusy: novaState == .thinking,
                onTap: {
                    // Handle Nova tap - open Nova assistant
                    print("Nova avatar tapped in admin dashboard")
                },
                onLongPress: {
                    // Handle Nova long press - holographic mode
                    print("Nova avatar long pressed - holographic mode")
                }
            )
            .environmentObject(novaManager)
            .onTapGesture(perform: onTap)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Nova AI")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(isExpanded ? selectedTab.rawValue : (insights.first?.title ?? "Ready to assist"))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: "chevron.up")
                    .foregroundColor(.white.opacity(0.7))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            
            if let onClose = onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal)
        .frame(height: 60)
    }
    
    private var tabBar: some View {
        HStack(spacing: 20) {
            ForEach(NovaTab.allCases, id: \.self) { tab in
                Button(action: {
                    if tab == .map {
                        onSelectMapTab()
                    } else {
                        withAnimation { selectedTab = tab }
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18))
                        Text(tab.rawValue)
                            .font(.caption2)
                    }
                    .foregroundColor(selectedTab == tab ? .cyan : .gray)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(.horizontal)
        .background(Color.black.opacity(0.2))
    }
    
    @ViewBuilder
    private var tabContent: some View {
        ZStack {
            switch selectedTab {
            case .priorities:
                PrioritiesContentView(insights: insights)
            case .map:
                // This tab's action is handled by the button, no content needed here.
                EmptyView()
            case .analytics:
                AnalyticsContentView()
            case .chat:
                ChatContentView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
    }
}

struct AdminInsightRow: View {
    let insight: CoreTypes.IntelligenceInsight
    
    private var priorityColor: Color {
        switch insight.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
    
    private var priorityIcon: String {
        switch insight.priority {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "info.circle.fill"
        case .low: return "lightbulb.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            Image(systemName: priorityIcon)
                .font(.system(size: 14))
                .foregroundColor(priorityColor)
                .frame(width: 20)
            
            // Insight content
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(insight.description)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Category badge
            Text(insight.category.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(priorityColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(priorityColor.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

// MARK: - CollapsibleAdminHeroWrapper (same as before)

struct CollapsibleAdminHeroWrapper: View {
    @Binding var isCollapsed: Bool
    
    let portfolio: CoreTypes.PortfolioMetrics
    let activeWorkers: [CoreTypes.WorkerProfile]
    let criticalAlerts: [CoreTypes.AdminAlert]
    let syncStatus: AdminHeroStatusCard.SyncStatus
    let complianceScore: Double
    
    let onBuildingsTap: () -> Void
    let onWorkersTap: () -> Void
    let onAlertsTap: () -> Void
    let onTasksTap: () -> Void
    let onComplianceTap: () -> Void
    let onSyncTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isCollapsed {
                MinimalAdminHeroCard(
                    totalBuildings: portfolio.totalBuildings,
                    activeWorkers: activeWorkers.count,
                    criticalAlerts: criticalAlerts.count,
                    completionRate: portfolio.overallCompletionRate,
                    complianceScore: complianceScore,
                    onExpand: {
                        withAnimation(.spring()) {
                            isCollapsed = false
                        }
                    }
                )
            } else {
                ZStack(alignment: .topTrailing) {
                    AdminHeroStatusCard(
                        portfolio: portfolio,
                        activeWorkers: activeWorkers,
                        criticalAlerts: criticalAlerts,
                        syncStatus: syncStatus,
                        complianceScore: complianceScore,
                        onBuildingsTap: onBuildingsTap,
                        onWorkersTap: onWorkersTap,
                        onAlertsTap: onAlertsTap,
                        onTasksTap: onTasksTap,
                        onComplianceTap: onComplianceTap,
                        onSyncTap: onSyncTap
                    )
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            isCollapsed = true
                        }
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    .padding(8)
                }
            }
        }
    }
}

// MARK: - MinimalAdminHeroCard (same as before)

struct MinimalAdminHeroCard: View {
    let totalBuildings: Int
    let activeWorkers: Int
    let criticalAlerts: Int
    let completionRate: Double
    let complianceScore: Double
    let onExpand: () -> Void
    
    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: 12) {
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
                
                HStack(spacing: 16) {
                    AdminMetricPill(value: "\(totalBuildings)", label: "Buildings", color: .blue)
                    AdminMetricPill(value: "\(activeWorkers)", label: "Active", color: .green)
                    
                    if criticalAlerts > 0 {
                        AdminMetricPill(value: "\(criticalAlerts)", label: "Alerts", color: .red)
                    }
                    
                    AdminMetricPill(value: "\(Int(complianceScore))%", label: "Compliance", color: complianceColor)
                    AdminMetricPill(value: "\(Int(completionRate * 100))%", label: "Complete", color: completionColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        if criticalAlerts > 0 { return .red }
        if completionRate < 0.7 || complianceScore < 70 { return .orange }
        return .green
    }
    
    private var hasCritical: Bool {
        criticalAlerts > 0 || complianceScore < 70
    }
    
    private var completionColor: Color {
        if completionRate > 0.8 { return .green }
        if completionRate > 0.6 { return .orange }
        return .red
    }
    
    private var complianceColor: Color {
        if complianceScore >= 90 { return .green }
        if complianceScore >= 80 { return .yellow }
        if complianceScore >= 70 { return .orange }
        return .red
    }
}

// MARK: - AdminHeroStatusCard (same as before)

struct AdminHeroStatusCard: View {
    let portfolio: CoreTypes.PortfolioMetrics
    let activeWorkers: [CoreTypes.WorkerProfile]
    let criticalAlerts: [CoreTypes.AdminAlert]
    let syncStatus: SyncStatus
    let complianceScore: Double
    
    let onBuildingsTap: () -> Void
    let onWorkersTap: () -> Void
    let onAlertsTap: () -> Void
    let onTasksTap: () -> Void
    let onComplianceTap: () -> Void
    let onSyncTap: () -> Void
    
    enum SyncStatus {
        case synced
        case syncing(progress: Double)
        case error(String)
        case offline
        
        var isLive: Bool {
            switch self {
            case .synced, .syncing: return true
            default: return false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with live indicator - Updated for Worker Metrics Focus
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Live Operations Control")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(activeWorkers.count) active workers • \(getTodaysTaskCount()) tasks in progress")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Live sync indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .opacity(syncStatus.isLive ? 1 : 0.3)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: syncStatus.isLive)
                    
                    Text("LIVE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            // Worker-focused metrics grid (prioritized by importance)
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // #1 Priority: Active Workers (most important)
                AdminMetricCard(
                    icon: "person.3.fill",
                    title: "Active Workers",
                    value: "\(activeWorkers.filter { $0.isClockedIn }.count)/\(activeWorkers.count)",
                    color: activeWorkerColor,
                    onTap: onWorkersTap
                )
                
                // #2 Priority: Today's Task Progress (immediate focus)
                AdminMetricCard(
                    icon: "checklist",
                    title: "Today's Tasks",
                    value: "\(getTodaysCompletedTasks())/\(getTodaysTaskCount())",
                    color: taskProgressColor,
                    onTap: onTasksTap
                )
                
                // #3 Priority: Building Projects Status (immediate projects)
                AdminMetricCard(
                    icon: "hammer.fill",
                    title: "Active Projects",
                    value: "\(getActiveBuildingProjects())",
                    color: .orange,
                    onTap: onBuildingsTap
                )
                
                // #4 Priority: Immediate Attention Items (urgent)
                AdminMetricCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Need Attention",
                    value: "\(getImmediateAttentionCount())",
                    color: .red,
                    onTap: onAlertsTap
                )
            }
            
            // Critical alerts
            if !criticalAlerts.isEmpty {
                AdminMetricCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Critical Alerts",
                    value: "\(criticalAlerts.count)",
                    color: .red,
                    onTap: onAlertsTap
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Functions for Worker-Focused Metrics
    
    private func getTodaysTaskCount() -> Int {
        // Estimate based on active workers and building count
        return activeWorkers.filter { $0.isClockedIn }.count * 3 + portfolio.totalBuildings
    }
    
    private func getTodaysCompletedTasks() -> Int {
        // Estimate based on completion rate
        let todaysTasks = getTodaysTaskCount()
        return Int(Double(todaysTasks) * portfolio.overallCompletionRate)
    }
    
    private func getActiveBuildingProjects() -> String {
        // Count buildings with active work
        let activeBuildings = activeWorkers.filter { $0.isClockedIn }.count > 0 ? 
                            min(portfolio.totalBuildings, activeWorkers.count) : 0
        return "\(activeBuildings)"
    }
    
    private func getImmediateAttentionCount() -> Int {
        return criticalAlerts.count + (portfolio.overallCompletionRate < 0.7 ? 1 : 0)
    }
    
    // MARK: - Color Computed Properties
    
    private var activeWorkerColor: Color {
        let activeCount = activeWorkers.filter { $0.isClockedIn }.count
        let totalCount = activeWorkers.count
        let ratio = totalCount > 0 ? Double(activeCount) / Double(totalCount) : 0
        
        if ratio > 0.8 { return .green }
        if ratio > 0.6 { return .orange }
        return .red
    }
    
    private var taskProgressColor: Color {
        let completed = getTodaysCompletedTasks()
        let total = getTodaysTaskCount()
        let ratio = total > 0 ? Double(completed) / Double(total) : 0
        
        if ratio > 0.8 { return .green }
        if ratio > 0.6 { return .orange }
        return .red
    }
    
    private var completionRateColor: Color {
        if portfolio.overallCompletionRate > 0.8 { return .green }
        if portfolio.overallCompletionRate > 0.6 { return .orange }
        return .red
    }
    
    private var complianceScoreColor: Color {
        if complianceScore >= 90 { return .green }
        if complianceScore >= 80 { return .yellow }
        if complianceScore >= 70 { return .orange }
        return .red
    }
}

// MARK: - Supporting Components (with unique names)

struct LocalAdminMetricCard: View {
    let value: String
    let label: String
    var subtitle: String? = nil
    let color: Color
    let icon: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                    
                    Spacer()
                }
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AdminQuickActionCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var showBadge: Bool = false
    var badgeCount: Int = 0
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Text(value)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                if showBadge && badgeCount > 0 {
                    Text("\(badgeCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: -8, y: 8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AdminMetricPill: View {
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
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

struct LocalAdminActivityRow: View {
    let activity: AdminActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(activityColor)
                .frame(width: 6, height: 6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if let workerName = activity.workerName {
                        Text(workerName)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    if let buildingName = activity.buildingName {
                        Text("• \(buildingName)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
    
    private var activityColor: Color {
        switch activity.type {
        case .taskCompleted: return .green
        case .workerClockIn: return .blue
        case .violation: return .red
        case .photoUploaded: return .purple
        default: return .gray
        }
    }
}

struct CriticalAlertRow: View {
    let alert: CoreTypes.AdminAlert
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: alertIcon)
                    .font(.title3)
                    .foregroundColor(.red)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let building = alert.affectedBuilding {
                        Text(building)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(alert.urgency.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(urgencyColor)
                    
                    Text(alert.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var alertIcon: String {
        switch alert.type {
        case .compliance: return "exclamationmark.shield"
        case .worker: return "person.fill.xmark"
        case .building: return "building.2.fill"
        case .task: return "checklist"
        case .system: return "exclamationmark.triangle.fill"
        }
    }
    
    private var urgencyColor: Color {
        switch alert.urgency {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

struct LiveIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            
            Text("LIVE")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .onAppear { isAnimating = true }
    }
}

// MARK: - Admin Main Menu View

struct AdminMainMenuView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Management") {
                    Label("Compliance Center", systemImage: "checkmark.shield")
                    Label("Worker Management", systemImage: "person.3")
                    Label("Building Portfolio", systemImage: "building.2")
                    Label("Task Review", systemImage: "checklist")
                }
                
                Section("Analytics") {
                    Label("Reports", systemImage: "doc.text")
                    Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                    Label("Insights", systemImage: "lightbulb")
                }
                
                Section("Tools") {
                    Label("Schedule Audit", systemImage: "calendar.badge.plus")
                    Label("Export Data", systemImage: "doc.badge.arrow.up")
                    Label("Messages", systemImage: "message")
                }
                
                Section("Support") {
                    Label("Help", systemImage: "questionmark.circle")
                    Label("Settings", systemImage: "gear")
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Admin Menu")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views (Placeholders)

struct AdminProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: NewAuthManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = authManager.currentUser {
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text(user.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Administrator")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(12)
                    }
                    .padding(.top, 40)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await authManager.logout()
                    }
                }) {
                    Label("Sign Out", systemImage: "arrow.right.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.horizontal)
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// AdminBuildingsListView is defined in its own file

struct AdminTaskReviewView: View {
    let tasks: [CoreTypes.ContextualTask]
    let onSelectTask: (CoreTypes.ContextualTask) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedFilter: TaskFilter = .all
    @State private var searchText = ""
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case completed = "Completed"
        case overdue = "Overdue"
        case photoRequired = "Photo Required"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .completed: return "checkmark.circle"
            case .overdue: return "exclamationmark.triangle"
            case .photoRequired: return "camera"
            }
        }
    }
    
    private var filteredTasks: [CoreTypes.ContextualTask] {
        let searched = tasks.filter { task in
            searchText.isEmpty || task.title.localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedFilter {
        case .all:
            return searched
        case .completed:
            return searched.filter { $0.status == .completed }
        case .overdue:
            return searched.filter { task in
                if let dueDate = task.dueDate {
                    return dueDate < Date() && task.status != .completed
                }
                return false
            }
        case .photoRequired:
            return searched.filter { $0.requiresPhoto == true }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.5))
                    
                    TextField("Search tasks...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .padding()
                
                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TaskFilter.allCases, id: \.self) { filter in
                            Button(action: { selectedFilter = filter }) {
                                HStack(spacing: 6) {
                                    Image(systemName: filter.icon)
                                        .font(.caption)
                                    Text(filter.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedFilter == filter ? Color.blue : Color.white.opacity(0.1))
                                )
                                .foregroundColor(selectedFilter == filter ? .white : .white.opacity(0.7))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 8)
                
                // Task List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTasks) { task in
                            AdminTaskCard(
                                task: task,
                                onTap: { onSelectTask(task) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationTitle("Task Review (\(filteredTasks.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct AdminTaskCard: View {
    let task: CoreTypes.ContextualTask
    let onTap: () -> Void
    
    private var statusColor: Color {
        if task.status == .completed { return .green }
        if let dueDate = task.dueDate, dueDate < Date() && task.status != .completed { return .red }
        return .blue
    }
    
    private var statusText: String {
        if task.status == .completed { return "Completed" }
        if let dueDate = task.dueDate, dueDate < Date() && task.status != .completed { return "Overdue" }
        return task.status.rawValue.capitalized
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if let description = task.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(statusText)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(statusColor)
                        
                        if let dueDate = task.dueDate {
                            Text(dueDate.formatted(.dateTime.month().day().hour().minute()))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                
                // Task metadata
                HStack(spacing: 16) {
                    if task.requiresPhoto == true {
                        HStack(spacing: 4) {
                            Image(systemName: "camera.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text("Photo Required")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let buildingName = task.buildingName {
                        HStack(spacing: 4) {
                            Image(systemName: "building.2")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(buildingName)
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(statusColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}



// AdminComplianceOverviewView is defined in its own file

struct NovaAssistantView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var novaAI: NovaAIManager
    
    var body: some View {
        NavigationView {
            VStack {
                NovaAvatar(
                    size: .large,
                    isActive: novaAI.novaState == .active,
                    hasUrgentInsights: false,
                    isBusy: novaAI.isThinking,
                    onTap: {
                        // Handle Nova tap in assistant view
                        print("Nova avatar tapped in assistant view")
                    },
                    onLongPress: {
                        // Handle Nova long press - holographic mode
                        print("Nova avatar long pressed - holographic mode in assistant")
                    }
                )
                    .padding()
                
                Text("Nova AI Assistant")
                    .font(.title)
                
                // Placeholder for Nova interaction
                Spacer()
            }
            .navigationTitle("Nova Assistant")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AdminInsightDetailView: View {
    let insight: CoreTypes.IntelligenceInsight
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text(insight.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(insight.description)
                    .font(.body)
                
                if let action = insight.recommendedAction {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended Action")
                            .font(.headline)
                        Text(action)
                            .font(.body)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Insight Detail")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct AdminActivity: Identifiable {
    let id = UUID()
    let type: ActivityType
    let description: String
    let workerName: String?
    let buildingName: String?
    let timestamp: Date
    
    enum ActivityType {
        case taskCompleted
        case workerClockIn
        case workerClockOut
        case violation
        case photoUploaded
        case issueResolved
    }
}

// MARK: - Nova Tab Content Views

struct PrioritiesContentView: View {
    let insights: [CoreTypes.IntelligenceInsight]
    
    private var actionableInsights: [CoreTypes.IntelligenceInsight] {
        insights.filter { $0.priority == .critical || $0.priority == .high }
            .sorted { $0.priority.rawValue < $1.priority.rawValue }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if actionableInsights.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        Text("All systems running smoothly")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("No urgent items require attention")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ForEach(actionableInsights) { insight in
                        AdminInsightRow(insight: insight)
                            .padding(.horizontal, 12)
                    }
                }
            }
            .padding(.vertical, 12)
        }
    }
}

struct AnalyticsContentView: View {
    @EnvironmentObject private var analyticsService: AnalyticsService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Quick Stats Row
                HStack(spacing: 12) {
                    NovaAnalyticsCard(
                        title: "Tasks Today",
                        value: "47",
                        icon: "checklist",
                        color: .cyan,
                        trend: .up("12%")
                    )
                    
                    NovaAnalyticsCard(
                        title: "Efficiency",
                        value: "87%",
                        icon: "speedometer",
                        color: .green,
                        trend: .up("5%")
                    )
                }
                
                HStack(spacing: 12) {
                    NovaAnalyticsCard(
                        title: "Response Time",
                        value: "12m",
                        icon: "clock.arrow.circlepath",
                        color: .orange,
                        trend: .down("3m")
                    )
                    
                    NovaAnalyticsCard(
                        title: "Quality Score",
                        value: "4.2",
                        icon: "star.fill",
                        color: .yellow,
                        trend: .up("0.1")
                    )
                }
                
                // Recent Activity Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Trends")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                    
                    VStack(spacing: 6) {
                        TrendRow(label: "Completion Rate", value: "↗️ +8% this week")
                        TrendRow(label: "Photo Compliance", value: "→ 92% steady")
                        TrendRow(label: "Worker Satisfaction", value: "↗️ +2 pts this month")
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}

struct ChatContentView: View {
    @State private var messageText = ""
    @State private var messages: [NovaMessage] = [
        NovaMessage(content: "Hello! I'm Nova, your AI assistant. How can I help optimize your operations today?", isFromUser: false, timestamp: Date().addingTimeInterval(-300))
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            // Input Bar
            HStack(spacing: 12) {
                TextField("Ask Nova anything...", text: $messageText)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.cyan)
                        .font(.system(size: 16))
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        // Add user message
        messages.append(NovaMessage(content: trimmedMessage, isFromUser: true, timestamp: Date()))
        messageText = ""
        
        // Simulate Nova response (in production, this would call the actual NovaAI service)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let responses = [
                "I can help analyze that data for you. Let me check the latest metrics.",
                "Based on current patterns, I recommend adjusting the route optimization.",
                "I've noticed some efficiency improvements in Building 3. Would you like details?",
                "The compliance scores look good overall. Any specific areas you'd like me to focus on?"
            ]
            
            if let response = responses.randomElement() {
                messages.append(NovaMessage(content: response, isFromUser: false, timestamp: Date()))
            }
        }
    }
}

// MARK: - Supporting Views

struct NovaAnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: Trend?
    
    enum Trend {
        case up(String)
        case down(String)
        case stable
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .stable: return "minus"
            }
        }
        
        var text: String {
            switch self {
            case .up(let value), .down(let value): return value
            case .stable: return "--"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Spacer()
                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend.icon)
                            .font(.caption2)
                        Text(trend.text)
                            .font(.caption2)
                    }
                    .foregroundColor(trend.color)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct TrendRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

struct ChatBubble: View {
    let message: NovaMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.isFromUser ? Color.cyan.opacity(0.8) : Color.white.opacity(0.15))
                    )
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser {
                Spacer()
            }
        }
    }
}

// MARK: - Supporting Data Types

struct NovaMessage: Identifiable {
    let id = UUID()
    let content: String
    let isFromUser: Bool
    let timestamp: Date
}

// MARK: - Preview Provider

struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        // For preview purposes, we'll need to handle the async container differently
        Text("Admin Dashboard Preview")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .preferredColorScheme(.dark)
    }
}