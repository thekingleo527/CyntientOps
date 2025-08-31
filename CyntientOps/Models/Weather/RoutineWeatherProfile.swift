//
//  RoutineWeatherProfile.swift
//  CyntientOps
//
//  Weather sensitivity profiles for routine categorization
//  Maps routine categories to weather requirements and constraints
//

import Foundation

// MARK: - Weather Chips and Profiles

public enum WeatherChip: CaseIterable {
    case goodWindow
    case wet
    case heavyRain
    case windy
    case hot
    case cold
    
    public var emoji: String {
        switch self {
        case .goodWindow: return "👍"
        case .wet: return "⚠️"
        case .heavyRain: return "🌧️"
        case .windy: return "🌬️"
        case .hot: return "🔥"
        case .cold: return "❄️"
        }
    }
    
    public var label: String {
        switch self {
        case .goodWindow: return "Good Window"
        case .wet: return "Wet Pavement"
        case .heavyRain: return "Heavy Rain"
        case .windy: return "High Wind"
        case .hot: return "Heat Alert"
        case .cold: return "Cold Alert"
        }
    }
    
    public var color: String {
        switch self {
        case .goodWindow: return "green"
        case .wet: return "orange"
        case .heavyRain: return "red"
        case .windy: return "cyan"
        case .hot: return "red"
        case .cold: return "blue"
        }
    }
}

public struct WeatherProfile {
    public let isOutdoor: Bool
    public let sensitiveToPrecip: Bool
    public let sensitiveToWind: Bool
    public let idealWindMax: Double?    // mph
    public let idealPrecipProbMax: Double? // 0...1
    
    public init(isOutdoor: Bool, sensitiveToPrecip: Bool, sensitiveToWind: Bool, 
                idealWindMax: Double? = nil, idealPrecipProbMax: Double? = nil) {
        self.isOutdoor = isOutdoor
        self.sensitiveToPrecip = sensitiveToPrecip
        self.sensitiveToWind = sensitiveToWind
        self.idealWindMax = idealWindMax
        self.idealPrecipProbMax = idealPrecipProbMax
    }
}

// MARK: - Routine Category Mapping

public enum RoutineCategory: String, CaseIterable {
    case cleaning = "Cleaning"
    case sanitation = "Sanitation" 
    case operations = "Operations"
    case maintenance = "Maintenance"
    case inspection = "Inspection"
    case repair = "Repair"
    case unknown = "Unknown"
    
    public init?(category: String?) {
        guard let category = category else { return nil }
        self = RoutineCategory(rawValue: category) ?? .unknown
    }
}

// MARK: - Weather Profiles by Category

public enum WeatherProfiles {
    public static func forCategory(_ category: RoutineCategory) -> WeatherProfile {
        switch category {
        case .cleaning:   
            return WeatherProfile(
                isOutdoor: true, 
                sensitiveToPrecip: true,  
                sensitiveToWind: false, 
                idealWindMax: 25, 
                idealPrecipProbMax: 0.3
            )
        case .sanitation: 
            return WeatherProfile(
                isOutdoor: true, 
                sensitiveToPrecip: true,  
                sensitiveToWind: true,  
                idealWindMax: 30, 
                idealPrecipProbMax: 0.4
            )
        case .operations: 
            return WeatherProfile(
                isOutdoor: true, 
                sensitiveToPrecip: false, 
                sensitiveToWind: true,  
                idealWindMax: 35, 
                idealPrecipProbMax: 0.6
            ) // DSNY window - more weather tolerant
        case .maintenance, .repair:
            return WeatherProfile(
                isOutdoor: true, 
                sensitiveToPrecip: true, 
                sensitiveToWind: false,
                idealWindMax: 20,
                idealPrecipProbMax: 0.2
            )
        case .inspection:
            return WeatherProfile(
                isOutdoor: false, 
                sensitiveToPrecip: false, 
                sensitiveToWind: false,
                idealWindMax: nil,
                idealPrecipProbMax: nil
            )
        case .unknown:          
            return WeatherProfile(
                isOutdoor: false, 
                sensitiveToPrecip: false, 
                sensitiveToWind: false, 
                idealWindMax: nil, 
                idealPrecipProbMax: nil
            )
        }
    }
    
    /// Get category from string with fallback
    public static func categoryFromString(_ categoryString: String?) -> RoutineCategory {
        guard let categoryString = categoryString else { return .unknown }
        return RoutineCategory(rawValue: categoryString) ?? .unknown
    }
}