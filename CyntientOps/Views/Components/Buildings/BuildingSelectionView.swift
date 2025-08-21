//
//  BuildingSelectionView.swift
//  CyntientOps v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Uses PropertyCard for building display
//  ✅ INTEGRATED: CyntientOpsDesign system
//  ✅ IMPROVED: Better map integration and transitions
//  ✅ OPTIMIZED: Consistent with other building views
//  ✅ FIXED: Renamed BuildingMapPin to avoid redeclaration
//  ✅ FIXED: Preview errors resolved
//

import SwiftUI
import MapKit
import CoreLocation

struct BuildingSelectionView: View {
    let buildings: [NamedCoordinate]
    let onSelect: (NamedCoordinate) -> Void
    var purpose: SelectionPurpose = .clockIn
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .list
    @State private var buildingMetrics: [String: BuildingMetrics] = [:]
    @State private var selectedBuilding: CoreTypes.NamedCoordinate?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7401, longitude: -73.9978),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    enum ViewMode {
        case list
        case map
    }
    
    enum SelectionPurpose {
        case clockIn
        case assignment
        case navigation
        
        var title: String {
            switch self {
            case .clockIn: return "Select Building to Clock In"
            case .assignment: return "Select Building"
            case .navigation: return "Select Destination"
            }
        }
        
        var actionText: String {
            switch self {
            case .clockIn: return "Clock In Here"
            case .assignment: return "Select"
            case .navigation: return "Navigate"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredBuildings: [NamedCoordinate] {
        if searchText.isEmpty {
            return buildings
        } else {
            return buildings.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark Elegance Background
                CyntientOpsDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom header
                    headerView
                    
                    // View content
                    if viewMode == .list {
                        listContent
                    } else {
                        mapContent
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
            // Title bar
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .francoTypography(CyntientOpsDesign.Typography.body)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                }
                
                Spacer()
                
                Text(purpose.title)
                    .francoTypography(CyntientOpsDesign.Typography.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                Spacer()
                
                // View mode toggle
                Button(action: toggleViewMode) {
                    Image(systemName: viewMode == .list ? "map" : "list.bullet")
                        .font(.title3)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(CyntientOpsDesign.DashboardColors.glassOverlay)
                        )
                }
            }
            .padding(CyntientOpsDesign.Spacing.md)
            
            // Search bar
            searchBar
            
            // Separator
            Rectangle()
                .fill(CyntientOpsDesign.DashboardColors.borderSubtle)
                .frame(height: 1)
        }
        .background(CyntientOpsDesign.DashboardColors.cardBackground.opacity(0.95))
    }
    
    private var searchBar: some View {
        HStack(spacing: CyntientOpsDesign.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
            
            TextField("Search buildings...", text: $searchText)
                .francoTypography(CyntientOpsDesign.Typography.body)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)
                }
            }
        }
        .padding(CyntientOpsDesign.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.md)
                .fill(CyntientOpsDesign.DashboardColors.glassOverlay)
        )
        .padding(.horizontal, CyntientOpsDesign.Spacing.md)
        .padding(.bottom, CyntientOpsDesign.Spacing.sm)
    }
    
    // MARK: - List Content
    
    private var listContent: some View {
        ScrollView {
            if filteredBuildings.isEmpty {
                emptySearchState
            } else {
                LazyVStack(spacing: CyntientOpsDesign.Spacing.sm) {
                    ForEach(filteredBuildings) { building in
                        SelectableBuildingCard(
                            building: building,
                            metrics: buildingMetrics[building.id],
                            purpose: purpose,
                            onSelect: {
                                handleSelection(building)
                            }
                        )
                    }
                }
                .padding(CyntientOpsDesign.Spacing.md)
            }
        }
    }
    
    // MARK: - Map Content
    
    private var mapContent: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: filteredBuildings) { building in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: building.latitude,
                    longitude: building.longitude
                )) {
                    BuildingSelectionMapPin(
                        building: building,
                        isSelected: selectedBuilding?.id == building.id,
                        onTap: {
                            withAnimation(CyntientOpsDesign.Animations.spring) {
                                selectedBuilding = building
                            }
                        }
                    )
                }
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Selected building detail overlay
            if let selected = selectedBuilding {
                VStack {
                    Spacer()
                    
                    SelectedBuildingOverlay(
                        building: selected,
                        metrics: buildingMetrics[selected.id],
                        purpose: purpose,
                        onSelect: {
                            handleSelection(selected)
                        },
                        onDismiss: {
                            withAnimation(CyntientOpsDesign.Animations.spring) {
                                selectedBuilding = nil
                            }
                        }
                    )
                    .padding(CyntientOpsDesign.Spacing.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptySearchState: some View {
        FrancoEmptyState(
            icon: "magnifyingglass",
            title: "No Results",
            message: "No buildings match '\(searchText)'",
            action: { searchText = "" },
            actionTitle: "Clear Search",
            role: .worker
        )
        .padding(CyntientOpsDesign.Spacing.lg)
    }
    
    // MARK: - Helper Methods
    
    private func toggleViewMode() {
        withAnimation(CyntientOpsDesign.Animations.spring) {
            viewMode = viewMode == .list ? .map : .list
        }
    }
    
    private func handleSelection(_ building: CoreTypes.NamedCoordinate) {
        onSelect(building)
        dismiss()
    }
    
    private func loadBuildingMetrics() async {
        // Load metrics for buildings (similar to AssignedBuildingsView)
        await withTaskGroup(of: (String, BuildingMetrics?).self) { group in
            for building in buildings {
                group.addTask {
                    // Simulate metrics loading - replace with actual service call
                    let mockMetrics = BuildingMetrics(
                        buildingId: building.id,
                        completionRate: Double.random(in: 0.5...1.0),
                        overdueTasks: Int.random(in: 0...3),
                        totalTasks: Int.random(in: 5...15),
                        activeWorkers: Int.random(in: 1...5),
                        overallScore: Double.random(in: 3.5...5.0),
                        pendingTasks: Int.random(in: 0...5),
                        urgentTasksCount: Int.random(in: 0...2)
                    )
                    return (building.id, mockMetrics)
                }
            }
            
            var metricsMap: [String: BuildingMetrics] = [:]
            for await (buildingId, metrics) in group {
                if let metrics = metrics {
                    metricsMap[buildingId] = metrics
                }
            }
            
            await MainActor.run {
                self.buildingMetrics = metricsMap
            }
        }
    }
}

// MARK: - Selectable Building Card

struct SelectableBuildingCard: View {
    let building: CoreTypes.NamedCoordinate
    let metrics: BuildingMetrics?
    let purpose: BuildingSelectionView.SelectionPurpose
    let onSelect: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: CyntientOpsDesign.Spacing.md) {
                // Building info using PropertyCard components
                PropertyCard(
                    building: building,
                    metrics: metrics,
                    mode: .worker,
                    onTap: {}
                )
                .allowsHitTesting(false) // Disable inner tap
                .overlay(
                    HStack {
                        Spacer()
                        
                        // Action button
                        VStack {
                            Image(systemName: actionIcon)
                                .font(.title2)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
                            
                            Text(purpose.actionText)
                                .francoTypography(CyntientOpsDesign.Typography.caption)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
                        }
                        .padding(.trailing, CyntientOpsDesign.Spacing.md)
                    }
                )
            }
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(CyntientOpsDesign.Animations.quick) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private var actionIcon: String {
        switch purpose {
        case .clockIn: return "clock.fill"
        case .assignment: return "checkmark.circle.fill"
        case .navigation: return "location.fill"
        }
    }
}

// MARK: - Selected Building Overlay (for Map View)

struct SelectedBuildingOverlay: View {
    let building: CoreTypes.NamedCoordinate
    let metrics: BuildingMetrics?
    let purpose: BuildingSelectionView.SelectionPurpose
    let onSelect: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: CyntientOpsDesign.Spacing.md) {
            // Dismiss handle
            Capsule()
                .fill(CyntientOpsDesign.DashboardColors.tertiaryText)
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            // Building card
            PropertyCard(
                building: building,
                metrics: metrics,
                mode: .admin,
                onTap: onSelect
            )
            
            // Action button
            Button(action: onSelect) {
                HStack {
                    Image(systemName: actionIcon)
                    Text(purpose.actionText)
                }
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(CyntientOpsDesign.DashboardColors.primaryAction)
                .cornerRadius(CyntientOpsDesign.CornerRadius.md)
            }
        }
        .padding(CyntientOpsDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CyntientOpsDesign.CornerRadius.xl)
                .fill(CyntientOpsDesign.DashboardColors.cardBackground)
                .francoShadow(CyntientOpsDesign.Shadow.lg)
        )
        .onTapGesture {
            onDismiss()
        }
    }
    
    private var actionIcon: String {
        switch purpose {
        case .clockIn: return "clock.fill"
        case .assignment: return "checkmark.circle.fill"
        case .navigation: return "location.fill"
        }
    }
}

