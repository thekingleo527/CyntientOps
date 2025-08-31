//
//  ClockInSheet.swift
//  CyntientOps
//
//  Clock-in selector for workers. Lists buildings sorted by proximity.
//  Allows coverage clock-in (not just assigned) and guards with a proximity hint.
//

import SwiftUI
import CoreLocation

struct ClockInSheet: View {
    @Environment(\.dismiss) private var dismiss
    let container: ServiceContainer
    let workerId: String

    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var buildings: [NamedCoordinate] = []
    @State private var sorted: [(building: NamedCoordinate, distance: CLLocationDistance?)] = []

    private let proximityThreshold: CLLocationDistance = 1000 // 1km soft guard

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading nearby buildings…").foregroundColor(.secondary)
                    }
                } else if let msg = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                        Text(msg).multilineTextAlignment(.center)
                        Button("Retry") { Task { await loadBuildings() } }
                    }
                    .padding()
                } else {
                    List {
                        Section(footer: Text("For accuracy, clock in when physically near the building.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)) {
                            ForEach(sorted, id: \.building.id) { entry in
                                let b = entry.building
                                let dist = entry.distance
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(b.name).font(.body)
                                        if let d = dist {
                                            Text(String(format: "%.0f m away", d))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text(b.address).font(.caption).foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Button("Clock In") {
                                        Task { await clockIn(to: b) }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.blue)
                                    .disabled((dist ?? .greatestFiniteMagnitude) > proximityThreshold)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Clock In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task { await loadBuildings() }
    }

    private func loadBuildings() async {
        isLoading = true
        errorMessage = nil
        do {
            // Try assigned first; fall back to all for coverage
            let assigned: [NamedCoordinate]
            if let list = try? await container.buildings.getBuildingsForWorker(workerId) {
                assigned = list
            } else {
                assigned = []
            }
            let all = (try? await container.buildings.getAllBuildings()) ?? []

            // Merge: assigned first (unique), then others
            var map: [String: NamedCoordinate] = [:]
            for b in assigned { map[b.id] = b }
            for b in all where map[b.id] == nil { map[b.id] = b }
            buildings = Array(map.values)

            // Sort by proximity
            let current = LocationManager.shared.location
            let currentCL = current.map { CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) }
            sorted = buildings.map { b in
                if let cur = currentCL {
                    let d = cur.distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
                    return (b, d)
                } else {
                    return (b, nil)
                }
            }
            .sorted { (lhs, rhs) in
                switch (lhs.distance, rhs.distance) {
                case let (l?, r?): return l < r
                case (_?, nil): return true
                case (nil, _?): return false
                default: return lhs.building.name < rhs.building.name
                }
            }

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func clockIn(to building: NamedCoordinate) async {
        do {
            try await container.clockIn.clockIn(workerId: workerId, buildingId: building.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

