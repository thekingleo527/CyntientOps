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
    
    private init() {}
    
    public func loadTasks() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            tasks = try await // TaskService injection needed.getAllTasks()
        } catch {
            print("❌ Failed to load tasks: \(error)")
        }
    }
    
    public func updateTask(_ task: ContextualTask) async {
        do {
            try await // TaskService injection needed.updateTask(task)
            await loadTasks()
        } catch {
            print("❌ Failed to update task: \(error)")
        }
    }
}
