//
//  WeatherHybridCard.swift
//  CyntientOps
//
//  Hybrid weather card: current snapshot + compact risk + hourly action
//

import SwiftUI

struct WeatherHybridCard: View {
    let snapshot: WeatherSnapshot?
    let suggestion: String?
    let onApplySuggestion: (() -> Void)?
    let onViewHourly: () -> Void

    @State private var showHourly = false

    private var isSpanish: Bool {
        Locale.current.language.languageCode?.identifier == "es"
    }

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
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon(for: snapshot))
                    .foregroundStyle(color(for: snapshot))
                Text("\(Int(snapshot.current.tempF))°")
                    .font(.title2).fontWeight(.semibold)
                Text(snapshot.current.condition)
                    .foregroundStyle(.secondary)
                Spacer()
                if let onApply = onApplySuggestion, suggestion != nil {
                    Button(isSpanish ? "Aplicar" : "Apply") { onApply() }
                        .font(.callout)
                        .buttonStyle(.borderedProminent)
                }
                Button(isSpanish ? "Ver por hora" : "View hourly") {
                    onViewHourly()
                }
                .font(.callout)
            }

            if let precip = nextPeakPrecip(snapshot) {
                Text(precip)
                    .font(.caption)
                    .foregroundStyle(.cyan)
            }

            if let suggestionText = suggestion {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb")
                    Text(suggestionText)
                }
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
            } else if let banner = riskBanner(snapshot) {
                HStack(spacing: 6) {
                    Image(systemName: banner.icon)
                    Text(banner.text)
                }
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
            }
        }
    }

    private var offlineTile: some View {
        HStack(spacing: 10) {
            Image(systemName: "cloud.slash")
                .foregroundStyle(.gray)
            Text(isSpanish ? "Tiempo sin conexión" : "Weather offline")
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

    private func nextPeakPrecip(_ snapshot: WeatherSnapshot) -> String? {
        let window = snapshot.hourly.prefix(12)
        guard let best = window.max(by: { $0.precipProb < $1.precipProb }), best.precipProb >= 0.5 else { return nil }
        let pct = Int(best.precipProb * 100)
        let time = best.date.formatted(date: .omitted, time: .shortened)
        if isSpanish {
            return "Lluvia probable ~\(pct)% a las \(time)"
        } else {
            return "Rain likely ~\(pct)% at \(time)"
        }
    }

    private func riskBanner(_ snapshot: WeatherSnapshot) -> (icon: String, text: String)? {
        let wind = snapshot.hourly.prefix(6).map(\.windMph).max() ?? 0
        let temp = snapshot.current.tempF
        if wind >= 25 {
            return ("wind", isSpanish ? "Viento fuerte: asegurar exteriores" : "Strong wind: secure outdoor work")
        }
        if temp >= 90 {
            return ("thermometer.sun", isSpanish ? "Calor extremo: hidratarse" : "Heat risk: stay hydrated")
        }
        return nil
    }
}
