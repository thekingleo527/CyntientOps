//
//  ClientDashboardMainView.swift
//  CyntientOps v7.0
//
//  🏢 PHASE 2: ENHANCED CLIENT DASHBOARD WITH 5-TAB STRUCTURE
//  Advanced UI components with comprehensive compliance suite
//

import SwiftUI
import Combine

struct ClientDashboardMainView: View {
    // MARK: - ServiceContainer Integration
    let container: ServiceContainer
    
    // MARK: - ViewModels  
    @StateObject private var viewModel: ClientDashboardViewModel
    @StateObject private var contextEngine: ClientContextEngine
    
    // MARK: - Environment Objects
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    
    // MARK: - State Management
    @State private var selectedTab: DashboardTab = .overview
    @State private var selectedBuildingId: String?
    @State private var showingBuildingSelector = false
    @State private var isPortfolioHeroCollapsed = false
    @State private var isPortfolioMapRevealed = false
    @State private var showCostData = true
    @State private var showingProfile = false
    @State private var refreshID = UUID()
    
    // MARK: - Tab Structure
    enum DashboardTab: String, CaseIterable {
        case overview = "Overview"
        case compliance = "Compliance"
        case buildings = "Buildings" 
        case analytics = "Analytics"
        case reports = "Reports"
        
        var icon: String {
            switch self {
            case .overview: return "chart.pie.fill"
            case .compliance: return "shield.checkered"
            case .buildings: return "building.2.fill"
            case .analytics: return "chart.bar.fill"
            case .reports: return "doc.text.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .overview: return .blue
            case .compliance: return .orange
            case .buildings: return .green
            case .analytics: return .purple
            case .reports: return .cyan
            }
        }
    }
    
    // MARK: - Initialization
    
