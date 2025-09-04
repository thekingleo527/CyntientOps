//
//  BuildingDetailTabContainer.swift  
//  CyntientOps
//
//  🚀 PERFORMANCE OPTIMIZED: Lazy-loaded tabs with minimal memory footprint
//  💡 PRODUCTION READY: Each tab loads only when accessed
//

import SwiftUI

@MainActor
struct BuildingDetailTabContainer: View {
    let building: CoreTypes.NamedCoordinate
    let container: ServiceContainer
    
    @State private var selectedTab = 0
    @State private var loadedTabs: Set<Int> = []
    // @StateObject private var memoryMonitor = MemoryPressureMonitor.shared // Commented until added to Xcode project
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Overview - Always loaded (essential)
            BuildingOverviewTab(
                building: building, 
                container: container
            )
            .tag(0)
            .tabItem {
                Label("Overview", systemImage: "building.2")
            }
            
            // Tasks - Lazy loaded
            Group {
                if loadedTabs.contains(1) {
                    BuildingTasksTab(
                        building: building,
                        container: container
                    )
                } else {
                    ProgressView("Loading tasks...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            loadTab(1)
                        }
                }
            }
            .tag(1)
            .tabItem {
                Label("Maintenance", systemImage: "wrench.and.screwdriver")
            }
            
            // Team - Lazy loaded
            Group {
                if loadedTabs.contains(2) {
                    BuildingTeamTab(
                        building: building,
                        container: container
                    )
                } else {
                    ProgressView("Loading team...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            loadTab(2)
                        }
                }
            }
            .tag(2)
            .tabItem {
                Label("Team", systemImage: "person.2")
            }
            
            // Compliance - Lazy loaded
            Group {
                if loadedTabs.contains(3) {
                    BuildingComplianceTab(
                        building: building,
                        container: container
                    )
                } else {
                    ProgressView("Loading compliance...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear {
                            loadTab(3)
                        }
                }
            }
            .tag(3)
            .tabItem {
                Label("Compliance", systemImage: "checkmark.shield")
            }

            // Routes (includes Sanitation) - Lazy loaded
            Group {
                if loadedTabs.contains(4) {
                    WorkerRoutesTab(
                        building: building,
                        container: container
                    )
                } else {
                    ProgressView("Loading routes…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear { loadTab(4) }
                }
            }
            .tag(4)
            .tabItem {
                Label("Routes", systemImage: "map")
            }
        }
        .onAppear {
            // Load first tab immediately
            loadTab(0)
        }
        .onChange(of: selectedTab) { _, newTab in
            loadTab(newTab)
        }
    }
    
    private func loadTab(_ tabIndex: Int) {
        guard !loadedTabs.contains(tabIndex) else { return }
        
        // TODO: Re-enable memory pressure monitoring when utilities are added to Xcode project
        /*
        // Check memory pressure before loading heavy tabs
        if memoryMonitor.shouldDisableFeature(.heavyComputation) && tabIndex > 1 {
            print("⚠️ Skipping tab \(tabIndex) load due to memory pressure")
            return
        }
        */
        
        // Small delay to ensure smooth animation
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            await MainActor.run {
                self.loadedTabs.insert(tabIndex)
            }
        }
    }
}

// MARK: - Worker Routes + Sanitation Tab (Optimized)
@MainActor
private struct WorkerRoutesTab: View {
    let building: CoreTypes.NamedCoordinate
    let container: ServiceContainer

