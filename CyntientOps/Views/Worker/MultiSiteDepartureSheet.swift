//
//  MultiSiteDepartureSheet.swift
//  CyntientOps
//
//  Aggregates multiple site departures with segmented control; enables final Clock Out when all sites completed.
//

import SwiftUI

struct MultiSiteDepartureSheet: View {
    let workerId: String
    let buildings: [NamedCoordinate]
    let container: ServiceContainer
    let onFinished: () -> Void

    @State private var selectedBuildingId: String
    @State private var completed: Set<String> = []
    @State private var viewModels: [String: SiteDepartureViewModel] = [:]
    @Environment(\.dismiss) private var dismiss

    init(workerId: String, buildings: [NamedCoordinate], container: ServiceContainer, onFinished: @escaping () -> Void) {
        self.workerId = workerId
        self.buildings = buildings
        self.container = container
        self.onFinished = onFinished
        _selectedBuildingId = State(initialValue: buildings.first?.id ?? "")
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented across buildings
                if !buildings.isEmpty {
                    Picker("Site", selection: $selectedBuildingId) {
                        ForEach(buildings, id: \.id) { b in
                            HStack {
                                Text(b.name)
                                if completed.contains(b.id) { Image(systemName: "checkmark.circle.fill").foregroundColor(.green) }
                            }.tag(b.id)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                }

                Divider()

                // Current site content
                if let current = buildings.first(where: { $0.id == selectedBuildingId }) {
                    let vm = viewModel(for: current)
                    SiteDepartureSingleView(viewModel: vm, buttonTitle: completed.contains(current.id) ? "Submitted" : "Submit Site Log") {
                        completed.insert(current.id)
                    }
                    .disabled(completed.contains(current.id))
                }

                // Finalize
                VStack {
                    Button {
                        onFinished()
                        dismiss()
                    } label: {
                        HStack { Spacer(); Text("Clock Out").bold(); Spacer() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(completed.count < buildings.count)
                    .padding()
                }
            }
            .navigationTitle("Site Departure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
        .onAppear { preloadViewModels() }
    }

    private func viewModel(for building: NamedCoordinate) -> SiteDepartureViewModel {
        if let vm = viewModels[building.id] { return vm }
        let vm = SiteDepartureViewModel(workerId: workerId, currentBuilding: building, container: container)
        viewModels[building.id] = vm
        return vm
    }

    private func preloadViewModels() {
        for b in buildings { _ = viewModel(for: b) }
    }
}

