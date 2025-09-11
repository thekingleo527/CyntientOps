import SwiftUI

struct WeatherTaskV2: Identifiable, Equatable {
    let id: String
    let title: String
    let notes: String?
    let estimatedMinutes: Int?
    let cautions: [String]
    let requiresPhoto: Bool
}

struct WeatherSuggestionV2: Identifiable, Equatable {
    let id: String
    let buildingId: String
    let buildingName: String
    let icon: String
    let headline: String
    let rationale: String
    let window: DateInterval
    let tasks: [WeatherTaskV2]
    let priority: Int
}

struct WeatherHybridCardV2: View {
    @State private var expanded: Bool = false
    let suggestion: WeatherSuggestionV2
    let onStart: (WeatherSuggestionV2) -> Void
    let onOpenBuilding: (String) -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                Image(systemName: suggestion.icon)
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey("weather.card.title"))
                        .font(.headline)
                    Text(suggestion.headline)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(suggestion.buildingName) • \(formatted(suggestion.window))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(expanded ? LocalizedStringKey("weather.hide_details") : LocalizedStringKey("weather.details")) {
                    AnalyticsManager.shared.track(AnalyticsEvent(name: .weatherCardExpand, properties: ["building_id": suggestion.buildingId]))
                    withAnimation { expanded.toggle() }
                }
                .buttonStyle(.bordered)
            }

            if expanded {
                Divider().padding(.vertical, 6)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(suggestion.tasks) { t in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "checklist")
                                Text(t.title).font(.subheadline.weight(.semibold))
                                if let m = t.estimatedMinutes {
                                    Text("• \(m) min").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            if let notes = t.notes { Text(notes).font(.caption) }
                            if !t.cautions.isEmpty {
                                Label(t.cautions.joined(separator: " • "), systemImage: "exclamationmark.triangle")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                        }
                        .padding(8)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }

                    HStack {
                        Button(LocalizedStringKey("weather.open_building")) { onOpenBuilding(suggestion.buildingId) }
                            .buttonStyle(.borderedProminent)
                        Button(LocalizedStringKey("weather.start")) {
                            AnalyticsManager.shared.track(AnalyticsEvent(name: .weatherCardStart, properties: ["building_id": suggestion.buildingId]))
                            onStart(suggestion)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .accessibilityElement(children: .contain)
        .onAppear { AnalyticsManager.shared.track(AnalyticsEvent(name: .weatherCardView, properties: ["building_id": suggestion.buildingId])) }
    }

    private func formatted(_ window: DateInterval) -> String {
        let fmt = DateIntervalFormatter()
        fmt.dateStyle = .none
        fmt.timeStyle = .short
        // DateIntervalFormatter can return nil; provide a sensible fallback
        if let s = fmt.string(from: window) { return s }
        let df = DateFormatter(); df.dateStyle = .none; df.timeStyle = .short
        return "\(df.string(from: window.start)) – \(df.string(from: window.end))"
    }
}
