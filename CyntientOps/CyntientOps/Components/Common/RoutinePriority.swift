//
//  RoutinePriority.swift
//  CyntientOps v6.0
//
//  ✅ GRDB MIGRATION: Updated from GRDBManager to GRDBManager
//  ✅ PRESERVED: All real-world building routine data
//  ✅ ASYNC/AWAIT: Modern concurrency patterns
//  ✅ KEVIN'S DATA: All sample routines for 6+ buildings preserved
//  ✅ FIXED: Renamed computed properties to avoid conflicts
//

import Foundation
import SwiftUI

// MARK: - Supporting Types

enum RoutinePriority: String, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct BuildingRoutine: Identifiable, Hashable {
    let id: String
    let buildingId: String
    let routineName: String
    let description: String
    let scheduleType: String // "daily", "weekly", "monthly"
    let scheduleDays: [String] // ["Monday", "Tuesday"] or ["1", "15"] for monthly
    let startTime: String // "09:00"
    let estimatedDuration: Int // minutes
    let priority: RoutinePriority
    let isActive: Bool
    let createdDate: Date
    
    // Computed properties - renamed to avoid conflicts
    var routineDisplaySchedule: String {
        switch scheduleType.lowercased() {
        case "daily":
            return "Daily at \(startTime)"
        case "weekly":
            let days = scheduleDays.prefix(3).joined(separator: ", ")
            return "\(days) at \(startTime)"
        case "monthly":
            let days = scheduleDays.joined(separator: ", ")
            return "Monthly on \(days)th at \(startTime)"
        default:
            return "Custom schedule"
        }
    }
    
    var isRoutineDueToday: Bool {
        let today = Calendar.current.component(.weekday, from: Date())
        let todayName = Calendar.current.weekdaySymbols[today - 1]
        
        switch scheduleType.lowercased() {
        case "daily":
            return true
        case "weekly":
            return scheduleDays.contains(todayName)
        default:
            return false
        }
    }
    
    var isRoutineOverdue: Bool {
        // Simple logic - if it's due today and past the start time
        guard isRoutineDueToday else { return false }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        guard let startDateTime = formatter.date(from: startTime) else { return false }
        
        let now = Date()
        let todayStart = Calendar.current.startOfDay(for: now)
        let todayStartTime = Calendar.current.date(byAdding: .second,
                                                   value: Int(startDateTime.timeIntervalSince1970),
                                                   to: todayStart) ?? now
        
        return now > todayStartTime
    }
    
    var nextRoutineDue: Date? {
        let calendar = Calendar.current
        let now = Date()
        
        switch scheduleType.lowercased() {
        case "daily":
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            guard let startDateTime = formatter.date(from: startTime) else { return nil }
            
            let todayStart = calendar.startOfDay(for: now)
            let todayStartTime = calendar.date(byAdding: .second,
                                               value: Int(startDateTime.timeIntervalSince1970),
                                               to: todayStart) ?? now
            
            if todayStartTime > now {
                return todayStartTime
            } else {
                return calendar.date(byAdding: .day, value: 1, to: todayStartTime)
            }
            
        case "weekly":
            // Find next occurrence of scheduled days
            for i in 0..<7 {
                let futureDate = calendar.date(byAdding: .day, value: i, to: now) ?? now
                let weekday = calendar.component(.weekday, from: futureDate)
                let weekdayName = calendar.weekdaySymbols[weekday - 1]
                
                if scheduleDays.contains(weekdayName) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    guard let startDateTime = formatter.date(from: startTime) else { continue }
                    
                    let dayStart = calendar.startOfDay(for: futureDate)
                    return calendar.date(byAdding: .second,
                                        value: Int(startDateTime.timeIntervalSince1970),
                                        to: dayStart)
                }
            }
            return nil
            
        default:
            return nil
        }
    }
}

// MARK: - Routine Repository Service (GRDB MIGRATED)

@MainActor
final class RoutineRepository: ObservableObject {
    static let shared = RoutineRepository()
    
    @Published var routines: [BuildingRoutine] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    // Using GRDBManager
    private let grdbManager = GRDBManager.shared
    private var lastRefresh: Date = Date.distantPast
    private let refreshInterval: TimeInterval = 300 // 5 minutes
    
    private init() {
        Task {
            await initializeDatabase()
            await loadInitialRoutines()
        }
    }
    
    // MARK: - Public Interface
    
    func getRoutinesForBuilding(_ buildingId: String) -> [BuildingRoutine] {
        return routines.filter { $0.buildingId == buildingId && $0.isActive }
    }
    
    func getAllActiveRoutines() -> [BuildingRoutine] {
        return routines.filter { $0.isActive }
    }
    
    func getOverdueRoutines() -> [BuildingRoutine] {
        return routines.filter { $0.isActive && $0.isRoutineOverdue }
    }
    
    func getDueTodayRoutines() -> [BuildingRoutine] {
        return routines.filter { $0.isActive && $0.isRoutineDueToday }
    }
    
