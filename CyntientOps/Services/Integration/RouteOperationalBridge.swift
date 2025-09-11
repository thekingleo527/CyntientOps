//
//  RouteOperationalBridge.swift
//  CyntientOps
//
//  Integration bridge between new RouteManager and existing OperationalDataManager
//  Ensures backwards compatibility while transitioning to route-based operations
//

import Foundation
import Combine

// MARK: - Route-Operational Integration Bridge

@MainActor
public final class RouteOperationalBridge: ObservableObject {
    
    // MARK: - Dependencies
    
    private let routeManager: RouteManager
    private let operationalManager: OperationalDataManager
    
    // MARK: - Published Properties
    
    @Published public private(set) var isIntegrated = false
    @Published public private(set) var bridgeStatus: BridgeStatus = .initializing
    
    public enum BridgeStatus {
        case initializing
        case active
        case error(String)
        case maintenance
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(routeManager: RouteManager, operationalManager: OperationalDataManager) {
        self.routeManager = routeManager
        self.operationalManager = operationalManager
        setupIntegration()
    }
    
    // MARK: - Integration Setup
    
    private func setupIntegration() {
        // Monitor route manager changes
        routeManager.$routes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] routes in
                self?.syncRoutesToOperational(routes)
            }
            .store(in: &cancellables)
        
