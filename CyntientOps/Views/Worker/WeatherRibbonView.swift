//
//  WeatherRibbonView.swift  
//  CyntientOps
//
//  Compact weather ribbon with expandable hourly forecast
//  Matches CyntientOps glass design system
//

import SwiftUI

struct WeatherRibbonView: View {
    let snapshot: WeatherSnapshot
    @State private var expanded = false
    
    var body: some View {
        VStack(spacing: 6) {
            // Main ribbon
            HStack(spacing: 10) {
                Text(snapshot.current.condition)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(Int(snapshot.current.tempF))°")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("• Wind \(Int(snapshot.current.windMph)) mph")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Rain probability for next 4 hours
                if let maxRain = snapshot.hourly.prefix(4).map(\.precipProb).max(), 
                   maxRain > 0.4 {
                    Text("• Rain \(Int(maxRain * 100))% next 4h")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                }
                
                Spacer()
                
                Button(expanded ? LocalizedStringKey("weather.hide_details") : LocalizedStringKey("weather.view_hourly")) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        expanded.toggle()
                    }
                }
                .font(.callout)
                .foregroundStyle(.blue)
            }
            
            // Expandable hourly forecast
            if expanded {
                HourlyStripView(blocks: Array(snapshot.hourly.prefix(12)))
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Hourly Strip View

private struct HourlyStripView: View {
    let blocks: [WeatherSnapshot.HourBlock]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(blocks) { block in
                    VStack(spacing: 4) {
                        Text(block.date.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text("\(Int(block.tempF))°")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        if block.precipProb > 0.2 {
                            Text("\(Int(block.precipProb * 100))%")
                                .font(.caption2)
                                .foregroundStyle(.cyan)
                        } else {
                            Text("—")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        if block.windMph > 15 {
                            Text("\(Int(block.windMph))mph")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        } else {
                            Spacer()
                                .frame(height: 12)
                        }
                    }
                    .frame(minWidth: 50)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

 
