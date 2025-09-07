//
//  TaskManager.swift
//  CyntientOps v6.0
//
//  Missing TaskManager implementation
//

import Foundation

@MainActor
public class TaskManager: ObservableObject {
    public static let shared = TaskManager()
    
    @Published public var tasks: [ContextualTask] = []
    @Published public var isLoading = false
    
    private var taskService: TaskService?
    
    private init() {}
    
    /// Set the task service for data operations
    public func setTaskService(_ service: TaskService) {
        self.taskService = service
    }
    
    public func loadTasks() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let taskService = taskService {
                tasks = try await taskService.getAllTasks()
            } else {
                print("⚠️ TaskService not available")
                tasks = []
            }
        } catch {
            print("❌ Failed to load tasks: \(error)")
        }
    }
    
    public func updateTask(_ task: ContextualTask) async {
        do {
            if let taskService = taskService {
                try await taskService.updateTask(task)
                await loadTasks()
            } else {
                print("⚠️ TaskService not available")
            }
        } catch {
            print("❌ Failed to update task: \(error)")
        }
    }
}
