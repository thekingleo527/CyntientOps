import SwiftUI

enum WeatherViewHelper {
    static func icon(for condition: CoreTypes.WeatherCondition) -> String {
        switch condition {
        case .clear: return "sun.max"
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud"
        case .overcast: return "cloud.fill"
        case .rain: return "cloud.rain"
        case .snow, .snowy: return "cloud.snow"
        case .storm: return "cloud.bolt"
        case .fog, .foggy: return "cloud.fog"
        case .windy: return "wind"
        case .hot: return "thermometer.sun"
        case .cold: return "thermometer.snowflake"
        }
    }

    static func color(for condition: CoreTypes.WeatherCondition) -> Color {
        switch condition {
        case .clear: return .orange
        case .sunny: return .yellow
        case .cloudy: return .gray
        case .overcast: return .gray.opacity(0.8)
        case .rain: return .blue
        case .snow, .snowy: return .cyan
        case .storm: return .purple
        case .fog, .foggy: return .gray.opacity(0.6)
        case .windy: return .mint
        case .hot: return .red
        case .cold: return .blue.opacity(0.7)
        }
    }
}

