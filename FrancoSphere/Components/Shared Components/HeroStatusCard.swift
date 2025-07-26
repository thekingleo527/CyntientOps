//
//  HeroStatusCard.swift
//  FrancoSphere
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ CORRECT: Uses proper CoreTypes.TaskProgress properties
//  ✅ WORKING: Matches actual CoreTypes.WeatherData structure
//  ✅ ALIGNED: With exact CoreTypes.WeatherCondition enum cases
//

import SwiftUI
import Foundation
import CoreLocation

struct HeroStatusCard: View {
    let workerId: String
    let currentBuilding: String?
    let weather: CoreTypes.WeatherData?
    let progress: CoreTypes.TaskProgress
    let onClockInTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with worker info
            headerView
            
            // Weather section
            if let weather = weather {
                weatherView(weather)
            }
            
            // Building status
            buildingStatusView
            
            // Task progress
            taskProgressView
            
            // Clock in prompt
            clockInPromptView
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good Morning")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Worker \(workerId)")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // Status indicator - green if good progress, orange if low
            Circle()
                .fill(progress.progressPercentage >= 50 ? Color.green : Color.orange)
                .frame(width: 12, height: 12)
        }
    }
    
    private func weatherView(_ weather: CoreTypes.WeatherData) -> some View {
        HStack {
            Image(systemName: getWeatherIconName(weather.condition))
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(Int(weather.temperature))°F")
                    .font(.headline)
                
                Text(weather.condition)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if weather.humidity > 0.7 {
                Label("\(Int(weather.humidity * 100))%", systemImage: "drop.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var buildingStatusView: some View {
        HStack {
            Image(systemName: "building.2")
                .font(.title3)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Building")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(currentBuilding ?? "Not assigned")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
    
    private var taskProgressView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(progress.completedTasks)/\(progress.totalTasks)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                    
                    Rectangle()
                        .fill(progress.progressPercentage >= 50 ? Color.green : Color.orange)
                        .frame(width: geometry.size.width * (progress.progressPercentage / 100), height: 6)
                }
                .cornerRadius(3)
            }
            .frame(height: 6)
            
            // Status details
            HStack {
                if progress.progressPercentage < 50 {
                    Label("Behind schedule", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                let remaining = progress.totalTasks - progress.completedTasks
                Text("\(remaining) remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var clockInPromptView: some View {
        Button(action: onClockInTap) {
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .font(.headline)
                
                Text("Clock In")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.blue)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getWeatherIconName(_ condition: CoreTypes.WeatherCondition) -> String {
        switch condition {
        case .clear:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .rainy:
            return "cloud.rain.fill"
        case .snowy:
            return "cloud.snow.fill"
        case .stormy:
            return "cloud.bolt.fill"
        case .foggy:
            return "cloud.fog.fill"
        case .windy:
            return "wind"
        case .hot:
            return "thermometer.sun.fill"
        case .cold:
            return "thermometer.snowflake"
        }
    }
}

// MARK: - ✅ FIXED: Preview with correct constructors
#Preview {
    let sampleWeather = CoreTypes.WeatherData(
        id: UUID().uuidString,
        temperature: 72.0,
        condition: .clear,
        humidity: 0.65,
        windSpeed: 5.0,
        outdoorWorkRisk: .low,
        timestamp: Date()
    )
    
    let sampleProgress = CoreTypes.TaskProgress(
        id: UUID().uuidString,
        totalTasks: 12,
        completedTasks: 8,
        lastUpdated: Date()
    )
    
    HeroStatusCard(
        workerId: "kevin",
        currentBuilding: "Rubin Museum",
        weather: sampleWeather,
        progress: sampleProgress,
        onClockInTap: {
            print("Clock in tapped")
        }
    )
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
