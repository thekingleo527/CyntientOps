//
//  WeatherHybridCard.swift
//  CyntientOps
//
//  Hybrid weather card: current snapshot + compact risk + hourly action
//

import SwiftUI

struct WeatherTaskItem {
    let id: String
    let title: String
    let affectedBy: String // e.g., "Rain", "Wind", "Heat"
    let recommendation: String // e.g., "Postpone until afternoon", "Complete early"
}

public struct WeatherSuggestion: Identifiable, Equatable {
    public enum Kind {
        case rain, snow, heat, cold, dsny, sun, wind, generic
    }
    public let id: String
    public let kind: Kind
    public let title: String
    public let subtitle: String
    public let taskTemplateId: String?
    public let dueBy: Date?
    public let buildingId: String?
}

enum WeatherSuggestionQuickAction {
    case start
    case viewPolicy
    case snooze
}

struct WeatherHybridCard: View {
    let snapshot: WeatherSnapshot?
    let suggestions: [WeatherSuggestion]
    let onSuggestionTap: ((WeatherSuggestion) -> Void)?
    let onViewHourly: () -> Void
    let onLongPressAction: ((WeatherSuggestion, WeatherSuggestionQuickAction) -> Void)?
    let weatherAffectedTasks: [WeatherTaskItem]?
    let onTaskTap: ((String) -> Void)?
    
    init(
        snapshot: WeatherSnapshot?,
        suggestions: [WeatherSuggestion] = [],
        onSuggestionTap: ((WeatherSuggestion) -> Void)? = nil,
        onViewHourly: @escaping () -> Void,
        onLongPressAction: ((WeatherSuggestion, WeatherSuggestionQuickAction) -> Void)? = nil,
        weatherAffectedTasks: [WeatherTaskItem]? = nil,
        onTaskTap: ((String) -> Void)? = nil
    ) {
        self.snapshot = snapshot
        self.suggestions = suggestions
        self.onSuggestionTap = onSuggestionTap
        self.onViewHourly = onViewHourly
        self.onLongPressAction = onLongPressAction
        self.weatherAffectedTasks = weatherAffectedTasks
        self.onTaskTap = onTaskTap
    }

    @State private var showHourly = false

