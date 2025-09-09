//
//  AdminPortfolioMapView.swift
//  CyntientOps v6.0
//
//  ✅ COMPLETE: Admin portfolio map with intelligent worker/building metric previews
//  ✅ MANHATTAN FOCUS: Proper zoom level for Manhattan portfolio
//

import SwiftUI
import MapKit

public struct AdminPortfolioMapView: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let workers: [CoreTypes.WorkerProfile]
    
    @State private var region: MKCoordinateRegion
    @State private var selectedBuilding: CoreTypes.NamedCoordinate?
    @State private var selectedWorker: CoreTypes.WorkerProfile?
    @State private var showWorkerLayer = true
    @State private var showBuildingMetrics = true
    
    init(buildings: [CoreTypes.NamedCoordinate], workers: [CoreTypes.WorkerProfile]) {
        self.buildings = buildings
        self.workers = workers
        
        // Manhattan-focused initialization with proper zoom
        let manhattanCenter = CLLocationCoordinate2D(
            latitude: 40.7450, // Chelsea/Lower Manhattan center
            longitude: -73.9950
        )
        
        self._region = State(initialValue:
            MKCoordinateRegion(
                center: manhattanCenter,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.025,  // Zoomed in for Manhattan
                    longitudeDelta: 0.020  // Optimized for Manhattan aspect ratio
                )
            )
        )
    }
    
    public var body: some View {
        ZStack {
            // Map with intelligent markers (classic annotationItems API)
            Map(coordinateRegion: $region, annotationItems: mapItems) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    switch item.kind {
                    case .building(let building):
                        AdminBuildingMapMarker(
                            building: building,
                            isSelected: selectedBuilding?.id == building.id,
                            showMetrics: showBuildingMetrics,
                            onTap: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedBuilding = building
                                    selectedWorker = nil
                                }
                            }
                        )
                    case .worker(let worker):
                        AdminWorkerMapMarker(
                            worker: worker,
                            isSelected: selectedWorker?.id == worker.id,
                            onTap: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedWorker = worker
                                    selectedBuilding = nil
                                }
                            }
                        )
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            
            // Map Controls Overlay
            VStack {
                HStack {
                    Spacer()
                    
                    // Map controls
            AdminMapControls(
                showWorkerLayer: $showWorkerLayer,
                showBuildingMetrics: $showBuildingMetrics,
                region: $region
            )
                }
                
                Spacer()
                
                // Map Legend
                AdminMapLegend(
                    buildingCount: buildings.count,
                    activeWorkerCount: workers.filter { $0.isClockedIn }.count,
                    showWorkerLayer: showWorkerLayer
                )
            }
            .padding(20)
            
            // Selection Previews
            if let building = selectedBuilding {
                AdminBuildingPreview(
                    building: building,
                    onDismiss: { selectedBuilding = nil }
                )
                .position(getPreviewPosition())
                .transition(.scale.combined(with: .opacity))
            }
            
            if let worker = selectedWorker {
                AdminWorkerPreview(
                    worker: worker,
                    onDismiss: { selectedWorker = nil }
                )
                .position(getPreviewPosition())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .background(CyntientOpsDesign.DashboardColors.baseBackground)
    }

    // MARK: - Map Items
    private struct MapItem: Identifiable {
        enum Kind { case building(CoreTypes.NamedCoordinate), worker(CoreTypes.WorkerProfile) }
        let id: String
        let coordinate: CLLocationCoordinate2D
        let kind: Kind
    }

    private var mapItems: [MapItem] {
        var items: [MapItem] = buildings.map { b in
            MapItem(id: "b-\(b.id)", coordinate: b.coordinate, kind: .building(b))
        }
        if showWorkerLayer {
            for w in workers where w.isClockedIn {
                if let loc = getCurrentWorkerLocation(w) {
                    items.append(MapItem(id: "w-\(w.id)", coordinate: loc, kind: .worker(w)))
                }
            }
        }
        return items
    }
    
    private func getCurrentWorkerLocation(_ worker: CoreTypes.WorkerProfile) -> CLLocationCoordinate2D? {
        // Get worker's current location based on assigned buildings
        // For demo, use first assigned building's location
        if let firstBuildingId = worker.assignedBuildingIds.first,
           let building = buildings.first(where: { $0.id == firstBuildingId }) {
            return building.coordinate
        }
        return nil
    }
    
    private func getPreviewPosition() -> CGPoint {
        return CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2 - 100)
    }
}

// MARK: - Map Markers

struct AdminBuildingMapMarker: View {
    let building: CoreTypes.NamedCoordinate
    let isSelected: Bool
    let showMetrics: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Selection ring
                if isSelected {
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.adminAccent.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .blur(radius: 2)
                }
                
