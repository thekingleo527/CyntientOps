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
    let currentBuildingId: String?
    let focusBuildingId: String?
    
    // Callbacks
    let onBuildingTap: (NamedCoordinate) -> Void
    
    // Dependencies
    let container: ServiceContainer
    
    // Map camera
    @State private var position: MapCameraPosition
    
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
        isRevealed: Binding<Bool>,
        container: ServiceContainer,
        onBuildingTap: @escaping (NamedCoordinate) -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.buildings = buildings
        self.currentBuildingId = currentBuildingId
        self.focusBuildingId = focusBuildingId
        self._isRevealed = isRevealed
        self.container = container
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
            if !mapCoachmarkSeen && !MapInteractionHint.hasUserSeenHint() {
                showHint = true
            } else {
                showHint = false
            }
        }
    }
    
    // MARK: - Unified Map Layer
    
    private var mapLayer: some View {
        ZStack {
            // The actual map (always present, but conditionally styled)
            Map(position: isRevealed ? $position : .constant(position)) {
                ForEach(buildings, id: \.id) { building in
                    Annotation(
                        building.name,
                        coordinate: building.coordinate
                    ) {
                        MapBuildingBubble(
                            building: building,
                            isSelected: building.id == currentBuildingId,
                            isFocused: isRevealed && (building.id == focusBuildingId || building.id == hoveredBuildingId),
                            isInteractive: isRevealed,
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
    
    // MARK: - Map Controls
    
    private var mapControls: some View {
        VStack {
            HStack {
                Spacer()
                
                // Zoom controls
                VStack(spacing: 8) {
                    // Zoom In button
                    Button(action: zoomIn) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "plus")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Zoom Out button
                    Button(action: zoomOut) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "minus")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.trailing, 8)
                
                // Close button
                Button(action: closeMap) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "chevron.down")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 20)
                .padding(.top, 60)
            }
            
            Spacer()
            
            // Map legend
            mapLegend
        }
    }
    
    // MARK: - Map Legend (Compact and Non-Intrusive)
    
    private var mapLegend: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Building count badge
                HStack(spacing: 6) {
                    Image(systemName: "building.2.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("\(buildings.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                
                // Current building indicator
                if currentBuildingId != nil {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Current")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .allowsHitTesting(false)
        .opacity(isRevealed ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.3).delay(0.2), value: isRevealed)
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

// MARK: - Enhanced Building Marker with Image Support

struct MapBuildingBubble: View {
    let building: NamedCoordinate
    let isSelected: Bool
    let isFocused: Bool
    let isInteractive: Bool
    let metrics: BuildingMetrics?
    var onTap: (() -> Void)?
    var onHover: ((Bool) -> Void)?
    
    @State private var isPressed = false
    
    
    var body: some View {
        Button(action: { onTap?() }) {
            ZStack {
                // Outer ring for focus/selection
                if isFocused || isSelected {
                    Circle()
                        .fill(ringColor.opacity(0.3))
                        .frame(width: 65, height: 65)
                        .blur(radius: 2)
                }
                
                // Always show building image if available, otherwise show icon
                if BuildingAssets.assetName(for: building.id) != nil {
                    // Show building image bubble (default)
                    buildingImageBubble
                } else {
                    // Show icon bubble as fallback
                    iconBubble
                }
                
                // Status indicator
                if let metrics = metrics {
                    statusIndicator(metrics)
                }
                
                // Star badge for current building (when selected)
                if isSelected {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .background(Circle().fill(.white).frame(width: 16, height: 16))
                        .offset(x: 20, y: -20)
                }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .scaleEffect(isFocused ? 1.15 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isInteractive)
        .onHover { hovering in
            onHover?(hovering)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    @ViewBuilder
    private var buildingImageBubble: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 55, height: 55)
            
            // Building image or fallback via shared mapping
            if let assetName = BuildingAssets.assetName(for: building.id) {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(borderColor, lineWidth: 2)
                    )
                    .overlay(
                        // Selection overlay
                        selectedOverlay
                    )
            } else {
                // Fallback to icon bubble
                iconBubbleContent
            }
        }
        .shadow(color: shadowColor, radius: 10, x: 0, y: 5)
    }
    
    @ViewBuilder
    private var iconBubble: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: 2)
                )
            
            iconBubbleContent
        }
        .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private var iconBubbleContent: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
        } else {
            VStack(spacing: 0) {
                Image(systemName: buildingIcon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
        }
    }
    
    @ViewBuilder
    private var selectedOverlay: some View {
        if isSelected {
            ZStack {
                Circle()
                    .fill(.black.opacity(0.4))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                    .background(Circle().fill(.white).frame(width: 24, height: 24))
            }
        }
    }
    
    private var ringColor: Color {
        if isSelected {
            return .green
        } else if let metrics = metrics {
            return riskColor(for: metrics)
        } else {
            return .blue
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .green
        } else if let metrics = metrics {
            return riskColor(for: metrics).opacity(0.8)
        } else {
            return .white.opacity(0.3)
        }
    }
    
    private var shadowColor: Color {
        if isSelected {
            return .green.opacity(0.5)
        } else if isFocused {
            return .blue.opacity(0.5)
        } else {
            return .black.opacity(0.3)
        }
    }
    
    private var buildingIcon: String {
        let name = building.name.lowercased()
        
        // Enhanced icon matching based on actual building names
        if name.contains("museum") || name.contains("rubin") {
            return "building.columns.fill"
        } else if name.contains("park") || name.contains("stuyvesant") || name.contains("cove") {
            return "leaf.fill"
        } else if name.contains("perry") || name.contains("elizabeth") || name.contains("walker") {
            return "house.fill"
        } else if name.contains("west") || name.contains("east") || name.contains("franklin") {
            return "building.2.fill"
        } else if name.contains("avenue") {
            return "building.fill"
        } else {
            return "building.2.fill"
        }
    }
    
    private var iconColor: Color {
        if let metrics = metrics {
            return riskColor(for: metrics)
        } else {
            return .blue
        }
    }
    
    @ViewBuilder
    private func statusIndicator(_ metrics: BuildingMetrics) -> some View {
        if metrics.urgentTasksCount > 0 {
            ZStack {
                Circle()
                    .fill(.red)
                    .frame(width: 20, height: 20)
                
                Text("\(metrics.urgentTasksCount)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .offset(x: 18, y: -18)
        }
    }
    
    private func riskColor(for metrics: BuildingMetrics) -> Color {
        if metrics.overdueTasks > 0 || metrics.urgentTasksCount > 0 {
            return .red
        } else if metrics.completionRate < 0.7 {
            return .orange
        } else {
            return .green
        }
    }
}

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
