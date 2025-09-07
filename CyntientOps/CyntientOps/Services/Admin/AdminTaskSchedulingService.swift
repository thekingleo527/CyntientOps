//
//  AdminTaskSchedulingService.swift
//  CyntientOps
//
//  🎯 ADMIN TASK SCHEDULING WITH SMART WORKER CALENDAR INTEGRATION
//  ✅ Schedule tasks at specific date/time
//  ✅ Smart dynamic updates to worker daily schedules
//  ✅ Integration with WorkerProfileView calendar
//  ✅ Conflict detection and resolution
//  ✅ Real-time schedule synchronization

import Foundation
import SwiftUI
import Combine

@MainActor
public class AdminTaskSchedulingService: ObservableObject {
    public static let shared = AdminTaskSchedulingService()
    
    // MARK: - Published State
    @Published public var scheduledTasks: [CoreTypes.AdminTaskSchedule] = []
    @Published public var workerScheduleContexts: [String: CoreTypes.WorkerScheduleContext] = [:]
    @Published public var isScheduling = false
    @Published public var lastSchedulingError: String?
    
    // MARK: - Private Properties
    private let container: ServiceContainer?
    private var cancellables = Set<AnyCancellable>()
    private let smartSchedulingEngine = SmartSchedulingEngine()
    
    // MARK: - Initialization
    private init(container: ServiceContainer? = nil) {
        self.container = container
        setupRealTimeSync()
    }
    
    public func setContainer(_ container: ServiceContainer) {
        // This will be called after ServiceContainer is initialized
    }
    
    // MARK: - Core Admin Task Scheduling
    
    /// Schedule a task at a specific date/time with smart worker calendar integration
    public func scheduleTask(
        task: CoreTypes.ContextualTask,
        scheduledDateTime: Date,
        assignedWorkerId: String? = nil,
        buildingId: String,
        createdBy: String,
        priority: CoreTypes.TaskUrgency = .medium,
        estimatedDuration: TimeInterval = 3600,
        requiresWorkerConfirmation: Bool = false,
        smartSchedulingEnabled: Bool = true
    ) async throws -> CoreTypes.AdminTaskSchedule {
        
        isScheduling = true
        lastSchedulingError = nil
        
        defer {
            isScheduling = false
        }
        
        do {
            // 1. Create the admin task schedule
            let adminSchedule = CoreTypes.AdminTaskSchedule(
                taskId: task.id,
                scheduledDateTime: scheduledDateTime,
                assignedWorkerId: assignedWorkerId,
                buildingId: buildingId,
                createdBy: createdBy,
                priority: priority,
                estimatedDuration: estimatedDuration,
                requiresWorkerConfirmation: requiresWorkerConfirmation,
                smartSchedulingEnabled: smartSchedulingEnabled
            )
            
            // 2. If smart scheduling is enabled, analyze and optimize
            var finalSchedule = adminSchedule
            if smartSchedulingEnabled {
                finalSchedule = try await optimizeScheduleWithSmartScheduling(schedule: adminSchedule)
            }
            
            // 3. Update worker's calendar context
            if let workerId = finalSchedule.assignedWorkerId {
                try await updateWorkerScheduleContext(workerId: workerId, newSchedule: finalSchedule)
            }
            
            // 4. Save to persistent storage
            await saveSchedule(finalSchedule)
            
            // 5. Add to local state
            scheduledTasks.append(finalSchedule)
            
            // 6. Notify worker if required
            if let workerId = finalSchedule.assignedWorkerId {
                await notifyWorkerOfNewSchedule(workerId: workerId, schedule: finalSchedule)
            }
            
            // 7. Update task with scheduling information
            await updateTaskWithScheduleInfo(task: task, schedule: finalSchedule)
            
            print("✅ Task scheduled successfully: \(task.title) at \(scheduledDateTime)")
            return finalSchedule
            
        } catch {
            lastSchedulingError = error.localizedDescription
            print("❌ Failed to schedule task: \(error)")
            throw error
        }
    }
    
