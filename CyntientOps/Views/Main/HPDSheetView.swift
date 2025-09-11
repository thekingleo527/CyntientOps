//
//  HPDSheetView.swift
//  CyntientOps
//
//  Shows HPD violations for portfolio or a specific building with timeframe filters.
//

import SwiftUI

struct HPDSheetView: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let violationsByBuilding: [String: [HPDViolation]]
    let selectedBuildingId: String?

    enum Timeframe: String, CaseIterable, Identifiable { case sevenDays = "7d", thirtyDays = "30d", sixMonths = "6m"; var id: String { rawValue } }
    @State private var timeframe: Timeframe = .thirtyDays
    @State private var lastSync: Date = Date()

    private var rows: [(building: CoreTypes.NamedCoordinate, open: Int, total: Int)] {
        let ids = Array(violationsByBuilding.keys)
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
            var items = violationsByBuilding[bid] ?? []
            items = items.filter { (parse($0.inspectionDate) ?? Date.distantPast) >= cutoff }
            let open = items.filter { $0.isActive }.count
            return (b, open, items.count)
        }.sorted { $0.open > $1.open }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("HPD Violations — ") + Text(displayLabel(for: timeframe)).bold()
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
                    Text("\(row.open)/\(row.total)")
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

private func displayLabel(for tf: HPDSheetView.Timeframe) -> String {
    switch tf {
    case .sevenDays: return "Last 7 days"
    case .thirtyDays: return "Last 30 days"
    case .sixMonths: return "Last 6 months"
    }
}

