//
//  WeatherDashboardComponent.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: With current CoreTypes and Phase 2.1 implementation
//  ✅ ENHANCED: Compatible with three-dashboard system
//  ✅ GRDB: Real-time data integration ready
//  ✅ FIXED: Removed isCompleted from ContextualTask initializers
//

import SwiftUI
import CoreLocation

struct WeatherDashboardComponent: View {
    let building: NamedCoordinate
    let weather: CoreTypes.WeatherData
    let tasks: [ContextualTask]
    let onTaskTap: (ContextualTask) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            buildingHeader
            
            // Weather Display
            weatherSection
            
            // Tasks Section
            if !tasks.isEmpty {
                tasksSection
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
    
    // MARK: - Building Header
    
    private var buildingHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(building.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // ✅ FIXED: address is non-optional, just check if not empty
                if !building.address.isEmpty {
                    Text(building.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Weather Section
    
    private var weatherSection: some View {
        HStack(spacing: 12) {
            // Weather Icon
            Image(systemName: weatherIcon)
                .foregroundColor(weatherColor)
                .font(.title2)
            
            // Temperature and Conditions
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(weather.temperature))°F")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(weather.condition.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Additional Weather Info
            VStack(alignment: .trailing, spacing: 2) {
                // Wind info if significant
                if weather.windSpeed > 10 {
                    HStack(spacing: 4) {
                        Image(systemName: "wind")
                            .foregroundColor(.gray)
                            .font(.caption2)
                        Text("\(Int(weather.windSpeed)) mph")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Humidity info if high
                if weather.humidity > 70 {
                    HStack(spacing: 4) {
                        Image(systemName: "humidity")
                            .foregroundColor(.blue)
                            .font(.caption2)
                        Text("\(Int(weather.humidity))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Tasks Section
    
    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's Tasks")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 4) {
                ForEach(tasks, id: \.id) { task in
                    TaskRowView(task: task, onTap: onTaskTap)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var weatherIcon: String {
        switch weather.condition {
        case .clear: return "sun.max"
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud"
        case .overcast: return "cloud.fill"
        case .rain: return "cloud.rain"
        case .snow: return "cloud.snow"
        case .snowy: return "cloud.snow.fill"
        case .storm: return "cloud.bolt"
        case .fog: return "cloud.fog"
        case .foggy: return "cloud.fog.fill"
        case .windy: return "wind"
        case .hot: return "thermometer.sun"
        case .cold: return "thermometer.snowflake"
        }
    }
    
    private var weatherColor: Color {
        switch weather.condition {
        case .clear: return .orange
        case .sunny: return .yellow
        case .cloudy: return .gray
        case .overcast: return .gray.opacity(0.8)
        case .rain: return .blue
        case .snow: return .cyan
        case .snowy: return .cyan.opacity(0.8)
        case .storm: return .purple
        case .fog: return .gray.opacity(0.7)
        case .foggy: return .gray.opacity(0.5)
        case .windy: return .mint
        case .hot: return .red
        case .cold: return .blue.opacity(0.7)
        }
    }
}

// MARK: - Task Row Component

struct TaskRowView: View {
    let task: ContextualTask
    let onTap: (ContextualTask) -> Void
    
    var body: some View {
        Button(action: { onTap(task) }) {
            HStack(spacing: 8) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                // Task title
                Text(task.title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                // Urgency badge
                if let urgency = task.urgency {
                    Text(urgencyText(urgency))
                        .font(.caption2)
                        .foregroundColor(urgencyColor(urgency))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(urgencyColor(urgency).opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        task.isCompleted ? .green : .gray
    }
    
    private func urgencyText(_ urgency: CoreTypes.TaskUrgency) -> String {
        switch urgency {
        case .low: return "Low"
        case .medium: return "Med"
        case .normal: return "Normal"
        case .high: return "High"
        case .critical: return "Critical"
        case .urgent: return "Urgent"
        case .emergency: return "Emergency"
        }
    }
    
    private func urgencyColor(_ urgency: CoreTypes.TaskUrgency) -> Color {
        switch urgency {
        case .low: return .green
        case .medium: return .orange
        case .normal: return .blue
        case .high: return .red
        case .critical, .urgent, .emergency: return .purple
        }
    }
}

// MARK: - Preview

struct WeatherDashboardComponent_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Sample with tasks
            WeatherDashboardComponent(
                building: sampleBuilding,
                weather: sampleWeather,
                tasks: sampleTasks,
                onTaskTap: { task in
                    print("Tapped task: \(task.title)")
                }
            )
            
            // Sample without tasks
            WeatherDashboardComponent(
                building: sampleBuilding,
                weather: stormyWeather,
                tasks: [],
                onTaskTap: { _ in }
            )
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Sample Data
    
    static var sampleBuilding: NamedCoordinate {
        // ✅ FIXED: Removed imageAssetName
        NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            address: "150 W 17th St, New York, NY 10011",
            latitude: 40.7402,
            longitude: -73.9980
        )
    }
    
    static var sampleWeather: CoreTypes.WeatherData {
        CoreTypes.WeatherData(
            temperature: 72,
            condition: CoreTypes.WeatherCondition.clear,
            humidity: 65,
            windSpeed: 8.5,
            outdoorWorkRisk: CoreTypes.OutdoorWorkRisk.low,
            timestamp: Date()
        )
    }
    
    static var stormyWeather: CoreTypes.WeatherData {
        CoreTypes.WeatherData(
            temperature: 58,
            condition: CoreTypes.WeatherCondition.storm,
            humidity: 85,
            windSpeed: 25.0,
            outdoorWorkRisk: CoreTypes.OutdoorWorkRisk.extreme,
            timestamp: Date()
        )
    }
    
    static var sampleTasks: [ContextualTask] {
        [
            // ✅ FIXED: Removed isCompleted parameter and using completedAt
            ContextualTask(
                id: "1",
                title: "Window Cleaning",
                description: "Clean exterior windows",
                status: .pending,  // Makes isCompleted false
                completedAt: nil,
                dueDate: Date(),
                category: .cleaning,
                urgency: .medium,
                building: nil,
                worker: nil,
                buildingId: "14",
                priority: .medium
            ),
            ContextualTask(
                id: "2",
                title: "HVAC Inspection",
                description: "Check HVAC system",
                status: .completed,  // Makes isCompleted true
                completedAt: Date(),
                dueDate: Date(),
                category: .maintenance,
                urgency: .high,
                building: nil,
                worker: nil,
                buildingId: "14",
                priority: .high
            ),
            ContextualTask(
                id: "3",
                title: "Emergency Exit Check",
                description: "Verify emergency exit accessibility",
                status: .pending,  // Makes isCompleted false
                completedAt: nil,
                dueDate: Date(),
                category: .inspection,
                urgency: .critical,
                building: nil,
                worker: nil,
                buildingId: "14",
                priority: .critical
            )
        ]
    }
}