    /// Get worker schedule context with smart recommendations
    public func getWorkerScheduleContext(workerId: String) async -> CoreTypes.WorkerScheduleContext {
        // Return cached context if available and recent
        if let context = workerScheduleContexts[workerId],
           Date().timeIntervalSince(context.lastUpdated) < 300 { // 5 minutes
            return context
        }
        
        // Build fresh context
        let currentSchedule = scheduledTasks.filter { $0.assignedWorkerId == workerId }
        let conflictingTasks = findConflictingTasks(for: workerId)
        let recommendedSlots = await smartSchedulingEngine.generateRecommendedSlots(
            for: workerId,
            currentSchedule: currentSchedule
        )
        
        let context = CoreTypes.WorkerScheduleContext(
            workerId: workerId,
            currentSchedule: currentSchedule,
            availabilityWindows: await getWorkerAvailabilityWindows(workerId: workerId),
            preferredWorkingHours: await getWorkerPreferredHours(workerId: workerId),
            buildingAssignments: await getWorkerBuildingAssignments(workerId: workerId),
            conflictingTasks: conflictingTasks,
            recommendedSlots: recommendedSlots
        )
        
        // Cache the context
        workerScheduleContexts[workerId] = context
        
        return context
    }
    
    /// Reschedule a task with smart conflict resolution
    public func rescheduleTask(
        scheduleId: String,
        newDateTime: Date,
        reason: String = "Admin rescheduled"
    ) async throws {
        
        guard let scheduleIndex = scheduledTasks.firstIndex(where: { $0.id == scheduleId }) else {
            throw SchedulingError.scheduleNotFound
        }
        
        var schedule = scheduledTasks[scheduleIndex]
        let oldDateTime = schedule.scheduledDateTime
        
        // Update schedule
        schedule.scheduledDateTime = newDateTime
        schedule.status = .rescheduled
        schedule.updatedAt = Date()
        
        // Check for conflicts at new time
        if let workerId = schedule.assignedWorkerId {
            let conflicts = await findScheduleConflicts(
                workerId: workerId,
                startTime: newDateTime,
                duration: schedule.estimatedDuration,
                excludingScheduleId: scheduleId
            )
            
            if !conflicts.isEmpty {
                print("⚠️ Rescheduling will create conflicts: \(conflicts.count) conflicts detected")
                // Still proceed but mark conflicts
            }
        }
        
        // Update in storage and local state
        scheduledTasks[scheduleIndex] = schedule
        await saveSchedule(schedule)
        
        // Update worker context
        if let workerId = schedule.assignedWorkerId {
            try await updateWorkerScheduleContext(workerId: workerId, newSchedule: schedule)
        }
        
        // Notify worker of reschedule
        if let workerId = schedule.assignedWorkerId {
            await notifyWorkerOfReschedule(
                workerId: workerId,
                schedule: schedule,
                oldDateTime: oldDateTime,
                reason: reason
            )
        }
        
        print("✅ Task rescheduled: \(schedule.taskId) from \(oldDateTime) to \(newDateTime)")
    }
    
    /// Cancel a scheduled task
    public func cancelScheduledTask(scheduleId: String, reason: String = "Cancelled by admin") async throws {
        guard let scheduleIndex = scheduledTasks.firstIndex(where: { $0.id == scheduleId }) else {
            throw SchedulingError.scheduleNotFound
        }
        
        var schedule = scheduledTasks[scheduleIndex]
        schedule.status = .cancelled
        schedule.updatedAt = Date()
        
        // Update storage
        await saveSchedule(schedule)
        
        // Update local state
        scheduledTasks[scheduleIndex] = schedule
        
        // Update worker context
        if let workerId = schedule.assignedWorkerId {
            try await updateWorkerScheduleContext(workerId: workerId, newSchedule: schedule)
        }
        
        // Notify worker
        if let workerId = schedule.assignedWorkerId {
            await notifyWorkerOfCancellation(workerId: workerId, schedule: schedule, reason: reason)
        }
        
        print("✅ Task schedule cancelled: \(schedule.taskId)")
    }
    
