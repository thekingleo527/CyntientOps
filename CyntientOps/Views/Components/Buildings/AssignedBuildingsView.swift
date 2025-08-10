//
//  AssignedBuildingsView.swift
//  CyntientOps v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Uses reusable PropertyCard component
//  ✅ INTEGRATED: CyntientOpsDesign system
//  ✅ IMPROVED: Better visual hierarchy and animations
//  ✅ OPTIMIZED: Consistent with BuildingsView pattern
//

import SwiftUI
import Foundation

struct AssignedBuildingsView: View {
    @StateObject private var contextEngine = WorkerContextEngine.shared
    @Environment(\.dismiss) private var dismiss
    
    // Use BuildingService directly without StateObject
    private let buildingService = BuildingService.shared
    
    @State private var buildingMetrics: [String: BuildingMetrics] = [:]
    @State private var isLoading = true
    
    var assignedBuildings: [NamedCoordinate] {
        contextEngine.assignedBuildings
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark Elegance Background
                CyntientOpsDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom header
                    headerView
                    
                    // Content
                    if assignedBuildings.isEmpty {
                        emptyState
                    } else {
                        buildingsList
                    }
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
            .task {
                await loadBuildingMetrics()
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Buildings")
                        .francoTypography(CyntientOpsDesign.Typography.title)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    if !assignedBuildings.isEmpty {
                        Text("\(assignedBuildings.count) assigned")
                            .francoTypography(CyntientOpsDesign.Typography.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    }
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .francoTypography(CyntientOpsDesign.Typography.body)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
            }
            .padding(CyntientOpsDesign.Spacing.md)
            
            // Separator
            Rectangle()
                .fill(CyntientOpsDesign.DashboardColors.borderSubtle)
                .frame(height: 1)
        }
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.95))
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        FrancoEmptyState(
            icon: "building.2.crop.circle",
            title: "No Buildings Assigned",
            message: "Contact your supervisor to get building assignments",
            action: contactSupervisor,
            actionTitle: "Contact Supervisor",
            role: .worker
        )
        .padding(CyntientOpsDesign.Spacing.lg)
    }
    
    // MARK: - Buildings List
    
    private var buildingsList: some View {
        ScrollView {
            LazyVStack(spacing: CyntientOpsDesign.Spacing.sm) {
                ForEach(assignedBuildings, id: \.id) { building in
                    NavigationLink {
                        BuildingDetailView(
                            buildingId: building.id,
                            buildingName: building.name,
                            buildingAddress: building.address
                        )
                    } label: {
                        AssignedBuildingCard(
                            building: building,
                            metrics: buildingMetrics[building.id],
                            isCurrentBuilding: isCurrentBuilding(building),
                            isPrimaryAssignment: isPrimaryAssignment(building),
                            taskCount: getTaskCount(for: building)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(CyntientOpsDesign.Spacing.md)
        }
    }
    
    // MARK: - Helper Methods
    
    private func isCurrentBuilding(_ building: CoreTypes.NamedCoordinate) -> Bool {
        contextEngine.clockInStatus.isClockedIn &&
        contextEngine.clockInStatus.building?.id == building.id
    }
    
    private func isPrimaryAssignment(_ building: CoreTypes.NamedCoordinate) -> Bool {
        contextEngine.assignedBuildings.first?.id == building.id
    }
    
    private func getTaskCount(for building: CoreTypes.NamedCoordinate) -> Int {
        contextEngine.getTasksForBuilding(building.id).count
    }
    
    private func contactSupervisor() {
        if let url = URL(string: "mailto:shawn@francomanagementgroup.com?subject=Building%20Assignment%20Request") {
            UIApplication.shared.open(url)
        }
    }
    
    private func loadBuildingMetrics() async {
        isLoading = true
        
        // Load metrics for each assigned building
        await withTaskGroup(of: (String, BuildingMetrics?).self) { group in
            for building in assignedBuildings {
                group.addTask {
                    do {
                        let metrics = try await self.buildingService.getBuildingMetrics(building.id)
                        return (building.id, metrics)
                    } catch {
                        return (building.id, nil)
                    }
                }
            }
            
            // Collect results
            var metricsMap: [String: BuildingMetrics] = [:]
            for await (buildingId, metrics) in group {
                if let metrics = metrics {
                    metricsMap[buildingId] = metrics
                }
            }
            
            await MainActor.run {
                self.buildingMetrics = metricsMap
                self.isLoading = false
            }
        }
    }
}

// MARK: - Assigned Building Card Component

struct AssignedBuildingCard: View {
    let building: CoreTypes.NamedCoordinate
    let metrics: BuildingMetrics?
    let isCurrentBuilding: Bool
    let isPrimaryAssignment: Bool
    let taskCount: Int
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: CyntientOpsDesign.Spacing.md) {
            // Building image using PropertyCard
            PropertyCard(
                building: building,
                metrics: metrics,
                mode: .worker,
                onTap: { }
            )
            .frame(width: 60, height: 60)
            
            // Building info
            VStack(alignment: .leading, spacing: CyntientOpsDesign.Spacing.xs) {
                Text(building.displayName)
                    .francoTypography(CyntientOpsDesign.Typography.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    .lineLimit(2)
                
                Text(building.fullAddress)
                    .francoTypography(CyntientOpsDesign.Typography.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .lineLimit(1)
                
                // Status badges
                HStack(spacing: CyntientOpsDesign.Spacing.sm) {
                    if isCurrentBuilding {
                        BuildingStatusBadge(
                            label: "CURRENT",
                            icon: "location.fill",
                            color: CyntientOpsDesign.DashboardColors.success
                        )
                    } else if isPrimaryAssignment {
                        BuildingStatusBadge(
                            label: "PRIMARY",
                            icon: "star.fill",
                            color: CyntientOpsDesign.DashboardColors.warning
                        )
                    } else {
                        BuildingStatusBadge(
                            label: "Assigned",
                            icon: "checkmark.circle.fill",
                            color: CyntientOpsDesign.DashboardColors.info
                        )
                    }
                    
                    Spacer()
                    
                    // Task count with metrics
                    if let metrics = metrics {
                        HStack(spacing: 4) {
                            if metrics.urgentTasksCount > 0 {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
                            }
                            
                            Text("\(taskCount) tasks")
                                .francoTypography(CyntientOpsDesign.Typography.caption)
                                .foregroundColor(taskCount > 0 ?
                                    CyntientOpsDesign.DashboardColors.warning :
                                    CyntientOpsDesign.DashboardColors.tertiaryText
                                )
                        }
                    } else if taskCount > 0 {
                        Text("\(taskCount) tasks")
                            .francoTypography(CyntientOpsDesign.Typography.caption)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
                    }
                }
                
                // Completion progress if available
                if let metrics = metrics {
                    FrancoMetricsProgress(value: metrics.completionRate, role: .worker)
                        .frame(height: 4)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
        }
        .francoCardPadding()
        .background(
            RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.lg)
                .fill(isCurrentBuilding ?
                    CyntientOpsDesign.DashboardColors.success.opacity(0.1) :
                    CyntientOpsDesign.DashboardColors.cardBackground
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.lg)
                        .stroke(
                            isCurrentBuilding ?
                            CyntientOpsDesign.DashboardColors.success.opacity(0.3) :
                            CyntientOpsDesign.DashboardColors.borderSubtle,
                            lineWidth: 1
                        )
                )
        )
        .francoShadow(CyntientOpsDesign.Shadow.sm)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(CyntientOpsDesign.Animations.quick) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(CyntientOpsDesign.Animations.quick) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Preview

struct AssignedBuildingsView_Previews: PreviewProvider {
    static var previews: some View {
        AssignedBuildingsView()
            .preferredColorScheme(.dark)
    }
}
