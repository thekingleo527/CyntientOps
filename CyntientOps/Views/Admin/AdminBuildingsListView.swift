//
//  AdminBuildingsListView.swift
//  CyntientOps v6.0
//
//  ✅ COMPLETE: Admin buildings list with metrics
//

import SwiftUI

public struct AdminBuildingsListView: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let buildingMetrics: [String: CoreTypes.BuildingMetrics]
    let onSelectBuilding: (CoreTypes.NamedCoordinate) -> Void
    
    @State private var searchText = ""
    @State private var sortBy: SortOption = .name
    
    enum SortOption: String, CaseIterable {
        case name = "Name"
        case priority = "Priority"
        case compliance = "Compliance"
        
        var icon: String {
            switch self {
            case .name: return "textformat.abc"
            case .priority: return "exclamationmark.triangle"
            case .compliance: return "checkmark.shield"
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search and Sort Bar
            VStack(spacing: 12) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                    
                    TextField("Search buildings...", text: $searchText)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(CyntientOpsDesign.DashboardColors.cardBackground)
                .cornerRadius(10)
                
                // Sort Options
                HStack {
                    Text("Sort by:")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: { sortBy = option }) {
                            HStack(spacing: 4) {
                                Image(systemName: option.icon)
                                    .font(.caption2)
                                Text(option.rawValue)
                                    .font(.caption)
                            }
                            .foregroundColor(sortBy == option ? CyntientOpsDesign.DashboardColors.adminAccent : CyntientOpsDesign.DashboardColors.tertiaryText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(sortBy == option ? CyntientOpsDesign.DashboardColors.adminAccent.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Buildings List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredAndSortedBuildings, id: \.id) { building in
                        AdminBuildingListItem(
                            building: building,
                            metrics: buildingMetrics[building.id],
                            onTap: { onSelectBuilding(building) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
    }
    
    private var filteredAndSortedBuildings: [CoreTypes.NamedCoordinate] {
        let filtered = searchText.isEmpty ? buildings : buildings.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
        
        return filtered.sorted { building1, building2 in
            switch sortBy {
            case .name:
                return building1.name < building2.name
            case .priority:
                let metrics1 = buildingMetrics[building1.id]
                let metrics2 = buildingMetrics[building2.id]
                return (metrics1?.urgentTasksCount ?? 0) > (metrics2?.urgentTasksCount ?? 0)
            case .compliance:
                let metrics1 = buildingMetrics[building1.id]
                let metrics2 = buildingMetrics[building2.id]
                return (metrics1?.complianceScore ?? 0) < (metrics2?.complianceScore ?? 0)
            }
        }
    }
}

struct AdminBuildingListItem: View {
    let building: CoreTypes.NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    let onTap: () -> Void
    
    var buildingImageAssetName: String? {
        let address = building.address
        return address
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Building Image
                ZStack {
                    if let assetName = buildingImageAssetName,
                       UIImage(named: assetName) != nil {
                        Image(assetName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [.blue.opacity(0.6), .purple.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "building.2")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.8))
                            )
                    }
                    
                    // Status indicator overlay
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(statusColor)
                                .frame(width: 12, height: 12)
                                .shadow(color: .black.opacity(0.3), radius: 1)
                        }
                        Spacer()
                        if let metrics = metrics, metrics.urgentTasksCount > 0 {
                            HStack {
                                Spacer()
                                Text("\\(metrics.urgentTasksCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(statusColor)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding(4)
                }
                .cornerRadius(12)
                
                // Building Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                    
                    Text(building.address)
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        .lineLimit(1)
                    
                    // Metrics Summary
                    if let metrics = metrics {
                        HStack(spacing: 12) {
                            AdminBuildingMetricPill(
                                label: "Tasks",
                                value: "\\(metrics.totalTasks - metrics.pendingTasks)/\\(metrics.totalTasks)",
                                color: taskProgressColor(metrics)
                            )
                            
                            AdminBuildingMetricPill(
                                label: "Compliance",
                                value: "\\(Int(metrics.complianceScore * 100))%",
                                color: complianceColor(metrics)
                            )
                        }
                    }
                }
                
                Spacer()
                
                // Navigation Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(CyntientOpsDesign.DashboardColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(statusColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        guard let metrics = metrics else { return CyntientOpsDesign.DashboardColors.info }
        
        if metrics.urgentTasksCount > 0 || metrics.overdueTasks > 0 {
            return CyntientOpsDesign.DashboardColors.critical
        } else if metrics.complianceScore < 0.8 {
            return CyntientOpsDesign.DashboardColors.warning
        }
        return CyntientOpsDesign.DashboardColors.success
    }
    
    private func taskProgressColor(_ metrics: CoreTypes.BuildingMetrics) -> Color {
        let completed = metrics.totalTasks - metrics.pendingTasks
        let ratio = metrics.totalTasks > 0 ? Double(completed) / Double(metrics.totalTasks) : 0
        
        if ratio >= 0.8 {
            return CyntientOpsDesign.DashboardColors.success
        } else if ratio >= 0.6 {
            return CyntientOpsDesign.DashboardColors.warning
        }
        return CyntientOpsDesign.DashboardColors.critical
    }
    
    private func complianceColor(_ metrics: CoreTypes.BuildingMetrics) -> Color {
        if metrics.complianceScore >= 0.8 {
            return CyntientOpsDesign.DashboardColors.success
        } else if metrics.complianceScore >= 0.6 {
            return CyntientOpsDesign.DashboardColors.warning
        }
        return CyntientOpsDesign.DashboardColors.critical
    }
}

struct AdminProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct AdminSettingRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AdminInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        }
        .padding(.vertical, 4)
    }
}

struct AdminBuildingMetricPill: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}