    init(container: ServiceContainer) {
        self.container = container
        self._viewModel = StateObject(wrappedValue: ClientDashboardViewModel(container: container))
        self._contextEngine = StateObject(wrappedValue: ClientContextEngine(container: container))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with tab selector
                clientDashboardHeader
                
                // Add the MapRevealContainer here
                MapRevealContainer(
                    buildings: contextEngine.clientBuildings,
                    isRevealed: $isPortfolioMapRevealed,
                    container: container,
                    onBuildingTap: { building in
                        selectedBuildingId = building.id
                        // You would need a state variable to show a detail sheet, e.g., showingBuildingDetail = true
                    }
                ) {
                    // Tab Content
                    tabContentView
                }
                
                // Bottom Tab Bar
                clientTabBar
            }
            .background(CyntientOpsDesign.DashboardColors.baseBackground)
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .task {
            await contextEngine.refreshContext()
        }
        .refreshable {
            await viewModel.refreshData()
            refreshID = UUID()
        }
        .sheet(isPresented: $showingProfile) {
            ClientProfileSheet(profile: contextEngine.clientProfile)
        }
    }
    
    // MARK: - Header
    
    private var clientDashboardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Portfolio")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(contextEngine.clientProfile?.name ?? "Client Dashboard")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Portfolio score
                VStack(spacing: 0) {
                    Text("\(Int(contextEngine.complianceOverview.overallScore * 100))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(contextEngine.complianceOverview.overallScore > 0.8 ? .green : .orange)
                    Text("Score")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Button(action: { showingProfile = true }) {
                    Image(systemName: "person.circle")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContentView: some View {
        switch selectedTab {
        case .overview:
            OverviewTabView(contextEngine: contextEngine, showCostData: showCostData)
            
        case .compliance:
            ClientComplianceTabView(
                contextEngine: contextEngine,
                complianceOverview: contextEngine.complianceOverview,
                allComplianceIssues: contextEngine.allComplianceIssues
            )
            
        case .buildings:
            ClientBuildingsTabView(
                container: container,
                buildings: contextEngine.clientBuildings,
                buildingMetrics: contextEngine.buildingMetrics
            )
            
        case .analytics:
            ClientAnalyticsTabView(
                portfolioHealth: contextEngine.portfolioHealth,
                performanceMetrics: CoreTypes.RealtimeMetrics(
                    lastUpdateTime: Date(),
                    activeAlerts: 0,
                    pendingActions: 0
                )
            )
            
        case .reports:
            ClientReportsTabView(
                container: container,
                buildings: contextEngine.clientBuildings
            )
        }
    }
    
    // MARK: - Tab Bar
    
    private var clientTabBar: some View {
        HStack {
            ForEach(DashboardTab.allCases, id: \.self) { tab in
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: selectedTab == tab ? 20 : 16))
                            .foregroundColor(selectedTab == tab ? tab.color : .gray)
                        
                        Text(tab.rawValue)
                            .font(.caption2)
                            .foregroundColor(selectedTab == tab ? tab.color : .gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
    }
}

// MARK: - Tab Views

struct OverviewTabView: View {
    let contextEngine: ClientContextEngine
    let showCostData: Bool
    @State private var isPortfolioHeroCollapsed = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Portfolio Performance Hero
                ClientDashboardPortfolioHeroCard(
                    portfolioHealth: contextEngine.portfolioHealth,
                    realtimeMetrics: CoreTypes.RealtimeMetrics(),
                    monthlyMetrics: contextEngine.monthlyMetrics,
                    onDrillDown: {
                        // TODO: Implement drill down functionality
                    }
                )
                
                // Quick Metrics Grid
                ClientMetricsOverviewGrid(
                    totalBuildings: contextEngine.clientBuildings.count,
                    activeWorkers: contextEngine.activeWorkerStatus.totalActive,
                    completionRate: contextEngine.portfolioHealth.overallScore,
                    complianceScore: Int(contextEngine.complianceOverview.overallScore * 100),
                    criticalIssues: contextEngine.complianceOverview.criticalViolations
                )
                
                // Real-time Status
                RealtimeMetricsCard(
                    routineMetrics: contextEngine.realtimeRoutineMetrics,
                    workerStatus: contextEngine.activeWorkerStatus,
                    monthlyMetrics: contextEngine.monthlyMetrics
                )
                
                // Recent Compliance Issues
                if !contextEngine.allComplianceIssues.isEmpty {
                    ComplianceIssuesSection(
                        issues: Array(contextEngine.allComplianceIssues.prefix(5)),
                        onIssueTap: { _ in }
                    )
                }
                
                // Intelligence Insights  
                VStack {
                    Text("Intelligence Insights")
                        .font(.headline)
                    Text("Cost optimization and insights coming soon...")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

struct ClientBuildingsTabView: View {
    let container: ServiceContainer
    let buildings: [CoreTypes.NamedCoordinate]
    let buildingMetrics: [String: CoreTypes.BuildingMetrics]
    
    @State private var selectedBuilding: CoreTypes.NamedCoordinate?
    @State private var showBuildingDetail = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(buildings, id: \.id) { building in
                    ClientBuildingCard(
                        building: building,
                        metrics: buildingMetrics[building.id],
                        onTap: {
                            selectedBuilding = building
                            showBuildingDetail = true
                        }
                    )
                }
            }
            .padding()
        }
        .sheet(isPresented: $showBuildingDetail) {
            if let building = selectedBuilding {
                NavigationView {
                    BuildingDetailView(
                        container: container,
                        buildingId: building.id,
                        buildingName: building.name,
                        buildingAddress: building.address
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showBuildingDetail = false
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
            }
        }
    }
}


struct MetricIndicator: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

struct ClientAnalyticsTabView: View {
    let portfolioHealth: CoreTypes.PortfolioHealth
    let performanceMetrics: CoreTypes.RealtimeMetrics
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Portfolio performance chart placeholder
                VStack(alignment: .leading, spacing: 12) {
                    Text("Portfolio Performance Trends")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("Performance Analytics")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        )
                        .cornerRadius(12)
                }
                .padding()
                .cyntientOpsDarkCardBackground()
                
                // Key metrics breakdown
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    AnalyticsMetricCard(
                        title: "Portfolio Health",
                        value: "\(Int(portfolioHealth.overallScore * 100))%",
                        trend: portfolioHealth.trend == .improving ? "↗️" : "↘️",
                        color: portfolioHealth.overallScore > 0.8 ? .green : .orange
                    )
                    
                    AnalyticsMetricCard(
                        title: "Active Buildings",
                        value: "\(portfolioHealth.activeBuildings)",
                        trend: "📍",
                        color: .blue
                    )
                    
                    AnalyticsMetricCard(
                        title: "Critical Issues",
                        value: "\(portfolioHealth.criticalIssues)",
                        trend: portfolioHealth.criticalIssues == 0 ? "✅" : "⚠️",
                        color: portfolioHealth.criticalIssues == 0 ? .green : .red
                    )
                    
                    AnalyticsMetricCard(
                        title: "Last Updated",
                        value: formatTimeAgo(portfolioHealth.lastUpdated),
                        trend: "🕒",
                        color: .gray
                    )
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct AnalyticsMetricCard: View {
    let title: String
    let value: String
    let trend: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trend)
                    .font(.title2)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }
}

struct ClientComplianceTabView: View {
    let contextEngine: ClientContextEngine
    let complianceOverview: CoreTypes.ComplianceOverview
    let allComplianceIssues: [CoreTypes.ComplianceIssue]
    
    @State private var selectedComplianceFilter: ComplianceFilter = .all
    
    enum ComplianceFilter: String, CaseIterable {
        case all = "All Issues"
        case dsny = "DSNY Violations"
        case hpd = "HPD Violations"
        case dob = "DOB Permits"
        case ll97 = "LL97 Emissions"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Compliance Score Header
                ComplianceScoreHeader(complianceOverview: complianceOverview)
                
                // Filter Picker
                Picker("Filter", selection: $selectedComplianceFilter) {
                    ForEach(ComplianceFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Filtered Compliance Issues
                FilteredComplianceIssuesView(
                    issues: filteredIssues,
                    filter: selectedComplianceFilter
                )
                
                // Real NYC Violations Summary
                if selectedComplianceFilter == .dsny || selectedComplianceFilter == .all {
                    RealNYCViolationsSummaryCard(contextEngine: contextEngine)
                }
            }
            .padding()
        }
    }
    
    private var filteredIssues: [CoreTypes.ComplianceIssue] {
        switch selectedComplianceFilter {
        case .all:
            return allComplianceIssues
        case .dsny:
            return allComplianceIssues.filter { $0.department == "DSNY" }
        case .hpd:
            return allComplianceIssues.filter { $0.department == "HPD" }
        case .dob:
            return allComplianceIssues.filter { $0.department == "DOB" }
        case .ll97:
            return allComplianceIssues.filter { $0.title.contains("LL97") || $0.title.contains("emissions") }
        }
    }
}

struct ClientReportsTabView: View {
    let container: ServiceContainer
    let buildings: [CoreTypes.NamedCoordinate]
    
    @State private var showingComplianceReport = false
    @State private var showingPerformanceReport = false
    @State private var showingEmissionsReport = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // LL97 Emissions Reporting
                ReportCard(
                    title: "LL97 Emissions Report",
                    description: "Comprehensive Local Law 97 compliance and emissions tracking",
                    icon: "leaf.circle.fill",
                    color: .green,
                    action: { showingEmissionsReport = true }
                )
                
                // HPD Violations Report
                ReportCard(
                    title: "HPD Violations Report", 
                    description: "Housing violations and compliance tracking",
                    icon: "exclamationmark.shield.fill",
                    color: .orange,
                    action: { showingComplianceReport = true }
                )
                
                // Portfolio Performance Report
                ReportCard(
                    title: "Portfolio Performance Report",
                    description: "Comprehensive building performance analytics",
                    icon: "chart.bar.doc.horizontal.fill",
                    color: .blue,
                    action: { showingPerformanceReport = true }
                )
                
                // Compliance Suite
                ReportCard(
                    title: "Full Compliance Suite",
                    description: "All compliance categories and predictive insights",
                    icon: "shield.checkered",
                    color: .purple,
                    action: { showingComplianceReport = true }
                )
            }
            .padding()
        }
        .sheet(isPresented: $showingEmissionsReport) {
            VStack {
                Text("LL97 Emissions Report")
                    .font(.title)
                Text("Loading emissions data...")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingComplianceReport) {
            VStack {
                Text("HPD Violations Report")
                    .font(.title)
                Text("Loading violation data...")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingPerformanceReport) {
            VStack {
                Text("Performance Report")
                    .font(.title)
                Text("Loading performance data...")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ReportCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .cyntientOpsDarkCardBackground()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views

// MARK: - Client Metrics Overview Grid (Used in Overview tab)
struct ClientMetricsOverviewGrid: View {
    let totalBuildings: Int
    let activeWorkers: Int
    let completionRate: Double
    let complianceScore: Int
    let criticalIssues: Int
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ClientMetricCard(
                icon: "building.2",
                title: "Buildings",
                value: "\(totalBuildings)",
                color: .blue
            )
            
            ClientMetricCard(
                icon: "person.3.fill",
                title: "Active Workers",
                value: "\(activeWorkers)",
                color: .green
            )
            
            ClientMetricCard(
                icon: "checkmark.circle.fill",
                title: "Completion",
                value: "\(Int(completionRate * 100))%",
                color: .cyan
            )
            
            ClientMetricCard(
                icon: "shield.fill",
                title: "Compliance",
                value: "\(complianceScore)%",
                color: complianceScore >= 90 ? .green : .orange
            )
            
            if criticalIssues > 0 {
                ClientMetricCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Critical Issues",
                    value: "\(criticalIssues)",
                    color: .red
                )
            }
        }
    }
}

// MARK: - Client Metric Card
struct ClientMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }
}

