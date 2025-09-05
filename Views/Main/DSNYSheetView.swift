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
    @State private var monthsWindow: Int = 6
    @State private var showOnlyRecent = true
    @State private var lastSync: Date = Date()

    private var rows: [(building: CoreTypes.NamedCoordinate, count: Int)] {
        let ids = Array(dsnyViolations.keys)
        let bmap = Dictionary(uniqueKeysWithValues: buildings.map { ($0.id, $0) })
        let filteredIds = selectedBuildingId != nil ? ids.filter { $0 == selectedBuildingId } : ids
        let cutoff = Calendar.current.date(byAdding: .month, value: -monthsWindow, to: Date()) ?? Date.distantPast
        func parse(_ s: String) -> Date? {
            let fmts = ["yyyy-MM-dd'T'HH:mm:ss.SSS","yyyy-MM-dd'T'HH:mm:ss","yyyy-MM-dd","MM/dd/yyyy"]
            for f in fmts { let df=DateFormatter(); df.locale=Locale(identifier: "en_US_POSIX"); df.dateFormat=f; if let d=df.date(from: s){return d} }
            return nil
        }
        return filteredIds.compactMap { bid in
            guard let b = bmap[bid] else { return nil }
            let source = (dsnyViolations[bid] ?? [])
            let list = showOnlyRecent ? source.filter { if let d=parse($0.issueDate){ return d >= cutoff } ; return false } : source
            let count = list.filter { $0.isActive }.count
            return (b, count)
        }.sorted { $0.count > $1.count }
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
            .listStyle(.plain)
            
            HStack {
                Text("Total: \(rows.reduce(0) { $0 + $1.count })")
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
