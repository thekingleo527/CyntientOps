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
    enum Timeframe: String, CaseIterable, Identifiable { case sevenDays = "7d", thirtyDays = "30d", sixMonths = "6m"; var id: String { rawValue } }
    @State private var timeframe: Timeframe = .thirtyDays
    @State private var lastSync: Date = Date()

    private var rows: [(building: CoreTypes.NamedCoordinate, active: Int, total: Int)] {
        let ids = Array(permitsByBuilding.keys)
        let bmap = Dictionary(uniqueKeysWithValues: buildings.map { ($0.id, $0) })
        let filteredIds = selectedBuildingId != nil ? ids.filter { $0 == selectedBuildingId } : ids
        let cutoff: Date = {
            let cal = Calendar.current
            switch timeframe {
            case .sevenDays: return cal.date(byAdding: .day, value: -7, to: Date()) ?? Date.distantPast
            case .thirtyDays: return cal.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast
            case .sixMonths: return cal.date(byAdding: .month, value: -6, to: Date()) ?? Date.distantPast
            }
        }()
        func parse(_ s: String?) -> Date? {
            guard let s=s else { return nil }
            let fmts=["yyyy-MM-dd'T'HH:mm:ss.SSS","yyyy-MM-dd'T'HH:mm:ss","yyyy-MM-dd","MM/dd/yyyy"]
            for f in fmts { let df=DateFormatter(); df.locale=Locale(identifier:"en_US_POSIX"); df.dateFormat=f; if let d=df.date(from:s){return d} }
            return nil
        }
        return filteredIds.compactMap { bid in
            guard let b = bmap[bid] else { return nil }
            var permits = permitsByBuilding[bid] ?? []
            permits = permits.filter { (parse($0.issuanceDate) ?? Date.distantPast) >= cutoff }
            let active = permits.filter { !$0.isExpired }.count
            return (b, active, permits.count)
        }.sorted { $0.active > $1.active }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("DOB Permits — ") + Text(displayLabel(for: timeframe)).bold()
                Spacer()
                Picker("Timeframe", selection: $timeframe) {
                    ForEach(Timeframe.allCases) { tf in
                        Text(displayLabel(for: tf)).tag(tf)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 280)
            }
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

private func displayLabel(for tf: DOBSheetView.Timeframe) -> String {
    switch tf {
    case .sevenDays: return "Last 7 days"
    case .thirtyDays: return "Last 30 days"
    case .sixMonths: return "Last 6 months"
    }
}
