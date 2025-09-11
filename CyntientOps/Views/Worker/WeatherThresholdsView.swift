//
//  WeatherThresholdsView.swift
//  CyntientOps
//
//  Surfaces per-building weather trigger thresholds from WeatherTriggeredTaskManager.
//

import SwiftUI

struct WeatherThresholdsView: View {
    let container: ServiceContainer
    let currentBuildingId: String?

    private var triggers: [WeatherTriggeredTaskManager.WeatherTrigger] {
        container.weatherTasks.activeTriggers
    }

    private var buildingNameMap: [String: String] {
        // Use synchronous shim from OperationalDataManager to avoid async in computed property
        let buildings = container.operationalData.getAllBuildings()
        return Dictionary(uniqueKeysWithValues: buildings.map { ($0.id, $0.name) })
    }

    var body: some View {
        List {
            ForEach(triggers, id: \.id) { trigger in
                Section(header: HStack {
                    Text(trigger.condition.rawValue)
                    Spacer()
                    Text(thresholdLabel(for: trigger))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }) {
                    let rows = rowsFor(trigger)
                    if rows.isEmpty {
                        Text("No buildings configured for this trigger")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(rows, id: \.self) { name in
                            Text(name)
                        }
                    }
                }
            }
        }
    }

    private func rowsFor(_ trigger: WeatherTriggeredTaskManager.WeatherTrigger) -> [String] {
        // Aggregate all buildingIds in triggered tasks and map to names; filter to current building if provided
        var ids = trigger.triggeredTasks.flatMap { $0.buildingIds }
        if let bid = currentBuildingId { ids = ids.filter { $0 == bid } }
        let names = ids.compactMap { buildingNameMap[$0] }
        return Array(Set(names)).sorted()
    }

    private func thresholdLabel(for trigger: WeatherTriggeredTaskManager.WeatherTrigger) -> String {
        switch trigger.condition {
        case .rainExpected: return ">= \(Int(trigger.threshold * 100))% in \(trigger.timeFrame.rawValue)"
        case .rainEnded: return "> 0.5 in rain (approx)"
        case .heavyWindWarning: return ">= \(Int(trigger.threshold)) mph"
        case .windEnded: return ">= \(Int(trigger.threshold)) mph"
        case .freezeWarning: return "<= \(Int(trigger.threshold))°F"
        case .heatWave: return ">= \(Int(trigger.threshold))°F"
        case .stormWarning: return ">= threshold"
        case .immediate: return "Immediate"
        }
    }
}
