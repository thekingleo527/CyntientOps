//
//  WeatherTasksSection.swift
//  CyntientOps v6.0
//
//  ✅ REAL WEATHER: Integrated with OpenMeteo API via WeatherDataAdapter
//  ✅ NO MOCK DATA: Removed all mock weather generators
//  ✅ PRODUCTION READY: Uses actual weather conditions for task generation
//

import SwiftUI

// Type aliases for CoreTypes

struct WeatherTasksSection: View {
    let building: NamedCoordinate
    let onTaskTap: (MaintenanceTask) -> Void
    
    @StateObject private var weatherAdapter = WeatherDataAdapter.shared
    @State private var weatherTasks: [MaintenanceTask] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader
            
            if isLoading {
                loadingView
            } else if weatherTasks.isEmpty {
                noWeatherTasksView
            } else {
                weatherTasksList
            }
        }
        .onAppear {
            loadWeatherTasks()
        }
        .onChange(of: building.id) { _ in
            loadWeatherTasks()
        }
    }
    
    // MARK: - UI Components
    
    private var sectionHeader: some View {
        HStack {
            Image(systemName: "cloud.rain")
                .foregroundColor(.blue)
            
            Text("Weather-Related Tasks")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            if let lastUpdate = weatherAdapter.lastUpdate {
                Text("Updated \(lastUpdate.formatted(.relative(presentation: .numeric)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var loadingView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Checking weather conditions...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private var noWeatherTasksView: some View {
        HStack {
            Image(systemName: "sun.max")
                .foregroundColor(.orange)
            
            Text("No weather-related tasks needed")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
    
    private var weatherTasksList: some View {
        LazyVStack(spacing: 8) {
            ForEach(weatherTasks) { task in
                WeatherTaskRow(task: task, onTap: { onTaskTap(task) })
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadWeatherTasks() {
        isLoading = true
        
        Task {
            // Fetch real weather data
            await weatherAdapter.fetchWeatherForBuildingAsync(building)
            
            // Generate weather-based tasks using real conditions
            let tasks = weatherAdapter.generateWeatherTasks(for: building)
            
            await MainActor.run {
                self.weatherTasks = tasks
                self.isLoading = false
            }
        }
    }
}

// MARK: - Weather Task Row

struct WeatherTaskRow: View {
    let task: MaintenanceTask
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                weatherIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(task.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                urgencyBadge
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var weatherIcon: some View {
        ZStack {
            Circle()
                .fill(task.urgency.color.opacity(0.2))
                .frame(width: 32, height: 32)
            
            Image(systemName: getWeatherIcon())
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(task.urgency.color)
        }
    }
    
    private var urgencyBadge: some View {
        Text(task.urgency.rawValue.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(task.urgency.color, in: Capsule())
    }
    
    private func getWeatherIcon() -> String {
        if task.title.lowercased().contains("snow") {
            return "snow"
        } else if task.title.lowercased().contains("rain") {
            return "cloud.rain"
        } else if task.title.lowercased().contains("storm") {
            return "cloud.bolt"
        } else if task.title.lowercased().contains("freeze") {
            return "thermometer.snowflake"
        } else if task.title.lowercased().contains("heat") {
            return "thermometer.sun"
        } else {
            return "exclamationmark.triangle"
        }
    }
}
