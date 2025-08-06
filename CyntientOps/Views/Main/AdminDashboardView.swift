//
//  AdminDashboardView.swift
//  CyntientOps (formerly CyntientOps) v6.0
//
//  ✅ REFACTORED: Complete hierarchical architecture implementation
//  ✅ FIXED: All compilation errors resolved
//  ✅ NOVA AI: Integrated with NovaAIManager singleton
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
    @State private var selectedWorker: CoreTypes.WorkerProfile?
    
    // Intelligence panel state
    @State private var showingIntelligencePanel = false
    @State private var currentContext: ViewContext = .dashboard
    @AppStorage("adminPanelPreference") private var userPanelPreference: IntelPanelState = .collapsed
    
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
                
                // Main scroll content
                ScrollView {
                    VStack(spacing: 16) {
                        // Collapsible Admin Hero Status Card
                        CollapsibleAdminHeroWrapper(
                            isCollapsed: $isHeroCollapsed,
                            portfolio: viewModel.portfolioMetrics,
                            activeWorkers: viewModel.activeWorkers,
                            criticalAlerts: viewModel.criticalAlerts,
                            syncStatus: viewModel.syncStatus,
                            complianceScore: viewModel.portfolioMetrics.complianceScore,
                            onBuildingsTap: { showAllBuildings = true },
                            onWorkersTap: { showingWorkerManagement = true },
                            onAlertsTap: { showCriticalAlerts() },
                            onTasksTap: { showCompletedTasks = true },
                            onComplianceTap: { showingComplianceCenter = true },
                            onSyncTap: { Task { await viewModel.refresh() } }
                        )
                        .zIndex(50)
                        
                        // Quick Actions Section
                        adminQuickActions
                        
                        // Live Activity Feed
                        if !viewModel.recentActivity.isEmpty {
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
                
                // Nova Intelligence Bar (Bottom)
                if showingIntelligencePanel {
                    AdminNovaIntelligenceBar(
                        novaState: novaAI.novaState,
                        insights: container.intelligence.getInsights(for: .admin),
                        isExpanded: .constant(intelligencePanelState == .expanded),
                        onTap: { showNovaAssistant = true }
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
            AdminBuildingsListView(
                buildings: viewModel.buildings,
                onSelectBuilding: { building in
                    selectedBuilding = building
                    showBuildingDetail = true
                    showAllBuildings = false
                }
            )
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
            AdminComplianceOverviewView()
                .environmentObject(container)
                .onAppear { currentContext = .compliance }
                .onDisappear { currentContext = .dashboard }
        }
        .sheet(isPresented: $showingWorkerManagement) {
            AdminWorkerManagementView(
                workers: viewModel.workers,
                onSelectWorker: { worker in
                    selectedWorker = worker
                }
            )
            .environmentObject(container)
            .onAppear { currentContext = .workerManagement }
            .onDisappear { currentContext = .dashboard }
        }
        .sheet(isPresented: $showingReports) {
            AdminReportsView()
                .environmentObject(container)
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
            // Logo/Menu
            Button(action: { showMainMenu = true }) {
                Image("AppIcon") // Or menu icon
                    .resizable()
                    .frame(width: 32, height: 32)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Good \(timeOfDay), \(authManager.currentWorkerName)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Portfolio Overview")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Nova AI Indicator
            Button(action: { showNovaAssistant = true }) {
                NovaAvatarView(
                    state: novaAI.novaState,
                    size: 32,
                    hasUrgent: hasCriticalAlerts()
                )
            }
            
            // Profile
            Button(action: { showProfileView = true }) {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
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
                ForEach(viewModel.recentActivity.prefix(5)) { activity in
                    AdminActivityRow(activity: activity)
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

struct NovaAvatarView: View {
    let state: NovaAIManager.NovaState
    let size: CGFloat
    let hasUrgent: Bool
    
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
    @EnvironmentObject var novaManager: NovaAIManager
    
    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [stateColor.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size * 0.8
                    )
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: 5)
                .opacity(pulseAnimation ? 1 : 0.5)
            
            // AI Image or Icon
            if let image = novaManager.novaImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(stateColor, lineWidth: 2)
                    )
                    .rotationEffect(.degrees(rotationAngle))
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
            } else {
                // Fallback icon
                Image(systemName: "brain")
                    .font(.system(size: size * 0.6))
                    .foregroundColor(stateColor)
                    .frame(width: size, height: size)
                    .background(Circle().fill(Color.black))
                    .overlay(
                        Circle()
                            .stroke(stateColor, lineWidth: 2)
                    )
            }
            
            // Urgent indicator
            if hasUrgent {
                Circle()
                    .fill(Color.red)
                    .frame(width: size * 0.3, height: size * 0.3)
                    .overlay(
                        Text("!")
                            .font(.system(size: size * 0.2, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: size * 0.3, y: -size * 0.3)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    var stateColor: Color {
        switch state {
        case .idle: return .blue.opacity(0.5)
        case .thinking: return .purple
        case .active: return .blue
        case .urgent: return .red
        case .error: return .orange
        }
    }
    
    func startAnimations() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        if state == .thinking {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// NovaIntelligenceBar component is imported from Components/Nova/
struct AdminNovaIntelligenceBar: View {
    let novaState: NovaAIManager.NovaState
    let insights: [CoreTypes.IntelligenceInsight]
    @Binding var isExpanded: Bool
    let onTap: () -> Void
    
    @State private var currentInsightIndex = 0
    
    var currentInsight: CoreTypes.IntelligenceInsight? {
        insights.isEmpty ? nil : insights[currentInsightIndex]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact Bar
            HStack(spacing: 12) {
                // Nova Avatar
                NovaAvatarView(
                    state: novaState,
                    size: 40,
                    hasUrgent: insights.contains { $0.priority == .critical }
                )
                .onTapGesture {
                    onTap()
                }
                
                if let insight = currentInsight {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(insight.description)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                } else {
                    Text("Nova AI Assistant")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Insight count
                if !insights.isEmpty {
                    Text("\(insights.count) insights")
                        .font(.caption2)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                }
                
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .foregroundColor(.white.opacity(0.5))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(.horizontal)
            .frame(height: 60)
            .background(
                Color.black.opacity(0.95)
                    .overlay(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .onAppear {
            startInsightRotation()
        }
    }
    
    func startInsightRotation() {
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            withAnimation {
                currentInsightIndex = (currentInsightIndex + 1) % max(insights.count, 1)
            }
        }
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
            // Header with live indicator
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Real-time data from \(activeWorkers.count) workers across \(portfolio.totalBuildings) buildings")
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
            
            // Metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AdminMetricCard(
                    value: "\(activeWorkers.filter { $0.isClockedIn }.count)/\(activeWorkers.count)",
                    label: "Workers Active",
                    subtitle: "\(activeWorkers.count - activeWorkers.filter { $0.isClockedIn }.count) on break",
                    color: .green,
                    icon: "person.3.fill",
                    onTap: onWorkersTap
                )
                
                AdminMetricCard(
                    value: "\(portfolio.totalBuildings)",
                    label: "Buildings",
                    subtitle: "\(portfolio.criticalIssues) need attention",
                    color: .blue,
                    icon: "building.2.fill",
                    onTap: onBuildingsTap
                )
                
                AdminMetricCard(
                    value: "\(Int(complianceScore))%",
                    label: "Compliance Score",
                    subtitle: portfolio.criticalIssues > 0 ? "\(portfolio.criticalIssues) issues" : "Good standing",
                    color: complianceScoreColor,
                    icon: "checkmark.shield.fill",
                    onTap: onComplianceTap
                )
                
                AdminMetricCard(
                    value: "\(Int(portfolio.overallCompletionRate * 100))%",
                    label: "Completion Rate",
                    color: completionRateColor,
                    icon: "chart.line.uptrend.xyaxis",
                    onTap: onTasksTap
                )
            }
            
            // Critical alerts
            if !criticalAlerts.isEmpty {
                AdminMetricCard(
                    value: "\(criticalAlerts.count)",
                    label: "Critical Alerts",
                    subtitle: "Action required",
                    color: .red,
                    icon: "exclamationmark.triangle.fill",
                    onTap: onAlertsTap
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
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

struct AdminBuildingsListView: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let onSelectBuilding: (CoreTypes.NamedCoordinate) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(buildings) { building in
                Button(action: { onSelectBuilding(building) }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(building.name)
                            .font(.headline)
                        Text(building.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Portfolio Buildings")
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

struct AdminTaskReviewView: View {
    let tasks: [CoreTypes.ContextualTask]
    let onSelectTask: (CoreTypes.ContextualTask) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List(tasks) { task in
                Button(action: { onSelectTask(task) }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(.headline)
                        if let description = task.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Task Review")
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

struct AdminComplianceOverviewView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Compliance Center")
                    .font(.largeTitle)
                    .padding()
                
                // Placeholder content
                Spacer()
            }
            .navigationTitle("Compliance")
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

struct NovaAssistantView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var novaAI: NovaAIManager
    
    var body: some View {
        NavigationView {
            VStack {
                NovaAvatarView(state: novaAI.novaState, size: 100, hasUrgent: false)
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

// MARK: - Preview Provider

struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let container = ServiceContainer()
        let viewModel = AdminDashboardViewModel(container: container)
        
        AdminDashboardView(viewModel: viewModel)
            .environmentObject(container)
            .environmentObject(NovaAIManager.shared)
            .environmentObject(NewAuthManager.shared)
            .preferredColorScheme(.dark)
    }
}
