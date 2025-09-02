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
    @State private var monthsWindow: Int = 6
    @State private var showOnlyRecent = true
    @State private var lastSync: Date = Date()

    private var rows: [(building: CoreTypes.NamedCoordinate, open: Int, total: Int)] {
        let ids = Array(violationsByBuilding.keys)
        let bmap = Dictionary(uniqueKeysWithValues: buildings.map { ($0.id, $0) })
        let filteredIds = selectedBuildingId != nil ? ids.filter { $0 == selectedBuildingId } : ids
        let cutoff = Calendar.current.date(byAdding: .month, value: -monthsWindow, to: Date()) ?? Date.distantPast
        func parse(_ s: String?) -> Date? {
            guard let s=s else { return nil }
            let fmts=["yyyy-MM-dd'T'HH:mm:ss.SSS","yyyy-MM-dd'T'HH:mm:ss","yyyy-MM-dd","MM/dd/yyyy"]
            for f in fmts { let df=DateFormatter(); df.locale=Locale(identifier:"en_US_POSIX"); df.dateFormat=f; if let d=df.date(from:s){return d} }
            return nil
        }
        return filteredIds.compactMap { bid in
            guard let b = bmap[bid] else { return nil }
            var items = violationsByBuilding[bid] ?? []
            if showOnlyRecent { items = items.filter { (parse($0.inspectionDate) ?? Date.distantPast) >= cutoff } }
            let open = items.filter { $0.isActive }.count
            return (b, open, items.count)
        }.sorted { $0.open > $1.open }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Toggle("Last \(monthsWindow) months", isOn: $showOnlyRecent).toggleStyle(.switch)
                Spacer()
                Stepper("", value: $monthsWindow, in: 1...24)
            }
            .font(.caption)
            .padding(.horizontal)

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
            .listStyle(.plain)

            HStack {
                Text("Total open: \(rows.reduce(0) { $0 + $1.open })")
                    .font(.caption)
                Spacer()
                Text("Last sync: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
    }
}
