//
//  HPDSheetView.swift
//  CyntientOps
//
//  Shows HPD violations for portfolio or a specific building.
//

import SwiftUI

struct HPDSheetView: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let violationsByBuilding: [String: [HPDViolation]]
    let selectedBuildingId: String?

    private var rows: [(building: CoreTypes.NamedCoordinate, open: Int, total: Int)] {
        let ids = Array(violationsByBuilding.keys)
        let bmap = Dictionary(uniqueKeysWithValues: buildings.map { ($0.id, $0) })
        let filteredIds = selectedBuildingId != nil ? ids.filter { $0 == selectedBuildingId } : ids
        return filteredIds.compactMap { bid in
            guard let b = bmap[bid] else { return nil }
            let items = violationsByBuilding[bid] ?? []
            let open = items.filter { $0.isActive }.count
            return (b, open, items.count)
        }.sorted { $0.open > $1.open }
    }

    var body: some View {
        List(rows, id: \.building.id) { row in
            HStack {
                VStack(alignment: .leading) {
                    Text(row.building.name)
                        .font(.subheadline)
                    Text(row.building.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\\(row.open)/\\(row.total)")
                    .font(.headline)
                    .foregroundColor(row.open > 0 ? .orange : .green)
            }
            .padding(.vertical, 6)
        }
    }
}

