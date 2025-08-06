//
//  UnifiedDataService.swift
//  CyntientOps v6.0
//
//  ✅ UPDATED: Removed duplicate types, now works with DatabaseInitializer
//  ✅ FOCUSED: Only handles data bridging and fallbacks
//  ✅ SIMPLIFIED: Delegates initialization to DatabaseInitializer
//

import Foundation
import Combine

/// Service that bridges OperationalDataManager to database services with fallback support
@MainActor
public class UnifiedDataService: ObservableObject {
    public static let shared = UnifiedDataService()
    
    // MARK: - Dependencies
    private let operationalData = OperationalDataManager.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingService = BuildingService.shared
    
    // MARK: - Published State
    @Published public var isReady = false
    @Published public var lastFallbackUse: Date?
    
    private init() {}
    
    // MARK: - Fallback Data Access
    
    /// Get tasks with fallback to OperationalDataManager
    public func getTasksWithFallback(for workerId: String, date: Date) async -> [CoreTypes.ContextualTask] {
        do {
            // Try database first
            let dbTasks = try await taskService.getTasks(for: workerId, date: date)
            if !dbTasks.isEmpty {
                return dbTasks
            }
            
            // Fallback to OperationalDataManager
            print("⚡ Using OperationalDataManager fallback for worker \(workerId)")
            lastFallbackUse = Date()
            return await getTasksFromOperationalData(workerId: workerId, date: date)
            
        } catch {
            print("❌ Database tasks failed, using fallback: \(error)")
            lastFallbackUse = Date()
            return await getTasksFromOperationalData(workerId: workerId, date: date)
        }
    }
    
    /// Get all tasks with fallback to OperationalDataManager
    public func getAllTasksWithFallback() async -> [CoreTypes.ContextualTask] {
        do {
            // Try database first
            let dbTasks = try await taskService.getAllTasks()
            if !dbTasks.isEmpty {
                return dbTasks
            }
            
            // Fallback to OperationalDataManager
            print("⚡ Using OperationalDataManager fallback for all tasks")
            lastFallbackUse = Date()
            return await getAllTasksFromOperationalData()
            
        } catch {
            print("❌ Database tasks failed, using fallback: \(error)")
            lastFallbackUse = Date()
            return await getAllTasksFromOperationalData()
        }
    }
    
    /// Get portfolio insights with fallback data
    public func generatePortfolioInsightsWithFallback() async -> [CoreTypes.IntelligenceInsight] {
        do {
            // Try normal intelligence service first
            let insights = try await IntelligenceService.shared.generatePortfolioInsights()
            if !insights.isEmpty {
                return insights
            }
            
            // Fallback: Generate insights from OperationalDataManager directly
            print("⚡ Generating insights from OperationalDataManager fallback")
            lastFallbackUse = Date()
            return await generateInsightsFromOperationalData()
            
        } catch {
            print("❌ Normal insights failed, using fallback: \(error)")
            lastFallbackUse = Date()
            return await generateInsightsFromOperationalData()
        }
    }
    
