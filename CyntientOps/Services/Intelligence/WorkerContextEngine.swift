//
//  WorkerContextEngine.swift
//  CyntientOps v6.0 - CONSOLIDATED VERSION
//
//  ✅ FIXED: Clock-in status tuple handling corrected
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: Removed unnecessary nil coalescing operators
//  ✅ FIXED: DashboardUpdate properly namespaced
//  ✅ CONSOLIDATED: All WorkerContextEngine functionality in one place
//  ✅ ENHANCED: Combined best features from all versions
//

import Foundation
import CoreLocation
import Combine
import UIKit

// MARK: - Building Assignment Type
public enum BuildingAssignmentType {
    case assigned     // Worker is directly assigned to this building
    case coverage     // Worker provides coverage for this building
    case unknown      // No assignment relationship
}

// MARK: - Worker Context Engine
@MainActor
public final class WorkerContextEngine: ObservableObject {
    public static let shared = WorkerContextEngine()
    
    // MARK: - Published Properties for SwiftUI
    @Published public var currentWorker: CoreTypes.WorkerProfile?
    @Published public var currentBuilding: CoreTypes.NamedCoordinate?
    @Published public var assignedBuildings: [CoreTypes.NamedCoordinate] = []
    @Published public var portfolioBuildings: [CoreTypes.NamedCoordinate] = []
    @Published public var todaysTasks: [CoreTypes.ContextualTask] = []
    @Published public var taskProgress: CoreTypes.TaskProgress?
    @Published public var clockInStatus: (isClockedIn: Bool, building: CoreTypes.NamedCoordinate?) = (false, nil)
    @Published public var isLoading = false
    @Published public var lastError: Error?
    @Published public var hasPendingScenario = false
    @Published public var lastRefreshTime: Date?
    @Published public var errorMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let refreshInterval: TimeInterval = 300 // 5 minutes
    private var refreshTimer: Timer?
    
    // MARK: - Dependencies
    private let operationalData = OperationalDataManager.shared
    private let workerService = WorkerService.shared
    private let buildingService = BuildingService.shared
    private let clockInManager = ClockInManager.shared
    private let taskService = TaskService.shared
    
    // MARK: - Initialization
    private init() {
        setupPeriodicUpdates()
        setupNotificationObservers()
    }
    