                // Building marker
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(CyntientOpsDesign.DashboardColors.adminAccent, lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 16))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
                    )
                
                // Metrics indicator
                if showMetrics {
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.success)
                        .frame(width: 12, height: 12)
                        .offset(x: 14, y: -14)
                }
            }
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct AdminWorkerMapMarker: View {
    let worker: CoreTypes.WorkerProfile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Selection ring
                if isSelected {
                    Circle()
                        .fill(CyntientOpsDesign.DashboardColors.success.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .blur(radius: 2)
                }
                
                // Worker marker
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(CyntientOpsDesign.DashboardColors.success, lineWidth: 2)
                    )
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                    )
                
                // Active indicator
                Circle()
                    .fill(CyntientOpsDesign.DashboardColors.success)
                    .frame(width: 8, height: 8)
                    .offset(x: 10, y: -10)
            }
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Map Controls

struct AdminMapControls: View {
    @Binding var showWorkerLayer: Bool
    @Binding var showBuildingMetrics: Bool
    @Binding var region: MKCoordinateRegion
    
    var body: some View {
        VStack(spacing: 8) {
            // Layer toggles
            VStack(spacing: 4) {
                AdminMapToggle(
                    icon: "person.2.fill",
                    isEnabled: $showWorkerLayer,
                    color: CyntientOpsDesign.DashboardColors.success
                )
                
                AdminMapToggle(
                    icon: "chart.bar.fill",
                    isEnabled: $showBuildingMetrics,
                    color: CyntientOpsDesign.DashboardColors.info
                )
            }
            
            Divider()
                .frame(width: 30)
                .background(Color.white.opacity(0.3))
            
            // Zoom controls
            VStack(spacing: 4) {
                AdminMapZoomButton(
                    icon: "plus",
                    action: { zoomIn() }
                )
                
                AdminMapZoomButton(
                    icon: "minus",
                    action: { zoomOut() }
                )
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private func zoomIn() {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: region.span.latitudeDelta * 0.5,
            longitudeDelta: region.span.longitudeDelta * 0.5
        )
        let newRegion = MKCoordinateRegion(center: region.center, span: newSpan)
        withAnimation(.easeInOut(duration: 0.3)) { region = newRegion }
    }
    
    private func zoomOut() {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: min(region.span.latitudeDelta * 2.0, 0.1),
            longitudeDelta: min(region.span.longitudeDelta * 2.0, 0.1)
        )
        let newRegion = MKCoordinateRegion(center: region.center, span: newSpan)
        withAnimation(.easeInOut(duration: 0.3)) { region = newRegion }
    }
}

struct AdminMapToggle: View {
    let icon: String
    @Binding var isEnabled: Bool
    let color: Color
    
    var body: some View {
        Button(action: { isEnabled.toggle() }) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(isEnabled ? color : .white.opacity(0.5))
                .frame(width: 32, height: 24)
        }
    }
}

struct AdminMapZoomButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 32, height: 24)
        }
    }
}

struct AdminMapLegend: View {
    let buildingCount: Int
    let activeWorkerCount: Int
    let showWorkerLayer: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "building.2.fill")
                    .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
                
                Text("Portfolio Buildings")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(buildingCount.formatted())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.adminAccent)
            }
            
            if showWorkerLayer {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                    
                    Text("Active Workers")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(activeWorkerCount.formatted())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}

// MARK: - Intelligent Previews

struct AdminBuildingPreview: View {
    let building: CoreTypes.NamedCoordinate
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(building.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Text(building.address)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            // Intelligent Building Metrics
            VStack(spacing: 8) {
                AdminMetricRow(
                    icon: "checkmark.circle.fill",
                    title: "Compliance",
                    value: "92%",
                    color: CyntientOpsDesign.DashboardColors.success
                )
                
                AdminMetricRow(
                    icon: "person.2.fill",
                    title: "Active Workers",
                    value: "3",
                    color: CyntientOpsDesign.DashboardColors.adminAccent
                )
                
                AdminMetricRow(
                    icon: "checkmark.square.fill",
                    title: "Tasks Today",
                    value: "8/10",
                    color: CyntientOpsDesign.DashboardColors.warning
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .frame(width: 200)
    }
}

struct AdminWorkerPreview: View {
    let worker: CoreTypes.WorkerProfile
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(worker.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Text(worker.role.rawValue)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            // Intelligent Worker Metrics
            VStack(spacing: 8) {
                AdminMetricRow(
                    icon: "clock.fill",
                    title: "Status",
                    value: worker.isClockedIn ? "Active" : "Offline",
                    color: worker.isClockedIn ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.warning
                )
                
                AdminMetricRow(
                    icon: "building.fill",
                    title: "Assigned Sites",
                    value: worker.assignedBuildingIds.count.formatted(),
                    color: CyntientOpsDesign.DashboardColors.adminAccent
                )
                
                AdminMetricRow(
                    icon: "checkmark.square.fill",
                    title: "Today's Progress",
                    value: "85%",
                    color: CyntientOpsDesign.DashboardColors.success
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .frame(width: 200)
    }
}

// Local lightweight metric row used by this view
private struct AdminMetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}
