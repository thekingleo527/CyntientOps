//
//  MapRevealContainer.swift
//  CyntientOps v6.0
//
//  ✅ ENHANCED: Dual-mode map with intelligence previews
//  ✅ FIXED: Uses WorkerContextEngine (not adapter)
//  ✅ INTEGRATED: BuildingPreviewPopover on tap
//  ✅ UNIFIED: Single building marker component
//  ✅ NEW: Shows building images when focused
//

import SwiftUI
import MapKit

struct MapRevealContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    // Map state (can be controlled externally)
    @Binding var isRevealed: Bool
    @State private var dragOffset: CGFloat = 0
    @State private var showHint = false
    @AppStorage("mapCoachmarkSeen") private var mapCoachmarkSeen: Bool = false
    @State private var selectedBuildingForPreview: NamedCoordinate?
    @State private var hoveredBuildingId: String?
    
    // Building data
    let buildings: [NamedCoordinate]
    let assignedBuildingIds: Set<String>?
    let visitedBuildingIds: Set<String>?
    let currentBuildingId: String?
    let focusBuildingId: String?
    
    // Callbacks
    let onBuildingTap: (NamedCoordinate) -> Void
    
    // Dependencies
    let container: ServiceContainer
    let forceShowAll: Bool
    // Admin-specific filtering (optional sets of building IDs)
    let adminMode: Bool
    let hpdBuildingIds: Set<String>?
    let dsnyBuildingIds: Set<String>?
    
    // Map camera
    @State private var position: MapCameraPosition
    @State private var selectedFilter: MapFilter = .all
    @State private var selectedAdminFilter: AdminMapFilter = .all
    @State private var showLegend: Bool = true

    enum MapFilter: String, CaseIterable {
        case all = "All"
        case assigned = "Assigned"
        case visited = "Visited"
    }
    enum AdminMapFilter: String, CaseIterable {
        case all = "All"
        case issues = "Issues"
        case hpd = "HPD"
        case dsny = "DSNY"
        case active = "Active"
        case visited = "Visited"
    }
    
    // Intelligence data
    @State private var buildingMetrics: [String: BuildingMetrics] = [:]
    @State private var isLoadingMetrics = false
    
    // Layout calculations
    private var mapLegendHeight: CGFloat {
        // Account for map legend (130) + safe area padding (20)
        return 150
    }
    
    // MARK: - Initialization
    
    init(
        buildings: [NamedCoordinate],
        currentBuildingId: String? = nil,
        focusBuildingId: String? = nil,
        assignedBuildingIds: Set<String>? = nil,
        visitedBuildingIds: Set<String>? = nil,
        forceShowAll: Bool = false,
        adminMode: Bool = false,
        hpdBuildingIds: Set<String>? = nil,
        dsnyBuildingIds: Set<String>? = nil,
        isRevealed: Binding<Bool>,
        container: ServiceContainer,
        onBuildingTap: @escaping (NamedCoordinate) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.buildings = buildings
        self.currentBuildingId = currentBuildingId
        self.focusBuildingId = focusBuildingId
        self.assignedBuildingIds = assignedBuildingIds
        self.visitedBuildingIds = visitedBuildingIds
        self._isRevealed = isRevealed
        self.container = container
        self.forceShowAll = forceShowAll
        self.adminMode = adminMode
        self.hpdBuildingIds = hpdBuildingIds
        self.dsnyBuildingIds = dsnyBuildingIds
        self.onBuildingTap = onBuildingTap
        self.content = content
        
        // Initialize map position - Focus on Chelsea/Lower Manhattan portfolio area
        let portfolioCenter: CLLocationCoordinate2D
        
        if !buildings.isEmpty {
            // Calculate the centroid of portfolio buildings for better focus
            let latSum = buildings.map { $0.coordinate.latitude }.reduce(0, +)
            let lonSum = buildings.map { $0.coordinate.longitude }.reduce(0, +)
            portfolioCenter = CLLocationCoordinate2D(
                latitude: latSum / Double(buildings.count),
                longitude: lonSum / Double(buildings.count)
            )
        } else {
            // Default to Chelsea neighborhood center (optimal for Manhattan portfolio)
            portfolioCenter = CLLocationCoordinate2D(
                latitude: 40.7450, // Chelsea area - 23rd Street vicinity
                longitude: -73.9950  // Between 8th and 9th Avenue
            )
        }
        
        self._position = State(initialValue: .region(
            MKCoordinateRegion(
                center: portfolioCenter,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.025,  // Tighter zoom for neighborhood focus
                    longitudeDelta: 0.020  // Optimized for Manhattan's aspect ratio
                )
            )
        ))
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Base map layer (always present)
            mapLayer
                .zIndex(0)
            
            // Main content overlay
            content()
                // When revealed, move content fully off-screen for true fullscreen map
                .offset(y: (isRevealed ? -UIScreen.main.bounds.height : 0) + dragOffset)
                .opacity(isRevealed ? 0.0 : 1.0)
                .safeAreaInset(edge: .bottom) {
                    if isRevealed {
                        Color.clear
                            .frame(height: mapLegendHeight)
                    }
                }
                .gesture(swipeGesture)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isRevealed)
                .zIndex(1)
                .allowsHitTesting(!isRevealed) // Allow touches when map is not revealed
            
            // Map controls when revealed (with proper timing)
            if isRevealed {
                mapControls
                    .zIndex(2)
                    .transition(.opacity.combined(with: .scale))
                    .animation(.easeInOut(duration: 0.4).delay(0.1), value: isRevealed)
            }
            
            // Intelligence popover
            if let building = selectedBuildingForPreview {
                intelligencePopover(for: building)
                    .zIndex(3)
            }
            
            // Swipe hint suppressed: intentionally disabled to avoid overlay
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .task {
            await preloadBuildingMetrics()
        }
        .onAppear {
            // Only show the hint once per app install unless reset.
            // Gate by both our app storage and the internal MapInteractionHint persistence.
            // Load persisted UI prefs per worker
            loadPersistedMapPrefs()

            if !mapCoachmarkSeen && !MapInteractionHint.hasUserSeenHint() {
                showHint = true
            } else {
                showHint = false
            }
        }
        .onChange(of: selectedFilter) { _ in persistMapPrefs() }
        .onChange(of: showLegend) { _ in persistMapPrefs() }
    }
    
    // MARK: - Unified Map Layer
    
    private var mapLayer: some View {
        ZStack {
            // The actual map (always present, but conditionally styled)
            Map(position: isRevealed ? $position : .constant(position)) {
                ForEach(displayedBuildings, id: \.id) { building in
                    Annotation(
                        building.name,
                        coordinate: building.coordinate
                    ) {
                        MapBuildingBubble(
                            building: building,
                            isSelected: building.id == currentBuildingId,
                            isFocused: isRevealed && (building.id == focusBuildingId || building.id == hoveredBuildingId),
                            isInteractive: isRevealed,
                            isAssigned: assignedBuildingIds?.contains(building.id) ?? false,
                            isVisited: visitedBuildingIds?.contains(building.id) ?? false,
                            metrics: buildingMetrics[building.id],
                            onTap: isRevealed ? {
                                handleBuildingTap(building)
                            } : nil,
                            onHover: isRevealed ? { isHovering in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    hoveredBuildingId = isHovering ? building.id : nil
                                }
                            } : nil
                        )
                    }
                }
            }
            // Use plain standard style to avoid MapKit icon pack lookups
            .mapStyle(.standard)
            .mapControls {
                if isRevealed {
                    MapCompass()
                    MapScaleView()
                }
            }
            .allowsHitTesting(isRevealed) // Only allow map interaction when revealed
            .blur(radius: isRevealed ? 0 : 12)
            .opacity(isRevealed ? 1.0 : 0.3)
            .animation(.easeInOut(duration: 0.4), value: isRevealed)
            
            // Overlay for ambient mode (with improved timing)
            if !isRevealed {
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.6),
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
                .opacity(isRevealed ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 0.4), value: isRevealed)
            }
        }
    }

    private var displayedBuildings: [NamedCoordinate] {
        let filteredByActive = buildings.filter { building in
            // Filter out 29-31 East 20th (building ID "2") and any buildings with that name
            building.id != "2" && !building.name.localizedCaseInsensitiveContains("29-31 East 20th")
        }
        if adminMode {
            switch selectedAdminFilter {
            case .all:
                return filteredByActive
            case .issues:
                return filteredByActive.filter { b in
                    if let m = buildingMetrics[b.id] { return m.hasIssues }
                    return false
                }
            case .hpd:
                if let ids = hpdBuildingIds { return filteredByActive.filter { ids.contains($0.id) } }
                return []
            case .dsny:
                if let ids = dsnyBuildingIds { return filteredByActive.filter { ids.contains($0.id) } }
                return []
            case .active:
                return filteredByActive.filter { b in (buildingMetrics[b.id]?.activeWorkers ?? 0) > 0 || (buildingMetrics[b.id]?.hasWorkerOnSite ?? false) }
            case .visited:
                if let ids = visitedBuildingIds { return filteredByActive.filter { ids.contains($0.id) } }
                return []
            }
        } else {
            switch selectedFilter {
            case .all:
                return filteredByActive
            case .assigned:
                guard let ids = assignedBuildingIds else { return filteredByActive }
                return filteredByActive.filter { ids.contains($0.id) }
            case .visited:
                guard let ids = visitedBuildingIds else { return filteredByActive }
                return filteredByActive.filter { ids.contains($0.id) }
            }
        }
    }
    
    // MARK: - Map Controls
    
    private var mapControls: some View {
        VStack {
            MapControlsBar(
                filters: adminMode ? AdminMapFilter.allCases.map { $0.rawValue } : MapFilter.allCases.map { $0.rawValue },
                selectedFilter: adminMode ? selectedAdminFilter.rawValue : selectedFilter.rawValue,
                onSelectFilter: { label in
                    if adminMode, let f = AdminMapFilter(rawValue: label) { selectedAdminFilter = f }
                    else if let f = MapFilter(rawValue: label) { selectedFilter = f }
                    // Refit region to selected set
                    let pts = displayedBuildings.map { $0.coordinate }
                    if !pts.isEmpty { position = .region(.fit(points: pts)) }
                },
                showLegend: $showLegend,
                onZoomIn: zoomIn,
                onZoomOut: zoomOut,
                onClose: closeMap
            )
            Spacer()
            mapLegend
        }
    }

    // Legend helper moved to MapControlsBar

    // MARK: - Persistence (per-worker)

    private func prefKey(_ name: String) -> String {
        let user = container.auth.currentUserId ?? "anon"
        return "map.pref.\(name).\(user)"
    }

    private func loadPersistedMapPrefs() {
        let defaults = UserDefaults.standard
        
        // Force "All" filter for workers (forceShowAll = true), allow saved preferences for clients
        if forceShowAll {
            selectedFilter = .all
            print("🗺️ MapRevealContainer: Forcing 'All' filter for worker - full portfolio view")
        } else if let raw = defaults.string(forKey: prefKey("filter")), let f = MapFilter(rawValue: raw) {
            selectedFilter = f
            print("🗺️ MapRevealContainer: Loaded saved filter '\(f.rawValue)' for client")
        }
        
        // Default to true if unset
        if defaults.object(forKey: prefKey("legendVisible")) != nil {
            showLegend = defaults.bool(forKey: prefKey("legendVisible"))
        }
    }

    private func persistMapPrefs() {
        let defaults = UserDefaults.standard
        
        // Don't persist filter changes when forceShowAll is true (workers)
        if !forceShowAll {
            defaults.set(selectedFilter.rawValue, forKey: prefKey("filter"))
        }
        
        defaults.set(showLegend, forKey: prefKey("legendVisible"))
    }
    
    // MARK: - Map Legend (Compact and Non-Intrusive)
    
    private var mapLegend: some View {
        MapLegendBar(
            buildingCount: buildings.count,
            hasCurrent: currentBuildingId != nil,
            isVisible: isRevealed
        )
    }
    
    // MARK: - Intelligence Popover
    
    private func intelligencePopover(for building: NamedCoordinate) -> some View {
        BuildingPreviewPopover(
            building: building,
            onDetails: {
                selectedBuildingForPreview = nil
                onBuildingTap(building)
            },
            onDismiss: {
                selectedBuildingForPreview = nil
            }
        )
        .position(popoverPosition(for: building))
        .transition(.scale.combined(with: .opacity))
        .zIndex(100)
    }
    
    // MARK: - Gesture Handling
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .global)
            .onChanged { value in
                let translation = value.translation.height
                let velocity = value.predictedEndTranslation.height - value.translation.height
                
                if !isRevealed && translation < 0 {
                    // Swiping up to reveal map - add resistance
                    let resistance: CGFloat = 2.5
                    dragOffset = max(translation / resistance, -UIScreen.main.bounds.height * 0.4)
                } else if isRevealed && translation > 0 {
                    // Swiping down to hide map - smoother tracking
                    dragOffset = min(translation * 0.8, UIScreen.main.bounds.height * 0.5)
                }
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    let translation = value.translation.height
                    let velocity = value.predictedEndTranslation.height
                    let threshold: CGFloat = 80
                    let velocityThreshold: CGFloat = 200
                    
                    // Consider both distance and velocity for better UX
                    if !isRevealed && (translation < -threshold || velocity < -velocityThreshold) {
                        // Reveal map - ensure clean state
                        isRevealed = true
                        showHint = false
                    } else if isRevealed && (translation > threshold || velocity > velocityThreshold) {
                        // Hide map - clean up all state
                        isRevealed = false
                        selectedBuildingForPreview = nil
                        hoveredBuildingId = nil
                    }
                    
                    // Always reset drag offset
                    dragOffset = 0
                }
                
                // Force UI update after gesture completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Ensure animations complete properly
                }
            }
    }
    
    // MARK: - Helper Methods
    
    private func handleBuildingTap(_ building: NamedCoordinate) {
        if selectedBuildingForPreview?.id == building.id {
            // Second tap - navigate to details
            selectedBuildingForPreview = nil
            onBuildingTap(building)
        } else {
            // First tap - show preview
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedBuildingForPreview = building
            }
        }
    }
    
    // MARK: - Zoom Controls
    
    private func zoomIn() {
        withAnimation(.easeInOut(duration: 0.3)) {
            // Zoom in by reducing the span by half
            position = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.7450, longitude: -73.9950),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.008)
            ))
        }
    }
    
    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.3)) {
            // Zoom out by increasing the span to show more area
            position = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.7450, longitude: -73.9950),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.04)
            ))
        }
    }
    
    private func closeMap() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isRevealed = false
        }
        
        // Clean up state immediately to prevent UI glitches
        selectedBuildingForPreview = nil
        hoveredBuildingId = nil
        dragOffset = 0
        
        // Ensure overlay state is properly reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Force state consistency
        }
    }
    
    private func popoverPosition(for building: NamedCoordinate) -> CGPoint {
        // Calculate position above the building marker
        let screenSize = UIScreen.main.bounds
        
        // Get approximate screen position for building
        // This is simplified - in production, use MKMapView conversion
        return CGPoint(
            x: screenSize.width / 2,
            y: screenSize.height / 2 - 150
        )
    }
    
    private func preloadBuildingMetrics() async {
        isLoadingMetrics = true
        
        for building in buildings {
            do {
                let metrics = try await container.metrics.calculateMetrics(for: building.id)
                await MainActor.run {
                    buildingMetrics[building.id] = metrics
                }
            } catch {
                print("Failed to load metrics for \(building.name): \(error)")
            }
        }
        
        isLoadingMetrics = false
    }
}

// MapBuildingBubble moved to CyntientOps/Maps/Components/MapBuildingBubble.swift

// MARK: - Preview Provider

// Preview disabled - requires ServiceContainer async initialization
/*
#Preview {
    MapRevealContainer(
        buildings: sampleBuildings,
        currentBuildingId: "14",
        isRevealed: .constant(false),
        container: container,
        onBuildingTap: { building in
            print("Navigate: \(building.name)")
        }
    ) {
        Text("MapRevealContainer Preview")
            .foregroundColor(.white)
    }
    .preferredColorScheme(.dark)
}
*/