    func refreshRoutines() async {
        guard Date().timeIntervalSince(lastRefresh) > refreshInterval else { return }
        
        isLoading = true
        error = nil
        
        do {
            await loadRoutinesFromDatabase()
            lastRefresh = Date()
        } catch {
            self.error = error
            print("❌ Failed to refresh routines: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Database Operations
    
    private func initializeDatabase() async {
        await createRoutinesTableIfNeeded()
    }
    
    private func createRoutinesTableIfNeeded() async {
        do {
            try await grdbManager.execute("""
                CREATE TABLE IF NOT EXISTS building_routines (
                    id TEXT PRIMARY KEY,
                    building_id TEXT NOT NULL,
                    routine_name TEXT NOT NULL,
                    description TEXT,
                    schedule_type TEXT NOT NULL,
                    schedule_days TEXT NOT NULL,
                    start_time TEXT NOT NULL,
                    estimated_duration INTEGER NOT NULL,
                    priority TEXT NOT NULL,
                    is_active INTEGER NOT NULL DEFAULT 1,
                    created_date DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            print("✅ Building routines table ready with GRDBManager")
        } catch {
            print("❌ Failed to create routines table: \(error)")
        }
    }
    
    private func loadInitialRoutines() async {
        await loadSampleRoutines()
        await loadRoutinesFromDatabase()
    }
    
    private func loadRoutinesFromDatabase() async {
        do {
            let results = try await grdbManager.query("""
                SELECT * FROM building_routines 
                WHERE is_active = 1 
                ORDER BY building_id, priority DESC, start_time
            """)
            
            let loadedRoutines = results.compactMap { row -> BuildingRoutine? in
                guard let id = row["id"] as? String,
                      let buildingId = row["building_id"] as? String,
                      let routineName = row["routine_name"] as? String,
                      let scheduleType = row["schedule_type"] as? String,
                      let scheduleDays = row["schedule_days"] as? String,
                      let startTime = row["start_time"] as? String,
                      let duration = row["estimated_duration"] as? Int64,
                      let priorityStr = row["priority"] as? String,
                      let isActiveInt = row["is_active"] as? Int64 else {
                    return nil
                }
                
                let description = row["description"] as? String ?? ""
                let priority = RoutinePriority(rawValue: priorityStr) ?? .medium
                let isActive = isActiveInt == 1
                let createdDate = Date() // Could parse from database if needed
                
                return BuildingRoutine(
                    id: id,
                    buildingId: buildingId,
                    routineName: routineName,
                    description: description,
                    scheduleType: scheduleType,
                    scheduleDays: scheduleDays.components(separatedBy: ","),
                    startTime: startTime,
                    estimatedDuration: Int(duration),
                    priority: priority,
                    isActive: isActive,
                    createdDate: createdDate
                )
            }
            
            routines = loadedRoutines
            print("✅ Loaded \(routines.count) building routines from GRDBManager")
            
        } catch {
            print("❌ Failed to load routines: \(error)")
            self.error = error
        }
    }
    
    // MARK: - Sample Data for Development
    
    private func loadSampleRoutines() async {
        // Check if we already have routines
        do {
            let count = try await grdbManager.query("SELECT COUNT(*) as count FROM building_routines")
            if let first = count.first, let countValue = first["count"] as? Int64, countValue > 0 {
                print("📋 Routines already exist, skipping sample data")
                return
            }
        } catch {
            print("⚠️ Could not check routine count, proceeding with sample data")
        }
        
        // Sample routines for Kevin's buildings
        let sampleRoutines = [
            // Building 3 (Kevin's building)
            ("routine_3_daily_sweep", "3", "Daily Lobby Sweep", "Sweep and mop lobby area", "daily", "", "08:00", 30, "medium"),
            ("routine_3_trash_pickup", "3", "Trash Collection", "Collect and stage trash for pickup", "weekly", "Tuesday,Thursday", "06:30", 45, "high"),
            ("routine_3_weekly_clean", "3", "Weekly Deep Clean", "Thorough cleaning of common areas", "weekly", "Saturday", "10:00", 120, "medium"),
            
            // Building 6 (Kevin's building)
            ("routine_6_daily_maint", "6", "Daily Maintenance Check", "Check all systems and common areas", "daily", "", "09:00", 45, "medium"),
            ("routine_6_trash", "6", "Waste Management", "Handle all waste collection", "weekly", "Monday,Wednesday,Friday", "07:00", 30, "high"),
            
            // Building 7 (Kevin's building)
            ("routine_7_entrance", "7", "Entrance Maintenance", "Clean and maintain building entrance", "daily", "", "07:30", 20, "low"),
            ("routine_7_dsny", "7", "DSNY Prep", "Prepare for DSNY pickup", "weekly", "Tuesday,Thursday", "06:00", 25, "critical"),
            
            // Building 9 (Kevin's building)
            ("routine_9_security", "9", "Security Rounds", "Walk building perimeter and check access", "daily", "", "18:00", 15, "high"),
            ("routine_9_maintenance", "9", "Equipment Check", "Inspect HVAC and utilities", "weekly", "Wednesday", "14:00", 60, "medium"),
            
            // Building 11 (Kevin's building)
            ("routine_11_cleaning", "11", "Full Building Clean", "Complete cleaning routine", "daily", "", "08:30", 90, "medium"),
            ("routine_11_inspection", "11", "Safety Inspection", "Check fire safety and exits", "weekly", "Friday", "16:00", 45, "high"),
            
            // Building 16 (Kevin's building)
            ("routine_16_daily", "16", "Daily Routine", "Standard daily maintenance", "daily", "", "09:30", 40, "medium"),
            ("routine_16_trash", "16", "Waste Collection", "Collect and organize waste", "weekly", "Monday,Thursday", "07:30", 35, "high")
        ]
        
        do {
            for (id, buildingId, name, desc, scheduleType, days, startTime, duration, priority) in sampleRoutines {
                try await grdbManager.execute("""
                    INSERT OR IGNORE INTO building_routines 
                    (id, building_id, routine_name, description, schedule_type, schedule_days, start_time, estimated_duration, priority, is_active) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
                """, [id, buildingId, name, desc, scheduleType, days, startTime, duration, priority])
            }
            
            print("✅ Sample building routines created with GRDBManager")
        } catch {
            print("❌ Failed to create sample routines: \(error)")
        }
    }
    
    // MARK: - CRUD Operations
    
    func addRoutine(_ routine: BuildingRoutine) async throws {
        try await grdbManager.execute("""
            INSERT INTO building_routines (
                id, building_id, routine_name, description, schedule_type,
                schedule_days, start_time, estimated_duration, priority, is_active
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            routine.id,
            routine.buildingId,
            routine.routineName,
            routine.description,
            routine.scheduleType,
            routine.scheduleDays.joined(separator: ","),
            routine.startTime,
            routine.estimatedDuration,
            routine.priority.rawValue,
            routine.isActive ? 1 : 0
        ])
        
        self.routines.append(routine)
        print("✅ Added routine: \(routine.routineName)")
    }
    
    func updateRoutine(_ routine: BuildingRoutine) async throws {
        try await grdbManager.execute("""
            UPDATE building_routines 
            SET routine_name = ?, description = ?, schedule_type = ?,
                schedule_days = ?, start_time = ?, estimated_duration = ?,
                priority = ?, is_active = ?
            WHERE id = ?
        """, [
            routine.routineName,
            routine.description,
            routine.scheduleType,
            routine.scheduleDays.joined(separator: ","),
            routine.startTime,
            routine.estimatedDuration,
            routine.priority.rawValue,
            routine.isActive ? 1 : 0,
            routine.id
        ])
        
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            routines[index] = routine
        }
        
        print("✅ Updated routine: \(routine.routineName)")
    }
    
    func deleteRoutine(_ routineId: String) async throws {
        try await grdbManager.execute("""
            UPDATE building_routines 
            SET is_active = 0 
            WHERE id = ?
        """, [routineId])
        
        routines.removeAll { $0.id == routineId }
        print("✅ Deleted routine: \(routineId)")
    }
    
    // MARK: - Utility Methods
    
    func getRoutineStats() -> (total: Int, overdue: Int, dueToday: Int) {
        let total = routines.filter { $0.isActive }.count
        let overdue = getOverdueRoutines().count
        let dueToday = getDueTodayRoutines().count
        
        return (total, overdue, dueToday)
    }
    
    func getRoutinesForBuildings(_ buildingIds: [String]) -> [BuildingRoutine] {
        return routines.filter { routine in
            buildingIds.contains(routine.buildingId) && routine.isActive
        }
    }
}

// MARK: - 📝 GRDB MIGRATION NOTES
/*
 ✅ COMPLETE GRDB MIGRATION:
 
 🔧 FIXED DATABASE MANAGER:
 - ✅ Changed to GRDBManager.shared
 - ✅ Using execute() and query() methods
 - ✅ Removed async suffixes
 
 🔧 FIXED NAMING CONFLICTS:
 - ✅ Renamed displaySchedule → routineDisplaySchedule
 - ✅ Renamed isDueToday → isRoutineDueToday
 - ✅ Renamed isOverdue → isRoutineOverdue
 - ✅ Added nextRoutineDue for consistency
 
 🔧 PRESERVED ALL DATA:
 - ✅ All Kevin's building routines (Buildings 3, 6, 7, 9, 11, 16)
 - ✅ All task types (daily sweeps, trash pickup, maintenance, security)
 - ✅ All priority levels and scheduling patterns
 - ✅ Complete CRUD operations for routine management
 
 🔧 MAINTAINED FUNCTIONALITY:
 - ✅ Building routine management system
 - ✅ Due today / overdue calculation logic
 - ✅ Priority-based organization
 - ✅ Schedule type handling (daily/weekly/monthly)
 - ✅ Database persistence with sample data
 
 🎯 STATUS: GRDB migration complete, naming conflicts resolved
 */
