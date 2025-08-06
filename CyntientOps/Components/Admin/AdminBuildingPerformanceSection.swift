//
//  AdminBuildingPerformanceSection.swift
//  CyntientOps Phase 4
//
//  Building performance grid section for admin dashboard
//

import SwiftUI

struct AdminBuildingPerformanceSection: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let buildingMetrics: [String: CoreTypes.BuildingMetrics]
    let onBuildingTap: (CoreTypes.NamedCoordinate) -> Void
    let onViewAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text("Building Performance")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                StatusPill(text: "\(buildings.count)", color: .blue, style: .outlined)
                
                Spacer()
                
                Button(action: onViewAll) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Building Grid (2 columns)
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 12) {
                ForEach(buildings) { building in
                    AdminBuildingPerformanceCard(
                        building: building,
                        metrics: buildingMetrics[building.id],
                        onTap: { onBuildingTap(building) }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct AdminBuildingPerformanceCard: View {
    let building: CoreTypes.NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    let onTap: () -> Void
    
    private var performanceColor: Color {
        guard let metrics = metrics else { return .gray }
        if metrics.completionRate >= 0.8 { return .green }
        if metrics.completionRate >= 0.6 { return .orange }
        return .red
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Building Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(building.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(building.type.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    Circle()
                        .fill(performanceColor)
                        .frame(width: 8, height: 8)
                }
                
                // Performance Bar
                if let metrics = metrics {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(Int(metrics.completionRate * 100))%")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(performanceColor)
                            
                            Spacer()
                            
                            Text("Complete")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(performanceColor)
                                    .frame(width: geometry.size.width * metrics.completionRate, height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                    
                    // Metrics Row
                    HStack {
                        AdminBuildingMetricBadge(
                            icon: "person.fill",
                            value: "\(metrics.activeWorkers)",
                            color: metrics.activeWorkers > 0 ? .green : .gray
                        )
                        
                        if metrics.overdueTasks > 0 {
                            AdminBuildingMetricBadge(
                                icon: "clock.badge.exclamationmark",
                                value: "\(metrics.overdueTasks)",
                                color: .red
                            )
                        }
                        
                        if metrics.criticalIssues > 0 {
                            AdminBuildingMetricBadge(
                                icon: "exclamationmark.triangle.fill",
                                value: "\(metrics.criticalIssues)",
                                color: .red
                            )
                        }
                        
                        Spacer()
                    }
                } else {
                    // No metrics available
                    VStack {
                        Text("No data")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(performanceColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AdminBuildingMetricBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(color)
            
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(color.opacity(0.2))
        .cornerRadius(4)
    }
}

#if DEBUG
struct AdminBuildingPerformanceSection_Previews: PreviewProvider {
    static var previews: some View {
        let mockBuildings = [
            CoreTypes.NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                address: "150 W 17th St",
                latitude: 40.7408,
                longitude: -73.9971,
                type: .educational
            ),
            CoreTypes.NamedCoordinate(
                id: "1",
                name: "JM Building A",
                address: "123 Main St",
                latitude: 40.7500,
                longitude: -73.9800,
                type: .residential
            ),
            CoreTypes.NamedCoordinate(
                id: "2",
                name: "Solar One Building",
                address: "456 Green Ave",
                latitude: 40.7600,
                longitude: -73.9700,
                type: .commercial
            ),
            CoreTypes.NamedCoordinate(
                id: "3",
                name: "Grand Elizabeth LLC",
                address: "789 Grand St",
                latitude: 40.7700,
                longitude: -73.9600,
                type: .residential
            )
        ]
        
        let mockMetrics = [
            "14": CoreTypes.BuildingMetrics(
                completionRate: 0.85,
                activeWorkers: 2,
                overdueTasks: 0,
                criticalIssues: 0
            ),
            "1": CoreTypes.BuildingMetrics(
                completionRate: 0.65,
                activeWorkers: 1,
                overdueTasks: 2,
                criticalIssues: 1
            ),
            "2": CoreTypes.BuildingMetrics(
                completionRate: 0.92,
                activeWorkers: 1,
                overdueTasks: 0,
                criticalIssues: 0
            ),
            "3": CoreTypes.BuildingMetrics(
                completionRate: 0.45,
                activeWorkers: 0,
                overdueTasks: 5,
                criticalIssues: 2
            )
        ]
        
        AdminBuildingPerformanceSection(
            buildings: mockBuildings,
            buildingMetrics: mockMetrics,
            onBuildingTap: { _ in },
            onViewAll: { }
        )
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
#endif