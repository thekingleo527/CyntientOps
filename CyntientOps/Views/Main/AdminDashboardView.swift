//
//  AdminDashboardView.swift
//  CyntientOps v6.0
//
//  ✅ REDESIGNED: Mirrors ClientDashboard structure and design
//  ✅ INTELLIGENCE PANEL: Expandable/collapsible with tabs like client
//  ✅ NOVA AI: Fixed avatar and streaming broadcast functionality
//  ✅ MANHATTAN FOCUS: Map properly zoomed to Manhattan area
//

import SwiftUI
import MapKit
import CoreLocation

public struct AdminDashboardView: View {
    @StateObject private var viewModel: AdminDashboardViewModel
    @EnvironmentObject private var authManager: NewAuthManager
    
    // MARK: - Responsive Layout
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    private let container: ServiceContainer
    
    init(container: ServiceContainer) {
        self.container = container
        self._viewModel = StateObject(wrappedValue: AdminDashboardViewModel(container: container))
    }
    
    // MARK: - Sheet Navigation
    enum AdminRoute: Identifiable {
        case profile, buildings, buildingDetail(String), workers, compliance, analytics, reports, emergencies, settings
        case workerDetail(String), chat, map
        
        var id: String {
            switch self {
            case .profile: return "profile"
            case .buildings: return "buildings"
            case .buildingDetail(let id): return "building-\(id)"
            case .workers: return "workers"
            case .compliance: return "compliance"
            case .analytics: return "analytics"
            case .reports: return "reports"
            case .emergencies: return "emergencies"
            case .settings: return "settings"
            case .workerDetail(let id): return "worker-\(id)"
            case .chat: return "chat"
            case .map: return "map"
            }
        }
    }
    
    // MARK: - Nova Intelligence Tabs (mirroring client)
    enum AdminNovaTab: String, CaseIterable {
        case priorities = "Priorities"
        case workers = "Workers"
        case buildings = "Buildings"
        case analytics = "Analytics"
        
        var icon: String {
            switch self {
            case .priorities: return "exclamationmark.triangle"
            case .workers: return "person.2"
            case .buildings: return "building.2"
            case .analytics: return "chart.bar"
            }
        }
    }
    
    // MARK: - State
    @State private var heroExpanded = true
    @State private var selectedNovaTab: AdminNovaTab = .priorities
    @State private var sheet: AdminRoute?
    @State private var isPortfolioMapRevealed = false
    @State private var intelligencePanelExpanded = false
    