    // MARK: - Main Context Loading
    public func loadContext(for workerId: CoreTypes.WorkerID) async throws {
        guard !isLoading else { return }
        isLoading = true
        lastError = nil
        errorMessage = nil
        
        do {
            // 1. Load worker profile directly from service
            if let workers = try? await workerService.getAllActiveWorkers(),
               let worker = workers.first(where: { $0.id == workerId }) {
                self.currentWorker = worker
            } else {
                // Fallback to operational data
                let workerName = WorkerConstants.getWorkerName(id: workerId)
                self.currentWorker = CoreTypes.WorkerProfile(
                    id: workerId,
                    name: workerName,
                    email: "\(workerId)@francosphere.com",
                    phoneNumber: "",
                    role: .worker,
                    skills: [],
                    certifications: [],
                    hireDate: Date(),
                    isActive: true,
                    profileImageUrl: nil
                )
            }
            
            // 2. Load portfolio buildings first
            self.portfolioBuildings = try await buildingService.getAllBuildings()
            
            // 3. Load assigned buildings from operational data
            var assignedBuildingsList: [CoreTypes.NamedCoordinate] = []
            let workerName = currentWorker?.name ?? WorkerConstants.getWorkerName(id: workerId)
            let operationalTasks = operationalData.getRealWorldTasks(for: workerName)
            let uniqueBuildingNames = Set(operationalTasks.map { $0.building })
            
            for buildingName in uniqueBuildingNames {
                if let building = findBuildingByName(buildingName, in: portfolioBuildings) {
                    assignedBuildingsList.append(building)
                }
            }
            
            self.assignedBuildings = assignedBuildingsList
            
            // 4. Load today's tasks
            await loadTodaysTasks(for: workerId)
            
            // 5. Update task progress
            updateTaskProgress()
            
            // 6. Load clock-in status
            await updateClockInStatus(for: workerId)
            
            // 7. Update UI state
            updatePendingScenarioStatus()
            lastRefreshTime = Date()
            
            print("✅ Context loaded successfully for worker: \(currentWorker?.name ?? workerId)")
            
        } catch {
            lastError = error
            errorMessage = error.localizedDescription
            print("❌ loadContext failed: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Task Loading
    private func loadTodaysTasks(for workerId: String) async {
        do {
            // Try to load from TaskService first
            let tasks = try await taskService.getTasksForWorker(workerId)
            self.todaysTasks = tasks
        } catch {
            // Fallback to operational data
            let workerName = currentWorker?.name ?? WorkerConstants.getWorkerName(id: workerId)
            let operationalTasks = operationalData.getRealWorldTasks(for: workerName)
            self.todaysTasks = generateContextualTasks(
                for: workerId,
                workerName: workerName,
                assignedBuildings: assignedBuildings,
                realWorldAssignments: operationalTasks
            )
        }
    }
    
    // MARK: - Task Generation
    private func generateContextualTasks(
        for workerId: String,
        workerName: String,
        assignedBuildings: [CoreTypes.NamedCoordinate],
        realWorldAssignments: [OperationalDataTaskAssignment]
    ) -> [CoreTypes.ContextualTask] {
        var tasks: [CoreTypes.ContextualTask] = []
        
        for (index, operational) in realWorldAssignments.enumerated() {
            let building = findBuildingForTask(operational.building, in: assignedBuildings)
            
            let task = CoreTypes.ContextualTask(
                            id: "op_task_\(workerId)_\(index)",
                            title: operational.taskName,
                            description: "Operational: \(operational.taskName) at \(operational.building)",
                            status: .pending,
                            completedAt: nil,
                            scheduledDate: Date(),
                            dueDate: Date().addingTimeInterval(3600),
                            category: mapOperationalCategory(operational.category),
                            urgency: mapOperationalUrgency(operational.skillLevel),
                            building: building,
                            worker: currentWorker,
                            buildingId: building?.id,
                            buildingName: building?.name,
                            assignedWorkerId: workerId,
                            priority: mapOperationalUrgency(operational.skillLevel),
                            frequency: nil,
                            requiresPhoto: false,
                            estimatedDuration: 3600,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
            
            tasks.append(task)
        }
        
        return tasks.sorted { task1, task2 in
            let urgency1 = task1.urgency?.numericValue ?? 0
            let urgency2 = task2.urgency?.numericValue ?? 0
            return urgency1 > urgency2
        }
    }
    
    // MARK: - Clock In Status (FIXED)
    private func updateClockInStatus(for workerId: String) async {
        // ✅ FIXED: Properly destructure the tuple returned by getClockInStatus
        let (isClockedIn, building) = await clockInManager.getClockInStatus(for: workerId)
        
        if isClockedIn, let building = building {
            // Update both published properties
            self.clockInStatus = (true, building)
            self.currentBuilding = building
        } else {
            // Not clocked in
            self.clockInStatus = (false, nil)
            self.currentBuilding = nil
        }
    }
    
    // MARK: - Building Helpers
    private func findBuildingByName(_ name: String, in buildings: [CoreTypes.NamedCoordinate]) -> CoreTypes.NamedCoordinate? {
        let lowercaseName = name.lowercased()
        
        // First try exact match
        if let exact = buildings.first(where: { $0.name.lowercased() == lowercaseName }) {
            return exact
        }
        
        // Then try contains match
        return buildings.first { building in
            let buildingNameLower = building.name.lowercased()
            return buildingNameLower.contains(lowercaseName) ||
                   lowercaseName.contains(buildingNameLower)
        }
    }
    
    private func findBuildingById(_ id: String?) -> CoreTypes.NamedCoordinate? {
        guard let id = id else { return nil }
        return portfolioBuildings.first { $0.id == id } ??
               assignedBuildings.first { $0.id == id }
    }
    
    private func findBuildingForTask(_ buildingName: String, in buildings: [CoreTypes.NamedCoordinate]) -> CoreTypes.NamedCoordinate? {
        return findBuildingByName(buildingName, in: buildings) ??
               findBuildingByName(buildingName, in: portfolioBuildings)
    }
    
    // MARK: - Public Methods
    
    /// Refresh the current context
    public func refreshContext() async {
        guard let workerId = currentWorker?.id else { return }
        try? await loadContext(for: workerId)
    }
    
    /// Check if a building is assigned to the current worker
    public func isBuildingAssigned(_ buildingId: String) -> Bool {
        return assignedBuildings.contains { $0.id == buildingId }
    }
    
    /// Get the assignment type for a building
    public func getBuildingAssignmentType(_ buildingId: String) -> BuildingAssignmentType {
        if assignedBuildings.contains(where: { $0.id == buildingId }) {
            return .assigned
        } else if portfolioBuildings.contains(where: { $0.id == buildingId }) {
            return .coverage
        }
        return .unknown
    }
    
    /// Update task completion status
    public func updateTaskCompletion(_ taskId: String, isCompleted: Bool) {
        if let index = todaysTasks.firstIndex(where: { $0.id == taskId }) {
            todaysTasks[index].isCompleted = isCompleted
            todaysTasks[index].completedAt = isCompleted ? Date() : nil
            updateTaskProgress()
            
            // Notify other services
            Task {
                await notifyTaskStatusChange(taskId: taskId, isCompleted: isCompleted)
            }
        }
    }
    
    /// Get tasks for a specific building
    public func getTasksForBuilding(_ buildingId: String) -> [CoreTypes.ContextualTask] {
        return todaysTasks.filter { $0.buildingId == buildingId }
    }
    
    /// Check if worker has any pending high-priority tasks
    public func hasPendingHighPriorityTasks() -> Bool {
        return todaysTasks.contains { task in
            !task.isCompleted &&
            (task.urgency == .high || task.urgency == .critical || task.urgency == .urgent)
        }
    }
    
    /// Get completion percentage for today's tasks
    public func getCompletionPercentage() -> Double {
        guard !todaysTasks.isEmpty else { return 0.0 }
        let completedCount = todaysTasks.filter { $0.isCompleted }.count
        return Double(completedCount) / Double(todaysTasks.count) * 100.0
    }
    
    /// Get today's summary
    public func getTodaysSummary() -> (total: Int, completed: Int, percentage: Double) {
        let total = todaysTasks.count
        let completed = todaysTasks.filter { $0.isCompleted }.count
        let percentage = total > 0 ? Double(completed) / Double(total) * 100.0 : 0.0
        return (total, completed, percentage)
    }
    
    /// Get buildings that need attention
    public func getBuildingsNeedingAttention() -> [CoreTypes.NamedCoordinate] {
        let buildingIds = todaysTasks
            .filter { !$0.isCompleted && ($0.urgency == .high || $0.urgency == .critical) }
            .compactMap { $0.buildingId }
            .unique()
        
        return assignedBuildings.filter { building in
            buildingIds.contains(building.id)
        }
    }
    
    /// Check if worker should clock out
    public func shouldSuggestClockOut() -> Bool {
        guard let currentBuildingId = currentBuilding?.id else { return false }
        let buildingTasks = todaysTasks.filter { $0.buildingId == currentBuildingId }
        return !buildingTasks.isEmpty && buildingTasks.allSatisfy { $0.isCompleted }
    }
    
    // MARK: - Access Methods (Legacy Support)
    public func getCurrentWorker() -> CoreTypes.WorkerProfile? { return currentWorker }
    public func getCurrentBuilding() -> CoreTypes.NamedCoordinate? { return currentBuilding }
    public func getAssignedBuildings() -> [CoreTypes.NamedCoordinate] { return assignedBuildings }
    public func getPortfolioBuildings() -> [CoreTypes.NamedCoordinate] { return portfolioBuildings }
    public func getTodaysTasks() -> [CoreTypes.ContextualTask] { return todaysTasks }
    public func getTaskProgress() -> CoreTypes.TaskProgress? { return taskProgress }
    
    // MARK: - Private Update Methods
    
    private func updateTaskProgress() {
        let completed = todaysTasks.filter { $0.isCompleted }.count
        taskProgress = CoreTypes.TaskProgress(
            totalTasks: todaysTasks.count,
            completedTasks: completed
        )
    }
    
    private func updatePendingScenarioStatus() {
        hasPendingScenario = hasPendingHighPriorityTasks() ||
                           todaysTasks.contains { $0.urgency == .emergency }
    }
    
    private func notifyTaskStatusChange(taskId: String, isCompleted: Bool) async {
        // Notify DashboardSyncService
        if let workerId = currentWorker?.id,
           let task = todaysTasks.first(where: { $0.id == taskId }) {
            // Fixed: Properly namespaced DashboardUpdate
            let update = CoreTypes.DashboardUpdate(
                source: CoreTypes.DashboardUpdate.Source.worker,
                type: isCompleted ? CoreTypes.DashboardUpdate.UpdateType.taskCompleted : CoreTypes.DashboardUpdate.UpdateType.taskStarted,
                buildingId: task.buildingId ?? "",
                workerId: workerId,
                data: ["taskId": taskId]
            )
            DashboardSyncService.shared.broadcastWorkerUpdate(update)
        }
    }
    
    // MARK: - Periodic Updates
    
    private func setupPeriodicUpdates() {
        Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.refreshContext()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupNotificationObservers() {
        // Refresh when app becomes active
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { await self?.refreshContext() }
            }
            .store(in: &cancellables)
        
        // Listen for task updates
        NotificationCenter.default.publisher(for: .workerContextTaskUpdated)
            .compactMap { $0.userInfo?["taskId"] as? String }
            .sink { [weak self] taskId in
                Task { await self?.refreshContext() }
            }
            .store(in: &cancellables)
        
        // Listen for clock-in changes
        NotificationCenter.default.publisher(for: .workerContextClockInStatusChanged)
            .sink { [weak self] _ in
                guard let workerId = self?.currentWorker?.id else { return }
                Task { await self?.updateClockInStatus(for: workerId) }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Mapping Helpers
    
    private func mapOperationalCategory(_ category: String) -> CoreTypes.TaskCategory? {
        switch category.lowercased() {
        case "cleaning": return .cleaning
        case "maintenance": return .maintenance
        case "repair": return .repair
        case "inspection": return .inspection
        case "landscaping": return .landscaping
        case "security": return .security
        case "sanitation": return .sanitation
        case "emergency": return .emergency
        case "inventory": return .inspection // Closest match
        default: return .maintenance
        }
    }
    
    private func mapOperationalUrgency(_ skillLevel: String) -> CoreTypes.TaskUrgency? {
        switch skillLevel.lowercased() {
        case "basic": return .low
        case "intermediate": return .medium
        case "advanced", "specialized": return .high
        case "expert", "critical": return .critical
        default: return .medium
        }
    }
}

// MARK: - Error Types
public enum WorkerContextError: Error, LocalizedError {
    case workerNotFound(String)
    case dataLoadingFailed(Error)
    case invalidConfiguration
    
    public var errorDescription: String? {
        switch self {
        case .workerNotFound(let id):
            return "Worker with ID \(id) not found"
        case .dataLoadingFailed(let error):
            return "Failed to load context data: \(error.localizedDescription)"
        case .invalidConfiguration:
            return "Invalid worker context configuration"
        }
    }
}

// MARK: - Helper Extensions

extension CoreTypes.TaskUrgency {
    var numericValue: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .normal: return 2
        case .high: return 3
        case .critical: return 4
        case .emergency: return 5
        case .urgent: return 4
        }
    }
}

extension Notification.Name {
    static let workerContextTaskUpdated = Notification.Name("workerContextTaskUpdated")
    static let workerContextClockInStatusChanged = Notification.Name("workerContextClockInStatusChanged")
}

private extension Array where Element: Hashable {
    func unique() -> [Element] {
        return Array(Set(self))
    }
}

// MARK: - WorkerContextEngineAdapter Compatibility
// For backwards compatibility, create a type alias
public typealias WorkerContextEngineAdapter = WorkerContextEngine

// MARK: - Compilation Fixes Applied
/*
 ✅ Fixed line 193: Clock-in status tuple handling
    - Changed from trying to access .session property to properly destructuring the tuple
    - getClockInStatus returns (isClockedIn: Bool, building: NamedCoordinate?)
    - Now correctly handles the tuple values
 ✅ Fixed WorkerService API calls - removed non-existent getWorkerAssignments
 ✅ Fixed TaskService.getTasksForWorker - removed date parameter
 ✅ Fixed ContextualTask initializer - removed extra parameters
 ✅ Fixed ClockInManager method - using getClockInStatus instead of getCurrentSession
 ✅ Fixed DashboardUpdate type - properly namespaced as CoreTypes.DashboardUpdate
 ✅ Fixed notification names - made them unique to avoid conflicts
 ✅ Fixed ClockInSession - removed non-existent address property
 ✅ Fixed nil coalescing operators - removed unnecessary usage with non-optional values
 ✅ Added CoreTypes namespace to all type references for consistency
 ✅ Added UIKit import for UIApplication notification
 */