// MARK: - Realtime Metrics Card
struct RealtimeMetricsCard: View {
    let routineMetrics: CoreTypes.RealtimeRoutineMetrics
    let workerStatus: CoreTypes.ActiveWorkerStatus
    let monthlyMetrics: CoreTypes.MonthlyMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Real-time Status")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Workers")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(workerStatus.totalActive)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Behind Schedule")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(routineMetrics.behindScheduleCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(routineMetrics.behindScheduleCount > 0 ? .orange : .green)
                }
                
                if monthlyMetrics.monthlyBudget > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Budget Used")
                        .font(.caption)
                        .foregroundColor(.gray)
                        Text("\(Int(monthlyMetrics.currentSpend / monthlyMetrics.monthlyBudget * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }
}

// MARK: - Compliance Issues Section
struct ComplianceIssuesSection: View {
    let issues: [CoreTypes.ComplianceIssue]
    let onIssueTap: (CoreTypes.ComplianceIssue) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Compliance Issues")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(issues.count) issues")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 8) {
                ForEach(issues.prefix(5)) { issue in
                    ComplianceIssueRow(issue: issue, onTap: {
                        onIssueTap(issue)
                    })
                }
            }
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }
}

// MARK: - Compliance Issue Row  
struct ComplianceIssueRow: View {
    let issue: CoreTypes.ComplianceIssue
    let onTap: () -> Void
    
