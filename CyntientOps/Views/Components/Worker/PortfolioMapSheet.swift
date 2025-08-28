//
//  PortfolioMapSheet.swift
//  CyntientOps
//
//  Full-screen portfolio map with building markers.
//

import SwiftUI
import MapKit

struct PortfolioMapSheet: View {
    let container: ServiceContainer
    @Environment(\.dismiss) private var dismiss
    @State private var buildings: [NamedCoordinate] = []
    @State private var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.7421, longitude: -73.9966), span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))

    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: buildings) { b in
                MapMarker(coordinate: b.coordinate, tint: .blue)
            }
            .ignoresSafeArea()
            .navigationTitle("Portfolio Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .task { await loadBuildings() }
    }

    private func loadBuildings() async {
        if let list = try? await container.buildings.getAllBuildings() {
            buildings = list
            if let first = list.first {
                region.center = first.coordinate
            }
        }
    }
}

