//
//  WorkerMetricsDTO.swift
//  CyntientOps
//
//  ✅ V6.0: Phase 1.1 - Comprehensive DTO System
//  ✅ FIXED: Added public initializer for BuildingIntelligenceDTO compatibility
//  ✅ Defines the performance metrics for a worker at a specific building.
//

import Foundation

public struct WorkerMetricsDTO: Codable, Hashable, Identifiable {
    public var id: String { "\(buildingId)-\(workerId)" }
    
    public let buildingId: CoreTypes.BuildingID
    public let workerId: CoreTypes.WorkerID
    
    // Core Performance Metrics
    public let overallScore: Int
    public let taskCompletionRate: Double
    public let maintenanceEfficiency: Double
    public let routineAdherence: Double
    
    // Supporting Data
    public let specializedTasksCompleted: Int
    public let totalTasksAssigned: Int
    public let averageTaskDuration: TimeInterval
    public let lastActiveDate: Date
    
    // ✅ ADDED: Public initializer for external creation
    public init(
        buildingId: CoreTypes.BuildingID,
        workerId: CoreTypes.WorkerID,
        overallScore: Int,
        taskCompletionRate: Double,
        maintenanceEfficiency: Double,
        routineAdherence: Double,
        specializedTasksCompleted: Int,
        totalTasksAssigned: Int,
        averageTaskDuration: TimeInterval,
        lastActiveDate: Date
    ) {
        self.buildingId = buildingId
        self.workerId = workerId
        self.overallScore = overallScore
        self.taskCompletionRate = taskCompletionRate
        self.maintenanceEfficiency = maintenanceEfficiency
        self.routineAdherence = routineAdherence
        self.specializedTasksCompleted = specializedTasksCompleted
        self.totalTasksAssigned = totalTasksAssigned
        self.averageTaskDuration = averageTaskDuration
        self.lastActiveDate = lastActiveDate
    }
    
    /// A convenience computed property to quickly identify top performers.
    public var isHighPerformer: Bool {
        return overallScore >= 90 && taskCompletionRate >= 0.95
    }
}
