//
//  DSNYTaskManager.swift
//  CyntientOps
//
//  DSNY task management and dashboard integration
//  Prevents workers from missing bin schedules
//  Provides proactive reminders and task generation
//

import Foundation
import Combine

// MARK: - DSNY Task Manager

@MainActor
public final class DSNYTaskManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public private(set) var todaysBinTasks: [DSNYTask] = []
    @Published public private(set) var upcomingBinTasks: [DSNYTask] = []
    @Published public private(set) var setOutReminders: [DSNYReminder] = []
    @Published public private(set) var lastUpdate: Date?
    
    // MARK: - Private Properties
    
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    
    public init() {
        refreshTasks()
        setupAutoRefresh()
    }
    
    // MARK: - Task Management
    
    /// Refresh all DSNY-related tasks and reminders
    public func refreshTasks() {
        let today = CollectionDay.from(weekday: Calendar.current.component(.weekday, from: Date()))
        
        // Get today's bin retrieval tasks
        todaysBinTasks = generateTodaysBinTasks(for: today)
        
        // Get tomorrow's bin set-out reminders
        upcomingBinTasks = generateUpcomingBinTasks()
        
        // Get evening set-out reminders
        setOutReminders = DSNYCollectionSchedule.getBinSetOutReminders(for: today)
        
        lastUpdate = Date()
        
        print("🗑️ DSNYTaskManager: Refreshed tasks - \(todaysBinTasks.count) bin tasks, \(setOutReminders.count) set-out reminders")
    }
    
    /// Get bin tasks for a specific worker
    public func getBinTasks(for workerId: String) -> [DSNYTask] {
        return todaysBinTasks.filter { $0.assignedWorkerId == workerId }
    }
    
    /// Mark a bin task as completed
    public func markBinTaskCompleted(taskId: String, workerId: String) {
        if let index = todaysBinTasks.firstIndex(where: { $0.id == taskId }) {
            todaysBinTasks[index] = todaysBinTasks[index].withCompletion(
                completedAt: Date(),
                completedBy: workerId
            )
        }
    }
    
    /// Check if a building needs bin management today
    public func needsBinManagement(buildingId: String) -> Bool {
        let today = CollectionDay.from(weekday: Calendar.current.component(.weekday, from: Date()))
        return DSNYCollectionSchedule.needsBinRetrieval(buildingId: buildingId, on: today)
    }
    
    /// Generate worker-specific dashboard cards for bin tasks
    public func getDashboardCards(for workerId: String) -> [DSNYDashboardCard] {
        let workerTasks = getBinTasks(for: workerId)
        let pendingTasks = workerTasks.filter { !$0.isCompleted }
        
        guard !pendingTasks.isEmpty else { return [] }
        
        let card = DSNYDashboardCard(
            title: "Bin Retrieval Tasks",
            subtitle: "\(pendingTasks.count) buildings need bins brought inside",
            tasks: pendingTasks,
            priority: .high, // Bin management is high priority
            icon: "trash.circle.fill"
        )
        
        return [card]
    }
    
    // MARK: - Private Methods
    
    private func generateTodaysBinTasks(for day: CollectionDay) -> [DSNYTask] {
        let buildingsToRetrieve = DSNYCollectionSchedule.getBuildingsForBinRetrieval(on: day)
        var tasks: [DSNYTask] = []
        
        for schedule in buildingsToRetrieve {
            // Determine assigned worker
            let workerId = determineAssignedWorker(for: schedule.buildingId, on: day)
            
            let task = DSNYTask(
                id: "dsny_retrieval_\(schedule.buildingId)_\(day.rawValue.lowercased())",
                buildingId: schedule.buildingId,
                buildingName: schedule.buildingName,
                taskType: .binRetrieval,
                scheduledTime: schedule.binRetrievalTime,
                assignedWorkerId: workerId,
                collectionDay: day,
                instructions: "Bring trash bins back inside after DSNY collection. \(schedule.specialInstructions)",
                isCompleted: false,
                completedAt: nil,
                completedBy: nil
            )
            
            tasks.append(task)
        }
        
        return tasks
    }
    
    private func generateUpcomingBinTasks() -> [DSNYTask] {
        let tomorrow = Date().addingTimeInterval(24 * 60 * 60)
        let tomorrowDay = CollectionDay.from(weekday: Calendar.current.component(.weekday, from: tomorrow))
        
        return generateTodaysBinTasks(for: tomorrowDay)
    }
    
    private func determineAssignedWorker(for buildingId: String, on day: CollectionDay) -> String {
        switch buildingId {
        case CanonicalIDs.Buildings.springStreet178,
             CanonicalIDs.Buildings.chambers148:
            return CanonicalIDs.Workers.edwinLema
            
        case CanonicalIDs.Buildings.perry68,
             CanonicalIDs.Buildings.firstAvenue123:
            return CanonicalIDs.Workers.kevinDutan
            
        case CanonicalIDs.Buildings.westSeventeenth136,
             CanonicalIDs.Buildings.westSeventeenth138:
            // Edwin covers Saturday, Kevin handles weekdays
            return day == .saturday ? CanonicalIDs.Workers.edwinLema : CanonicalIDs.Workers.kevinDutan
            
        default:
            return CanonicalIDs.Workers.kevinDutan // Default assignment
        }
    }
    
    private func setupAutoRefresh() {
        // Refresh every 30 minutes to catch schedule changes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshTasks()
            }
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}

