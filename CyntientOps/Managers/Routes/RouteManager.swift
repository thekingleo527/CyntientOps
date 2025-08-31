//
//  RouteManager.swift
//  CyntientOps
//
//  Route-based operational management system
//  Replaces discrete task management with real workflow sequences
//

import Foundation
import Combine
import GRDB

// MARK: - Route Management System

@MainActor
public final class RouteManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var routes: [WorkerRoute] = []
    @Published public private(set) var buildingProfiles: [BuildingOperationalProfile] = []
    @Published public private(set) var currentRouteProgress: [String: RouteProgress] = [:] // RouteID -> Progress
    @Published public private(set) var isInitialized = false
    @Published public private(set) var lastUpdate: Date?
    
    // MARK: - Private Properties
    
    private let database: GRDBManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(database: GRDBManager) {
        self.database = database
        setupRoutes()
        setupBuildingProfiles()
    }
    
    // MARK: - Route Setup
    
    private func setupRoutes() {
        // Load all worker routes
        var allRoutes: [WorkerRoute] = []
        
        // Kevin Dutan's complete weekly schedule
        allRoutes.append(contentsOf: KevinDutanCompleteSchedule.getWeeklyRoutes())
        
        // Edwin Lema's complete weekly schedule  
        allRoutes.append(contentsOf: EdwinLemaRoutes.getWeeklyRoutes())
        
        // TODO: Add other workers when available
        // allRoutes.append(contentsOf: GregHutsonRoutes.getWeeklyRoutes())
        // allRoutes.append(contentsOf: MercedesInamaguaRoutes.getWeeklyRoutes())
        // allRoutes.append(contentsOf: LuisLopezRoutes.getWeeklyRoutes())
        // allRoutes.append(contentsOf: AngelGuirachochaRoutes.getWeeklyRoutes())
        
        routes = allRoutes
        print("✅ RouteManager: Loaded \(routes.count) worker routes across \(Set(routes.map { $0.workerId }).count) workers")
        
        // Log route summary
        let routesByWorker = Dictionary(grouping: routes) { $0.workerId }
        for (workerId, workerRoutes) in routesByWorker {
            let workerName = CanonicalIDs.Workers.getName(for: workerId) ?? "Unknown"
            print("   - \(workerName): \(workerRoutes.count) daily routes")
        }
    }
    
    private func setupBuildingProfiles() {
        buildingProfiles = KevinBuildingProfiles.getAllProfiles()
        print("✅ RouteManager: Loaded \(buildingProfiles.count) building profiles")
    }
    
    // MARK: - Route Queries
    
    /// Get routes for a specific worker
    public func getRoutes(for workerId: String) -> [WorkerRoute] {
        return routes.filter { $0.workerId == workerId }
    }
    
    /// Get route for a specific worker and day
    public func getRoute(for workerId: String, dayOfWeek: Int) -> WorkerRoute? {
        return routes.first { $0.workerId == workerId && $0.dayOfWeek == dayOfWeek }
    }
    
    /// Get current route for a worker (based on today)
    public func getCurrentRoute(for workerId: String) -> WorkerRoute? {
        let today = Calendar.current.component(.weekday, from: Date())
        return getRoute(for: workerId, dayOfWeek: today)
    }
    
    /// Get active sequences for a worker at current time
    public func getActiveSequences(for workerId: String) -> [RouteSequence] {
        guard let route = getCurrentRoute(for: workerId) else { return [] }
        
        let now = Date()
        return route.sequences.filter { sequence in
            let endTime = sequence.arrivalTime.addingTimeInterval(sequence.estimatedDuration)
            return sequence.arrivalTime <= now && now <= endTime
        }
    }
    
    /// Get upcoming sequences for a worker
    public func getUpcomingSequences(for workerId: String, limit: Int = 3) -> [RouteSequence] {
        guard let route = getCurrentRoute(for: workerId) else { return [] }
        
        let now = Date()
        return route.sequences
            .filter { $0.arrivalTime > now }
            .sorted { $0.arrivalTime < $1.arrivalTime }
            .prefix(limit)
            .map { $0 }
    }
    
    // MARK: - Weather-Aware Route Optimization
    
    /// Reorder flexible sequences based on weather conditions
    public func optimizeRoute(for workerId: String, weather: WeatherSnapshot) -> WorkerRoute? {
        guard let originalRoute = getCurrentRoute(for: workerId) else { return nil }
        
        var optimizedSequences: [RouteSequence] = []
        var weatherSensitiveSequences: [RouteSequence] = []
        var weatherProtectedSequences: [RouteSequence] = []
        
        // Separate sequences by weather sensitivity and flexibility
        for sequence in originalRoute.sequences {
            let hasWeatherSensitiveTasks = sequence.operations.contains { $0.isWeatherSensitive }
            
            if sequence.isFlexible && hasWeatherSensitiveTasks {
                weatherSensitiveSequences.append(sequence)
            } else if sequence.isFlexible && !hasWeatherSensitiveTasks {
                weatherProtectedSequences.append(sequence)
            } else {
                // Non-flexible sequences maintain their position
                optimizedSequences.append(sequence)
            }
        }
        
        // Reorder based on weather conditions
        let currentWeather = weather.current
        let upcomingRain = weather.hourly.prefix(4).map { $0.precipProb }.max() ?? 0
        
        if upcomingRain > 0.6 || currentWeather.windMph > 25 {
            // Bad weather: Indoor first, then outdoor when conditions improve
            optimizedSequences.append(contentsOf: weatherProtectedSequences)
            optimizedSequences.append(contentsOf: weatherSensitiveSequences)
        } else {
            // Good weather: Outdoor first while conditions are favorable
            optimizedSequences.append(contentsOf: weatherSensitiveSequences)
            optimizedSequences.append(contentsOf: weatherProtectedSequences)
        }
        
        // Maintain dependency order
        let sortedSequences = maintainDependencyOrder(optimizedSequences)
        
        return WorkerRoute(
            id: "\(originalRoute.id)_weather_optimized",
            workerId: originalRoute.workerId,
            routeName: "\(originalRoute.routeName) (Weather Optimized)",
            dayOfWeek: originalRoute.dayOfWeek,
            startTime: originalRoute.startTime,
            estimatedEndTime: originalRoute.estimatedEndTime,
            sequences: sortedSequences,
            routeType: originalRoute.routeType
        )
    }
    
    private func maintainDependencyOrder(_ sequences: [RouteSequence]) -> [RouteSequence] {
        var sortedSequences: [RouteSequence] = []
        var remainingSequences = sequences
        
        while !remainingSequences.isEmpty {
            // Find sequences with satisfied dependencies
            let readySequences = remainingSequences.filter { sequence in
                sequence.dependencies.allSatisfy { dependency in
                    sortedSequences.contains { $0.id == dependency }
                }
            }
            
            if readySequences.isEmpty {
                // No sequences ready - break dependency cycle by taking earliest
                if let earliest = remainingSequences.min(by: { $0.arrivalTime < $1.arrivalTime }) {
                    sortedSequences.append(earliest)
                    remainingSequences.removeAll { $0.id == earliest.id }
                }
            } else {
                // Add ready sequences in arrival time order
                let sortedReady = readySequences.sorted { $0.arrivalTime < $1.arrivalTime }
                sortedSequences.append(contentsOf: sortedReady)
                remainingSequences.removeAll { sequence in
                    readySequences.contains { $0.id == sequence.id }
                }
            }
        }
        
        return sortedSequences
    }
    
    // MARK: - Building Profile Queries
    
    /// Get operational profile for a building
    public func getBuildingProfile(for buildingId: String) -> BuildingOperationalProfile? {
        return buildingProfiles.first { $0.buildingId == buildingId }
    }
    
    /// Get weather-sensitive areas for a building
    public func getWeatherSensitiveAreas(for buildingId: String) -> [BuildingOperationalProfile.WeatherSensitiveArea] {
        return getBuildingProfile(for: buildingId)?.weatherSensitiveAreas ?? []
    }
    
    // MARK: - Route Progress Tracking
    
    /// Update progress for a route sequence
    public func updateSequenceProgress(_ sequenceId: String, progress: SequenceProgress) {
        // Find the route containing this sequence
        for route in routes {
            if route.sequences.contains(where: { $0.id == sequenceId }) {
                if currentRouteProgress[route.id] == nil {
                    currentRouteProgress[route.id] = RouteProgress(routeId: route.id)
                }
                currentRouteProgress[route.id]?.sequenceProgress[sequenceId] = progress
                break
            }
        }
        
        lastUpdate = Date()
    }
    
    /// Get overall route completion percentage
    public func getRouteCompletion(for routeId: String) -> Double {
        guard let routeProgress = currentRouteProgress[routeId],
              let route = routes.first(where: { $0.id == routeId }) else {
            return 0.0
        }
        
        let totalSequences = route.sequences.count
        let completedSequences = routeProgress.sequenceProgress.values.filter { 
            $0.status == .completed 
        }.count
        
        return totalSequences > 0 ? Double(completedSequences) / Double(totalSequences) : 0.0
    }
}

// MARK: - Supporting Types

public struct RouteProgress {
    public let routeId: String
    public var sequenceProgress: [String: SequenceProgress] = [:] // SequenceID -> Progress
    public var startTime: Date?
    public var estimatedCompletionTime: Date?
    
    public init(routeId: String) {
        self.routeId = routeId
    }
}

public struct SequenceProgress {
    public let sequenceId: String
    public var status: SequenceStatus
    public var completedOperations: Set<String> = [] // Operation IDs
    public var startTime: Date?
    public var completionTime: Date?
    public var notes: String?
    
    public enum SequenceStatus {
        case pending
        case inProgress
        case completed
        case skipped
        case weatherDelayed
    }
    
    public init(sequenceId: String, status: SequenceStatus = .pending) {
        self.sequenceId = sequenceId
        self.status = status
    }
    
    public var completionPercentage: Double {
        guard !completedOperations.isEmpty else { return 0.0 }
        // This would need to be calculated against total operations in the sequence
        return status == .completed ? 1.0 : 0.5
    }
}