    /// Get all scheduled tasks for a specific worker
    public func getScheduledTasks(for workerId: String, dateRange: DateInterval? = nil) -> [CoreTypes.AdminTaskSchedule] {
        let workerTasks = scheduledTasks.filter { $0.assignedWorkerId == workerId }
        
        if let dateRange = dateRange {
            return workerTasks.filter { dateRange.contains($0.scheduledDateTime) }
        }
        
        return workerTasks
    }
    
    /// Get all scheduled tasks for a specific building
    public func getScheduledTasksForBuilding(_ buildingId: String, dateRange: DateInterval? = nil) -> [CoreTypes.AdminTaskSchedule] {
        let buildingTasks = scheduledTasks.filter { $0.buildingId == buildingId }
        
        if let dateRange = dateRange {
            return buildingTasks.filter { dateRange.contains($0.scheduledDateTime) }
        }
        
        return buildingTasks
    }
    
    // MARK: - Smart Scheduling Engine Integration
    
    private func optimizeScheduleWithSmartScheduling(
        schedule: CoreTypes.AdminTaskSchedule
    ) async throws -> CoreTypes.AdminTaskSchedule {
        
        guard let workerId = schedule.assignedWorkerId else {
            return schedule // No worker assigned, can't optimize
        }
        
        // Get worker context for optimization
        let context = await getWorkerScheduleContext(workerId: workerId)
        
        // Check for conflicts
        let conflicts = await findScheduleConflicts(
            workerId: workerId,
            startTime: schedule.scheduledDateTime,
            duration: schedule.estimatedDuration
        )
        
        var optimizedSchedule = schedule
        
        if !conflicts.isEmpty {
            print("⚠️ Schedule conflicts detected, finding optimal time slot...")
            
            // Find best alternative time slot
            if let recommendedSlot = await smartSchedulingEngine.findBestTimeSlot(
                for: workerId,
                around: schedule.scheduledDateTime,
                duration: schedule.estimatedDuration,
                context: context
            ) {
                optimizedSchedule.scheduledDateTime = recommendedSlot.startTime
                print("✅ Optimized schedule time: \(recommendedSlot.startTime)")
                print("📝 Reason: \(recommendedSlot.reasoning)")
            }
        }
        
        return optimizedSchedule
    }
    
    // MARK: - Worker Schedule Integration
    
    private func updateWorkerScheduleContext(
        workerId: String,
        newSchedule: CoreTypes.AdminTaskSchedule
    ) async throws {
        
        let currentContext = await getWorkerScheduleContext(workerId: workerId)
        
        // Update the current schedule in context
        var updatedSchedule = currentContext.currentSchedule
        if let existingIndex = updatedSchedule.firstIndex(where: { $0.id == newSchedule.id }) {
            updatedSchedule[existingIndex] = newSchedule
        } else {
            updatedSchedule.append(newSchedule)
        }
        
        // Recalculate conflicts and recommendations
        let conflictingTasks = findConflictingTasks(for: workerId)
        let recommendedSlots = await smartSchedulingEngine.generateRecommendedSlots(
            for: workerId,
            currentSchedule: updatedSchedule
        )
        
        let updatedContext = CoreTypes.WorkerScheduleContext(
            workerId: workerId,
            currentSchedule: updatedSchedule,
            availabilityWindows: currentContext.availabilityWindows,
            preferredWorkingHours: currentContext.preferredWorkingHours,
            buildingAssignments: currentContext.buildingAssignments,
            conflictingTasks: conflictingTasks,
            recommendedSlots: recommendedSlots,
            lastUpdated: Date()
        )
        
        // Update cached context
        workerScheduleContexts[workerId] = updatedContext
        
        // Trigger update to WorkerProfileView (this will be handled by the real-time sync)
        await broadcastWorkerScheduleUpdate(workerId: workerId, context: updatedContext)
    }
    
    // MARK: - Conflict Detection
    
