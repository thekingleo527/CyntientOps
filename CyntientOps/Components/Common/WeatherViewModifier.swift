//
//  WeatherViewModifier.swift
//  CyntientOps
//
//  ✅ V6.0 FIXED: Exhaustive switch statements with all CoreTypes.WeatherCondition cases
//  ✅ INTEGRATION: Uses existing WeatherDataAdapter properly
//  ✅ COMPATIBILITY: Fixed StateObject access patterns
//

import SwiftUI

struct WeatherViewModifier: ViewModifier {
    @StateObject private var weatherAdapter = WeatherDataAdapter.shared
    @State private var showWeatherAlert = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                weatherOverlay,
                alignment: .topTrailing
            )
            .alert("Weather Alert", isPresented: $showWeatherAlert) {
                Button("OK") {}
            } message: {
                Text(weatherAlertMessage)
            }
            .onAppear {
                loadCurrentWeather()
            }
    }
    
    @ViewBuilder
    private var weatherOverlay: some View {
        if let weather = weatherAdapter.currentWeather {
            // weather.condition is already a WeatherCondition enum
            let conditionEnum = weather.condition
            
            HStack(spacing: 8) {
                Image(systemName: getWeatherIcon(for: conditionEnum))
                    .foregroundColor(getWeatherColor(for: conditionEnum))
                
                Text(weather.formattedTemperature)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.8))
            .clipShape(Capsule())
            .shadow(radius: 2)
            .padding()
            .onTapGesture {
                checkWeatherAlerts()
            }
        }
    }
    
    private func getWeatherIcon(for condition: CoreTypes.WeatherCondition) -> String {
        switch condition {
        case .clear:
            return "sun.max"
        case .sunny:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .rain:
            return "cloud.rain.fill"
        case .snow, .snowy:
            return "cloud.snow.fill"
        case .storm:
            return "cloud.bolt.fill"
        case .fog, .foggy:
            return "cloud.fog.fill"
        case .windy:
            return "wind"
        case .overcast:
            return "cloud.fill"
        case .hot:
            return "thermometer.sun"
        case .cold:
            return "thermometer.snowflake"
        }
    }
    
    private func getWeatherColor(for condition: CoreTypes.WeatherCondition) -> Color {
        switch condition {
        case .clear:
            return .yellow
        case .sunny:
            return .orange
        case .cloudy:
            return .gray
        case .rain:
            return .blue
        case .snow, .snowy:
            return .cyan
        case .storm:
            return .purple
        case .fog, .foggy:
            return .gray.opacity(0.7)
        case .windy:
            return .mint
        case .overcast:
            return .gray.opacity(0.9)
        case .hot:
            return .red
        case .cold:
            return .indigo
        }
    }
    
    private var weatherAlertMessage: String {
        guard let weather = weatherAdapter.currentWeather else {
            return "No weather data available"
        }
        
        // weather.condition is already a WeatherCondition enum
        let conditionEnum = weather.condition
        
        switch conditionEnum {
        case .storm:
            return "Severe weather alert: Storm conditions detected"
        case .rain:
            // FIX: Use windSpeed as proxy for rain intensity since no precipitation property
            if weather.windSpeed > 15 {
                return "Heavy rain alert: Consider indoor tasks"
            } else {
                return "Rain detected: Monitor outdoor conditions"
            }
        case .snow, .snowy:
            return "Snow alert: Use caution for outdoor work"
        case .fog, .foggy:
            return "Fog alert: Reduced visibility conditions"
        case .windy:
            if weather.windSpeed > 25 {
                return "High wind alert: Secure outdoor materials"
            } else {
                return "Windy conditions detected"
            }
        case .clear, .sunny:
            return "Current weather conditions are favorable"
        case .cloudy, .overcast:
            return "Cloudy conditions - good for most outdoor work"
        case .hot:
            return "Heat alert: Stay hydrated and take frequent breaks"
        case .cold:
            return "Cold weather alert: Dress warmly and check for ice"
        }
    }
    
    private func loadCurrentWeather() {
        // Weather data is managed by WeatherDataAdapter.shared
        // No manual loading needed - other components will populate the shared instance
        // If needed, this could trigger loading for a default location
        print("ℹ️ WeatherViewModifier: Weather data will be loaded by other components")
    }
    
    private func checkWeatherAlerts() {
        guard let weather = weatherAdapter.currentWeather else { return }
        
        // weather.condition is already a WeatherCondition enum
        let conditionEnum = weather.condition
        
        // FIX: Use outdoor work risk and wind speed instead of precipitation
        if conditionEnum == .storm ||
           weather.outdoorWorkRisk == .extreme ||
           weather.outdoorWorkRisk == .high ||
           weather.windSpeed > 20 {
            showWeatherAlert = true
        }
    }
}

extension View {
    func weatherAware() -> some View {
        self.modifier(WeatherViewModifier())
    }
}

// Add extension for WeatherData if formattedTemperature is missing
extension CoreTypes.WeatherData {
    var formattedTemperature: String {
        return "\(Int(temperature))°F"
    }
}