    /// Get building-specific insights with fallback
    public func getBuildingInsightsWithFallback(for buildingId: String) async -> [CoreTypes.IntelligenceInsight] {
        do {
            // Try normal intelligence service first
            let insights = try await IntelligenceService.shared.generateBuildingInsights(for: buildingId)
            if !insights.isEmpty {
                return insights
            }
            
            // Fallback: Generate basic insights
            print("⚡ Using fallback for building insights")
            lastFallbackUse = Date()
            return await generateBuildingInsightsFromOperationalData(buildingId: buildingId)
            
        } catch {
            print("❌ Building insights failed, using fallback: \(error)")
            lastFallbackUse = Date()
            return await generateBuildingInsightsFromOperationalData(buildingId: buildingId)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if services are ready (for UI display)
    public func checkServicesReady() async {
        do {
            // Quick check if services have data
            let hasTasks = try await taskService.getAllTasks().count > 0
            let hasWorkers = try await workerService.getAllActiveWorkers().count > 0
            let hasBuildings = try await buildingService.getAllBuildings().count > 0
            
            isReady = hasTasks && hasWorkers && hasBuildings
            
            if !isReady {
                print("⚠️ Services not fully ready - fallback mode available")
            }
        } catch {
            print("❌ Service check failed: \(error)")
            isReady = false
        }
    }
    
    // MARK: - Private Conversion Methods
    
    private func getTasksFromOperationalData(workerId: String, date: Date) async -> [CoreTypes.ContextualTask] {
        let workerName = WorkerConstants.getWorkerName(id: workerId)
        let workerTasks = operationalData.getRealWorldTasks(for: workerName)
        
        var contextualTasks: [CoreTypes.ContextualTask] = []
        
        for operationalTask in workerTasks {
            let contextualTask = await convertOperationalTaskToContextualTask(operationalTask, workerId: workerId)
            contextualTasks.append(contextualTask)
        }
        
        return contextualTasks
    }
    
    private func getAllTasksFromOperationalData() async -> [CoreTypes.ContextualTask] {
        let allTasks = operationalData.getAllRealWorldTasks()
        var contextualTasks: [CoreTypes.ContextualTask] = []
        
        for operationalTask in allTasks {
            guard let workerId = getWorkerIdFromName(operationalTask.assignedWorker) else { continue }
            let contextualTask = await convertOperationalTaskToContextualTask(operationalTask, workerId: workerId)
            contextualTasks.append(contextualTask)
        }
        
        return contextualTasks
    }
    
    private func convertOperationalTaskToContextualTask(_ operationalTask: OperationalDataTaskAssignment, workerId: String) async -> CoreTypes.ContextualTask {
        let buildingId = await getBuildingIdFromName(operationalTask.building) ?? "unknown_building_\(operationalTask.building.hash)"
        
        return CoreTypes.ContextualTask(
            id: "op_\(operationalTask.taskName.hash)_\(workerId)",
            title: operationalTask.taskName,
            description: generateTaskDescription(operationalTask),
            status: .pending,
            completedAt: nil,
            dueDate: calculateDueDate(for: operationalTask),
            category: mapToTaskCategory(operationalTask.category),
            urgency: mapToTaskUrgency(operationalTask.skillLevel),
            building: nil,
            worker: nil,
            buildingId: buildingId,
            priority: mapToTaskUrgency(operationalTask.skillLevel)
        )
    }
    
    private func generateTaskDescription(_ operationalTask: OperationalDataTaskAssignment) -> String {
        var description = "Operational task: \(operationalTask.taskName)"
        
        if let startHour = operationalTask.startHour, let endHour = operationalTask.endHour {
            description += " (scheduled \(startHour):00 - \(endHour):00)"
        }
        
        if operationalTask.recurrence != "On-Demand" {
            description += " - \(operationalTask.recurrence)"
        }
        
        description += " at \(operationalTask.building)"
        
        return description
    }
    
    private func calculateDueDate(for operationalTask: OperationalDataTaskAssignment) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        if let startHour = operationalTask.startHour {
            let todayAtStartHour = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: now)
            
            if let scheduledTime = todayAtStartHour, scheduledTime < now {
                return calendar.date(byAdding: .day, value: 1, to: scheduledTime)
            }
            
            return todayAtStartHour
        }
        
        return calendar.date(byAdding: .hour, value: 2, to: now)
    }
    
    private func generateInsightsFromOperationalData() async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // Get task distribution by worker
        let workerTaskCounts = operationalData.getWorkerTaskSummary()
        
        // Generate insights about task distribution
        for (workerName, taskCount) in workerTaskCounts {
            if taskCount > 20 {
                insights.append(CoreTypes.IntelligenceInsight(
                    title: "High Task Load",
                    description: "\(workerName) has \(taskCount) tasks assigned",
                    type: .operations,
                    priority: .medium,
                    actionRequired: false,
                    affectedBuildings: []
                ))
            }
        }
        
        // Generate insights about building coverage
        let buildingCoverage = operationalData.getBuildingCoverage()
        for (building, workers) in buildingCoverage {
            if workers.count == 1 {
                insights.append(CoreTypes.IntelligenceInsight(
                    title: "Single Worker Coverage",
                    description: "\(building) relies on single worker: \(workers.first ?? "Unknown")",
                    type: .maintenance,
                    priority: .medium,
                    actionRequired: true,
                    affectedBuildings: []
                ))
            }
        }
        
        // Generate insights about category distribution
        let categoryDistribution = operationalData.getCategoryDistribution()
        let maintenanceCount = categoryDistribution["Maintenance"] ?? 0
        let cleaningCount = categoryDistribution["Cleaning"] ?? 0
        