    @State private var schedule: DSNY.BuildingSchedule?
    @State private var dsnyCount: Int = 0
    @State private var loading = true
    @State private var routeData: [RouteSequence] = []
    @State private var workerMap: [String: String] = [:]
    @State private var selectedDate = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Date selector for routes
                VStack(alignment: .leading, spacing: 8) {
                    Label("Routes", systemImage: "map")
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.compact)
                        .onChange(of: selectedDate) { _ in Task { await loadRoutes() } }
                }
                .padding()
                .cyntientOpsDarkCardBackground()

                // Route sequences list
                if loading && routeData.isEmpty {
                    ProgressView("Loading routes…").tint(.white)
                } else if routeData.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "map.circle").font(.largeTitle).foregroundColor(.gray)
                        Text("No routes scheduled for this date").font(.caption).foregroundColor(.gray)
                    }
                    .padding()
                    .cyntientOpsDarkCardBackground()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(routeData, id: \.id) { seq in
                            RouteSequenceCard(
                                sequence: seq,
                                container: container,
                                overrideWorkerName: workerMap[seq.id]
                            )
                        }
                    }
                }

                // Collection Schedule card
                VStack(alignment: .leading, spacing: 12) {
                    Label("Collection Schedule", systemImage: "calendar.badge.clock")
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    if let s = schedule {
                        let routes = DSNY.DSNYRoute.fromBuildingSchedule(s)
                        if routes.isEmpty {
                            Text("No schedule available").font(.caption).foregroundColor(.gray)
                        } else {
                            ForEach(routes, id: \.id) { r in
                                HStack {
                                    Text(r.dayOfWeek)
                                    Spacer()
                                    Text(r.serviceType)
                                    Text(r.time)
                                        .foregroundColor(.secondary)
                                }
                                .font(.subheadline)
                            }
                        }
                    } else if loading {
                        ProgressView().tint(.white)
                    } else {
                        Text("No schedule available").font(.caption).foregroundColor(.gray)
                    }
                }
                .padding()
                .cyntientOpsDarkCardBackground()

                // Sanitation Compliance card
                VStack(alignment: .leading, spacing: 12) {
                    Label("Sanitation Compliance", systemImage: "trash.circle.fill")
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    HStack {
                        Text("Violations (last 6 mo)")
                            .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        Spacer()
                        Text("\(dsnyCount)")
                            .font(.headline)
                            .foregroundColor(dsnyCount > 0 ? .orange : .green)
                    }
                }
                .padding()
                .cyntientOpsDarkCardBackground()
            }
            .padding()
        }
        .task { await loadData() }
    }

    private func loadData() async {
        loading = true
        // Schedule
        if let s = try? await DSNYAPIService.shared.getSchedule(for: building) {
            await MainActor.run { self.schedule = s }
        }
        // DSNY violations (from compliance cache/service)
        let count = container.nycCompliance.getDSNYViolations(for: building.id).filter { $0.isActive }.count
        await MainActor.run { self.dsnyCount = count }
        await loadRoutes()
    }

    private func loadRoutes() async {
        loading = true
        let routes = container.routes.routes
        let weekday = Calendar.current.component(.weekday, from: selectedDate)

        func sequenceCoversBuilding(_ sequence: RouteSequence, buildingId: String) -> Bool {
            if sequence.buildingId == buildingId { return true }
            switch sequence.buildingId {
            case "17th_street_complex":
                let group: Set<String> = [
                    CanonicalIDs.Buildings.westSeventeenth117,
                    CanonicalIDs.Buildings.westSeventeenth135_139,
                    CanonicalIDs.Buildings.westSeventeenth138,
                    CanonicalIDs.Buildings.westSeventeenth136,
                    CanonicalIDs.Buildings.rubinMuseum,
                    CanonicalIDs.Buildings.westEighteenth112
                ]
                return group.contains(building.id)
            case "multi_location":
                let group: Set<String> = [
                    CanonicalIDs.Buildings.firstAvenue123,
                    CanonicalIDs.Buildings.springStreet178
                ]
                return group.contains(building.id)
            default:
                return false
            }
        }

        var seqs: [RouteSequence] = []
        var map: [String: String] = [:]
        for route in routes where route.dayOfWeek == weekday {
            let workerName = CanonicalIDs.Workers.getName(for: route.workerId) ?? "Unknown Worker"
            for seq in route.sequences where sequenceCoversBuilding(seq, buildingId: building.id) {
                seqs.append(seq)
                map[seq.id] = workerName
            }
        }
        await MainActor.run {
            self.routeData = seqs
            self.workerMap = map
            self.loading = false
        }
    }
}