        // Monitor operational manager changes
        operationalManager.$currentStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                if status.contains("tasks refreshed") || status.contains("routines updated") {
                    self?.syncOperationalToRoutes()
                }
            }
            .store(in: &cancellables)
        
        bridgeStatus = .active
        isIntegrated = true
        print("✅ RouteOperationalBridge: Integration active")
    }
    
    // MARK: - Legacy Task Conversion
    
    /// Convert route sequences to legacy TaskItems for existing ViewModels
    public func convertRoutesToTasks(for workerId: String, date: Date = Date()) -> [WorkerDashboardViewModel.TaskItem] {
        let dayOfWeek = Calendar.current.component(.weekday, from: date)
        guard let route = routeManager.getRoute(for: workerId, dayOfWeek: dayOfWeek) else {
            return []
        }
        
        var taskItems: [WorkerDashboardViewModel.TaskItem] = []
        
        for sequence in route.sequences {
            // Convert each operation in the sequence to a TaskItem
            var cumulative: TimeInterval = 0
            for operation in sequence.operations {
                let taskId = "\(sequence.id)_\(operation.id)"
                let scheduledTime = sequence.arrivalTime.addingTimeInterval(cumulative)
                
                let urgency = determineUrgency(from: operation, scheduledTime: scheduledTime)
                let taskItem = WorkerDashboardViewModel.TaskItem(
                    id: taskId,
                    title: operation.name,
                    description: operation.instructions ?? "",
                    buildingId: sequence.buildingId,
                    dueDate: scheduledTime,
                    urgency: urgency,
                    isCompleted: false,
                    category: convertOperationCategoryToLegacy(operation.category),
                    requiresPhoto: operation.requiresPhoto
                )
                
                taskItems.append(taskItem)
                cumulative += operation.estimatedDuration
            }
        }
        
        return taskItems.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
    }
    
    /// Convert new OperationTask.TaskCategory to legacy string category
    private func convertOperationCategoryToLegacy(_ category: OperationTask.TaskCategory) -> String {
        switch category {
        case .sweeping, .hosing, .vacuuming, .mopping, .posterRemoval, .treepitCleaning:
            return "Cleaning"
        case .trashCollection, .binManagement, .dsnySetout:
            return "Sanitation"
        case .stairwellCleaning, .laundryRoom:
            return "Cleaning"
        case .buildingInspection:
            return "Inspection"
        case .maintenance:
            return "Maintenance"
        }
    }
    
    /// Convert TaskLocation to string representation
    private func convertTaskLocationToString(_ location: OperationTask.TaskLocation) -> String {
        return location.rawValue
    }
    
    /// Determine task priority based on operation characteristics
    private func determinePriority(from operation: OperationTask) -> LegacyTaskPriority {
        switch operation.category {
        case .dsnySetout:
            return .critical // Compliance-critical
        case .buildingInspection:
            return .high
        case .maintenance:
            return .medium
        case .trashCollection, .binManagement:
            return .medium
        default:
            return .normal
        }
    }
    
    // MARK: - Context Conversion
    
    /// Convert route sequences to ContextualTasks for weather-aware system
    public func convertSequencesToContextualTasks(for workerId: String) -> [CoreTypes.ContextualTask] {
        let now = Date()
        let upcomingSequences = routeManager.getUpcomingSequences(for: workerId, limit: 10)
        
        var contextualTasks: [CoreTypes.ContextualTask] = []
        
        for sequence in upcomingSequences {
            var cumulative: TimeInterval = 0
            for operation in sequence.operations {
                let taskId = "\(sequence.id)_\(operation.id)"
                let scheduledTime = sequence.arrivalTime.addingTimeInterval(cumulative)
                
                let contextualTask = CoreTypes.ContextualTask(
                    id: taskId,
                    title: operation.name,
                    description: operation.instructions ?? "",
                    status: .pending,
                    dueDate: scheduledTime,
                    category: convertOperationToContextualCategory(operation.category),
                    urgency: convertToCoreUrgency(from: operation, scheduledTime: scheduledTime),
                    building: nil,
                    worker: nil,
                    buildingId: sequence.buildingId,
                    buildingName: sequence.buildingName,
                    assignedWorkerId: workerId,
                    requiresPhoto: operation.requiresPhoto,
                    estimatedDuration: operation.estimatedDuration
                )
                
                contextualTasks.append(contextualTask)
                cumulative += operation.estimatedDuration
            }
        }
        
        return contextualTasks.sorted { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }
    }
    
    private func convertOperationToContextualCategory(_ category: OperationTask.TaskCategory) -> CoreTypes.TaskCategory? {
        switch category {
        case .sweeping, .hosing, .vacuuming, .mopping, .posterRemoval, .treepitCleaning:
            return .cleaning
        case .trashCollection, .binManagement, .dsnySetout:
            return .sanitation
        case .maintenance:
            return .maintenance
        case .buildingInspection:
            return .inspection
        default:
            return .administrative
        }
    }

    private func determineUrgency(from operation: OperationTask, scheduledTime: Date) -> WorkerDashboardViewModel.TaskItem.TaskUrgency {
        let timeUntilDue = scheduledTime.timeIntervalSinceNow
        if operation.category == .dsnySetout { return .urgent }
        if timeUntilDue <= 3600 { return .high }
        if timeUntilDue <= 7200 { return .normal }
        return .low
    }

    private func convertToCoreUrgency(from operation: OperationTask, scheduledTime: Date) -> CoreTypes.TaskUrgency {
        let timeUntilDue = scheduledTime.timeIntervalSinceNow
        if operation.category == .dsnySetout { return .urgent }
        if timeUntilDue <= 3600 { return .high }
        if timeUntilDue <= 7200 { return .normal }
        return .low
    }
    
    // MARK: - Route Information Queries
    
    /// Get current route information for display in ViewModels
    public func getCurrentRouteInfo(for workerId: String) -> RouteInfo? {
        guard let route = routeManager.getCurrentRoute(for: workerId) else { return nil }
        
        let activeSequences = routeManager.getActiveSequences(for: workerId)
        let upcomingSequences = routeManager.getUpcomingSequences(for: workerId, limit: 3)
        let completionRate = routeManager.getRouteCompletion(for: route.id)
        
        return RouteInfo(
            routeId: route.id,
            routeName: route.routeName,
            startTime: route.startTime,
            estimatedEndTime: route.estimatedEndTime,
            activeSequences: activeSequences,
            upcomingSequences: upcomingSequences,
            completionRate: completionRate,
            totalSequences: route.sequences.count
        )
    }
    
    /// Get weather-optimized route for a worker
    public func getWeatherOptimizedRoute(for workerId: String, weather: WeatherSnapshot) -> WorkerRoute? {
        return routeManager.optimizeRoute(for: workerId, weather: weather)
    }
    
    // MARK: - Sync Methods (Private)
    
    private func syncRoutesToOperational(_ routes: [WorkerRoute]) {
        // Convert route data to operational format if needed
        // This maintains backwards compatibility
        print("🔄 RouteOperationalBridge: Syncing \(routes.count) routes to operational system")
    }
    
    private func syncOperationalToRoutes() {
        // Update route progress based on operational task completions
        print("🔄 RouteOperationalBridge: Syncing operational updates to routes")
    }
}

// MARK: - Supporting Types

public struct RouteInfo {
    public let routeId: String
    public let routeName: String
    public let startTime: Date
    public let estimatedEndTime: Date
    public let activeSequences: [RouteSequence]
    public let upcomingSequences: [RouteSequence]
    public let completionRate: Double
    public let totalSequences: Int
    
    public var currentSequence: RouteSequence? {
        activeSequences.first
    }
    
    public var nextSequence: RouteSequence? {
        upcomingSequences.first
    }
    
    public var isOnSchedule: Bool {
        let now = Date()
        let expectedProgress = now.timeIntervalSince(startTime) / estimatedEndTime.timeIntervalSince(startTime)
        return completionRate >= expectedProgress * 0.8 // 80% of expected progress
    }
}

// Legacy compatibility
public enum LegacyTaskPriority {
    case critical
    case high
    case medium
    case normal
}