        if maintenanceCount > cleaningCount * 2 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Maintenance Heavy Portfolio",
                description: "Maintenance tasks (\(maintenanceCount)) significantly outnumber cleaning tasks (\(cleaningCount))",
                type: .maintenance,
                priority: .low,
                actionRequired: false,
                affectedBuildings: []
            ))
        }
        
        return insights
    }
    
    private func generateBuildingInsightsFromOperationalData(buildingId: String) async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // Get building name
        let buildingName = await getBuildingName(for: buildingId) ?? "Building \(buildingId)"
        
        // Get tasks for this building
        let buildingTasks = operationalData.getTasksForBuilding(buildingName)
        
        if buildingTasks.isEmpty {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "No Scheduled Tasks",
                description: "\(buildingName) has no tasks in operational data",
                type: .maintenance,
                priority: .high,
                actionRequired: true,
                affectedBuildings: [buildingId]
            ))
        } else {
            // Task count insight
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Building Activity",
                description: "\(buildingName) has \(buildingTasks.count) scheduled tasks",
                type: .operations,
                priority: .low,
                actionRequired: false,
                affectedBuildings: [buildingId]
            ))
            
            // Worker coverage
            let assignedWorkers = Set(buildingTasks.map { $0.assignedWorker })
            if assignedWorkers.count == 1 {
                insights.append(CoreTypes.IntelligenceInsight(
                    title: "Limited Worker Coverage",
                    description: "Only \(assignedWorkers.first ?? "Unknown") assigned to \(buildingName)",
                    type: .efficiency,
                    priority: .medium,
                    actionRequired: true,
                    affectedBuildings: [buildingId]
                ))
            }
        }
        
        return insights
    }
    
    // MARK: - Utility Methods
    
    private func getWorkerIdFromName(_ workerName: String) -> String? {
        let workerNameMap: [String: String] = [
            "Greg Hutson": "1",
            "Edwin Lema": "2",
            "Kevin Dutan": "4",
            "Mercedes Inamagua": "5",
            "Luis Lopez": "6",
            "Angel Guirachocha": "7",
            "Shawn Magloire": "8"
        ]
        return workerNameMap[workerName]
    }
    
    private func getBuildingIdFromName(_ buildingName: String) async -> String? {
        do {
            let buildings = try await buildingService.getAllBuildings()
            return buildings.first { building in
                building.name.lowercased().contains(buildingName.lowercased()) ||
                buildingName.lowercased().contains(building.name.lowercased())
            }?.id
        } catch {
            print("⚠️ Error looking up building '\(buildingName)': \(error)")
            return nil
        }
    }
    
    private func getBuildingName(for buildingId: String) async -> String? {
        do {
            let building = try await buildingService.getBuilding(buildingId: buildingId)
            return building.name
        } catch {
            print("⚠️ Error getting building name for ID '\(buildingId)': \(error)")
            return nil
        }
    }
    
    private func mapToTaskCategory(_ category: String) -> CoreTypes.TaskCategory {
        switch category.lowercased() {
        case "cleaning": return .cleaning
        case "maintenance": return .maintenance
        case "sanitation": return .sanitation
        case "inspection": return .inspection
        case "repair": return .repair
        case "security": return .security
        case "utilities": return .utilities
        case "landscaping": return .landscaping
        case "emergency": return .emergency
        default: return .maintenance
        }
    }
    
    private func mapToTaskUrgency(_ skillLevel: String) -> CoreTypes.TaskUrgency {
        switch skillLevel.lowercased() {
        case "advanced": return .high
        case "intermediate": return .medium
        case "basic": return .low
        default: return .medium
        }
    }
}

// MARK: - Extensions for Convenience

extension UnifiedDataService {
    
    /// Quick check if fallback was used recently
    public var usingFallbackMode: Bool {
        guard let lastUse = lastFallbackUse else { return false }
        return Date().timeIntervalSince(lastUse) < 300 // Within last 5 minutes
    }
    
    /// Get status description for UI
    public var statusDescription: String {
        if isReady {
            return "Database Connected"
        } else if usingFallbackMode {
            return "Using Fallback Data"
        } else {
            return "Checking Services..."
        }
    }
}