    var severityColor: Color {
        switch issue.severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(severityColor)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(issue.title)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let buildingName = issue.buildingName {
                        Text(buildingName)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Text(issue.severity.rawValue)
                    .font(.caption2)
                    .foregroundColor(severityColor)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Intelligence Insights Section
struct IntelligenceInsightsSection: View {
    let insights: [CoreTypes.IntelligenceInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intelligence Insights")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(insights.prefix(3)) { insight in
                    IntelligenceInsightRow(insight: insight)
                }
            }
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }
}

// MARK: - Intelligence Insight Row
struct IntelligenceInsightRow: View {
    let insight: CoreTypes.IntelligenceInsight
    
    var priorityColor: Color {
        switch insight.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(priorityColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if let impact = insight.estimatedImpact {
                    Text(impact)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Profile Sheet

struct ClientProfileSheet: View {
    let profile: ClientProfile?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let profile = profile {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text(profile.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(profile.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let company = profile.company {
                        Text(company)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Client User")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding()
            .background(CyntientOpsDesign.DashboardColors.baseBackground)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Compliance Supporting Views

struct ComplianceScoreHeader: View {
    let complianceOverview: CoreTypes.ComplianceOverview
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Portfolio Compliance")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Overall Score")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack {
                    Text("\(Int(complianceOverview.overallScore * 100))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(complianceOverview.overallScore > 0.8 ? .green : .orange)
                    
                    Text("out of 100")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            if complianceOverview.criticalViolations > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("\(complianceOverview.criticalViolations) critical violations require immediate attention")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }
}

struct FilteredComplianceIssuesView: View {
    let issues: [CoreTypes.ComplianceIssue]
    let filter: ClientComplianceTabView.ComplianceFilter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(filter.rawValue) (\(issues.count))")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if issues.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    
                    Text("No \(filter.rawValue.lowercased()) found")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 8) {
                    ForEach(issues.prefix(10)) { issue in
                        ComplianceIssueRow(issue: issue, onTap: {
                            // Handle issue tap
                        })
                    }
                }
            }
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }
}

struct RealNYCViolationsSummaryCard: View {
    let contextEngine: ClientContextEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundColor(.orange)
                Text("NYC Violations Summary")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Real-time data")
                    .font(.caption2)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(4)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ViolationSummaryCard(
                    title: "DSNY Violations",
                    count: contextEngine.allComplianceIssues.filter { $0.department == "DSNY" }.count,
                    color: .orange,
                    icon: "trash.circle.fill"
                )
                
                ViolationSummaryCard(
                    title: "HPD Violations", 
                    count: contextEngine.allComplianceIssues.filter { $0.department == "HPD" }.count,
                    color: .red,
                    icon: "house.circle.fill"
                )
                
                ViolationSummaryCard(
                    title: "DOB Issues",
                    count: contextEngine.allComplianceIssues.filter { $0.department == "DOB" }.count,
                    color: .blue,
                    icon: "hammer.circle.fill"
                )
                
                ViolationSummaryCard(
                    title: "LL97 Issues",
                    count: contextEngine.allComplianceIssues.filter { $0.title.contains("LL97") }.count,
                    color: .green,
                    icon: "leaf.circle.fill"
                )
            }
            
            Text("Data sourced from NYC Open Data APIs in real-time")
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.top, 8)
        }
        .padding()
        .cyntientOpsDarkCardBackground()
    }
}

struct ViolationSummaryCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(height: 100)
        .background(color.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

 
