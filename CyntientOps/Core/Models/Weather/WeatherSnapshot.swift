//
//  WeatherSnapshot.swift
//  CyntientOps
//
//  Weather domain model for UI consumption
//  Lightweight snapshot for weather-aware task scheduling
//

import Foundation

// MARK: - Weather Snapshot for UI

public struct WeatherSnapshot {
    public struct Current {
        public let tempF: Double
        public let condition: String        // "Light rain", "Cloudy", etc.
        public let windMph: Double
        
        public init(tempF: Double, condition: String, windMph: Double) {
            self.tempF = tempF
            self.condition = condition
            self.windMph = windMph
        }
    }
    
    public struct HourBlock: Identifiable {
        public let id = UUID()
        public let date: Date               // top of hour
        public let precipProb: Double       // 0...1
        public let precipIntensity: Double? // optional
        public let windMph: Double
        public let tempF: Double
        
        public init(date: Date, precipProb: Double, precipIntensity: Double? = nil, windMph: Double, tempF: Double) {
            self.date = date
            self.precipProb = precipProb
            self.precipIntensity = precipIntensity
            self.windMph = windMph
            self.tempF = tempF
        }
    }
    
    public let current: Current
    public let hourly: [HourBlock]         // next 12 hours
    
    public init(current: Current, hourly: [HourBlock]) {
        self.current = current
        self.hourly = hourly
    }
}

// MARK: - WeatherSnapshot Extensions

public extension WeatherSnapshot {
    /// Convert from existing CoreTypes.WeatherData array
    static func from(current: CoreTypes.WeatherData?, hourly: [CoreTypes.WeatherData]) -> WeatherSnapshot? {
        guard let current = current else { return nil }
        
        let currentSnapshot = Current(
            tempF: current.temperature,
            condition: current.condition.rawValue.capitalized,
            windMph: current.windSpeed
        )
        
        let hourlyBlocks = hourly.prefix(12).map { weather in
            HourBlock(
                date: weather.timestamp,
                precipProb: precipitationProbability(from: weather.condition),
                precipIntensity: precipitationIntensity(from: weather.condition),
                windMph: weather.windSpeed,
                tempF: weather.temperature
            )
        }
        
        return WeatherSnapshot(current: currentSnapshot, hourly: Array(hourlyBlocks))
    }
    
    private static func precipitationProbability(from condition: CoreTypes.WeatherCondition) -> Double {
        switch condition {
        case .sunny, .clear: return 0.0
        case .cloudy: return 0.1
        case .overcast: return 0.2
        case .rain: return 0.8
        case .storm: return 0.9
        case .snow, .snowy: return 0.85
        case .fog, .foggy: return 0.3
        case .windy: return 0.1
        case .hot, .cold: return 0.0
        }
    }
    
    private static func precipitationIntensity(from condition: CoreTypes.WeatherCondition) -> Double? {
        switch condition {
        case .rain: return 0.6
        case .storm: return 0.9
        case .snow, .snowy: return 0.5
        default: return nil
        }
    }
}
