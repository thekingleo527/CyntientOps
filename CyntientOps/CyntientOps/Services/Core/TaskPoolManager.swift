//
//  TaskPoolManager.swift
//  CyntientOps
//
//  🎯 TASK MANAGEMENT: Controls 371 concurrent Task spawns to prevent thread explosion
//  ⚡ PERFORMANCE: Limits concurrent operations to device capabilities
//

import Foundation

@globalActor
public actor TaskPoolActor {
    public static let shared = TaskPoolActor()
}

@TaskPoolActor
public final class TaskPoolManager {
    public static let shared = TaskPoolManager()
    
    private var activeTasks: Set<UUID> = []
    private var pendingTasks: [(UUID, () async -> Void)] = []
    private let maxConcurrentTasks: Int
    private let highPriorityLimit: Int
    
    private init() {
        // Optimize for iPhone performance in field
        self.maxConcurrentTasks = 8  // Reduced from unlimited
        self.highPriorityLimit = 4   // Reserve slots for UI-critical tasks
        
        // Start monitoring task
        Task {
            await monitorTasks()
        }
    }
    
    /// Execute task with automatic pooling
    public func execute<T>(
        priority: Task.Priority = .medium,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        
        return try await withCheckedThrowingContinuation { continuation in
            let taskId = UUID()
            
            let wrappedOperation = {
                do {
                    let result = try await operation()
                    await self.taskCompleted(taskId)
                    continuation.resume(returning: result)
                } catch {
                    await self.taskCompleted(taskId)
                    continuation.resume(throwing: error)
                }
            }
            
            Task {
                await queueTask(id: taskId, priority: priority, operation: wrappedOperation)
            }
        }
    }
    
    /// Execute task without return value
    public func executeVoid(
        priority: Task.Priority = .medium,
        operation: @escaping () async throws -> Void
    ) {
        let taskId = UUID()
        
        let wrappedOperation = {
            do {
                try await operation()
            } catch {
                print("Task \(taskId) failed: \(error)")
            }
            await self.taskCompleted(taskId)
        }
        
        Task {
            await queueTask(id: taskId, priority: priority, operation: wrappedOperation)
        }
    }
    
    private func queueTask(
        id: UUID,
        priority: Task.Priority,
        operation: @escaping () async -> Void
    ) async {
        
        // Check if we can execute immediately
        if activeTasks.count < maxConcurrentTasks {
            activeTasks.insert(id)
            
            Task(priority: priority) {
                await operation()
            }
        } else {
            // Queue for later execution
            if isHighPriority(priority) {
                // High priority tasks go to front
                pendingTasks.insert((id, operation), at: 0)
            } else {
                pendingTasks.append((id, operation))
            }
        }
    }
    
    private func taskCompleted(_ id: UUID) async {
        activeTasks.remove(id)
        
        // Start next pending task if available
        if !pendingTasks.isEmpty && activeTasks.count < maxConcurrentTasks {
            let (nextId, nextOperation) = pendingTasks.removeFirst()
            activeTasks.insert(nextId)
            
            Task {
                await nextOperation()
            }
        }
    }

    private func isHighPriority(_ p: Task.Priority) -> Bool {
        switch p {
        case .high, .userInitiated:
            return true
        default:
            return false
        }
    }
    
    private func monitorTasks() async {
        while true {
            try? await Task.sleep(for: .seconds(5))
            
            let activeCount = activeTasks.count
            let pendingCount = pendingTasks.count
            
            if activeCount > 0 || pendingCount > 0 {
                print("🎯 Task Pool: \(activeCount) active, \(pendingCount) pending")
            }
            
            // Emergency cleanup for stuck tasks
            if activeTasks.count >= maxConcurrentTasks && pendingTasks.count > 20 {
                print("⚠️ Task pool congestion detected, clearing some pending tasks")
                let keepCount = min(pendingTasks.count, 10)
                pendingTasks = Array(pendingTasks.prefix(keepCount))
            }
        }
    }
    
    /// Cancel all pending tasks (emergency use)
    public func cancelPendingTasks() async {
        pendingTasks.removeAll()
        print("🚫 All pending tasks cancelled")
    }
    
    /// Get current status
    public func getStatus() async -> (active: Int, pending: Int) {
        return (activeTasks.count, pendingTasks.count)
    }
}

// MARK: - Convenience Extensions

public enum TaskPool {
    /// Create a pooled task that respects concurrency limits
    public static func pooled(
        priority: Task.Priority = .medium,
        operation: @escaping () async throws -> Void
    ) {
        Task {
            await TaskPoolManager.shared.executeVoid(priority: priority, operation: operation)
        }
    }

    /// Create a pooled task with return value
    public static func pooled<T>(
        priority: Task.Priority = .medium,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await TaskPoolManager.shared.execute(priority: priority, operation: operation)
    }
}
