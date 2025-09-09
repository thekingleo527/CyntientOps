//
//  AdminWeatherRibbon.swift
//  CyntientOps
//
//  Portfolio weather snapshot with route impact hints.
//

import SwiftUI

public struct AdminWeatherRibbon: View {
    let container: ServiceContainer
    @State private var advisory: String?

    public init(container: ServiceContainer) { self.container = container }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Weather Impact", systemImage: "cloud.sun.rain")
                    .font(.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                Spacer()
                if let current = container.weather.currentWeather {
                    Text("\(Int(current.temperature))°F • \(current.condition.rawValue.capitalized)")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                }
            }
            
            if let snapshot = WeatherSnapshot.from(current: container.weather.currentWeather, hourly: container.weather.forecast) {
                // Now
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundStyle(.yellow)
                    Text("Now: \(Int(snapshot.current.tempF))° • \(snapshot.current.condition)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                // Next 12h quick summary
                if let peak = nextPeakPrecip(snapshot) {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.fill").foregroundStyle(.cyan)
                        Text(peak)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                // Next 48h quick view (scanning hourly blocks)
                let next48 = snapshot.hourly.prefix(48)
                let maxProb48 = next48.map { $0.precipProb }.max() ?? 0
                let highWind48 = next48.map { $0.windMph }.max() ?? 0
                HStack(spacing: 8) {
                    Image(systemName: highWind48 > 25 ? "wind" : (maxProb48 >= 0.6 ? "cloud.rain" : "sun.max"))
                        .foregroundStyle(maxProb48 >= 0.6 ? .cyan : (highWind48 > 25 ? .orange : .yellow))
                    Text(maxProb48 >= 0.6 ? "48h: Wet conditions likely" : (highWind48 > 25 ? "48h: Windy period expected" : "48h: Fair conditions"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                let atRisk = topWeatherSensitiveSequences(snapshot: snapshot)
                if atRisk.isEmpty {
                    Text("No route impacts expected in next few hours")
                        .font(.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                } else {
                    ForEach(atRisk.prefix(3), id: \.seqId) { item in
                        HStack(spacing: 8) {
                            Image(systemName: item.icon)
                                .foregroundColor(item.color)
                            Text("\(item.workerName): \(item.buildingName) at \(item.time.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                            Spacer()
                            Text(item.hint)
                                .font(.caption2)
                                .foregroundColor(item.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(item.color.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
            if let adv = advisory {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text(adv).font(.caption).foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .cyntientOpsDarkCardBackground()
        .task { computeAdvisory() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("WeatherAdvisory"))) { note in
            if let info = note.userInfo as? [String: String],
               let body = info["body"] {
                advisory = body
            }
        }
    }

    private func computeAdvisory() {
        guard let snap = WeatherSnapshot.from(current: container.weather.currentWeather, hourly: container.weather.forecast) else { return }
        // Simple DSNY advisory: high precip AND cold temps soon
        let coldSoon = snap.hourly.prefix(12).contains { $0.tempF <= 34 }
        let wetSoon = snap.hourly.prefix(12).contains { $0.precipProb >= 0.35 }
        if coldSoon && wetSoon { advisory = "DSNY advisory: winter precip risk in next 12h" }
    }

    private func nextPeakPrecip(_ snapshot: WeatherSnapshot) -> String? {
        let window = snapshot.hourly.prefix(12)
        guard let best = window.max(by: { $0.precipProb < $1.precipProb }), best.precipProb >= 0.5 else { return nil }
        let pct = Int(best.precipProb * 100)
        let time = best.date.formatted(date: .omitted, time: .shortened)
        return "Rain likely ~\(pct)% at \(time)"
    }

    private func topWeatherSensitiveSequences(snapshot: WeatherSnapshot) -> [ImpactRow] {
        let today = Calendar.current.component(.weekday, from: Date())
        let routes = container.routes.routes.filter { $0.dayOfWeek == today }
        var rows: [ImpactRow] = []
        for route in routes {
            let workerName = CanonicalIDs.Workers.getName(for: route.workerId) ?? route.workerId
            for seq in route.sequences {
                // Heuristic: if operations contain weather sensitive tasks and precip prob or wind high soon
                let sensitive = seq.operations.contains { $0.isWeatherSensitive }
                guard sensitive else { continue }
                let soon = snapshot.hourly.prefix(4)
                let maxProb = soon.map { $0.precipProb }.max() ?? 0
                let highWind = soon.map { $0.windMph }.max() ?? 0
                if maxProb > 0.6 || highWind > 25 {
                    rows.append(ImpactRow(
                        seqId: seq.id,
                        workerName: workerName,
                        buildingName: seq.buildingName,
                        time: seq.arrivalTime,
                        hint: maxProb > 0.6 ? "Rain risk" : "High wind",
                        icon: maxProb > 0.6 ? "drop.fill" : "wind",
                        color: maxProb > 0.6 ? CyntientOpsDesign.DashboardColors.info : .orange
                    ))
                }
            }
        }
        return rows.sorted { $0.time < $1.time }
    }

    private struct ImpactRow {
        let seqId: String
        let workerName: String
        let buildingName: String
        let time: Date
        let hint: String
        let icon: String
        let color: Color
    }
}
