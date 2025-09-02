//
//  DSNYSheetView.swift
//  CyntientOps
//
//  Shows DSNY violations summary for portfolio or a specific building.
//

import SwiftUI

struct DSNYSheetView: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let dsnyViolations: [String: [DSNYViolation]]
    let selectedBuildingId: String?

    private var rows: [(building: CoreTypes.NamedCoordinate, count: Int)] {
        let ids = Array(dsnyViolations.keys)
        let bmap = Dictionary(uniqueKeysWithValues: buildings.map { ($0.id, $0) })
        let filteredIds = selectedBuildingId != nil ? ids.filter { $0 == selectedBuildingId } : ids
        return filteredIds.compactMap { bid in
            guard let b = bmap[bid] else { return nil }
            let count = (dsnyViolations[bid] ?? []).filter { $0.isActive }.count
            return (b, count)
        }.sorted { $0.count > $1.count }
    }

    var body: some View {
        List(rows, id: \.building.id) { row in
            HStack {
                VStack(alignment: .leading) {
                    Text(row.building.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text(row.building.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(row.count)")
                    .font(.headline)
                    .foregroundColor(row.count > 0 ? .orange : .green)
            }
            .padding(.vertical, 6)
        }
    }
}

