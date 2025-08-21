
//  SiteLogService.swift
//  CyntientOps
//
//  Service for managing site departure logs and compliance tracking
//

import Foundation
import CoreLocation

public actor SiteLogService {
    public static let shared = SiteLogService()
    private let grdbManager = GRDBManager.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Create a departure log when worker leaves a site
    public func createDepartureLog(
        workerId: String,
        buildingId: String,
        checklist: DepartureChecklist,
        isCompliant: Bool,
        notes: String?,
        nextDestination: String? = nil,
        departureMethod: DepartureMethod = .normal,
        location: CLLocation? = nil
    ) async throws -> String {
        let logId = UUID().uuidString
        
        try await grdbManager.execute("""
            INSERT INTO site_departure_logs (
                id, worker_id, building_id, departed_at,
                tasks_completed_count, tasks_remaining_count,
                photos_provided_count, is_fully_compliant,
                notes, next_destination_building_id,
                departure_method, location_lat, location_lon,
                time_spent_minutes, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            logId,
            workerId,
            buildingId,
            Date().ISO8601Format(),
            checklist.completedTasks.count,
            checklist.incompleteTasks.count,
            checklist.photoCount,
            isCompliant ? 1 : 0,
            notes as Any,
            nextDestination as Any,
            departureMethod.rawValue,
            location?.coordinate.latitude as Any,
            location?.coordinate.longitude as Any,
            checklist.timeSpentMinutes as Any,
            Date().ISO8601Format()
        ])
        
        // Broadcast update for real-time monitoring
        await broadcastDeparture(
            workerId: workerId,
            buildingId: buildingId,
            checklist: checklist,
            departureMethod: departureMethod
        )
        
        // Update clock session if this is end of day
        if departureMethod == .endOfDay {
            await updateClockOutTime(workerId: workerId, buildingId: buildingId)
        }
        
        return logId
    }
    
    /// Get today's departures for a worker
    public func getTodaysDepartures(for workerId: String) async throws -> [DepartureLogRecord] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let rows = try await grdbManager.query("""
            SELECT dl.*, b.name as building_name, b.address as building_address
            FROM site_departure_logs dl
            JOIN buildings b ON dl.building_id = b.id
            WHERE dl.worker_id = ?
            AND dl.departed_at >= ? AND dl.departed_at < ?
            ORDER BY dl.departed_at DESC
        """, [
            workerId,
            today.ISO8601Format(),
            tomorrow.ISO8601Format()
        ])
        
        return rows.compactMap { DepartureLogRecord(from: $0) }
    }
    
    /// Get departure logs for a building
    public func getBuildingDepartures(for buildingId: String, days: Int = 7) async throws -> [DepartureLogRecord] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        let rows = try await grdbManager.query("""
            SELECT dl.*, b.name as building_name, b.address as building_address,
                   w.name as worker_name
            FROM site_departure_logs dl
            JOIN buildings b ON dl.building_id = b.id
            JOIN workers w ON dl.worker_id = w.id
            WHERE dl.building_id = ?
            AND dl.departed_at >= ?
            ORDER BY dl.departed_at DESC
        """, [
            buildingId,
            startDate.ISO8601Format()
        ])
        
        return rows.compactMap { DepartureLogRecord(from: $0) }
    }
    
    /// Get compliance rate for a worker
    public func getComplianceRate(for workerId: String, days: Int = 30) async throws -> Double {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        let rows = try await grdbManager.query("""
            SELECT 
                COUNT(*) as total_departures,
                SUM(is_fully_compliant) as compliant_departures
            FROM site_departure_logs
            WHERE worker_id = ?
            AND departed_at >= ?
        """, [
            workerId,
            startDate.ISO8601Format()
        ])
        
        guard let row = rows.first,
              let total = row["total_departures"] as? Int64,
              let compliant = row["compliant_departures"] as? Int64,
              total > 0 else {
            return 0.0
        }
        
        return Double(compliant) / Double(total) * 100.0
    }
    
    /// Get average time spent per building
    public func getAverageTimeSpent(for workerId: String, buildingId: String? = nil) async throws -> TimeInterval {
        var query = """
            SELECT AVG(time_spent_minutes) as avg_time
            FROM site_departure_logs
            WHERE worker_id = ?
        """
        
        var params: [Any] = [workerId]
        
        if let buildingId = buildingId {
            query += " AND building_id = ?"
            params.append(buildingId)
        }
        
        let rows = try await grdbManager.query(query, params)
        
        let avgMinutes = rows.first?["avg_time"] as? Double ?? 0
        return avgMinutes * 60 // Convert to seconds
    }
    
    /// Get incomplete task patterns
    public func getIncompleteTaskPatterns(for buildingId: String, days: Int = 30) async throws -> [TaskPattern] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        // Get departure logs with incomplete tasks
        let departureLogs = try await grdbManager.query("""
            SELECT dl.*, rt.title, rt.category, rt.urgency
            FROM site_departure_logs dl
            JOIN routine_tasks rt ON rt.building_id = dl.building_id
            WHERE dl.building_id = ?
            AND dl.departed_at >= ?
            AND dl.tasks_remaining_count > 0
            AND rt.isCompleted = 0
            ORDER BY dl.departed_at DESC
        """, [
            buildingId,
            startDate.ISO8601Format()
        ])
        
        // Analyze patterns
        var taskPatterns: [String: TaskPattern] = [:]
        
        for log in departureLogs {
            guard let taskTitle = log["title"] as? String else { continue }
            
            var pattern = taskPatterns[taskTitle] ?? TaskPattern(
                taskTitle: taskTitle,
                category: log["category"] as? String,
                urgency: log["urgency"] as? String,
                incompleteCount: 0,
                totalOccurrences: 0
            )
            
            pattern.incompleteCount += 1
            taskPatterns[taskTitle] = pattern
        }
        
        return Array(taskPatterns.values).sorted { $0.incompleteCount > $1.incompleteCount }
    }
    
    /// Check if worker has departed from building today
    public func hasWorkerDepartedToday(workerId: String, buildingId: String) async throws -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        
        let rows = try await grdbManager.query("""
            SELECT COUNT(*) as count
            FROM site_departure_logs
            WHERE worker_id = ? AND building_id = ?
            AND departed_at >= ?
        """, [
            workerId,
            buildingId,
            today.ISO8601Format()
        ])
        
        let count = rows.first?["count"] as? Int64 ?? 0
        return count > 0
    }
    
    // MARK: - Private Methods
    
    private func broadcastDeparture(
        workerId: String,
        buildingId: String,
        checklist: DepartureChecklist,
        departureMethod: DepartureMethod
    ) async {
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .buildingUpdate,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "action": "site_departure",
                "completedTasks": String(checklist.completedTasks.count),
                "remainingTasks": String(checklist.incompleteTasks.count),
                "photoCount": String(checklist.photoCount),
                "timeSpent": String(checklist.timeSpentMinutes ?? 0),
                "departureMethod": departureMethod.rawValue,
                "isCompliant": String(checklist.incompleteTasks.isEmpty),
                "timestamp": ISO8601DateFormatter().string(from: Date())
            ]
        )
        
        await MainActor.run {
            DashboardSyncService.shared.broadcastWorkerUpdate(update)
        }
    }
    
    private func updateClockOutTime(workerId: String, buildingId: String) async {
        let today = Calendar.current.startOfDay(for: Date())
        
        do {
            // Find the most recent clock session for today
            let rows = try await grdbManager.query("""
                SELECT id FROM clock_sessions
                WHERE worker_id = ? AND building_id = ?
                AND clock_in_time >= ?
                AND clock_out_time IS NULL
                ORDER BY clock_in_time DESC
                LIMIT 1
            """, [
                workerId,
                buildingId,
                today.ISO8601Format()
            ])
            
            if let sessionId = rows.first?["id"] as? String {
                try await grdbManager.execute("""
                    UPDATE clock_sessions
                    SET clock_out_time = ?,
                        duration_minutes = (
                            CAST((julianday(?) - julianday(clock_in_time)) * 24 * 60 AS INTEGER)
                        )
                    WHERE id = ?
                """, [
                    Date().ISO8601Format(),
                    Date().ISO8601Format(),
                    sessionId
                ])
            }
        } catch {
            print("Failed to update clock out time: \(error)")
        }
    }
}

// MARK: - Supporting Types

public struct TaskPattern {
    let taskTitle: String
    let category: String?
    let urgency: String?
    var incompleteCount: Int
    var totalOccurrences: Int
    
    var incompletionRate: Double {
        guard totalOccurrences > 0 else { return 0 }
        return Double(incompleteCount) / Double(totalOccurrences) * 100
    }
}

// MARK: - Analytics Extensions

extension SiteLogService {
    
    /// Get departure analytics for a building
    public func getBuildingDepartureAnalytics(buildingId: String, days: Int = 30) async throws -> DepartureAnalytics {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        // Get all departures
        let rows = try await grdbManager.query("""
            SELECT 
                COUNT(*) as total_departures,
                SUM(is_fully_compliant) as compliant_departures,
                AVG(tasks_completed_count) as avg_completed,
                AVG(tasks_remaining_count) as avg_remaining,
                AVG(time_spent_minutes) as avg_time_spent,
                SUM(CASE WHEN departure_method = 'emergency' THEN 1 ELSE 0 END) as emergency_count
            FROM site_departure_logs
            WHERE building_id = ?
            AND departed_at >= ?
        """, [
            buildingId,
            startDate.ISO8601Format()
        ])
        
        guard let row = rows.first else {
            return DepartureAnalytics.empty
        }
        
        let totalDepartures = row["total_departures"] as? Int64 ?? 0
        let compliantDepartures = row["compliant_departures"] as? Int64 ?? 0
        let avgCompleted = row["avg_completed"] as? Double ?? 0
        let avgRemaining = row["avg_remaining"] as? Double ?? 0
        let avgTimeSpent = row["avg_time_spent"] as? Double ?? 0
        let emergencyCount = row["emergency_count"] as? Int64 ?? 0
        
        return DepartureAnalytics(
            totalDepartures: Int(totalDepartures),
            compliantDepartures: Int(compliantDepartures),
            complianceRate: totalDepartures > 0 ? Double(compliantDepartures) / Double(totalDepartures) * 100 : 0,
            averageTasksCompleted: avgCompleted,
            averageTasksRemaining: avgRemaining,
            averageTimeSpentMinutes: avgTimeSpent,
            emergencyDepartures: Int(emergencyCount)
        )
    }
    
    /// Get worker departure trends
    public func getWorkerDepartureTrends(workerId: String, days: Int = 30) async throws -> [DepartureTrend] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        let rows = try await grdbManager.query("""
            SELECT 
                DATE(departed_at) as departure_date,
                COUNT(*) as departure_count,
                SUM(is_fully_compliant) as compliant_count,
                AVG(tasks_completed_count) as avg_completed,
                AVG(time_spent_minutes) as avg_time
            FROM site_departure_logs
            WHERE worker_id = ?
            AND departed_at >= ?
            GROUP BY DATE(departed_at)
            ORDER BY departure_date DESC
        """, [
            workerId,
            startDate.ISO8601Format()
        ])
        
        return rows.compactMap { row in
            guard let dateString = row["departure_date"] as? String,
                  let date = DateFormatter.yyyyMMdd.date(from: dateString) else {
                return nil
            }
            
            return DepartureTrend(
                date: date,
                departureCount: Int(row["departure_count"] as? Int64 ?? 0),
                compliantCount: Int(row["compliant_count"] as? Int64 ?? 0),
                averageTasksCompleted: row["avg_completed"] as? Double ?? 0,
                averageTimeMinutes: row["avg_time"] as? Double ?? 0
            )
        }
    }
}

// MARK: - Analytics Types

public struct DepartureAnalytics {
    let totalDepartures: Int
    let compliantDepartures: Int
    let complianceRate: Double
    let averageTasksCompleted: Double
    let averageTasksRemaining: Double
    let averageTimeSpentMinutes: Double
    let emergencyDepartures: Int
    
    static let empty = DepartureAnalytics(
        totalDepartures: 0,
        compliantDepartures: 0,
        complianceRate: 0,
        averageTasksCompleted: 0,
        averageTasksRemaining: 0,
        averageTimeSpentMinutes: 0,
        emergencyDepartures: 0
    )
}

public struct DepartureTrend {
    let date: Date
    let departureCount: Int
    let compliantCount: Int
    let averageTasksCompleted: Double
    let averageTimeMinutes: Double
    
    var complianceRate: Double {
        departureCount > 0 ? Double(compliantCount) / Double(departureCount) * 100 : 0
    }
}

// MARK: - Date Formatter Extension

private extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