    var body: some View {
        GlassCard(
            intensity: .regular,
            cornerRadius: CyntientOpsDesign.CornerRadius.glassCard,
            padding: CyntientOpsDesign.Spacing.cardPadding
        ) {
            if let snap = snapshot {
                content(snapshot: snap)
            } else {
                offlineTile
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func content(snapshot: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Title + Weather Snapshot
            HStack(spacing: 12) {
                Text("Weather-based Suggestions")
                    .font(.headline)
                Spacer()
                Image(systemName: icon(for: snapshot))
                    .foregroundStyle(color(for: snapshot))
                Text("\(Int(snapshot.current.tempF))°")
                    .font(.title3).fontWeight(.semibold)
                Text(snapshot.current.condition)
                    .foregroundStyle(.secondary)
                Button(LocalizedStringKey("weather.view_hourly")) { onViewHourly() }
                    .font(.callout)
            }

            if let precip = nextPeakPrecip(snapshot) {
                Text(precip)
                    .font(.caption)
                    .foregroundStyle(.cyan)
            }

            // Suggestions list (0–3)
            if suggestions.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal")
                        .foregroundStyle(.secondary)
                    Text("All clear — no weather-based actions right now.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                VStack(spacing: 8) {
                    ForEach(suggestions.prefix(3)) { s in
                        Button(action: { onSuggestionTap?(s) }) {
                            HStack(alignment: .center, spacing: 10) {
                                Image(systemName: suggestionIcon(for: s.kind))
                                    .font(.headline)
                                    .foregroundStyle(suggestionColor(for: s.kind))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(s.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(s.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                let showStart: Bool = {
                                    if s.kind == .dsny, let due = s.dueBy {
                                        // Allow start within 15 minutes before due or after
                                        return Date().addingTimeInterval(15*60) >= due
                                    }
                                    return s.taskTemplateId != nil
                                }()
                                Text(showStart ? "Start" : "View")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                        }
                        .contextMenu {
                            if s.taskTemplateId != nil {
                                Button("Start", systemImage: "play.fill") { onLongPressAction?(s, .start) }
                            }
                            Button("View policy", systemImage: "doc.text") { onLongPressAction?(s, .viewPolicy) }
                            Button("Snooze today", systemImage: "bell.slash") { onLongPressAction?(s, .snooze) }
                        }
                    }
                }
            }

            // Weather-affected tasks (compact)
            if let tasks = weatherAffectedTasks, !tasks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey("weather.affected_tasks"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    ForEach(tasks.prefix(2), id: \.id) { task in
                        Button(action: { onTaskTap?(task.id) }) {
                            HStack(spacing: 6) {
                                Image(systemName: weatherIcon(for: task.affectedBy))
                                    .font(.caption)
                                    .foregroundStyle(weatherColor(for: task.affectedBy))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(task.title)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(task.recommendation)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }

    private var offlineTile: some View {
        HStack(spacing: 10) {
            Image(systemName: "cloud.slash")
                .foregroundStyle(.gray)
            Text(LocalizedStringKey("weather.offline"))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func icon(for snapshot: WeatherSnapshot) -> String {
        let c = snapshot.current.condition.lowercased()
        if c.contains("rain") { return "cloud.rain" }
        if c.contains("storm") || c.contains("thunder") { return "cloud.bolt" }
        if c.contains("snow") { return "cloud.snow" }
        if c.contains("cloud") || c.contains("overcast") { return "cloud" }
        return "sun.max"
    }

    private func color(for snapshot: WeatherSnapshot) -> Color {
        let c = snapshot.current.condition.lowercased()
        if c.contains("rain") { return .blue }
        if c.contains("storm") || c.contains("thunder") { return .purple }
        if c.contains("snow") { return .cyan }
        if c.contains("cloud") || c.contains("overcast") { return .gray }
        return .yellow
    }

    private func suggestionIcon(for kind: WeatherSuggestion.Kind) -> String {
        switch kind {
        case .rain: return "cloud.rain"
        case .snow: return "cloud.snow"
        case .heat: return "thermometer.sun"
        case .cold: return "thermometer.snowflake"
        case .dsny: return "trash.circle"
        case .sun: return "sun.max"
        case .wind: return "wind"
        case .generic: return "lightbulb"
        }
    }

    private func suggestionColor(for kind: WeatherSuggestion.Kind) -> Color {
        switch kind {
        case .rain: return .blue
        case .snow: return .cyan
        case .heat: return .orange
        case .cold: return .blue
        case .dsny: return .green
        case .sun: return .yellow
        case .wind: return .gray
        case .generic: return .white
        }
    }

    private func nextPeakPrecip(_ snapshot: WeatherSnapshot) -> String? {
        let window = snapshot.hourly.prefix(12)
        guard let best = window.max(by: { $0.precipProb < $1.precipProb }), best.precipProb >= 0.5 else { return nil }
        let pct = Int(best.precipProb * 100)
        let time = best.date.formatted(date: .omitted, time: .shortened)
        let fmt = NSLocalizedString("weather.rain_likely_at", comment: "Rain likely ~%d%% at %@")
        return String(format: fmt, pct, time)
    }

    private func riskBanner(_ snapshot: WeatherSnapshot) -> (icon: String, text: String)? {
        let temp = snapshot.current.tempF
        if temp >= 90 {
            return ("thermometer.sun", NSLocalizedString("weather.risk.heat", comment: "Heat risk: stay hydrated"))
        }
        return nil
    }

    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case "rain", "precipitation": return "cloud.rain"
        case "wind": return "wind"
        case "heat": return "thermometer.sun"
        case "cold": return "thermometer.snowflake"
        case "storm": return "cloud.bolt"
        default: return "exclamationmark.triangle"
        }
    }

    private func weatherColor(for condition: String) -> Color {
        switch condition.lowercased() {
        case "rain", "precipitation": return .blue
        case "wind": return .gray
        case "heat": return .orange
        case "cold": return .cyan
        case "storm": return .purple
        default: return .yellow
        }
    }
}