    // MARK: - Body
    public var body: some View {
        MapRevealContainer(
            buildings: viewModel.buildings,
            currentBuildingId: nil,
            focusBuildingId: nil,
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
                    // Header (mirroring client)
                    AdminHeaderV3B(
                        adminName: "System Administrator",
                        portfolioCount: viewModel.buildingCount,
                        complianceScore: viewModel.complianceScore,
                        hasAlerts: hasUrgentItems(),
                        onRoute: handleHeaderRoute
                    )
                    .zIndex(100)
                    
                    // Scrollable Content
                    ScrollView {
                        VStack(spacing: 16) {
                            // Collapsible Admin Hero Card (mirroring client)
                            AdminRealTimeHeroCard(
                                isExpanded: $heroExpanded,
                                portfolioMetrics: viewModel.portfolioMetrics,
                                activeWorkers: viewModel.workersActive,
                                workersTotal: viewModel.workersTotal,
                                criticalAlerts: viewModel.criticalAlerts,
                                onBuildingsTap: { sheet = .buildings },
                                onWorkersTap: { sheet = .workers },
                                onComplianceTap: { sheet = .compliance }
                            )
                            
                            // Urgent Items Section (admin-specific)
                            if hasUrgentItems() {
                                AdminUrgentItemsSection(
                                    criticalAlerts: viewModel.criticalAlerts.count,
                                    complianceIssues: getComplianceIssuesCount(),
                                    workersNeedingAttention: getWorkersNeedingAttention(),
                                    onEmergenciesTap: { sheet = .emergencies },
                                    onComplianceTap: { sheet = .compliance }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .refreshable {
                        await viewModel.refreshDashboardData()
                    }
                    
                    // Intelligence Bar - Expands upward, compacts content (mirroring client)
                    AdminNovaIntelligenceBar(
                        selectedTab: $selectedNovaTab,
                        portfolioMetrics: viewModel.portfolioMetrics,
                        buildings: viewModel.buildings,
                        workers: viewModel.workers,
                        criticalAlerts: viewModel.criticalAlerts,
                        onTabTap: handleNovaTabTap,
                        onMapToggle: handlePortfolioMapToggle,
                        onEmergencyBroadcast: { sheet = .emergencies },
                        viewModel: viewModel
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, isPortfolioMapRevealed ? 0 : 8)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(item: $sheet) { route in
            NavigationView {
                adminSheetContent(for: route)
            }
        }
        .task {
            await viewModel.initialize()
        }
    }
    
    // MARK: - Header Actions
    private func handleHeaderRoute(_ route: AdminHeaderV3B.HeaderRoute) {
        switch route {
        case .profile: sheet = .profile
        case .chat: sheet = .chat
        case .settings: sheet = .settings
        case .logout: handleLogout()
        }
    }
    
    private func handleLogout() {
        // Clear session and navigate back to login
        Task {
            await authManager.logout()
            // Navigation will be handled by ContentView based on auth state
        }
    }
    
    // MARK: - Nova Tab Actions
    private func handleNovaTabTap(_ tab: AdminNovaTab) {
        withAnimation(CyntientOpsDesign.Animations.spring) {
            if selectedNovaTab == tab && viewModel.intelligencePanelExpanded {
                // Clicking same tab when expanded - collapse panel
                viewModel.intelligencePanelExpanded = false
            } else {
                // Clicking different tab or clicking when collapsed - switch tab and expand
                selectedNovaTab = tab
                viewModel.intelligencePanelExpanded = true
            }
        }
    }
    
    private func handlePortfolioMapToggle() {
        withAnimation(CyntientOpsDesign.Animations.spring) {
            isPortfolioMapRevealed.toggle()
        }
    }
    
    // MARK: - Helper Methods
    private func getAdminName() -> String {
        return "System Administrator"
    }
    
    private func hasUrgentItems() -> Bool {
        return !viewModel.criticalAlerts.isEmpty ||
               viewModel.complianceScore < 0.8 ||
               getWorkersNeedingAttention() > 0
    }
    
    private func getComplianceIssuesCount() -> Int {
        // Count buildings with compliance issues
        return viewModel.buildings.filter { building in
            if let metrics = viewModel.buildingMetrics[building.id] {
                return metrics.complianceScore < 0.8
            }
            return false
        }.count
    }
    
    private func getWorkersNeedingAttention() -> Int {
        // Count workers with issues or needing supervisor attention
        return viewModel.workers.filter { worker in
            return !worker.isClockedIn && worker.isActive // Workers who should be working
        }.count
    }
    
// MARK: - Admin Metric Components (mirroring client)

struct AdminMetricTile: View {
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
    
// MARK: - Admin Urgent Items Section (mirroring client)

struct AdminUrgentItemsSection: View {
    let criticalAlerts: Int
    let complianceIssues: Int
    let workersNeedingAttention: Int
    let onEmergenciesTap: () -> Void
    let onComplianceTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
                
                Text("Urgent Admin Items")
                    .font(.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                if criticalAlerts > 0 {
                    AdminUrgentItem(
                        icon: "exclamationmark.octagon.fill",
                        title: "Critical Alerts",
                        count: criticalAlerts,
                        color: CyntientOpsDesign.DashboardColors.critical,
                        action: onEmergenciesTap
                    )
                }
                
                if complianceIssues > 0 {
                    AdminUrgentItem(
                        icon: "shield.lefthalf.fill",
                        title: "Compliance Issues",
                        count: complianceIssues,
                        color: CyntientOpsDesign.DashboardColors.critical,
                        action: onComplianceTap
                    )
                }
                
                if workersNeedingAttention > 0 {
                    AdminUrgentItem(
                        icon: "person.badge.exclamationmark",
                        title: "Workers Need Attention",
                        count: workersNeedingAttention,
                        color: CyntientOpsDesign.DashboardColors.warning,
                        action: {}
                    )
                }
            }
        }
        .padding(16)
        .cyntientOpsDarkCardBackground(cornerRadius: 12)
    }
}

struct AdminUrgentItem: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
                    
                    Text("Requires immediate attention")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .cornerRadius(8)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
    
    // MARK: - Sheet Content
    @ViewBuilder
    private func adminSheetContent(for route: AdminRoute) -> some View {
        switch route {
        case .profile:
            AdminProfileView(viewModel: viewModel)
                .navigationTitle("Admin Profile")
                
        case .buildings:
            AdminBuildingsListView(
                buildings: viewModel.buildings,
                buildingMetrics: viewModel.buildingMetrics,
                onSelectBuilding: { building in
                    sheet = .buildingDetail(building.id)
                }
            )
                .navigationTitle("Portfolio Buildings")
            
        case .buildingDetail(let buildingId):
            if let building = viewModel.buildings.first(where: { $0.id == buildingId }) {
                BuildingDetailView(
                    buildingId: building.id,
                    buildingName: building.name,
                    buildingAddress: building.address
                )
                .navigationTitle(building.name)
            }
            
        case .workers:
            AdminWorkerManagementView(clientBuildings: viewModel.buildings)
                .navigationTitle("Worker Management")
                
        case .compliance:
            ComplianceOverviewView()
                .navigationTitle("Compliance Overview")
            
        case .analytics:
            AdminAnalyticsView(viewModel: viewModel)
                .navigationTitle("Portfolio Analytics")
                
        case .reports:
            AdminReportsView()
                .navigationTitle("System Reports")
                
        case .emergencies:
            AdminEmergencyManagementView(alerts: viewModel.criticalAlerts)
                .navigationTitle("Emergency Management")
                
        case .settings:
            AdminSettingsView()
                .navigationTitle("System Settings")
                
        case .workerDetail(let workerId):
            AdminWorkerDetailView(workerId: workerId, container: container)
                .navigationTitle("Worker Details")
                
        case .chat:
            NovaInteractionView()
                .navigationTitle("Nova Assistant")
                
        case .map:
            AdminPortfolioMapView(buildings: viewModel.buildings, workers: viewModel.workers)
                .navigationTitle("Portfolio Map")
        }
    }
}

// MARK: - Admin Helper Components

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
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
    }
}

struct AdminImmediateItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

// MARK: - Admin Header Component (mirroring client)

struct AdminHeaderV3B: View {
    enum HeaderRoute: Identifiable {
        case profile, chat, settings, logout
        
        var id: String {
            switch self {
            case .profile: return "profile"
            case .chat: return "chat" 
            case .settings: return "settings"
            case .logout: return "logout"
            }
        }
    }
    
    let adminName: String
    let portfolioCount: Int
    let complianceScore: Double
    let hasAlerts: Bool
    let onRoute: (HeaderRoute) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                // Left: CyntientOps Logo
                Button(action: { /* Handle logo tap */ }) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(CyntientOpsDesign.DashboardColors.adminAccent)
                                .frame(width: 32, height: 32)
                            
                            Text("CO")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text("CYNTIENT")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            
                            Text("OPS")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Center: Nova Manager Avatar
                Button(action: { onRoute(.chat) }) {
                    VStack(spacing: 4) {
                        NovaAvatar(
                            size: .medium,
                            isActive: true,
                            hasUrgentInsights: hasAlerts,
                            isBusy: false,
                            onTap: { onRoute(.chat) },
                            onLongPress: { }
                        )
                        .frame(width: 40, height: 40)
                        
                        VStack(spacing: 1) {
                            Text("NOVA")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            
                            Text("AI Manager")
                                .font(.system(size: 7, weight: .medium))
                                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Right: Admin Profile with Logout
                HStack(spacing: 8) {
                    // Logout button
                    Button(action: { onRoute(.logout) }) {
                        Image(systemName: "power")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Admin Profile
                    Button(action: { onRoute(.profile) }) {
                        HStack(spacing: 12) {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("System Administrator")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                                    .lineLimit(1)
                                
                                HStack(spacing: 4) {
                                    Text("\(portfolioCount) Buildings")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
                                    
                                    Text("\(Int(complianceScore * 100))% Compliant")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(complianceColor)
                                }
                            }
                            
                            ProfileChip(
                                name: adminName,
                                initials: getInitials(adminName),
                                photoURL: nil,
                                tap: { onRoute(.profile) }
                            )
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(height: 68)
            
            Divider()
                .opacity(0.3)
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
    }
    
    private var complianceColor: Color {
        if complianceScore >= 0.8 {
            return CyntientOpsDesign.DashboardColors.success
        } else if complianceScore >= 0.6 {
            return CyntientOpsDesign.DashboardColors.warning
        } else {
            return CyntientOpsDesign.DashboardColors.critical
        }
    }
    
    private func getInitials(_ name: String) -> String {
        let components = name.components(separatedBy: " ")
        let first = String(components.first?.first ?? "S")
        let last = components.count > 1 ? String(components.last?.first ?? "A") : ""
        return "\(first)\(last)".uppercased()
    }
}

// MARK: - Admin Real-time Hero Card (mirroring client)

struct AdminRealTimeHeroCard: View {
    @Binding var isExpanded: Bool
    let portfolioMetrics: CoreTypes.PortfolioMetrics
    let activeWorkers: Int
    let workersTotal: Int
    let criticalAlerts: [CoreTypes.AdminAlert]
    let onBuildingsTap: () -> Void
    let onWorkersTap: () -> Void
    let onComplianceTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                // Full Hero Card with Real-time Data
                VStack(spacing: 16) {
                    // Top Row - Portfolio Overview
                    HStack(spacing: 12) {
                        AdminMetricCard(
                            icon: "building.2",
                            title: "Buildings",
                            value: "\(portfolioMetrics.totalBuildings)",
                            color: CyntientOpsDesign.DashboardColors.adminAccent,
                            onTap: onBuildingsTap
                        )
                        
                        AdminMetricCard(
                            icon: "person.2.fill",
                            title: "Workers",
                            value: "\(activeWorkers)/\(workersTotal)",
                            color: activeWorkersColor,
                            onTap: onWorkersTap
                        )
                    }
                    
                    // Middle Row - Performance Metrics
                    HStack(spacing: 12) {
                        AdminMetricCard(
                            icon: "shield.checkered",
                            title: "Compliance",
                            value: "\(Int(portfolioMetrics.complianceScore * 100))%",
                            color: complianceColor,
                            onTap: onComplianceTap
                        )
                        
                        AdminMetricCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Completion",
                            value: "\(Int(portfolioMetrics.overallCompletionRate * 100))%",
                            color: completionColor,
                            onTap: { /* Show analytics */ }
                        )
                    }
                    
                    // Bottom Row - Critical Status
                    if hasImmediateItems {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Critical Attention")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    if !criticalAlerts.isEmpty {
                                        AdminImmediateItem(
                                            icon: "exclamationmark.triangle.fill",
                                            text: "\(criticalAlerts.count) Critical Alerts",
                                            color: CyntientOpsDesign.DashboardColors.critical
                                        )
                                    }
                                    
                                    if portfolioMetrics.criticalIssues > 0 {
                                        AdminImmediateItem(
                                            icon: "exclamationmark.shield.fill",
                                            text: "\(portfolioMetrics.criticalIssues) Critical Issues",
                                            color: CyntientOpsDesign.DashboardColors.critical
                                        )
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
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
                .cyntientOpsDarkCardBackground(cornerRadius: 12)
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
                                .fill(overallStatusColor)
                                .frame(width: 8, height: 8)
                                .scaleEffect(activeWorkers > 0 ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: activeWorkers > 0)
                            
                            Text(activeWorkers > 0 ? "Live" : "Offline")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(overallStatusColor)
                        }
                        
                        // Quick metrics
                        HStack(spacing: 12) {
                            AdminMetricPill(
                                value: "\(portfolioMetrics.totalBuildings)",
                                label: "Buildings",
                                color: CyntientOpsDesign.DashboardColors.adminAccent
                            )
                            
                            AdminMetricPill(
                                value: "\(activeWorkers)",
                                label: "Active",
                                color: CyntientOpsDesign.DashboardColors.success
                            )
                            
                            AdminMetricPill(
                                value: "\(Int(portfolioMetrics.complianceScore * 100))%",
                                label: "Compliant",
                                color: complianceColor
                            )
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .cyntientOpsDarkCardBackground(cornerRadius: 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var hasImmediateItems: Bool {
        return !criticalAlerts.isEmpty || portfolioMetrics.criticalIssues > 0
    }
    
    private var complianceSubtitle: String {
        if portfolioMetrics.criticalIssues > 0 {
            return "\(portfolioMetrics.criticalIssues) Critical"
        }
        return "All Clear"
    }
    
    private var activeWorkersColor: Color {
        let ratio = workersTotal > 0 ? Double(activeWorkers) / Double(workersTotal) : 0
        if ratio >= 0.8 {
            return CyntientOpsDesign.DashboardColors.success
        } else if ratio >= 0.6 {
            return CyntientOpsDesign.DashboardColors.warning
        }
        return CyntientOpsDesign.DashboardColors.critical
    }
    
    private var complianceColor: Color {
        if portfolioMetrics.complianceScore >= 0.8 {
            return CyntientOpsDesign.DashboardColors.success
        } else if portfolioMetrics.complianceScore >= 0.6 {
            return CyntientOpsDesign.DashboardColors.warning
        }
        return CyntientOpsDesign.DashboardColors.critical
    }
    
    private var completionColor: Color {
        if portfolioMetrics.overallCompletionRate >= 0.8 {
            return CyntientOpsDesign.DashboardColors.success
        } else if portfolioMetrics.overallCompletionRate >= 0.6 {
            return CyntientOpsDesign.DashboardColors.warning
        }
        return CyntientOpsDesign.DashboardColors.critical
    }
    
    private var overallStatusColor: Color {
        if !criticalAlerts.isEmpty || portfolioMetrics.criticalIssues > 0 {
            return CyntientOpsDesign.DashboardColors.critical
        } else if portfolioMetrics.complianceScore < 0.8 || portfolioMetrics.overallCompletionRate < 0.8 {
            return CyntientOpsDesign.DashboardColors.warning
        }
        return CyntientOpsDesign.DashboardColors.success
    }
}

// MARK: - Admin Nova Intelligence Bar (mirroring client design)

struct AdminNovaIntelligenceBar: View {
    @Binding var selectedTab: AdminDashboardView.AdminNovaTab
    let portfolioMetrics: CoreTypes.PortfolioMetrics
    let buildings: [CoreTypes.NamedCoordinate]
    let workers: [CoreTypes.WorkerProfile]
    let criticalAlerts: [CoreTypes.AdminAlert]
    let onTabTap: (AdminDashboardView.AdminNovaTab) -> Void
    let onMapToggle: () -> Void
    let onEmergencyBroadcast: () -> Void
    @ObservedObject var viewModel: AdminDashboardViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Intelligence Content Panel with Dynamic Height
            intelligenceContentPanel
                .frame(height: getIntelligencePanelHeight())
                .animation(CyntientOpsDesign.Animations.spring, value: selectedTab)
                .animation(CyntientOpsDesign.Animations.spring, value: viewModel.intelligencePanelExpanded)
            
            // Tab Bar with Proper Spacing
            HStack(spacing: 0) {
                ForEach(AdminDashboardView.AdminNovaTab.allCases, id: \.self) { tab in
                    AdminNovaTabButton(
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
            .cyntientOpsDarkCardBackground(cornerRadius: 0)
        }
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Dynamic Panel Height
    
    private func getIntelligencePanelHeight() -> CGFloat {
        if !viewModel.intelligencePanelExpanded {
            return 60
        }
        
        switch selectedTab {
        case .priorities:
            let hasItems = !criticalAlerts.isEmpty || portfolioMetrics.criticalIssues > 0
            return hasItems ? 260 : 180  // Taller for streaming broadcast
        case .workers:
            return workers.count > 3 ? 220 : 180
        case .buildings:
            return buildings.count > 3 ? 200 : 160
        case .analytics:
            return 200
        }
    }
    
    @ViewBuilder
    private var intelligenceContentPanel: some View {
        if viewModel.intelligencePanelExpanded {
            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .priorities:
                        AdminPrioritiesContent(
                            criticalAlerts: criticalAlerts,
                            portfolioMetrics: portfolioMetrics,
                            onEmergencyBroadcast: onEmergencyBroadcast,
                            onMapToggle: onMapToggle
                        )
                        
                    case .workers:
                        AdminWorkersContent(
                            workers: workers,
                            activeCount: viewModel.workersActive,
                            totalCount: viewModel.workersTotal
                        )
                        
                    case .buildings:
                        AdminBuildingsContent(
                            buildings: buildings,
                            portfolioMetrics: portfolioMetrics,
                            onMapToggle: onMapToggle
                        )
                        
                    case .analytics:
                        AdminAnalyticsContent(
                            portfolioMetrics: portfolioMetrics,
                            buildingCount: buildings.count
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(CyntientOpsDesign.DashboardColors.cardBackground) // Fixed transparency
        } else {
            Color.clear
                .background(CyntientOpsDesign.DashboardColors.cardBackground) // Fixed transparency
        }
    }
    
    private func getBadgeCount(for tab: AdminDashboardView.AdminNovaTab) -> Int {
        switch tab {
        case .priorities:
            return criticalAlerts.count + portfolioMetrics.criticalIssues
        case .workers:
            return workers.filter { !$0.isClockedIn && $0.isActive }.count
        case .buildings:
            return buildings.filter { building in
                if let metrics = viewModel.buildingMetrics[building.id] {
                    return metrics.urgentTasksCount > 0
                }
                return false
            }.count
        case .analytics:
            return 0
        }
    }
}

// MARK: - Admin Nova Tab Button (mirroring client)

struct AdminNovaTabButton: View {
    let tab: AdminDashboardView.AdminNovaTab
    let isSelected: Bool
    let badgeCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? CyntientOpsDesign.DashboardColors.adminAccent : CyntientOpsDesign.DashboardColors.tertiaryText)
                    
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
                    .foregroundColor(isSelected ? CyntientOpsDesign.DashboardColors.adminAccent : CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Admin Intelligence Content Panels

struct AdminPrioritiesContent: View {
    let criticalAlerts: [CoreTypes.AdminAlert]
    let portfolioMetrics: CoreTypes.PortfolioMetrics
    let onEmergencyBroadcast: () -> Void
    let onMapToggle: () -> Void
    
    @State private var streamingMessage = "📡 LIVE: All systems operational"
    @State private var animationTimer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Streaming Emergency Broadcast (always visible)
            AdminStreamingBroadcast(
                message: $streamingMessage,
                hasEmergencies: !criticalAlerts.isEmpty
            )
            
            if !criticalAlerts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Critical System Alerts")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    ForEach(criticalAlerts.prefix(3), id: \.id) { alert in
                        AdminPriorityItem(
                            title: alert.title,
                            severity: alert.urgency,
                            timestamp: alert.timestamp,
                            onTap: onEmergencyBroadcast
                        )
                    }
                }
            } else {
                AdminStatusOK()
            }
        }
        .onAppear {
            startStreamingUpdate()
        }
        .onDisappear {
            animationTimer?.invalidate()
        }
    }
    
    private func startStreamingUpdate() {
        let messages = [
            "📡 LIVE: Portfolio operating at 94% efficiency",
            "📡 LIVE: All workers clocked in and active",
            "📡 LIVE: Compliance status: 92% across all buildings",
            "📡 LIVE: No critical alerts - systems nominal"
        ]
        
        var messageIndex = 0
        animationTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                streamingMessage = messages[messageIndex]
                messageIndex = (messageIndex + 1) % messages.count
            }
        }
    }
}

struct AdminStreamingBroadcast: View {
    @Binding var message: String
    let hasEmergencies: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(hasEmergencies ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.success)
                .frame(width: 8, height: 8)
                .scaleEffect(1.2)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: hasEmergencies)
            
            Text(message)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill((hasEmergencies ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.success).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke((hasEmergencies ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.success).opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct AdminPriorityItem: View {
    let title: String
    let severity: CoreTypes.AIPriority
    let timestamp: Date
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: severityIcon)
                    .font(.subheadline)
                    .foregroundColor(severityColor)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                    
                    Text(timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var severityIcon: String {
        switch severity {
        case .low: return "info.circle"
        case .medium: return "exclamationmark.circle"
        case .high: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
    
    private var severityColor: Color {
        switch severity {
        case .low: return CyntientOpsDesign.DashboardColors.info
        case .medium: return CyntientOpsDesign.DashboardColors.warning
        case .high: return CyntientOpsDesign.DashboardColors.critical
        case .critical: return CyntientOpsDesign.DashboardColors.critical
        }
    }
}

struct AdminStatusOK: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.success)
            
            Text("All Systems Operational")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text("No critical alerts requiring attention")
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct AdminWorkersContent: View {
    let workers: [CoreTypes.WorkerProfile]
    let activeCount: Int
    let totalCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Worker Status Overview")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                
                Spacer()
                
                Text("\(activeCount)/\(totalCount) Active")
                    .font(.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
            }
            
            ForEach(workers.prefix(4), id: \.id) { worker in
                AdminWorkerStatusRow(worker: worker)
            }
            
            if workers.count > 4 {
                Button("View All Workers") {
                    // Handle view all
                }
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
            }
        }
    }
}

struct AdminWorkerStatusRow: View {
    let worker: CoreTypes.WorkerProfile
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(worker.isClockedIn ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.warning)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(worker.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Text(worker.isClockedIn ? "Active" : "Offline")
                    .font(.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            
            Spacer()
            
            if worker.isClockedIn {
                Text("\(worker.assignedBuildingIds.count) sites")
                    .font(.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AdminBuildingsContent: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let portfolioMetrics: CoreTypes.PortfolioMetrics
    let onMapToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Portfolio Overview")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                
                Spacer()
                
                Button("View Map") {
                    onMapToggle()
                }
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
            }
            
            // Buildings status grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                AdminBuildingStatusTile(
                    title: "Total",
                    count: buildings.count,
                    color: CyntientOpsDesign.DashboardColors.adminAccent
                )
                
                AdminBuildingStatusTile(
                    title: "Issues",
                    count: portfolioMetrics.criticalIssues,
                    color: portfolioMetrics.criticalIssues > 0 ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.success
                )
            }
        }
    }
}

struct AdminBuildingStatusTile: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

struct AdminAnalyticsContent: View {
    let portfolioMetrics: CoreTypes.PortfolioMetrics
    let buildingCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portfolio Performance")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            HStack(spacing: 12) {
                AdminAnalyticTile(
                    title: "Efficiency",
                    value: "\(Int(portfolioMetrics.overallCompletionRate * 100))%",
                    trend: "+5%",
                    color: CyntientOpsDesign.DashboardColors.success
                )
                
                AdminAnalyticTile(
                    title: "Compliance",
                    value: "\(Int(portfolioMetrics.complianceScore * 100))%",
                    trend: "+2%",
                    color: CyntientOpsDesign.DashboardColors.info
                )
            }
        }
    }
}

// MARK: - Missing Admin Components (Placeholder implementations)

struct AdminWorkerDetailView: View {
    let workerId: String
    let container: ServiceContainer
    
    var body: some View {
        VStack {
            Text("Worker Detail View")
            Text("Worker ID: \(workerId)")
        }
        .padding()
    }
}

struct AdminAnalyticTile: View {
    let title: String
    let value: String
    let trend: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(trend)
                    .font(.caption)
                    .foregroundColor(color)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Missing Admin Components

struct AdminProfileView: View {
    @ObservedObject var viewModel: AdminDashboardViewModel
    
    var body: some View {
        VStack {
            Text("Admin Profile")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
    }
}

struct AdminBuildingsListView: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let buildingMetrics: [String: CoreTypes.BuildingMetrics]
    let onSelectBuilding: (CoreTypes.NamedCoordinate) -> Void
    
    var body: some View {
        VStack {
            Text("Buildings List")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
    }
}

struct AdminAnalyticsView: View {
    @ObservedObject var viewModel: AdminDashboardViewModel
    
    var body: some View {
        VStack {
            Text("Analytics")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
    }
}

struct AdminEmergencyManagementView: View {
    let alerts: [CoreTypes.AdminAlert]
    
    var body: some View {
        VStack {
            Text("Emergency Management")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
    }
}

struct AdminSettingsView: View {
    var body: some View {
        VStack {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
    }
}

struct AdminPortfolioMapView: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let workers: [CoreTypes.WorkerProfile]
    
    var body: some View {
        VStack {
            Text("Portfolio Map")
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
    }
}

// MARK: - Preview
struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Admin Dashboard Preview")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .preferredColorScheme(.dark)
    }
}