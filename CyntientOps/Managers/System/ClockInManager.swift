//
//  ClockInManager.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: Removed duplicate types that exist in QuickBooksPayrollExporter
//  ✅ FIXED: Using correct DashboardSyncService broadcast methods
//  ✅ FIXED: Removed LocationManager dependency
//  ✅ ENHANCED: Full integration with QuickBooks payroll export
//

import Foundation
import CoreLocation
import Combine
import GRDB

/// Portfolio-aware clock in/out system with QuickBooks integration
@MainActor
public class ClockInManager: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = ClockInManager()
    
    // MARK: - Properties
    
    private var activeSessions: [CoreTypes.WorkerID: ClockInSession] = [:]
    private let grdbManager = GRDBManager.shared
    
    // MARK: - Types
    
    public struct ClockInSession {
        let id: String // Unique session ID for tracking
        let workerId: CoreTypes.WorkerID
        let buildingId: String
        let buildingName: String
        let startTime: Date
        let location: CLLocationCoordinate2D?
        
        init(workerId: CoreTypes.WorkerID, buildingId: String, buildingName: String, startTime: Date, location: CLLocationCoordinate2D?) {
            self.id = UUID().uuidString
            self.workerId = workerId
            self.buildingId = buildingId
            self.buildingName = buildingName
            self.startTime = startTime
            self.location = location
        }
    }
    
    public enum ClockInError: LocalizedError {
        case alreadyClockedIn
        case notClockedIn
        case invalidLocation
        case buildingNotFound
        case databaseError(String)
        
        public var errorDescription: String? {
            switch self {
            case .alreadyClockedIn:
                return "Already clocked in at another building"
            case .notClockedIn:
                return "Not currently clocked in"
            case .invalidLocation:
                return "Invalid location for clock in"
            case .buildingNotFound:
                return "Building not found"
            case .databaseError(let message):
                return "Database error: \(message)"
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        // Simple init without async operations
    }
    
    /// Initialize the clock-in manager
    public func initialize() async {
        await ensureDatabaseSchema()
        await loadActiveSessions()
    }
    
    // MARK: - Clock In/Out Methods (WITH FULL INTEGRATION)
    
    /// Clock in at ANY building - now with QuickBooks-ready tracking
    public func clockIn(workerId: CoreTypes.WorkerID, building: NamedCoordinate, location: CLLocationCoordinate2D? = nil) async throws {
        guard activeSessions[workerId] == nil else {
            throw ClockInError.alreadyClockedIn
        }

        let session = ClockInSession(
            workerId: workerId,
            buildingId: building.id,
            buildingName: building.name,
            startTime: Date(),
            location: location
        )
        
        // Create database entry for QuickBooks export
        do {
            try await createTimeClockEntry(session: session)
            activeSessions[workerId] = session
            
            print("✅ Worker \(workerId) clocked IN at \(building.name)")
            
            // Notify DashboardSyncService
            await notifyDashboardSync(
                workerId: workerId,
                buildingId: building.id,
                buildingName: building.name,
                isClockedIn: true
            )
            
            // Post UI notification
            await postClockInNotification(
                workerId: workerId,
                buildingId: building.id,
                buildingName: building.name,
                isClockedIn: true
            )
            
        } catch {
            throw ClockInError.databaseError(error.localizedDescription)
        }
    }

    /// Clock out - updates database for payroll export
    public func clockOut(workerId: CoreTypes.WorkerID) async throws {
        guard let session = activeSessions[workerId] else {
            throw ClockInError.notClockedIn
        }

        let clockOutTime = Date()
        
        do {
            // Update database entry with clock out time
            try await updateTimeClockEntry(
                sessionId: session.id,
                clockOutTime: clockOutTime
            )
            
            activeSessions.removeValue(forKey: workerId)
            
            print("✅ Worker \(workerId) clocked OUT from \(session.buildingName)")
            
            // Calculate hours worked for immediate feedback
            let hoursWorked = clockOutTime.timeIntervalSince(session.startTime) / 3600.0
            print("   Hours worked: \(String(format: "%.2f", hoursWorked))")
            
            // Notify DashboardSyncService
            await notifyDashboardSync(
                workerId: workerId,
                buildingId: session.buildingId,
                buildingName: session.buildingName,
                isClockedIn: false
            )
            
            // Post UI notification with hours worked
            await postClockOutNotification(
                workerId: workerId,
                buildingId: session.buildingId,
                hoursWorked: hoursWorked
            )
            
        } catch {
            throw ClockInError.databaseError(error.localizedDescription)
        }
    }
    
    // MARK: - Query Methods
    
    /// Get current clock-in status for a worker
    public func getClockInStatus(for workerId: CoreTypes.WorkerID) -> (isClockedIn: Bool, building: NamedCoordinate?) {
        if let session = activeSessions[workerId] {
            let building = NamedCoordinate(
                id: session.buildingId,
                name: session.buildingName,
                address: "", // We don't store address in session
                latitude: session.location?.latitude ?? 0,
                longitude: session.location?.longitude ?? 0
            )
            return (true, building)
        }
        return (false, nil)
    }
    
    /// Get all active sessions
    public func getAllActiveSessions() -> [ClockInSession] {
        Array(activeSessions.values)
    }
    
    /// Get worker's time entries for a date range (for payroll integration)
    /// Returns TimeClockEntry objects that are compatible with QuickBooksPayrollExporter
    public func getTimeEntries(for workerId: CoreTypes.WorkerID, from startDate: Date, to endDate: Date) async throws -> [Any] {
        let dateFormatter = ISO8601DateFormatter()
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        let rows = try await grdbManager.query("""
            SELECT id, workerId, clockInTime, clockOutTime, buildingId, buildingName, notes
            FROM time_clock_entries
            WHERE workerId = ? 
            AND date(clockInTime) >= date(?) 
            AND date(clockInTime) <= date(?)
            ORDER BY clockInTime DESC
        """, [workerId, startDateString, endDateString])
        
        // Return raw data for compatibility with PayrollExporter
        return rows
    }
    
    // MARK: - Database Integration (QuickBooks-Ready)
    
    private func ensureDatabaseSchema() async {
        do {
            // Create time_clock_entries table if not exists
            try await grdbManager.execute("""
                CREATE TABLE IF NOT EXISTS time_clock_entries (
                    id TEXT PRIMARY KEY,
                    workerId TEXT NOT NULL,
                    clockInTime TEXT NOT NULL,
                    clockOutTime TEXT,
                    buildingId TEXT NOT NULL,
                    buildingName TEXT NOT NULL,
                    locationLat REAL,
                    locationLon REAL,
                    notes TEXT,
                    exported BOOLEAN DEFAULT 0,
                    exportDate TEXT,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (workerId) REFERENCES workers(id)
                )
            """, [])
            
            // Create index for faster queries
            try await grdbManager.execute("""
                CREATE INDEX IF NOT EXISTS idx_time_entries_worker_date 
                ON time_clock_entries(workerId, clockInTime)
            """, [])
            
            print("✅ Clock-in database schema verified")
            
        } catch {
            print("❌ Failed to ensure database schema: \(error)")
        }
    }
    
    private func loadActiveSessions() async {
        do {
            // Load any sessions without clock-out time (active sessions)
            let rows = try await grdbManager.query("""
                SELECT id, workerId, clockInTime, buildingId, buildingName, locationLat, locationLon
                FROM time_clock_entries
                WHERE clockOutTime IS NULL
                AND date(clockInTime) = date('now')
            """, [])
            
            let dateFormatter = ISO8601DateFormatter()
            
            for row in rows {
                guard let _ = row["id"] as? String,
                      let workerId = row["workerId"] as? String,
                      let clockInString = row["clockInTime"] as? String,
                      let clockInTime = dateFormatter.date(from: clockInString),
                      let buildingId = row["buildingId"] as? String,
                      let buildingName = row["buildingName"] as? String else {
                    continue
                }
                
                let location: CLLocationCoordinate2D?
                if let lat = row["locationLat"] as? Double,
                   let lon = row["locationLon"] as? Double {
                    location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                } else {
                    location = nil
                }
                
                let session = ClockInSession(
                    workerId: workerId,
                    buildingId: buildingId,
                    buildingName: buildingName,
                    startTime: clockInTime,
                    location: location
                )
                
                activeSessions[workerId] = session
            }
            
            print("✅ Loaded \(activeSessions.count) active sessions")
            
        } catch {
            print("❌ Failed to load active sessions: \(error)")
        }
    }
    
    private func createTimeClockEntry(session: ClockInSession) async throws {
        let dateFormatter = ISO8601DateFormatter()
        
        try await grdbManager.execute("""
            INSERT INTO time_clock_entries 
            (id, workerId, clockInTime, buildingId, buildingName, locationLat, locationLon)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, [
            session.id,
            session.workerId,
            dateFormatter.string(from: session.startTime),
            session.buildingId,
            session.buildingName,
            session.location?.latitude as Any,
            session.location?.longitude as Any
        ])
    }
    
    private func updateTimeClockEntry(sessionId: String, clockOutTime: Date) async throws {
        let dateFormatter = ISO8601DateFormatter()
        
        try await grdbManager.execute("""
            UPDATE time_clock_entries 
            SET clockOutTime = ?
            WHERE id = ?
        """, [
            dateFormatter.string(from: clockOutTime),
            sessionId
        ])
    }
    
    // MARK: - Integration Helpers
    
    @MainActor
    private func notifyDashboardSync(workerId: String, buildingId: String, buildingName: String, isClockedIn: Bool) async {
        if isClockedIn {
            DashboardSyncService.shared.onWorkerClockedIn(
                workerId: workerId,
                buildingId: buildingId,
                buildingName: buildingName
            )
        } else {
            DashboardSyncService.shared.onWorkerClockedOut(
                workerId: workerId,
                buildingId: buildingId
            )
        }
        
        // Create detailed dashboard update using the correct broadcast method
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: isClockedIn ? .workerClockedIn : .workerClockedOut,
            buildingId: buildingId,
            workerId: workerId,
            data: [
                "buildingName": buildingName,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "action": isClockedIn ? "clockIn" : "clockOut"
            ]
        )
        
        // Use the correct broadcast method for worker updates
        DashboardSyncService.shared.broadcastWorkerUpdate(update)
    }
    
    @MainActor
    private func postClockInNotification(workerId: String, buildingId: String, buildingName: String, isClockedIn: Bool) async {
        NotificationCenter.default.post(
            name: .workerClockInChanged,
            object: nil,
            userInfo: [
                "workerId": workerId,
                "isClockedIn": isClockedIn,
                "buildingId": buildingId,
                "buildingName": buildingName
            ]
        )
    }
    
    @MainActor
    private func postClockOutNotification(workerId: String, buildingId: String, hoursWorked: Double) async {
        NotificationCenter.default.post(
            name: .workerClockInChanged,
            object: nil,
            userInfo: [
                "workerId": workerId,
                "isClockedIn": false,
                "buildingId": buildingId,
                "hoursWorked": hoursWorked
            ]
        )
    }
    
    // MARK: - Payroll Integration Helpers
    
    /// Get summary of hours worked for payroll period
    /// Uses PayPeriod type from QuickBooksPayrollExporter
    public func getPayrollSummary(for workerId: CoreTypes.WorkerID, startDate: Date, endDate: Date) async throws -> WorkerHoursSummary {
        let dateFormatter = ISO8601DateFormatter()
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        let rows = try await grdbManager.query("""
            SELECT id, clockInTime, clockOutTime
            FROM time_clock_entries
            WHERE workerId = ? 
            AND date(clockInTime) >= date(?) 
            AND date(clockInTime) <= date(?)
            AND clockOutTime IS NOT NULL
            ORDER BY clockInTime
        """, [workerId, startDateString, endDateString])
        
        var totalHours: Double = 0
        var totalDays = Set<String>()
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "yyyy-MM-dd"
        
        for row in rows {
            if let clockInString = row["clockInTime"] as? String,
               let clockOutString = row["clockOutTime"] as? String,
               let clockIn = dateFormatter.date(from: clockInString),
               let clockOut = dateFormatter.date(from: clockOutString) {
                
                let hours = clockOut.timeIntervalSince(clockIn) / 3600.0
                totalHours += hours
                totalDays.insert(dayFormatter.string(from: clockIn))
            }
        }
        
        return WorkerHoursSummary(
            workerId: workerId,
            totalHours: totalHours,
            daysWorked: totalDays.count,
            entryCount: rows.count
        )
    }
    
    /// Mark entries as exported to QuickBooks
    public func markEntriesAsExported(_ entryIds: [String], exportDate: Date) async throws {
        let dateFormatter = ISO8601DateFormatter()
        let exportDateString = dateFormatter.string(from: exportDate)
        
        for entryId in entryIds {
            try await grdbManager.execute("""
                UPDATE time_clock_entries 
                SET exported = 1, exportDate = ?
                WHERE id = ?
            """, [exportDateString, entryId])
        }
    }
}

// MARK: - Supporting Types

public struct WorkerHoursSummary {
    public let workerId: String
    public let totalHours: Double
    public let daysWorked: Int
    public let entryCount: Int
}

// MARK: - Notification Names

// Notification.Name extension is in ClockInService.swift

// MARK: - SwiftUI Integration

extension ClockInManager {
    /// Convenience method for SwiftUI views
    @MainActor
    public func clockInOut(workerId: CoreTypes.WorkerID, building: NamedCoordinate) async throws {
        let status = await getClockInStatus(for: workerId)
        
        if status.isClockedIn {
            try await clockOut(workerId: workerId)
        } else {
            try await clockIn(workerId: workerId, building: building)
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension ClockInManager {
    /// Clear all active sessions (for testing)
    public func clearAllSessions() {
        activeSessions.removeAll()
        print("🧹 Cleared all clock-in sessions")
    }
    
    /// Print current state
    public func printCurrentState() {
        print("📍 Clock-In Manager State:")
        print("   Active Sessions: \(activeSessions.count)")
        for (workerId, session) in activeSessions {
            print("   - Worker \(workerId): \(session.buildingName) since \(session.startTime)")
        }
    }
    
    /// Generate test data for payroll testing
    public func generateTestTimeEntries(for workerId: String, days: Int) async throws {
        let calendar = Calendar.current
        let now = Date()
        
        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            
            // Morning shift
            let clockIn = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date)!
            let clockOut = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: date)!
            
            let sessionId = UUID().uuidString
            let dateFormatter = ISO8601DateFormatter()
            
            try await grdbManager.execute("""
                INSERT INTO time_clock_entries 
                (id, workerId, clockInTime, clockOutTime, buildingId, buildingName)
                VALUES (?, ?, ?, ?, ?, ?)
            """, [
                sessionId,
                workerId,
                dateFormatter.string(from: clockIn),
                dateFormatter.string(from: clockOut),
                "14", // Rubin Museum
                "Rubin Museum"
            ])
        }
        
        print("✅ Generated \(days) days of test time entries for worker \(workerId)")
    }
}
#endif