// MARK: - Building Selection Map Pin (Renamed from BuildingMapPin to avoid conflict)

struct BuildingSelectionMapPin: View {
    let building: CoreTypes.NamedCoordinate
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Image(systemName: isSelected ? "mappin.circle.fill" : "mappin.circle")
                    .font(.title)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryAction)
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .animation(CyntientOpsDesign.Animations.spring, value: isSelected)
                
                if !isSelected {
                    // Small label when not selected
                    Text(building.name)
                        .francoTypography(CyntientOpsDesign.Typography.caption2)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(CyntientOpsDesign.DashboardColors.cardBackground)
                                .francoShadow(CyntientOpsDesign.Shadow.sm)
                        )
                        .offset(y: -5)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("List View") {
    BuildingSelectionView(
        buildings: [
            CoreTypes.NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                address: "12 West 18th Street, New York, NY",
                latitude: 40.7389,
                longitude: -73.9936
            ),
            CoreTypes.NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                address: "150 W 17th St, New York, NY 10011",
                latitude: 40.7401,
                longitude: -73.9978
            )
        ],
        onSelect: { building in
            print("Selected: \(building.name)")
        },
        purpose: BuildingSelectionView.SelectionPurpose.clockIn  // Fixed: Full type path
    )
    .preferredColorScheme(ColorScheme.dark)  // Fixed: Full type path
}

#Preview("Map View") {
    BuildingSelectionView(
        buildings: [
            CoreTypes.NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                address: "12 West 18th Street, New York, NY",
                latitude: 40.7389,
                longitude: -73.9936
            ),
            CoreTypes.NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                address: "150 W 17th St, New York, NY 10011",
                latitude: 40.7401,
                longitude: -73.9978
            ),
            CoreTypes.NamedCoordinate(
                id: "2",
                name: "111 West 19th Street",
                address: "111 West 19th Street, New York, NY",
                latitude: 40.7412,
                longitude: -73.9951
            ),
            CoreTypes.NamedCoordinate(
                id: "3",
                name: "205 East 12th Street",
                address: "205 East 12th Street, New York, NY",
                latitude: 40.7318,
                longitude: -73.9879
            )
        ],
        onSelect: { building in
            print("Selected: \(building.name)")
        },
        purpose: BuildingSelectionView.SelectionPurpose.navigation  // Fixed: Full type path
    )
    .preferredColorScheme(ColorScheme.dark)  // Fixed: Full type path
}