// MARK: - Supporting Types

public struct DSNYTask {
    public let id: String
    public let buildingId: String
    public let buildingName: String
    public let taskType: DSNYTaskType
    public let scheduledTime: DSNYTime
    public let assignedWorkerId: String
    public let collectionDay: CollectionDay
    public let instructions: String
    public let isCompleted: Bool
    public let completedAt: Date?
    public let completedBy: String?
    
    public func withCompletion(completedAt: Date, completedBy: String) -> DSNYTask {
        return DSNYTask(
            id: id,
            buildingId: buildingId,
            buildingName: buildingName,
            taskType: taskType,
            scheduledTime: scheduledTime,
            assignedWorkerId: assignedWorkerId,
            collectionDay: collectionDay,
            instructions: instructions,
            isCompleted: true,
            completedAt: completedAt,
            completedBy: completedBy
        )
    }
}

public enum DSNYTaskType {
    case binRetrieval
    case binSetOut
    case scheduleReminder
}

public struct DSNYDashboardCard {
    public let title: String
    public let subtitle: String
    public let tasks: [DSNYTask]
    public let priority: TaskPriority
    public let icon: String
    
    public enum TaskPriority {
        case low, medium, high, urgent
    }
}

// MARK: - ServiceContainer Integration

extension DSNYTaskManager {
    
    /// Integration method for ServiceContainer
    public static func shared() -> DSNYTaskManager {
        return DSNYTaskManager()
    }
    
    /// Get integration data for WorkerDashboardViewModel
    public func getWorkerDashboardIntegration(for workerId: String) -> DSNYWorkerIntegration {
        let tasks = getBinTasks(for: workerId)
        let pendingTasks = tasks.filter { !$0.isCompleted }
        let completedTasks = tasks.filter { $0.isCompleted }
        
        return DSNYWorkerIntegration(
            pendingBinTasks: pendingTasks,
            completedBinTasks: completedTasks,
            dashboardCards: getDashboardCards(for: workerId),
            hasUrgentTasks: !pendingTasks.isEmpty
        )
    }
}

public struct DSNYWorkerIntegration {
    public let pendingBinTasks: [DSNYTask]
    public let completedBinTasks: [DSNYTask]
    public let dashboardCards: [DSNYDashboardCard]
    public let hasUrgentTasks: Bool
    
    public var totalBinTasks: Int {
        return pendingBinTasks.count + completedBinTasks.count
    }
    
    public var completionRate: Double {
        guard totalBinTasks > 0 else { return 0.0 }
        return Double(completedBinTasks.count) / Double(totalBinTasks)
    }
}
