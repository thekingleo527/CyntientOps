//
//  ComprehensiveIntelligencePanel.swift
//  CyntientOps v6.0
//
//  🎯 COMPREHENSIVE ADMIN INTELLIGENCE PANEL
//  ✅ 5-Tab Interface: Workers | Portfolio | Compliance | Chat | Analytics
//  ✅ Operational Intelligence Integration
//  ✅ Real-time Vendor Repository Management
//  ✅ Routine Completion Tracking
//  ✅ Recurring Task Reminder System
//  ✅ Nova AI Chat Integration
//  ✅ Advanced Analytics Dashboard
//

import SwiftUI

struct ComprehensiveIntelligencePanel: View {
    // MARK: - Binding Properties
    @Binding var selectedTab: IntelligenceTab
    @Binding var isPresented: Bool
    
    // MARK: - ViewModel Dependencies
    @ObservedObject var viewModel: AdminDashboardViewModel
    
    // MARK: - Private State
    @State private var searchText = ""
    @State private var showingWorkerDetail = false
    @State private var selectedWorker: CoreTypes.WorkerProfile?
    @State private var showingBuildingDetail = false
    @State private var selectedBuilding: CoreTypes.NamedCoordinate?
    @State private var showingVendorManagement = false
    
    // MARK: - Tab Definition
    enum IntelligenceTab: String, CaseIterable {
        case workers = "Workers"
        case portfolio = "Portfolio"
        case compliance = "Compliance"
        case chat = "Chat"
        case analytics = "Analytics"
        
        var icon: String {
            switch self {
            case .workers: return "person.2.fill"
            case .portfolio: return "building.2.fill"
            case .compliance: return "shield.checkered"
            case .chat: return "message.fill"
            case .analytics: return "chart.line.uptrend.xyaxis"
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Navigation
                IntelligenceTabBar()
                
                // Main Content Area
                TabView(selection: $selectedTab) {
                    WorkersIntelligenceView()
                        .tag(IntelligenceTab.workers)
                    
                    PortfolioIntelligenceView()
                        .tag(IntelligenceTab.portfolio)
                    
                    ComplianceIntelligenceView()
                        .tag(IntelligenceTab.compliance)
                    
                    ChatIntelligenceView()
                        .tag(IntelligenceTab.chat)
                    
                    AnalyticsIntelligenceView()
                        .tag(IntelligenceTab.analytics)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color.black.opacity(0.05))
            .navigationTitle("Intelligence Center")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Refresh Data") {
                            Task {
                                await viewModel.loadDashboardData()
                            }
                        }
                        
                        Button("Export Intelligence") {
                            // Export functionality
                        }
                        
                        Button("Settings") {
                            // Settings functionality
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingWorkerDetail) {
            if let worker = selectedWorker {
                WorkerDetailSheet(worker: worker, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingBuildingDetail) {
            if let building = selectedBuilding {
                BuildingDetailSheet(building: building, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingVendorManagement) {
            VendorManagementSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - Tab Navigation Bar
    private func IntelligenceTabBar() -> some View {
        HStack(spacing: 0) {
            ForEach(IntelligenceTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18))
                            .foregroundColor(selectedTab == tab ? tab.color : .gray)
                        
                        Text(tab.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedTab == tab ? tab.color : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Rectangle()
                            .fill(selectedTab == tab ? tab.color.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.white.opacity(0.05))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Workers Intelligence View
    private func WorkersIntelligenceView() -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Workers Overview Section
                WorkersOverviewSection()
                
                // Active Workers Grid
                ActiveWorkersGrid()
                
                // Worker Capabilities Management
                WorkerCapabilitiesSection()
                
                // Recent Worker Activity
                RecentWorkerActivitySection()
            }
            .padding()
        }
        .searchable(text: $searchText, prompt: "Search workers...")
    }
    
    // MARK: - Portfolio Intelligence View
    private func PortfolioIntelligenceView() -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Portfolio Overview
                PortfolioOverviewSection()
                
                // Building Grid with Routine Status
                BuildingsRoutineGrid()
                
                // Vendor Repository Management
                VendorRepositorySection()
                
                // Building Performance Analytics
                BuildingPerformanceSection()
            }
            .padding()
        }
        .searchable(text: $searchText, prompt: "Search buildings...")
    }
    
    // MARK: - Compliance Intelligence View
    private func ComplianceIntelligenceView() -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Compliance Overview
                ComplianceOverviewSection()
                
                // Photo Compliance Tracking
                PhotoComplianceSection()
                
                // Recurring Task Reminders
                RecurringRemindersSection()
                
                // Critical Compliance Alerts
                CriticalAlertsSection()
            }
            .padding()
        }
    }
    
