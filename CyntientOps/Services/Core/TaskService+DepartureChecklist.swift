//
//  TaskService+DepartureChecklist.swift
//  CyntientOps
//
//  Focused helpers for Site Departure (single-site clock-out gate)

import Foundation

extension TaskService {
    /// Fetch today's tasks for a worker at a specific building
    public func fetchDailyTasks(workerId: String, buildingId: String, date: Date) async throws -> [ContextualTask] {
        let dateString = ISO8601DateFormatter().string(from: date)
        let rows = try await grdbManager.query("""
            SELECT t.*, w.name as worker_name, b.name as building_name
            FROM routine_tasks t
            LEFT JOIN workers w ON t.workerId = w.id
            LEFT JOIN buildings b ON t.buildingId = b.id
            WHERE t.workerId = ? AND t.buildingId = ? AND DATE(t.scheduledDate) = DATE(?)
            ORDER BY t.scheduledDate
        """, [workerId, buildingId, dateString])

        return rows.compactMap { convertRowToContextualTask($0) }
    }

    /// Mark all of today's tasks complete for a worker at a building (awaited)
    public func completeAllFor(workerId: String, buildingId: String, date: Date) async throws {
        let dateString = ISO8601DateFormatter().string(from: date)
        // Complete tasks which are not cancelled and scheduled for today
        try await grdbManager.execute("""
            UPDATE routine_tasks
            SET isCompleted = 1, completedDate = datetime('now')
            WHERE workerId = ? AND buildingId = ? AND DATE(scheduledDate) = DATE(?) AND (isCancelled IS NULL OR isCancelled = 0)
        """, [workerId, buildingId, dateString])
    }
}

