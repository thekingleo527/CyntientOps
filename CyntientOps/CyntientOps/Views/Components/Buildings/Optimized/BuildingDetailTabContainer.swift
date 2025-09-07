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
                Label("Tasks", systemImage: "checklist")
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