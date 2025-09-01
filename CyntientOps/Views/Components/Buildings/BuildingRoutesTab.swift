//
//  BuildingRoutesTab.swift
//  CyntientOps
//
//  Standalone routes tab for BuildingDetailView; shows route sequences
//  for a given building and selected date.
//

import SwiftUI

struct BuildingRoutesTab: View {
    let buildingId: String
    let buildingName: String
    let container: ServiceContainer
    let viewModel: BuildingDetailViewModel

    @State private var selectedDate = Date()
    @State private var routeData: [RouteSequence] = []
    @State private var workerMap: [String: String] = [:] // sequence.id -> worker name
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Operational Routes")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)

                Text("View worker routes and sequences for this building")
                    .font(.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }

            // Date Picker
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                .datePickerStyle(.compact)
                .onChange(of: selectedDate) { _ in
                    loadRouteData()
                }
                .glassCard(cornerRadius: 12)

            if isLoading {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading routes...")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .glassCard()
            } else if routeData.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "map.circle")
                        .font(.system(size: 48))
                        .foregroundColor(CyntientOpsDesign.DashboardColors.tertiaryText)

                    Text("No Routes Scheduled")
                        .font(.headline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)

                    Text("No worker routes found for this building on the selected date")
                        .font(.subheadline)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .glassCard()
            } else {
                // Routes list
                LazyVStack(spacing: 12) {
                    ForEach(routeData, id: \.id) { sequence in
                        RouteSequenceCard(
                            sequence: sequence,
                            container: container,
                            overrideWorkerName: workerMap[sequence.id]
                        )
                    }
                }
            }
        }
        .task {
            loadRouteData()
        }
    }

    private func loadRouteData() {
        isLoading = true

        Task {
            _ = Calendar.current.component(.weekday, from: selectedDate)
            let routes = container.routes
            let allRoutes = routes.routes
            let selectedWeekday = Calendar.current.component(.weekday, from: selectedDate)

            // Only show routes for workers assigned to this building (if available)
            let allowedWorkerIds: Set<String> = {
                let ids = viewModel.assignedWorkers.map { $0.id }
                return ids.isEmpty ? Set(allRoutes.map { $0.workerId }) : Set(ids)
            }()

            // Helper: map multi-location sequence buildingIds to member buildingIds
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
                        CanonicalIDs.Buildings.westEighteenth112 // include 112 mapping
                    ]
                    return group.contains(buildingId)
                case "multi_location":
                    let group: Set<String> = [
                        CanonicalIDs.Buildings.firstAvenue123,
                        CanonicalIDs.Buildings.springStreet178
                    ]
                    return group.contains(buildingId)
                default:
                    return false
                }
            }

            var sequences: [RouteSequence] = []
            var map: [String: String] = [:]

            for route in allRoutes where allowedWorkerIds.contains(route.workerId) && route.dayOfWeek == selectedWeekday {
                let workerName = CanonicalIDs.Workers.getName(for: route.workerId) ?? "Unknown Worker"
                for seq in route.sequences where sequenceCoversBuilding(seq, buildingId: buildingId) {
                    sequences.append(seq)
                    map[seq.id] = workerName
                }
            }

            await MainActor.run {
                self.workerMap = map
                self.routeData = sequences
                self.isLoading = false
            }
            print("🗺️ BuildingRoutesTab: \(buildingName) — sequences: \(sequences.count), workers: \(Set(map.values).count)")
        }
    }
}
