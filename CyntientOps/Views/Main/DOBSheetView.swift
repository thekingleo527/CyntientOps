//
//  DOBSheetView.swift
//  CyntientOps
//
//  Shows DOB permits summary for portfolio or a specific building.
//

import SwiftUI

struct DOBSheetView: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let permitsByBuilding: [String: [DOBPermit]]
    let selectedBuildingId: String?

    private var rows: [(building: CoreTypes.NamedCoordinate, active: Int, total: Int)] {
        let ids = Array(permitsByBuilding.keys)
        let bmap = Dictionary(uniqueKeysWithValues: buildings.map { ($0.id, $0) })
        let filteredIds = selectedBuildingId != nil ? ids.filter { $0 == selectedBuildingId } : ids
        return filteredIds.compactMap { bid in
            guard let b = bmap[bid] else { return nil }
            let permits = permitsByBuilding[bid] ?? []
            let active = permits.filter { !$0.isExpired }.count
            return (b, active, permits.count)
        }.sorted { $0.active > $1.active }
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
                Text("\(row.active)/\(row.total)")
                    .font(.headline)
                    .foregroundColor(row.active > 0 ? .blue : .green)
            }
            .padding(.vertical, 6)
        }
    }
}

