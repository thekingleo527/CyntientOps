//
//  AdminDashboardView.swift
//  CyntientOps v6.0
//
//  ✅ REFACTORED: Clean, streamlined admin dashboard
//  ✅ WORKER FOCUSED: Hero card shows worker metrics, quick actions for admin tasks
//  ✅ NOVA AI: Integrated with NovaAIManager and persistent avatar
//  ✅ SERVICE CONTAINER: Proper dependency injection
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
    @State private var showNovaAssistant = false
    @State private var selectedBuilding: CoreTypes.NamedCoordinate?
    @State private var isMapRevealed = false
    @State private var refreshID = UUID()
    
    // MARK: - Initialization
    init(viewModel: AdminDashboardViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Admin Header
                adminHeader
                
                // Main content with map reveal
                MapRevealContainer(
                    buildings: viewModel.buildings,
                    currentBuildingId: nil,
                    focusBuildingId: nil,
                    isRevealed: $isMapRevealed,
                    onBuildingTap: { building in
                        selectedBuilding = building
                        viewModel.sheet = .buildings
                    }
                ) {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Hero Card with KPIs and Next Actions
                            heroCard
                            
                            // Quick Actions - Admin Tasks  
                            quickActionsSection
                            
                            // Live Activity
                            if !viewModel.crossDashboardUpdates.isEmpty {
                                liveActivitySection
                            }
                            
                            Spacer(minLength: 80) // Reserve space for intelligence bar
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    .refreshable {
                        await viewModel.refreshDashboardData()
                        refreshID = UUID()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            NovaAdminIntelligenceBar(
                container: container,
                adminContext: [
                    "adminName": "Admin Dashboard",
                    "totalBuildings": viewModel.buildingCount,
                    "activeWorkers": viewModel.workersActive,
                    "totalWorkers": viewModel.workersTotal,
                    "portfolioCompletion": "\(Int(viewModel.completionToday * 100))%",
                    "complianceScore": viewModel.complianceScore,
                    "criticalAlerts": viewModel.criticalAlerts.count
                ],
                novaManager: novaAI
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(item: $viewModel.sheet) { route in
            adminSheetContent(for: route)
        }
        .task {
            await viewModel.initialize()
        }
    }
    
    // MARK: - View Components
    
    private var adminHeader: some View {
        HStack(spacing: 16) {
            // Left: CyntientOps brand pill
            HStack(spacing: 8) {
                Image(systemName: "building.columns.fill")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
                    .font(.title3)
                Text("CyntientOps")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.6))
            .clipShape(Capsule())
            
            // Center-left: Nova avatar/status
            NovaAvatar(
                size: .small,
                isActive: novaAI.novaState == .active,
                hasUrgentInsights: novaAI.hasUrgentInsights,
                isBusy: novaAI.isThinking,
                onTap: { showNovaAssistant = true },
                onLongPress: { novaAI.toggleHolographicMode() }
            )
            
            Spacer()
            
            // Sync indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.isSynced ? .green : .red)
                    .frame(width: 6, height: 6)
                Text(viewModel.lastSyncAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Right: Admin user pill
            Button(action: { viewModel.sheet = .profile }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.adminAccent.gradient)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("AD")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    Text("Admin")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.6))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var heroCard: some View {
        VStack(spacing: 16) {
            // Operations Status Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Operations Command")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(viewModel.isSynced ? .green : .red)
                            .frame(width: 6, height: 6)
                        Text(viewModel.isSynced ? "LIVE" : "OFFLINE")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.isSynced ? .green : .red)
                    }
                }
                
                Spacer()
            }
            
            // Pressable KPI Row
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Buildings KPI
                Button(action: { viewModel.sheet = .buildings }) {
                    AdminKPICard(
                        icon: "building.2.fill",
                        title: "Buildings",
                        value: "\(viewModel.buildingCount)",
                        color: CyntientOpsDesign.DashboardColors.adminAccent
                    )
                }
                .buttonStyle(.plain)
                
                // Active Workers KPI
                Button(action: { viewModel.sheet = .workers }) {
                    AdminKPICard(
                        icon: "person.2.fill",
                        title: "Active Workers", 
                        value: "\(viewModel.workersActive)/\(viewModel.workersTotal)",
                        color: CyntientOpsDesign.DashboardColors.success
                    )
                }
                .buttonStyle(.plain)
                
                // Compliance KPI
                Button(action: { viewModel.sheet = .compliance }) {
                        AdminKPICard(
                        icon: "checkmark.shield.fill",
                        title: "Compliance",
                        value: "\(Int(viewModel.complianceScore*100))%",
                        color: getComplianceColor()
                    )
                }
                .buttonStyle(.plain)
                
                // Completion Today KPI
                Button(action: { viewModel.sheet = .analytics }) {
                    AdminKPICard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Completion Today",
                        value: "\(Int(viewModel.completionToday*100))%",
                        color: getCompletionColor()
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Next Actions Row
            VStack(alignment: .leading, spacing: 8) {
                Text("Next Actions")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                
                HStack(spacing: 8) {
                    // Emergencies Chip
                    if !viewModel.criticalAlerts.isEmpty {
                        Button(action: { viewModel.sheet = .emergencies }) {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                Text("Emergencies (\(viewModel.criticalAlerts.count))")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.red.opacity(0.2))
                            .clipShape(Capsule())
                        }
                    }
                    
                    // Reports Chip
                    Button(action: { viewModel.sheet = .reports }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
                                .font(.caption)
                            Text("Generate Reports")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(CyntientOpsDesign.DashboardColors.adminAccent.opacity(0.2))
                        .clipShape(Capsule())
                    }
                    
                    // Map Toggle Chip
                    Button(action: { isMapRevealed.toggle() }) {
                        HStack(spacing: 4) {
                            Image(systemName: isMapRevealed ? "map.fill" : "map")
                                .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                                .font(.caption)
                            Text("Open Map")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(CyntientOpsDesign.DashboardColors.info.opacity(0.2))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AdminQuickActionCard(
                    title: "Compliance",
                    value: "\(Int(viewModel.portfolioMetrics.complianceScore))%",
                    icon: "checkmark.shield.fill",
                    color: complianceScoreColor,
                    action: { viewModel.sheet = .compliance }
                )
                
                AdminQuickActionCard(
                    title: "Create Task",
                    value: "New",
                    icon: "plus.circle.fill",
                    color: .green,
                    action: { viewModel.sheet = .workers }
                )
                
                AdminQuickActionCard(
                    title: "Reports",
                    value: "Generate",
                    icon: "doc.badge.arrow.up",
                    color: .purple,
                    action: { viewModel.sheet = .reports }
                )
                
                AdminQuickActionCard(
                    title: "Portfolio Map",
                    value: "View",
                    icon: "map.fill",
                    color: .blue,
                    action: { isMapRevealed.toggle() }
                )
            }
        }
    }
    
    private var liveActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Activity", systemImage: "dot.radiowaves.left.and.right")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            VStack(spacing: 8) {
                ForEach(viewModel.crossDashboardUpdates.prefix(5)) { update in
                    ActivityRow(update: update)
                }
            }
        }
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Sheet Content
    
    @ViewBuilder
    private func adminSheetContent(for route: AdminDashboardViewModel.AdminRoute) -> some View {
        NavigationView {
            switch route {
                case .buildings:
                    if let building = selectedBuilding {
                        BuildingDetailView(
                            buildingId: building.id,
                            buildingName: building.name,
                            buildingAddress: building.address
                        )
                        .environmentObject(container)
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { viewModel.sheet = nil }
                                    .foregroundColor(.white)
                            }
                        }
                    } else {
                        VStack {
                            Text("Buildings Management")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                            Text("Portfolio buildings overview")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { viewModel.sheet = nil }
                                    .foregroundColor(.white)
                            }
                        }
                    }
                case .workers:
                    AdminWorkerManagementView()
                        .environmentObject(container)
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { viewModel.sheet = nil }
                                    .foregroundColor(.white)
                            }
                        }
                case .compliance:
                    ComplianceOverviewView()
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { viewModel.sheet = nil }
                                    .foregroundColor(.white)
                            }
                        }
                case .reports:
                    AdminReportsView()
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") { viewModel.sheet = nil }
                                    .foregroundColor(.white)
                            }
                        }
                case .emergencies:
                    VStack {
                        Text("Emergency Management")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text("Critical alerts and emergency response")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { viewModel.sheet = nil }
                                .foregroundColor(.white)
                        }
                    }
                case .analytics:
                    VStack {
                        Text("Analytics Dashboard") 
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text("Portfolio performance analytics")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { viewModel.sheet = nil }
                                .foregroundColor(.white)
                        }
                    }
                case .profile:
                    VStack {
                        Text("Admin Profile")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text("Administrator profile and account settings")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { viewModel.sheet = nil }
                                .foregroundColor(.white)
                        }
                    }
                case .settings:
                    VStack {
                        Text("Admin Settings")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                        Text("System configuration and admin preferences")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { viewModel.sheet = nil }
                                .foregroundColor(.white)
                        }
                    }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getTodaysTaskCount() -> Int {
        return viewModel.activeWorkers.filter { $0.isClockedIn }.count * 3 + viewModel.portfolioMetrics.totalBuildings
    }
    
    private func getTodaysCompletedTasks() -> Int {
        let todaysTasks = getTodaysTaskCount()
        return Int(Double(todaysTasks) * viewModel.portfolioMetrics.overallCompletionRate)
    }
    
    private var activeWorkerColor: Color {
        let activeCount = viewModel.activeWorkers.filter { $0.isClockedIn }.count
        let totalCount = viewModel.activeWorkers.count
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
    
    private var complianceScoreColor: Color {
        let score = viewModel.portfolioMetrics.complianceScore
        if score >= 90 { return .green }
        if score >= 80 { return .yellow }
        if score >= 70 { return .orange }
        return .red
    }
    
    private func getComplianceColor() -> Color {
        if viewModel.complianceScore >= 0.9 { return CyntientOpsDesign.DashboardColors.success }
        else if viewModel.complianceScore >= 0.7 { return CyntientOpsDesign.DashboardColors.warning }
        else { return CyntientOpsDesign.DashboardColors.critical }
    }
    
    private func getCompletionColor() -> Color {
        if viewModel.completionToday >= 0.8 { return CyntientOpsDesign.DashboardColors.success }
        else if viewModel.completionToday >= 0.6 { return CyntientOpsDesign.DashboardColors.warning }
        else { return CyntientOpsDesign.DashboardColors.critical }
    }
}

// MARK: - Supporting Views

struct AdminQuickActionCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.3))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityRow: View {
    let update: CoreTypes.DashboardUpdate
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(activityColor)
                .frame(width: 6, height: 6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(update.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let workerName = update.data["workerName"] {
                    Text(workerName)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            Text(update.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
    
    private var activityColor: Color {
        switch update.type {
        case .taskCompleted: return .green
        case .workerClockedIn, .workerClockedOut: return .blue
        case .criticalAlert, .criticalUpdate: return .red
        case .buildingMetricsChanged: return .purple
        case .complianceStatusChanged, .complianceUpdate: return .orange
        default: return .gray
        }
    }
}

struct NovaAssistantView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var novaAI: NovaAIManager
    
    var body: some View {
        NavigationView {
            VStack {
                NovaAvatar(
                    size: .large,
                    isActive: novaAI.novaState == .active,
                    hasUrgentInsights: novaAI.hasUrgentInsights,
                    isBusy: novaAI.isThinking
                )
                .padding()
                
                Text("Nova AI Assistant")
                    .font(.title)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationTitle("Nova Assistant")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Admin KPI Card Component

struct AdminKPICard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text(title)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
        .frame(minHeight: 80)
        .frame(maxWidth: .infinity)
        .padding()
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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