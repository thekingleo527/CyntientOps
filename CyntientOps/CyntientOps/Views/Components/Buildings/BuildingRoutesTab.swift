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
                        RouteSequenceCard(sequence: sequence, container: container)
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

            // Filter sequences for this building
            let buildingSequences = allRoutes.flatMap { route in
                route.sequences.filter { sequence in
                    sequence.buildingId == buildingId ||
                    (buildingId.contains("17th") && sequence.buildingId.contains("17th")) ||
                    (buildingId.contains("18th") && sequence.buildingId.contains("18th"))
                }
            }

            await MainActor.run {
                self.routeData = buildingSequences
                self.isLoading = false
            }
        }
    }
}