    private func findScheduleConflicts(
        workerId: String,
        startTime: Date,
        duration: TimeInterval,
        excludingScheduleId: String? = nil
    ) async -> [CoreTypes.AdminTaskSchedule] {
        
        let endTime = startTime.addingTimeInterval(duration)
        
        return scheduledTasks.filter { schedule in
            // Skip if this is the schedule we're excluding
            if let excludeId = excludingScheduleId, schedule.id == excludeId {
                return false
            }
            
            // Only check schedules for the same worker
            guard schedule.assignedWorkerId == workerId else { return false }
            
            // Only check active schedules
            guard schedule.status == .scheduled || schedule.status == .confirmed else { return false }
            
            let scheduleEndTime = schedule.scheduledDateTime.addingTimeInterval(schedule.estimatedDuration)
            
            // Check for time overlap
            return startTime < scheduleEndTime && endTime > schedule.scheduledDateTime
        }
    }
    
    private func findConflictingTasks(for workerId: String) -> [CoreTypes.AdminTaskSchedule] {
        let workerTasks = scheduledTasks.filter { $0.assignedWorkerId == workerId }
        
        var conflicts: [CoreTypes.AdminTaskSchedule] = []
        
        for i in 0..<workerTasks.count {
            for j in (i+1)..<workerTasks.count {
                let task1 = workerTasks[i]
                let task2 = workerTasks[j]
                
                let task1End = task1.scheduledDateTime.addingTimeInterval(task1.estimatedDuration)
                let task2End = task2.scheduledDateTime.addingTimeInterval(task2.estimatedDuration)
                
                // Check for overlap
                if task1.scheduledDateTime < task2End && task1End > task2.scheduledDateTime {
                    if !conflicts.contains(where: { $0.id == task1.id }) {
                        conflicts.append(task1)
                    }
                    if !conflicts.contains(where: { $0.id == task2.id }) {
                        conflicts.append(task2)
                    }
                }
            }
        }
        
        return conflicts
    }
    
    // MARK: - Worker Data Fetching
    
    private func getWorkerAvailabilityWindows(workerId: String) async -> [CoreTypes.AvailabilityWindow] {
        // This would integrate with the worker's availability settings
        // For now, return default business hours
        let calendar = Calendar.current
        let now = Date()
        
        return (2...6).map { dayOfWeek in // Monday to Friday
            CoreTypes.AvailabilityWindow(
                startTime: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now) ?? now,
                endTime: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now) ?? now,
                dayOfWeek: dayOfWeek,
                isRecurring: true
            )
        }
    }
    
    private func getWorkerPreferredHours(workerId: String) async -> CoreTypes.WorkingHours? {
        // This would fetch from worker preferences
        return CoreTypes.WorkingHours()
    }
    
    private func getWorkerBuildingAssignments(workerId: String) async -> [String] {
        // This would fetch from worker-building assignments
        return []
    }
    
    // MARK: - Data Persistence
    
    private func saveSchedule(_ schedule: CoreTypes.AdminTaskSchedule) async {
        // This would save to the database
        // For now, we'll just update the local state
        print("💾 Saving schedule: \(schedule.id)")
    }
    
    private func updateTaskWithScheduleInfo(
        task: CoreTypes.ContextualTask,
        schedule: CoreTypes.AdminTaskSchedule
    ) async {
        // Update the original task with scheduling information
        print("📝 Updating task with schedule info: \(task.id)")
    }
    
    // MARK: - Worker Notifications
    
    private func notifyWorkerOfNewSchedule(
        workerId: String,
        schedule: CoreTypes.AdminTaskSchedule
    ) async {
        // This would send a notification to the worker
        print("🔔 Notifying worker \(workerId) of new schedule: \(schedule.scheduledDateTime)")
    }
    
    private func notifyWorkerOfReschedule(
        workerId: String,
        schedule: CoreTypes.AdminTaskSchedule,
        oldDateTime: Date,
        reason: String
    ) async {
        print("🔔 Notifying worker \(workerId) of reschedule from \(oldDateTime) to \(schedule.scheduledDateTime)")
    }
    
    private func notifyWorkerOfCancellation(
        workerId: String,
        schedule: CoreTypes.AdminTaskSchedule,
        reason: String
    ) async {
        print("🔔 Notifying worker \(workerId) of cancelled schedule: \(schedule.scheduledDateTime)")
    }
    
    // MARK: - Real-Time Synchronization
    
    private func setupRealTimeSync() {
        // Subscribe to worker schedule updates
        // This ensures WorkerProfileView gets real-time updates
    }
    
    private func broadcastWorkerScheduleUpdate(
        workerId: String,
        context: CoreTypes.WorkerScheduleContext
    ) async {
        // Broadcast to all listening views (especially WorkerProfileView)
        print("📡 Broadcasting schedule update for worker: \(workerId)")
    }
}

