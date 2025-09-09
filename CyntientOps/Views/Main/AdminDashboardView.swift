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
#if canImport(UIKit)
import UIKit
#endif
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
        case profile, buildings, buildingDetail(String), workers, compliance, schedules, analytics, reports, emergencies, settings
        case workerDetail(String), chat, map
        case exampleReport(String)
        case verificationSummary
        case maintenanceHistory(String?)
        case dsnySheet(String?)
        case dobSheet(String?)
        case hpdSheet(String?)
        
        var id: String {
            switch self {
            case .profile: return "profile"
            case .buildings: return "buildings"
            case .buildingDetail(let id): return "building-\(id)"
            case .workers: return "workers"
            case .compliance: return "compliance"
            case .analytics: return "analytics"
            case .schedules: return "schedules"
            case .reports: return "reports"
            case .emergencies: return "emergencies"
            case .settings: return "settings"
            case .workerDetail(let id): return "worker-\(id)"
            case .chat: return "chat"
            case .map: return "map"
            case .exampleReport(let id): return "example-report-\(id)"
            case .verificationSummary: return "verification-summary"
            case .maintenanceHistory(let id): return "maintenance-history-\(id ?? "portfolio")"
            case .dsnySheet(let id): return "dsny-sheet-\(id ?? "portfolio")"
            case .dobSheet(let id): return "dob-sheet-\(id ?? "portfolio")"
            case .hpdSheet(let id): return "hpd-sheet-\(id ?? "portfolio")"
        }
    }
    }
    
    // MARK: - Nova Intelligence Tabs (mirroring client)
    enum AdminNovaTab: String, CaseIterable {
        case priorities = "Priorities"
        case routines = "Routines"
        case workers = "Workers"
        case buildings = "Buildings"
        case compliance = "Compliance"
        case analytics = "Analytics"
        
        var icon: String {
            switch self {
            case .priorities: return "exclamationmark.triangle"
            case .routines: return "checklist"
            case .workers: return "person.2"
            case .buildings: return "building.2"
            case .compliance: return "checkmark.shield.fill"
            case .analytics: return "chart.bar"
            }
        }
    }
    
    // MARK: - State
    @State private var heroExpanded = true
    @State private var selectedNovaTab: AdminNovaTab = .priorities
    @State private var activeSheet: AdminRoute?
    @State private var isPortfolioMapRevealed = false
    @State private var intelligencePanelExpanded = false
    @State private var exampleReportText: String? = nil
    
    // MARK: - Body
    public var body: some View {
        MapRevealContainer(
            buildings: viewModel.buildings,
            currentBuildingId: nil,
            focusBuildingId: nil,
            forceShowAll: true,
            adminMode: true,
            hpdBuildingIds: Set(viewModel.hpdViolationsData.compactMap { (bid, list) in list.first(where: { $0.isActive }) != nil ? bid : nil }),
            dsnyBuildingIds: Set(viewModel.dsnyViolationsByBuilding.compactMap { (bid, list) in list.first(where: { $0.isActive }) != nil ? bid : nil }),
            isRevealed: $isPortfolioMapRevealed,
            container: container,
            onBuildingTap: { building in
                activeSheet = .buildingDetail(building.id)
            }
        ) {
            ZStack {
                // Dark Background
                CyntientOpsDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header (role-specific)
                    AdminDashboardHeader(
                        adminName: authManager.currentUser?.name ?? "Administrator",
                        totalBuildings: viewModel.buildingCount,
                        activeWorkers: viewModel.workersActive,
                        criticalAlerts: viewModel.criticalAlerts.count,
                        syncStatus: viewModel.dashboardSyncStatus,
                        onProfileTap: { activeSheet = .profile },
                        onNovaTap: { activeSheet = .chat }
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
                            onBuildingsTap: { activeSheet = .buildings },
                            onWorkersTap: { activeSheet = .workers },
                            onComplianceTap: { activeSheet = .compliance }
                        )
                        
                        // Weather Impact Ribbon (portfolio snapshot)
                        AdminWeatherRibbon(container: container)

                        // Recent Activity (admin-only, summarized & deduped)
                        RecentActivityList(
                            onOpenBuilding: { bid in activeSheet = .buildingDetail(bid) },
                            isWorker: false
                        )
                        .environmentObject(container.dashboardSync)
                            
                            // Urgent Items Section (admin-specific)
                            if hasUrgentItems() {
                                AdminUrgentItemsSection(
                                    criticalAlerts: viewModel.criticalAlerts.count,
                                    complianceIssues: getComplianceIssuesCount(),
                                    workersNeedingAttention: getWorkersNeedingAttention(),
                                    onEmergenciesTap: { activeSheet = .emergencies },
                                    onComplianceTap: { activeSheet = .compliance }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .refreshable {
                        await viewModel.refreshDashboardData()
                    }
                    
                    // Intelligence Bar docked with safe area inset (prevents covering tabs)
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .safeAreaInset(edge: .bottom) {
            AdminNovaIntelligenceBar(
                selectedTab: $selectedNovaTab,
                portfolioMetrics: viewModel.portfolioMetrics,
                buildings: viewModel.buildings,
                workers: viewModel.workers,
                criticalAlerts: viewModel.criticalAlerts,
                onTabTap: handleNovaTabTap,
                onMapToggle: handlePortfolioMapToggle,
                onEmergencyBroadcast: { activeSheet = .emergencies },
                onExampleReport: {
                    if let first = viewModel.buildings.first,
                       let report = viewModel.getDetailedPropertyReport(buildingId: first.id) {
                        exampleReportText = report
                        activeSheet = .exampleReport(first.id)
                    }
                },
                onVerificationSummary: {
                    activeSheet = .verificationSummary
                },
                // Wiring for tiles
                onIssuesTap: { activeSheet = .maintenanceHistory(nil) },
                onHPD: { activeSheet = .hpdSheet(nil) },
                onDOB: { activeSheet = .dobSheet(nil) },
                onDSNY: { activeSheet = .dsnySheet(nil) },
                onOpenSchedules: { selectedNovaTab = .routines },
                container: container,
                viewModel: viewModel
            )
            .background(.ultraThinMaterial)
        }
        .sheet(item: $activeSheet) { route in
            NavigationView {
                adminSheetContent(for: route)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NovaNavigate"))) { note in
            guard let info = note.userInfo as? [String: String] else { return }
            if let view = info["openView"] {
                switch view {
                case "admin_hpd_list":
                    activeSheet = .hpdSheet(nil)
                case "admin_dsny_list":
                    activeSheet = .dsnySheet(nil)
                case "admin_dob_list":
                    activeSheet = .dobSheet(nil)
                case "admin_building_detail":
                    if let bid = info["buildingId"] { activeSheet = .buildingDetail(bid) }
                default:
                    break
                }
            }
        }
        .task {
            await viewModel.initialize()
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
                viewModel.intelligencePanelExpanded = false
            } else {
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

    // MARK: - Symbol Fallback Utility (static so nested views can call)
    static func safeSystemSymbol(_ name: String, fallback: String) -> String {
#if canImport(UIKit)
        return UIImage(systemName: name) != nil ? name : fallback
#else
        return name
#endif
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
                        icon: AdminDashboardView.safeSystemSymbol("person.badge.exclamationmark", fallback: "person.fill.questionmark"),
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

// (removed file-scope fallback; using static helper on AdminDashboardView)

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

        case .schedules:
            AdminScheduleView(container: container)
                .navigationTitle("Portfolio Schedules")

        case .buildings:
            AdminBuildingsListView(
                buildings: viewModel.buildings,
                buildingMetrics: viewModel.buildingMetrics,
                onSelectBuilding: { building in
                    activeSheet = .buildingDetail(building.id)
                }
            )
                .navigationTitle("Portfolio Buildings")
            
        case .buildingDetail(let buildingId):
            if let building = viewModel.buildings.first(where: { $0.id == buildingId }) {
                BuildingDetailView(
                    container: container,
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
            AdminReportsView(container: container)
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
            NovaInteractionView(container: container)
                .navigationTitle("Nova Assistant")
                
        case .map:
            VStack {
                Text("Portfolio Map")
                    .font(.title2)
                Text("Map view coming soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Portfolio Map")
        
        case .maintenanceHistory(let buildingId):
            let targetId = buildingId ?? viewModel.buildings.first?.id ?? ""
            MaintenanceHistoryView(buildingID: targetId)
                .navigationTitle("Maintenance History")

        case .dsnySheet(let buildingId):
            let bId = buildingId
            DSNYSheetView(
                buildings: viewModel.buildings,
                dsnyViolations: viewModel.dsnyViolationsByBuilding,
                selectedBuildingId: bId
            )
            .navigationTitle("DSNY Summary")

        case .dobSheet(let buildingId):
            let bId = buildingId
            DOBSheetView(
                buildings: viewModel.buildings,
                permitsByBuilding: viewModel.dobPermitsData,
                selectedBuildingId: bId
            )
            .navigationTitle("DOB Permits")

        case .hpdSheet(let buildingId):
            let bId = buildingId
            HPDSheetView(
                buildings: viewModel.buildings,
                violationsByBuilding: viewModel.hpdViolationsData,
                selectedBuildingId: bId
            )
            .navigationTitle("HPD Violations")

        case .exampleReport(let buildingId):
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let report = viewModel.getDetailedPropertyReport(buildingId: buildingId) {
                        Text(report)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            .padding()
                            .cyntientOpsDarkCardBackground(cornerRadius: 12)
                    } else {
                        Text("No report available")
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                }
                .padding()
            }
            .navigationTitle("Example Report")

        case .verificationSummary:
            VerificationSummarySheet(viewModel: viewModel)
                .navigationTitle("Verification Summary")
        }
    }
}

// MARK: - Verification Summary Sheet + Export

import UniformTypeIdentifiers

struct VerificationSummarySheet: View {
    @ObservedObject var viewModel: AdminDashboardViewModel
    @State private var summaryText: String = ""
    @State private var isExporting = false
    @State private var document: TextDocument = TextDocument(text: "")

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView {
                Text(summaryText)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .padding()
                    .cyntientOpsDarkCardBackground(cornerRadius: 12)
            }
            HStack {
                Button {
                    UIPasteboard.general.string = summaryText
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)

                Button {
                    document = TextDocument(text: summaryText)
                    isExporting = true
                } label: {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
                .tint(CyntientOpsDesign.DashboardColors.adminAccent)
            }
        }
        .padding()
        .task {
            summaryText = await viewModel.getPortfolioVerificationSummary(limit: 50)
        }
        .fileExporter(isPresented: $isExporting, document: document, contentType: .commaSeparatedText, defaultFilename: "verification_summary") { _ in }
    }
}

struct TextDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText, .commaSeparatedText] }
    var text: String
    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents, let s = String(data: data, encoding: .utf8) {
            text = s
        } else { text = "" }
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return .init(regularFileWithContents: data)
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

// Legacy AdminHeaderV3B removed in favor of AdminDashboardHeader

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
                            value: workersLabel,
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

private extension AdminRealTimeHeroCard {
    var workersLabel: String {
        guard workersTotal > 0 else { return "0" }
        return activeWorkers >= workersTotal ? "All Active" : "\(activeWorkers)/\(workersTotal)"
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
    let onExampleReport: () -> Void
    let onVerificationSummary: () -> Void
    let onIssuesTap: () -> Void
    let onHPD: () -> Void
    let onDOB: () -> Void
    let onDSNY: () -> Void
    let onOpenSchedules: () -> Void
    let container: ServiceContainer
    @ObservedObject var viewModel: AdminDashboardViewModel
    
    // Panel accordion state with persistence
    enum PanelState: String { case collapsed, half, expanded }
    @AppStorage("panelState.admin") private var storedPanelState: String = PanelState.collapsed.rawValue
    @State private var panelState: PanelState = .collapsed
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Intelligence Content Panel with Dynamic Height
            intelligenceContentPanel
                .frame(height: getPanelHeight())
                .animation(CyntientOpsDesign.Animations.spring, value: selectedTab)
                .animation(CyntientOpsDesign.Animations.spring, value: panelState)
                .gesture(panelDrag)
            
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
            .overlay(alignment: .trailing) {
                HStack(spacing: 8) {
                    Chip(text: "Active: \(viewModel.workersActive)", color: CyntientOpsDesign.DashboardColors.success)
                    Button(action: onOpenSchedules) {
                        Label("Schedules", systemImage: "calendar")
                            .font(.footnote)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(CyntientOpsDesign.DashboardColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.trailing, 10)
            }
        }
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            panelState = PanelState(rawValue: storedPanelState) ?? .half
            viewModel.intelligencePanelExpanded = panelState != .collapsed
        }
        .onChange(of: panelState) { _, new in
            storedPanelState = new.rawValue
            viewModel.intelligencePanelExpanded = new != .collapsed
        }
    }
    
    private func getPanelHeight() -> CGFloat {
        let full: CGFloat = 380
        let half: CGFloat = 0.4 * UIScreen.main.bounds.height
        let collapsed: CGFloat = 64
        switch panelState {
        case .collapsed: return collapsed
        case .half: return min(half, full)
        case .expanded: return max(half, full)
        }
    }
    
    private var panelDrag: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in dragOffset = value.translation.height }
            .onEnded { value in
                withAnimation(CyntientOpsDesign.Animations.spring) {
                    if value.translation.height < -50 { // drag up
                        panelState = (panelState == .half) ? .expanded : .half
                    } else if value.translation.height > 50 { // drag down
                        panelState = (panelState == .half) ? .collapsed : .half
                    }
                    dragOffset = 0
                }
            }
    }
    
    @ViewBuilder
    private var intelligenceContentPanel: some View {
        if viewModel.intelligencePanelExpanded {
            ScrollView {
                VStack(spacing: 16) {
                    // Last Activity Ticker (keep headers clean; show here)
                    LastActivityTicker(updates: Array(viewModel.crossDashboardUpdates.suffix(8)))
                        .padding(.horizontal, 4)
                    switch selectedTab {
                    case .priorities:
                        AdminPrioritiesContent(
                            criticalAlerts: criticalAlerts,
                            portfolioMetrics: portfolioMetrics,
                            workersActive: viewModel.workersActive,
                            workersTotal: viewModel.workersTotal,
                            onEmergencyBroadcast: onEmergencyBroadcast,
                            onMapToggle: onMapToggle
                        )
                        
                    case .routines:
                        AdminRoutinesPanel(viewModel: AdminRoutinesViewModel(workerService: container.workers))
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
                            hpdOpenCount: viewModel.hpdViolationsData.values.flatMap { $0 }.filter { $0.isActive }.count,
                            dobActivePermits: viewModel.dobPermitsData.values.flatMap { $0 }.filter { !$0.isExpired }.count,
                            dsnyViolationsCount: viewModel.dsnyViolationsByBuilding.values.flatMap { $0 }.filter { $0.isActive }.count,
                            onMapToggle: onMapToggle,
                            onIssuesTap: onIssuesTap,
                            onHPD: onHPD,
                            onDOB: onDOB,
                            onDSNY: onDSNY
                        )
                        
                    case .compliance:
                        AdminComplianceContent(
                            complianceIssues: viewModel.complianceIssues,
                            hpdViolations: viewModel.hpdViolationsData.values.flatMap { $0 },
                            dsnyViolations: viewModel.dsnyViolationsByBuilding.values.flatMap { $0 },
                            complianceScore: Int(viewModel.complianceScore),
                            onMapToggle: onMapToggle
                        )
                        
                    case .analytics:
                        AdminAnalyticsContent(
                            portfolioMetrics: portfolioMetrics,
                            buildingCount: buildings.count,
                            hpdOpen: viewModel.hpdViolationsData.values.flatMap { $0 }.filter { $0.isActive }.count,
                            dsnyOpen: viewModel.dsnyViolationsByBuilding.values.flatMap { $0 }.filter { $0.isActive }.count,
                            dobActive: viewModel.dobPermitsData.values.flatMap { $0 }.filter { !$0.isExpired }.count,
                            ll97NonCompliant: viewModel.ll97EmissionsData.values.flatMap { $0 }.filter { !$0.isCompliant }.count,
                            workersActive: viewModel.workersActive,
                            workersTotal: viewModel.workersTotal,
                            complianceTrend: viewModel.complianceTrendText,
                            onExampleReport: onExampleReport,
                            onVerificationSummary: onVerificationSummary
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
        case .routines:
            return 0
        case .workers:
            return workers.filter { !$0.isClockedIn && $0.isActive }.count
        case .buildings:
            return buildings.filter { building in
                if let metrics = viewModel.buildingMetrics[building.id] {
                    return metrics.urgentTasksCount > 0
                }
                return false
            }.count
        case .compliance:
            return viewModel.complianceIssues.filter { $0.severity == .critical || $0.severity == .high }.count
        case .analytics:
            return 0
        }
    }
}

// Reusable chip
private struct Chip: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Last Activity Ticker
private struct LastActivityTicker: View {
    let updates: [CoreTypes.DashboardUpdate]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.horizontal.circle")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                Text("Last Activity")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                Spacer()
            }
            ForEach(updates.reversed(), id: \.id) { u in
                HStack(spacing: 6) {
                    Text(summary(for: u))
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    Text(shortTime(u.timestamp))
                        .font(.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
            }
        }
        .padding(8)
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func summary(for u: CoreTypes.DashboardUpdate) -> String {
        switch u.type {
        case .taskCompleted:
            let b = u.data["buildingName"] ?? u.buildingId
            return "Task completed at \(b)"
        case .workerClockedIn:
            let name = u.data["workerName"] ?? u.workerId
            let b = u.data["buildingName"] ?? u.buildingId
            return "\(name) clocked in @ \(b)"
        case .workerClockedOut:
            let name = u.data["workerName"] ?? u.workerId
            let b = u.data["buildingName"] ?? u.buildingId
            return "\(name) clocked out @ \(b)"
        case .buildingMetricsChanged:
            let b = u.data["buildingName"] ?? u.buildingId
            if let action = u.data["action"], action == "photoBatch" || action == "urgentPhoto" {
                return "Photo update at \(b)"
            }
            return "Metrics updated for \(b)"
        default:
            return u.type.rawValue
        }
    }
    
    private func shortTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }
}

// MARK: - Admin Compliance Content
struct AdminComplianceContent: View {
    let complianceIssues: [CoreTypes.ComplianceIssue]
    let hpdViolations: [HPDViolation]
    let dsnyViolations: [DSNYViolation]
    let complianceScore: Int
    let onMapToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Compliance Overview")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                
                Spacer()
                
                Button(action: onMapToggle) {
                    Image(systemName: "map")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Compliance Score
            HStack {
                VStack(alignment: .leading) {
                    Text("Portfolio Score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(complianceScore)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(complianceScore > 80 ? .green : complianceScore > 60 ? .orange : .red)
                }
                
                Spacer()
                
                // Critical Issues Count
                VStack(alignment: .trailing) {
                    Text("Critical Issues")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(complianceIssues.filter { $0.severity == .critical }.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
            
            // NYC Violations Summary
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("HPD Violations", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                    Spacer()
                    Text("\(hpdViolations.filter { $0.isActive }.count) active")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
                
                HStack {
                    Label("DSNY Violations", systemImage: "trash")
                        .font(.caption)
                    Spacer()
                    Text("\(dsnyViolations.filter { $0.isActive }.count) active")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                
                HStack {
                    Label("Total Issues", systemImage: "checkmark.shield")
                        .font(.caption)
                    Spacer()
                    Text("\(complianceIssues.count) tracked")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .cornerRadius(12)
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
    let workersActive: Int
    let workersTotal: Int
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
        func liveWorkerMessage() -> String {
            if workersTotal > 0 && workersActive == workersTotal {
                return "📡 LIVE: All workers clocked in and active"
            }
            if workersTotal > 0 {
                return "📡 LIVE: \(workersActive)/\(workersTotal) workers active"
            }
            return "📡 LIVE: No active workers"
        }
        let messages = [
            "📡 LIVE: Portfolio operating at \(Int(portfolioMetrics.overallCompletionRate * 100))% efficiency",
            liveWorkerMessage(),
            "📡 LIVE: Compliance status: \(Int(portfolioMetrics.complianceScore * 100))%",
            criticalAlerts.isEmpty ? "📡 LIVE: No critical alerts - systems nominal" : "📡 LIVE: \(criticalAlerts.count) critical alerts"
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

            // Vertical list for readability and accessibility
            VStack(spacing: 8) {
                ForEach(workers, id: \.id) { worker in
                    HStack {
                        Circle()
                            .fill(worker.isClockedIn ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.warning)
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(worker.name)
                                .font(.subheadline)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            Text(worker.isClockedIn ? "On-site" : "Off shift")
                                .font(.caption2)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                        }
                        Spacer()
                        Text("\(worker.assignedBuildingIds.count) bldgs")
                            .font(.caption2)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(CyntientOpsDesign.DashboardColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

struct AdminWorkerPill: View {
    let worker: CoreTypes.WorkerProfile
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(worker.isClockedIn ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.warning)
                .frame(width: 8, height: 8)
            Text(initials(from: worker.name))
                .font(.caption2)
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())
            Text(worker.name)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? "?"
        let last = parts.dropFirst().first?.prefix(1) ?? ""
        return String(first + last)
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
    let hpdOpenCount: Int
    let dobActivePermits: Int
    let dsnyViolationsCount: Int
    let onMapToggle: () -> Void
    let onIssuesTap: () -> Void
    let onHPD: () -> Void
    let onDOB: () -> Void
    let onDSNY: () -> Void
    
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
                Button(action: onMapToggle) { AdminBuildingStatusTile(
                    title: "Total",
                    count: buildings.count,
                    color: CyntientOpsDesign.DashboardColors.adminAccent
                ) }.buttonStyle(.plain)
                
                Button(action: { onIssuesTap() }) { AdminBuildingStatusTile(
                    title: "Issues",
                    count: portfolioMetrics.criticalIssues,
                    color: portfolioMetrics.criticalIssues > 0 ? CyntientOpsDesign.DashboardColors.critical : CyntientOpsDesign.DashboardColors.success
                ) }.buttonStyle(.plain)

                Button(action: { onDSNY() }) { AdminBuildingStatusTile(
                    title: "DSNY Open",
                    count: dsnyViolationsCount,
                    color: dsnyViolationsCount > 0 ? CyntientOpsDesign.DashboardColors.warning : CyntientOpsDesign.DashboardColors.success
                ) }.buttonStyle(.plain)

                Button(action: { onHPD() }) { AdminBuildingStatusTile(
                    title: "HPD Open",
                    count: hpdOpenCount,
                    color: hpdOpenCount > 0 ? CyntientOpsDesign.DashboardColors.warning : CyntientOpsDesign.DashboardColors.success
                ) }.buttonStyle(.plain)

                Button(action: { onDOB() }) { AdminBuildingStatusTile(
                    title: "DOB Active",
                    count: dobActivePermits,
                    color: dobActivePermits > 0 ? CyntientOpsDesign.DashboardColors.info : CyntientOpsDesign.DashboardColors.success
                ) }.buttonStyle(.plain)
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
    let hpdOpen: Int
    let dsnyOpen: Int
    let dobActive: Int
    let ll97NonCompliant: Int
    let workersActive: Int
    let workersTotal: Int
    let complianceTrend: String
    let onExampleReport: () -> Void
    let onVerificationSummary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Portfolio Performance")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)

            // Top KPIs
            HStack(spacing: 12) {
                AdminAnalyticTile(
                    title: "Efficiency",
                    value: "\(Int(portfolioMetrics.overallCompletionRate * 100))%",
                    trend: trendText(portfolioMetrics.overallCompletionRate),
                    color: CyntientOpsDesign.DashboardColors.success
                )

                AdminAnalyticTile(
                    title: "Compliance",
                    value: complianceValue,
                    trend: complianceTrend,
                    color: CyntientOpsDesign.DashboardColors.info
                )
            }

            // Compliance + Activity snapshots
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                AdminAnalyticTile(
                    title: "HPD Open",
                    value: String(hpdOpen),
                    trend: "",
                    color: hpdOpen > 0 ? CyntientOpsDesign.DashboardColors.warning : CyntientOpsDesign.DashboardColors.success
                )
                AdminAnalyticTile(
                    title: "DSNY Open",
                    value: String(dsnyOpen),
                    trend: "",
                    color: dsnyOpen > 0 ? CyntientOpsDesign.DashboardColors.warning : CyntientOpsDesign.DashboardColors.success
                )
                AdminAnalyticTile(
                    title: "DOB Active",
                    value: String(dobActive),
                    trend: "",
                    color: dobActive > 0 ? CyntientOpsDesign.DashboardColors.info : CyntientOpsDesign.DashboardColors.success
                )
                AdminAnalyticTile(
                    title: "LL97 Non-Comp",
                    value: String(ll97NonCompliant),
                    trend: "",
                    color: ll97NonCompliant > 0 ? CyntientOpsDesign.DashboardColors.warning : CyntientOpsDesign.DashboardColors.success
                )
                AdminAnalyticTile(
                    title: "Buildings",
                    value: String(buildingCount),
                    trend: "",
                    color: CyntientOpsDesign.DashboardColors.adminAccent
                )
                AdminAnalyticTile(
                    title: "Workers Active",
                    value: "\(workersActive)/\(workersTotal)",
                    trend: "",
                    color: workersActive > 0 ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.warning
                )
            }

            // Example report generator (first building)
            HStack {
                Spacer()
                Button(action: onExampleReport) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("Example Building Report")
                    }
                }
                .buttonStyle(.bordered)
                .tint(CyntientOpsDesign.DashboardColors.adminAccent)
                
                Button(action: onVerificationSummary) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal")
                        Text("Verification Summary")
                    }
                }
                .buttonStyle(.bordered)
                .tint(CyntientOpsDesign.DashboardColors.success)
            }
        }
    }

    private var complianceValue: String {
        // portfolioMetrics.complianceScore may be 0-1 or 0-100 depending on source; normalize
        if portfolioMetrics.complianceScore <= 1.0 {
            return "\(Int(portfolioMetrics.complianceScore * 100))%"
        } else {
            return "\(Int(portfolioMetrics.complianceScore))%"
        }
    }

    private func trendText(_ rate: Double) -> String {
        // Placeholder for now; compute week-over-week deltas when available
        return ""
    }
}

// MARK: - Admin Analytics Components

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

// MARK: - Missing Admin Components (Placeholder implementations)
#if false

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

struct AdminBuildingsListPlaceholder: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let buildingMetrics: [String: CoreTypes.BuildingMetrics]
    let onSelectBuilding: (CoreTypes.NamedCoordinate) -> Void
    
    var body: some View {
        VStack {
            Text("Buildings List (Placeholder)")
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

struct AdminSettingsViewEmbedded: View {
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

#endif

 
