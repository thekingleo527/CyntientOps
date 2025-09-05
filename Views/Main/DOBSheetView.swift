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
    @State private var monthsWindow: Int = 6
    @State private var showOnlyRecent = true
    @State private var lastSync: Date = Date()

    private var rows: [(building: CoreTypes.NamedCoordinate, active: Int, total: Int)] {
        let ids = Array(permitsByBuilding.keys)
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
            var permits = permitsByBuilding[bid] ?? []
            if showOnlyRecent { permits = permits.filter { (parse($0.issuanceDate) ?? Date.distantPast) >= cutoff } }
            let active = permits.filter { !$0.isExpired }.count
            return (b, active, permits.count)
        }.sorted { $0.active > $1.active }
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
                    Text("\(row.active)/\(row.total)")
                        .font(.headline)
                        .foregroundColor(row.active > 0 ? .blue : .green)
                }
                .padding(.vertical, 6)
            }
            .listStyle(.plain)

            HStack {
                Text("Total active: \(rows.reduce(0) { $0 + $1.active })")
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
