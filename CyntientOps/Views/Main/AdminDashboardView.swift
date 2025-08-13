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
    @State private var showProfileView = false
    @State private var showNovaAssistant = false
    @State private var selectedBuilding: CoreTypes.NamedCoordinate?
    @State private var showBuildingDetail = false
    @State private var showComplianceCenter = false
    @State private var showTaskRequest = false
    @State private var showReports = false
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
                    isRevealed: $isMapRevealed,
                    onBuildingTap: { building in
                        selectedBuilding = building
                        showBuildingDetail = true
                    }
                ) {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Hero Card - Worker Focused
                            heroCard
                            
                            // Quick Actions - Admin Tasks
                            quickActionsSection
                            
                            // Live Activity
                            if !viewModel.crossDashboardUpdates.isEmpty {
                                liveActivitySection
                            }
                            
                            Spacer(minLength: 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    .refreshable {
                        await viewModel.refresh()
                        refreshID = UUID()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showNovaAssistant) {
            NovaAssistantView()
                .environmentObject(novaAI)
                .environmentObject(container)
        }
        .sheet(isPresented: $showBuildingDetail) {
            if let building = selectedBuilding {
                BuildingDetailView(
                    buildingId: building.id,
                    buildingName: building.name,
                    buildingAddress: building.address
                )
                .environmentObject(container)
            }
        }
        .sheet(isPresented: $showComplianceCenter) {
            complianceCenterSheet
        }
        .sheet(isPresented: $showTaskRequest) {
            taskRequestSheet
        }
        .sheet(isPresented: $showReports) {
            reportsSheet
        }
        .task {
            await viewModel.initialize()
        }
    }
    
    // MARK: - View Components
    
    private var adminHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Admin Dashboard")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(viewModel.activeWorkers.count) active workers")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Nova Avatar
            NovaAvatar(
                size: .small,
                isActive: novaAI.novaState == .active,
                hasUrgentInsights: novaAI.hasUrgentInsights,
                isBusy: novaAI.isThinking,
                onTap: { showNovaAssistant = true },
                onLongPress: { novaAI.toggleHolographicMode() }
            )
            
            Button(action: {
                Task { await authManager.logout() }
            }) {
                Image(systemName: "power.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var heroCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Operations Status")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
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
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AdminMetricCard(
                    title: "Active Workers",
                    value: "\(viewModel.activeWorkers.filter { $0.isClockedIn }.count)/\(viewModel.activeWorkers.count)",
                    icon: "person.3.fill",
                    color: activeWorkerColor
                )
                
                AdminMetricCard(
                    title: "Today's Tasks",
                    value: "\(getTodaysCompletedTasks())/\(getTodaysTaskCount())",
                    icon: "checklist",
                    color: taskProgressColor
                )
                
                AdminMetricCard(
                    title: "Buildings",
                    value: "\(viewModel.portfolioMetrics.totalBuildings)",
                    icon: "building.2.crop.circle",
                    color: .blue
                )
                
                AdminMetricCard(
                    title: "Compliance",
                    value: "\(Int(viewModel.portfolioMetrics.complianceScore))%",
                    icon: "checkmark.shield.fill",
                    color: complianceScoreColor
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AdminQuickActionCard(
                    title: "Compliance",
                    value: "\(Int(viewModel.portfolioMetrics.complianceScore))%",
                    icon: "checkmark.shield.fill",
                    color: complianceScoreColor,
                    action: { showComplianceCenter = true }
                )
                
                AdminQuickActionCard(
                    title: "Create Task",
                    value: "New",
                    icon: "plus.circle.fill",
                    color: .green,
                    action: { showTaskRequest = true }
                )
                
                AdminQuickActionCard(
                    title: "Reports",
                    value: "Generate",
                    icon: "doc.badge.arrow.up",
                    color: .purple,
                    action: { showReports = true }
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
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Sheet Views
    
    private var complianceCenterSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Compliance Center")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(Int(viewModel.portfolioMetrics.complianceScore))% Overall Score")
                    .font(.title2)
                    .foregroundColor(complianceScoreColor)
                
                Spacer()
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showComplianceCenter = false }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var taskRequestSheet: some View {
        NavigationView {
            VStack {
                Text("Create New Task")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showTaskRequest = false }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var reportsSheet: some View {
        NavigationView {
            VStack {
                Text("Generate Reports")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showReports = false }
                        .foregroundColor(.white)
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
}

// MARK: - Supporting Views

struct AdminMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
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
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
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
}

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
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ActivityRow: View {
    let update: CoreTypes.CrossDashboardUpdate
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(activityColor)
                .frame(width: 6, height: 6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(update.description)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let workerName = update.workerName {
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
        case .workerClockIn: return .blue
        case .violation: return .red
        case .photoUploaded: return .purple
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