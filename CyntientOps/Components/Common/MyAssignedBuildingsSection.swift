//
//  MyAssignedBuildingsSection.swift
//  CyntientOps v6.0
//
//  ✅ GLASS MORPHISM: Aligned with v6.0 design language
//  ✅ FIXED: Removed imageAssetName references (not in NamedCoordinate)
//  ✅ ENHANCED: Grid layout matching WorkerDashboardView
//  ✅ METRICS: Retained real-time building metrics display
//

import SwiftUI

struct MyAssignedBuildingsSection: View {
    let buildings: [NamedCoordinate]
    let primaryBuilding: NamedCoordinate?
    let onBuildingTap: (NamedCoordinate) -> Void
    let onShowAllBuildings: () -> Void
    
    // Service references
    private let buildingMetricsService = BuildingMetricsService.shared
    
    @State private var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @State private var isLoadingMetrics = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Glass header
            glassHeader
            
            if buildings.isEmpty {
                glassEmptyState
            } else {
                // Grid layout matching WorkerDashboardView
                buildingsGrid
            }
        }
        .task {
            await loadAllBuildingMetrics()
        }
    }
    
    // MARK: - Glass Header
    
    private var glassHeader: some View {
        HStack {
            Text("My Buildings")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: onShowAllBuildings) {
                HStack(spacing: 4) {
                    Text("All")
                    Image(systemName: "chevron.right")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }
    
    // MARK: - Buildings Grid
    
    private var buildingsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(buildings, id: \.id) { building in
                GlassBuildingMetricCard(
                    building: building,
                    isPrimary: building.id == primaryBuilding?.id,
                    metrics: buildingMetrics[building.id],
                    isLoadingMetrics: isLoadingMetrics,
                    onTap: { onBuildingTap(building) }
                )
            }
        }
    }
    
    // MARK: - Glass Empty State
    
    private var glassEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Buildings Assigned")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Contact your supervisor to get building assignments")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .francoCardPadding()
        .francoGlassBackground()
        .francoShadow(CyntientOpsDesign.Shadow.glassCard)
    }
    
    // MARK: - Metrics Loading
    
    private func loadAllBuildingMetrics() async {
        isLoadingMetrics = true
        
        await withTaskGroup(of: (String, CoreTypes.BuildingMetrics?).self) { group in
            for building in buildings {
                group.addTask {
                    do {
                        let metrics = try await buildingMetricsService.calculateMetrics(for: building.id)
                        return (building.id, metrics)
                    } catch {
                        print("❌ Failed to load metrics for building \(building.id): \(error)")
                        return (building.id, nil)
                    }
                }
            }
            
            for await (buildingId, metrics) in group {
                if let metrics = metrics {
                    buildingMetrics[buildingId] = metrics
                }
            }
        }
        
        isLoadingMetrics = false
    }
}

// MARK: - Glass Building Metric Card

struct GlassBuildingMetricCard: View {
    let building: NamedCoordinate
    let isPrimary: Bool
    let metrics: CoreTypes.BuildingMetrics?
    let isLoadingMetrics: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Building icon placeholder (no imageAssetName in NamedCoordinate)
                buildingIcon
                
                // Building info
                VStack(alignment: .leading, spacing: 8) {
                    // Name and primary badge
                    VStack(alignment: .leading, spacing: 4) {
                        Text(building.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if isPrimary {
                            GlassStatusBadge(
                                text: "PRIMARY",
                                style: .success,
                                size: .small
                            )
                        }
                    }
                    
                    Spacer()
                    
                    // Metrics section
                    if isLoadingMetrics {
                        loadingState
                    } else if let metrics = metrics {
                        metricsDisplay(metrics)
                    } else {
                        noMetricsState
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(12)
        .frame(height: 160)
        .francoPropertyCardBackground()
        .francoShadow(CyntientOpsDesign.Shadow.propertyCard)
        .overlay(
            // Glow effect for primary building
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPrimary ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
                .shadow(color: isPrimary ? .blue.opacity(0.5) : .clear, radius: 5)
        )
    }
    
    // MARK: - Building Icon
    
    private var buildingIcon: some View {
        ZStack {
            if let assetName = buildingImageAssetName,
               UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 80)
                    .clipped()
            } else {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        Image(systemName: getBuildingIcon())
                            .font(.title)
                            .foregroundColor(.white.opacity(0.8))
                    )
                    .frame(height: 80)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var buildingImageAssetName: String? {
        let address = building.address
        return address
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")
    }
    
    private func getBuildingIcon() -> String {
        let name = building.name.lowercased()
        
        if name.contains("museum") || name.contains("rubin") {
            return "building.columns.fill"
        } else if name.contains("park") || name.contains("cove") {
            return "tree.fill"
        } else if name.contains("perry") || name.contains("elizabeth") {
            return "house.fill"
        } else {
            return "building.2.fill"
        }
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        HStack(spacing: 4) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.7)
            
            Text("Loading...")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - No Metrics State
    
    private var noMetricsState: some View {
        Text("Tap to view details")
            .font(.caption2)
            .foregroundColor(.white.opacity(0.5))
    }
    
    // MARK: - Metrics Display
    
    private func metricsDisplay(_ metrics: CoreTypes.BuildingMetrics) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Completion rate with visual indicator
            HStack(spacing: 6) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                        .frame(width: 20, height: 20)
                    
                    Circle()
                        .trim(from: 0, to: metrics.completionRate)
                        .stroke(
                            completionGradient(metrics.completionRate),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 20, height: 20)
                        .rotationEffect(.degrees(-90))
                }
                
                Text("\(Int(metrics.completionRate * 100))%")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            // Task status
            HStack(spacing: 12) {
                if metrics.overdueTasks > 0 {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 5, height: 5)
                        Text("\(metrics.overdueTasks)")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                
                if metrics.pendingTasks > 0 {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 5, height: 5)
                        Text("\(metrics.pendingTasks)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                if metrics.hasWorkerOnSite {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 5, height: 5)
                            .shadow(color: .green, radius: 2)
                        Text("Live")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func completionGradient(_ rate: Double) -> LinearGradient {
        let colors: [Color] = {
            switch rate {
            case 0.9...1.0: return [.green, .mint]
            case 0.7..<0.9: return [.blue, .cyan]
            case 0.5..<0.7: return [.orange, .yellow]
            default: return [.red, .orange]
            }
        }()
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview

struct MyAssignedBuildingsSection_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBuildings = [
            NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                address: "150 W 17th St, New York, NY 10011",
                latitude: 40.7402,
                longitude: -73.9980
            ),
            NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                address: "40 West 18th St, New York, NY 10011",
                latitude: 40.7398,
                longitude: -73.9972
            ),
            NamedCoordinate(
                id: "10",
                name: "131 Perry Street",
                address: "131 Perry St, New York, NY 10014",
                latitude: 40.7348,
                longitude: -74.0063
            )
        ]
        
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // With buildings
                MyAssignedBuildingsSection(
                    buildings: sampleBuildings,
                    primaryBuilding: sampleBuildings[0],
                    onBuildingTap: { building in
                        print("Building tapped: \(building.name)")
                    },
                    onShowAllBuildings: {
                        print("Show all buildings tapped")
                    }
                )
                .padding(.horizontal, 20)
                
                // Empty state
                MyAssignedBuildingsSection(
                    buildings: [],
                    primaryBuilding: nil,
                    onBuildingTap: { _ in },
                    onShowAllBuildings: { }
                )
                .padding(.horizontal, 20)
            }
        }
        .preferredColorScheme(.dark)
    }
}