    // MARK: - Chat Intelligence View
    private func ChatIntelligenceView() -> some View {
        NovaAIChatInterface(
            viewModel: viewModel,
            context: .adminIntelligence
        )
    }
    
    // MARK: - Analytics Intelligence View
    private func AnalyticsIntelligenceView() -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Operational Analytics Overview
                OperationalAnalyticsOverview()
                
                // Routine Completion Analytics
                RoutineAnalyticsSection()
                
                // Performance Trends
                PerformanceTrendsSection()
                
                // Predictive Insights
                PredictiveInsightsSection()
            }
            .padding()
        }
    }
    
    // MARK: - Workers Tab Components
    
    private func WorkersOverviewSection() -> some View {
        IntelligenceSectionCard(
            title: "Workers Overview",
            subtitle: "\(viewModel.activeWorkers.count) active workers across \(viewModel.buildings.count) buildings"
        ) {
            HStack(spacing: 20) {
                WorkerMetricTile(
                    title: "Active Today",
                    value: "\(viewModel.activeWorkers.count)",
                    color: .blue
                )
                
                WorkerMetricTile(
                    title: "Clocked In",
                    value: "\(viewModel.activeWorkers.filter { $0.isActive }.count)",
                    color: .green
                )
                
                if let opMetrics = viewModel.operationalMetrics {
                    WorkerMetricTile(
                        title: "Tasks Completed",
                        value: "\(opMetrics.completedTasksToday)",
                        color: .purple
                    )
                }
            }
        }
    }
    
    private func ActiveWorkersGrid() -> some View {
        IntelligenceSectionCard(
            title: "Active Workers",
            subtitle: "Real-time status and assignments"
        ) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(viewModel.activeWorkers) { worker in
                    WorkerStatusCard(
                        worker: worker,
                        routineStatus: viewModel.getWorkerRoutineStatus(workerId: worker.id),
                        onTap: {
                            selectedWorker = worker
                            showingWorkerDetail = true
                        }
                    )
                }
            }
        }
    }
    
    private func WorkerCapabilitiesSection() -> some View {
        IntelligenceSectionCard(
            title: "Worker Capabilities",
            subtitle: "Manage permissions and access levels"
        ) {
            VStack(spacing: 12) {
                ForEach(viewModel.activeWorkers.prefix(3)) { worker in
                    WorkerCapabilityRow(
                        worker: worker,
                        capabilities: viewModel.workerCapabilities[worker.id]
                    )
                }
                
                Button("Manage All Capabilities") {
                    // Show capability management
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    private func RecentWorkerActivitySection() -> some View {
        IntelligenceSectionCard(
            title: "Recent Activity",
            subtitle: "Latest worker actions and completions"
        ) {
            VStack(spacing: 8) {
                ForEach(viewModel.recentActivity.prefix(5)) { activity in
                    ActivityRow(activity: activity)
                }
            }
        }
    }
    
    // MARK: - Portfolio Tab Components
    
    private func PortfolioOverviewSection() -> some View {
        IntelligenceSectionCard(
            title: "Portfolio Overview",
            subtitle: "\(viewModel.buildings.count) buildings with operational intelligence"
        ) {
            HStack(spacing: 16) {
                PortfolioMetricTile(
                    title: "Completion Rate",
                    value: "\(Int(viewModel.portfolioMetrics.overallCompletionRate * 100))%",
                    color: viewModel.portfolioMetrics.overallCompletionRate > 0.8 ? .green : .orange
                )
                
                if let opMetrics = viewModel.operationalMetrics {
                    PortfolioMetricTile(
                        title: "Fully Complete",
                        value: "\(opMetrics.buildingsWithFullCompletion)",
                        color: .cyan
                    )
                    
                    PortfolioMetricTile(
                        title: "Routine Efficiency",
                        value: opMetrics.completionPercentage,
                        color: opMetrics.operationalEfficiency.color
                    )
                }
            }
        }
    }
    
    private func BuildingsRoutineGrid() -> some View {
        IntelligenceSectionCard(
            title: "Buildings Status",
            subtitle: "Routine completion and operational status"
        ) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                ForEach(viewModel.buildings) { building in
                    BuildingRoutineCard(
                        building: building,
                        routineStatus: viewModel.getRoutineCompletionStatus(for: building.id),
                        vendorAccess: viewModel.getVendorAccessHistory(for: building.id).count,
                        onTap: {
                            selectedBuilding = building
                            showingBuildingDetail = true
                        }
                    )
                }
            }
        }
    }
    
    private func VendorRepositorySection() -> some View {
        IntelligenceSectionCard(
            title: "Vendor Access Management",
            subtitle: "Building-specific vendor repositories"
        ) {
            VStack(spacing: 12) {
                ForEach(Array(viewModel.buildingVendorRepositories.keys.prefix(3)), id: \.self) { buildingId in
                    if let repository = viewModel.buildingVendorRepositories[buildingId],
                       let building = viewModel.buildings.first(where: { $0.id == buildingId }) {
                        VendorRepositoryRow(
                            building: building,
                            repository: repository
                        )
                    }
                }
                
                Button("Manage Vendor Access") {
                    showingVendorManagement = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    private func BuildingPerformanceSection() -> some View {
        IntelligenceSectionCard(
            title: "Performance Insights",
            subtitle: "AI-generated building performance analysis"
        ) {
            VStack(spacing: 12) {
                ForEach(viewModel.portfolioInsights.prefix(3)) { insight in
                    PerformanceInsightRow(insight: insight)
                }
            }
        }
    }
    
    // MARK: - Compliance Tab Components
    
    private func ComplianceOverviewSection() -> some View {
        IntelligenceSectionCard(
            title: "Compliance Overview",
            subtitle: "Portfolio-wide compliance monitoring"
        ) {
            HStack(spacing: 16) {
                ComplianceMetricTile(
                    title: "Overall Score",
                    value: "\(Int(viewModel.portfolioMetrics.complianceScore))%",
                    color: viewModel.portfolioMetrics.complianceScore > 85 ? .green : .orange
                )
                
                if let photoStats = viewModel.photoComplianceStats {
                    ComplianceMetricTile(
                        title: "Photo Compliance",
                        value: photoStats.compliancePercentage,
                        color: photoStats.isCompliant ? .green : .red
                    )
                }
                
                ComplianceMetricTile(
                    title: "Critical Issues",
                    value: "\(viewModel.portfolioMetrics.criticalIssues)",
                    color: viewModel.portfolioMetrics.criticalIssues > 0 ? .red : .green
                )
            }
        }
    }
    
    private func PhotoComplianceSection() -> some View {
        IntelligenceSectionCard(
            title: "Photo Evidence Compliance",
            subtitle: "Task completion with required photo evidence"
        ) {
            if let photoStats = viewModel.photoComplianceStats {
                PhotoComplianceChart(stats: photoStats)
            } else {
                Text("Loading photo compliance data...")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func RecurringRemindersSection() -> some View {
        IntelligenceSectionCard(
            title: "Recurring Task Reminders",
            subtitle: "\(viewModel.pendingReminders.count) active reminders"
        ) {
            VStack(spacing: 8) {
                ForEach(viewModel.getTodaysPendingReminders().prefix(5)) { reminder in
                    ReminderRow(reminder: reminder)
                }
                
                if viewModel.pendingReminders.count > 5 {
                    Button("View All \(viewModel.pendingReminders.count) Reminders") {
                        // Show all reminders
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func CriticalAlertsSection() -> some View {
        IntelligenceSectionCard(
            title: "Critical Alerts",
            subtitle: "\(viewModel.criticalRoutineAlerts.count) active alerts"
        ) {
            VStack(spacing: 8) {
                ForEach(viewModel.criticalRoutineAlerts) { alert in
                    CriticalAlertRow(alert: alert)
                }
                
                if viewModel.criticalRoutineAlerts.isEmpty {
                    Text("No critical alerts")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // MARK: - Analytics Tab Components
    
    private func OperationalAnalyticsOverview() -> some View {
        IntelligenceSectionCard(
            title: "Operational Analytics",
            subtitle: "Real-time operational intelligence metrics"
        ) {
            if let opMetrics = viewModel.operationalMetrics {
                OperationalMetricsGrid(metrics: opMetrics)
            } else {
                Text("Loading operational analytics...")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private func RoutineAnalyticsSection() -> some View {
        IntelligenceSectionCard(
            title: "Routine Completion Analytics",
            subtitle: "Building-by-building routine performance"
        ) {
            RoutineCompletionChart(completions: viewModel.routineCompletions)
        }
    }
    
    private func PerformanceTrendsSection() -> some View {
        IntelligenceSectionCard(
            title: "Performance Trends",
            subtitle: "7-day and 30-day trend analysis"
        ) {
            PerformanceTrendCharts(buildingMetrics: viewModel.buildingMetrics)
        }
    }
    
    private func PredictiveInsightsSection() -> some View {
        IntelligenceSectionCard(
            title: "AI Predictive Insights",
            subtitle: "Machine learning-powered operational predictions"
        ) {
            VStack(spacing: 12) {
                ForEach(viewModel.portfolioInsights.filter { $0.type == .predictive }) { insight in
                    PredictiveInsightRow(insight: insight)
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct IntelligenceSectionCard<Content: View>: View {
    let title: String
    let subtitle: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            content()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Extension for ViewModel Helper Methods

extension AdminDashboardViewModel {
    func getWorkerRoutineStatus(workerId: String) -> String {
        // Calculate routine status for worker
        let workerCompletions = routineCompletions.values.filter { status in
            // Find completions involving this worker
            status.binPlacements.contains { $0.workerId == workerId } ||
            status.cleaningCompletions.contains { $0.workerId == workerId }
        }
        
        if workerCompletions.isEmpty {
            return "No routines assigned"
        }
        
        let averageCompletion = workerCompletions.reduce(0.0) { sum, status in
            sum + status.overallCompletionRate
        } / Double(workerCompletions.count)
        
        return "\(Int(averageCompletion * 100))% routine completion"
    }
}

// MARK: - Placeholder Components (would be implemented separately)

struct WorkerMetricTile: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WorkerStatusCard: View {
    let worker: CoreTypes.WorkerProfile
    let routineStatus: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(worker.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Circle()
                        .fill(worker.isActive ? .green : .gray)
                        .frame(width: 8, height: 8)
                }
                
                Text(routineStatus)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Additional placeholder components would be implemented similarly...
struct WorkerCapabilityRow: View {
    let worker: CoreTypes.WorkerProfile
    let capabilities: AdminDashboardViewModel.WorkerCapabilities?
    
    var body: some View {
        HStack {
            Text(worker.name)
                .font(.subheadline)
            
            Spacer()
            
            if let caps = capabilities {
                HStack(spacing: 8) {
                    if caps.canUploadPhotos {
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if caps.canAddEmergencyTasks {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// More placeholder components would be implemented for the complete interface...

#if DEBUG
struct ComprehensiveIntelligencePanel_Previews: PreviewProvider {
    static var previews: some View {
        let container = ServiceContainer.shared
        let mockViewModel = AdminDashboardViewModel(container: container)
        
        ComprehensiveIntelligencePanel(
            selectedTab: .constant(.workers),
            isPresented: .constant(true),
            viewModel: mockViewModel
        )
    }
}
#endif