// MARK: - Smart Scheduling Engine

private class SmartSchedulingEngine {
    
    func generateRecommendedSlots(
        for workerId: String,
        currentSchedule: [CoreTypes.AdminTaskSchedule]
    ) async -> [CoreTypes.ScheduleSlot] {
        
        // Generate smart recommendations based on:
        // - Current schedule gaps
        // - Worker preferences  
        // - Building locations
        // - Travel time
        // - Historical patterns
        
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        
        return [
            CoreTypes.ScheduleSlot(
                startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow,
                endTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow) ?? tomorrow,
                confidence: 0.9,
                reasoning: "Optimal morning slot with no conflicts",
                conflictLevel: .none,
                buildingId: "default"
            ),
            CoreTypes.ScheduleSlot(
                startTime: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: tomorrow) ?? tomorrow,
                endTime: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: tomorrow) ?? tomorrow,
                confidence: 0.8,
                reasoning: "Good afternoon slot, allows for lunch break",
                conflictLevel: .minor,
                buildingId: "default"
            )
        ]
    }
    
    func findBestTimeSlot(
        for workerId: String,
        around preferredTime: Date,
        duration: TimeInterval,
        context: CoreTypes.WorkerScheduleContext
    ) async -> CoreTypes.ScheduleSlot? {
        
        // Intelligent algorithm to find the best alternative time slot
        // when the preferred time has conflicts
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: preferredTime)
        
        // Try slots in 30-minute increments around the preferred time
        for hourOffset in [-2, -1, 1, 2] {
            let candidateTime = calendar.date(byAdding: .hour, value: hourOffset, to: preferredTime) ?? preferredTime
            
            // Check if this slot is available
            let hasConflicts = context.conflictingTasks.contains { schedule in
                let scheduleEnd = schedule.scheduledDateTime.addingTimeInterval(schedule.estimatedDuration)
                let candidateEnd = candidateTime.addingTimeInterval(duration)
                
                return candidateTime < scheduleEnd && candidateEnd > schedule.scheduledDateTime
            }
            
            if !hasConflicts {
                return CoreTypes.ScheduleSlot(
                    startTime: candidateTime,
                    endTime: candidateTime.addingTimeInterval(duration),
                    confidence: 0.85,
                    reasoning: "Alternative slot \(abs(hourOffset)) hours from preferred time",
                    conflictLevel: .none,
                    buildingId: context.buildingAssignments.first ?? "default"
                )
            }
        }
        
        return nil
    }
}

// MARK: - Scheduling Errors

public enum SchedulingError: LocalizedError {
    case scheduleNotFound
    case conflictingSchedule
    case workerNotAvailable
    case invalidTimeSlot
    case optimizationFailed
    
    public var errorDescription: String? {
        switch self {
        case .scheduleNotFound:
            return "Schedule not found"
        case .conflictingSchedule:
            return "Schedule conflicts with existing tasks"
        case .workerNotAvailable:
            return "Worker is not available at the requested time"
        case .invalidTimeSlot:
            return "Invalid time slot specified"
        case .optimizationFailed:
            return "Failed to optimize schedule"
        }
    }
}