//
//  V003_WorkerAssignments.swift
//  CyntientOps
//
//  ✅ FIXED: Uses GRDBManager instead of GRDBManager
//  ✅ FIXED: Added explicit type annotations for query results
//  ✅ FIXED: Uses correct async/await patterns for GRDB
//  ✅ V6.0: GRDB Migration - Updated for GRDB-powered database
//  ✅ Maintains Edwin's exact building assignments from CSV
//  ✅ Enhanced error handling and validation
//

import Foundation
import GRDB

struct V003_WorkerAssignments {
    
    func run() async throws {
        logInfo("🔄 Starting V003_WorkerAssignments migration with GRDB...")
        
        // ✅ FIXED: Use GRDBManager instead of GRDBManager
        let manager = GRDBManager.shared
        
        // Create worker_assignments table with enhanced schema
        try await manager.execute("""
            CREATE TABLE IF NOT EXISTS worker_assignments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id INTEGER NOT NULL,
                building_id TEXT NOT NULL,
                worker_name TEXT NOT NULL,
                is_active INTEGER DEFAULT 1,
                assigned_date TEXT DEFAULT CURRENT_TIMESTAMP,
                is_primary INTEGER DEFAULT 0,
                UNIQUE(worker_id, building_id)
            );
        """)
        
        // Create indexes for performance
        try await manager.execute("""
            CREATE INDEX IF NOT EXISTS idx_worker_assignments_worker 
            ON worker_assignments(worker_id, is_active);
        """)
        
        try await manager.execute("""
            CREATE INDEX IF NOT EXISTS idx_worker_assignments_building 
            ON worker_assignments(building_id, is_active);
        """)
        
        // Edwin's exact buildings from CSV (Worker ID 2 for Edwin Lema)
        let edwinAssignments = [
            (workerId: 2, buildingId: "15", workerName: "Edwin Lema", isPrimary: true),   // Stuyvesant Cove Park
            (workerId: 2, buildingId: "13", workerName: "Edwin Lema", isPrimary: false), // 133 East 15th Street
            (workerId: 2, buildingId: "5", workerName: "Edwin Lema", isPrimary: false),  // 131 Perry Street
            (workerId: 2, buildingId: "7", workerName: "Edwin Lema", isPrimary: false),  // 136 West 17th Street
            (workerId: 2, buildingId: "8", workerName: "Edwin Lema", isPrimary: false),  // 138 West 17th Street
            (workerId: 2, buildingId: "9", workerName: "Edwin Lema", isPrimary: false),  // 135-139 West 17th Street
            (workerId: 2, buildingId: "10", workerName: "Edwin Lema", isPrimary: false), // 117 West 17th Street
            (workerId: 2, buildingId: "1", workerName: "Edwin Lema", isPrimary: false)   // 12 West 18th Street
        ]
        
        // Kevin's assignments (Worker ID 4 for Kevin Dutan)
        let kevinAssignments = [
            (workerId: 4, buildingId: "14", workerName: "Kevin Dutan", isPrimary: true),  // Rubin Museum
            (workerId: 4, buildingId: "5", workerName: "Kevin Dutan", isPrimary: false),  // 131 Perry Street
            (workerId: 4, buildingId: "6", workerName: "Kevin Dutan", isPrimary: false),  // 68 Perry Street
            (workerId: 4, buildingId: "7", workerName: "Kevin Dutan", isPrimary: false),  // 136 West 17th Street
            (workerId: 4, buildingId: "8", workerName: "Kevin Dutan", isPrimary: false),  // 138 West 17th Street
            (workerId: 4, buildingId: "9", workerName: "Kevin Dutan", isPrimary: false),  // 135-139 West 17th Street
            (workerId: 4, buildingId: "12", workerName: "Kevin Dutan", isPrimary: false), // 178 Spring Street
            (workerId: 4, buildingId: "16", workerName: "Kevin Dutan", isPrimary: false)  // 29-31 East 20th Street
        ]
        
        // Other workers' assignments for completeness
        let otherAssignments = [
            // Greg Hutson (Worker ID 1)
            (workerId: 1, buildingId: "1", workerName: "Greg Hutson", isPrimary: true),   // 12 West 18th Street
            (workerId: 1, buildingId: "2", workerName: "Greg Hutson", isPrimary: false),  // 29-31 East 20th Street
            (workerId: 1, buildingId: "3", workerName: "Greg Hutson", isPrimary: false),  // 36 Walker Street
            
            // Mercedes Inamagua (Worker ID 5)
            (workerId: 5, buildingId: "20", workerName: "Mercedes Inamagua", isPrimary: true),  // CyntientOps HQ - Evening shift
            (workerId: 5, buildingId: "14", workerName: "Mercedes Inamagua", isPrimary: false), // Rubin Museum - Roof drain
            (workerId: 5, buildingId: "11", workerName: "Mercedes Inamagua", isPrimary: false), // 112 West 18th Street
            (workerId: 5, buildingId: "13", workerName: "Mercedes Inamagua", isPrimary: false), // 133 East 15th Street
            (workerId: 5, buildingId: "17", workerName: "Mercedes Inamagua", isPrimary: false), // 178 Spring Street Alt
            
            // Luis Lopez (Worker ID 6)
            (workerId: 6, buildingId: "3", workerName: "Luis Lopez", isPrimary: true),   // 36 Walker Street
            (workerId: 6, buildingId: "4", workerName: "Luis Lopez", isPrimary: false),  // 41 Elizabeth Street
            (workerId: 6, buildingId: "12", workerName: "Luis Lopez", isPrimary: false), // 178 Spring Street
            
            // Angel Guirachocha (Worker ID 7)
            (workerId: 7, buildingId: "4", workerName: "Angel Guirachocha", isPrimary: true),  // 41 Elizabeth Street
            (workerId: 7, buildingId: "11", workerName: "Angel Guirachocha", isPrimary: false), // 112 West 18th Street
            (workerId: 7, buildingId: "16", workerName: "Angel Guirachocha", isPrimary: false), // 29-31 East 20th Street
            (workerId: 7, buildingId: "18", workerName: "Angel Guirachocha", isPrimary: false), // Additional Building
            
            // Shawn Magloire (Worker ID 8) - Admin oversight
            (workerId: 8, buildingId: "1", workerName: "Shawn Magloire", isPrimary: false),  // 12 West 18th Street
            (workerId: 8, buildingId: "14", workerName: "Shawn Magloire", isPrimary: false), // Rubin Museum
            (workerId: 8, buildingId: "15", workerName: "Shawn Magloire", isPrimary: false), // Stuyvesant Cove Park
            (workerId: 8, buildingId: "7", workerName: "Shawn Magloire", isPrimary: false)   // 136 West 17th Street
        ]
        
        // Combine all assignments
        let allAssignments = edwinAssignments + kevinAssignments + otherAssignments
        
        logInfo("📊 Inserting \(allAssignments.count) worker assignments...")
        
        // Insert all assignments with GRDB-compatible parameter binding
        for assignment in allAssignments {
            try await manager.execute("""
                INSERT OR IGNORE INTO worker_assignments 
                (worker_id, building_id, worker_name, is_active, is_primary, assigned_date) 
                VALUES (?, ?, ?, ?, ?, ?)
            """, [
                assignment.workerId,
                assignment.buildingId,
                assignment.workerName,
                1, // is_active
                assignment.isPrimary ? 1 : 0,
                ISO8601DateFormatter().string(from: Date())
            ])
        }
        
        // Verify Edwin's assignments were created
        let edwinCheck: [[String: Any]] = try await manager.query("""
            SELECT COUNT(*) as count FROM worker_assignments 
            WHERE worker_id = 2 AND is_active = 1
        """)
        
        // ✅ FIXED: Explicit type annotation for count
        let edwinCount: Int64 = edwinCheck.first?["count"] as? Int64 ?? 0
        logInfo("✅ Edwin has \(edwinCount) building assignments")
        
        // Verify Kevin's assignments were created
        let kevinCheck: [[String: Any]] = try await manager.query("""
            SELECT COUNT(*) as count FROM worker_assignments 
            WHERE worker_id = 4 AND is_active = 1
        """)
        
        // ✅ FIXED: Explicit type annotation for count
        let kevinCount: Int64 = kevinCheck.first?["count"] as? Int64 ?? 0
        logInfo("✅ Kevin has \(kevinCount) building assignments")
        
        // Get total assignment count
        let totalCheck: [[String: Any]] = try await manager.query("""
            SELECT COUNT(*) as count FROM worker_assignments WHERE is_active = 1
        """)
        
        // ✅ FIXED: Explicit type annotation for count
        let totalCount: Int64 = totalCheck.first?["count"] as? Int64 ?? 0
        logInfo("✅ Total active assignments: \(totalCount)")
        
        // Print assignment summary by worker
        let summaryQuery: [[String: Any]] = try await manager.query("""
            SELECT 
                worker_name,
                COUNT(*) as assignment_count,
                SUM(is_primary) as primary_count
            FROM worker_assignments 
            WHERE is_active = 1
            GROUP BY worker_id, worker_name
            ORDER BY worker_name
        """)
        
        logInfo("\n📋 Assignment Summary:")
        for row in summaryQuery {
            let name = row["worker_name"] as? String ?? "Unknown"
            let count = row["assignment_count"] as? Int64 ?? 0
            let primary = row["primary_count"] as? Int64 ?? 0
            logInfo("   \(name): \(count) buildings (\(primary) primary)")
        }
        
        logInfo("\n✅ V003_WorkerAssignments GRDB migration completed successfully!")
    }
}

// MARK: - GRDB-Compatible Extensions

extension V003_WorkerAssignments {
    
    /// Verify the migration worked correctly
    static func verifyMigration() async throws -> Bool {
        // ✅ FIXED: Use GRDBManager instead of GRDBManager
        let manager = GRDBManager.shared
        
        // Check if table exists
        let tableCheck: [[String: Any]] = try await manager.query("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name='worker_assignments'
        """)
        
        guard !tableCheck.isEmpty else {
            logInfo("❌ worker_assignments table not found")
            return false
        }
        
        // Check if Edwin has his assignments
        let edwinCheck: [[String: Any]] = try await manager.query("""
            SELECT building_id, worker_name 
            FROM worker_assignments 
            WHERE worker_id = 2 AND is_active = 1
            ORDER BY building_id
        """)
        
        if edwinCheck.count >= 8 {
            logInfo("✅ Migration verification: Edwin has \(edwinCheck.count) buildings")
            return true
        } else {
            logInfo("⚠️ Migration verification: Edwin only has \(edwinCheck.count) buildings (expected 8)")
            return false
        }
    }
    
    /// Get detailed assignment report
    static func getAssignmentReport() async throws {
        // ✅ FIXED: Use GRDBManager instead of GRDBManager
        let manager = GRDBManager.shared
        
        let report: [[String: Any]] = try await manager.query("""
            SELECT 
                wa.worker_name,
                wa.building_id,
                b.name as building_name,
                wa.is_primary,
                wa.assigned_date
            FROM worker_assignments wa
            LEFT JOIN buildings b ON CAST(wa.building_id AS TEXT) = CAST(b.id AS TEXT)
            WHERE wa.is_active = 1
            ORDER BY wa.worker_name, wa.building_id
        """)
        
        logInfo("\n📊 Detailed Assignment Report:")
        var currentWorker = ""
        
        for row in report {
            let workerName = row["worker_name"] as? String ?? "Unknown"
            let buildingId = row["building_id"] as? String ?? "?"
            let buildingName = row["building_name"] as? String ?? "Unknown Building"
            let isPrimary = (row["is_primary"] as? Int64) == 1
            
            if workerName != currentWorker {
                currentWorker = workerName
                logInfo("\n👤 \(workerName):")
            }
            
            let primaryFlag = isPrimary ? " (PRIMARY)" : ""
            logInfo("   🏢 \(buildingId): \(buildingName)\(primaryFlag)")
        }
        
        logInfo("\n")
    }
    
    /// Quick validation for specific workers
    static func validateWorkerAssignments() async throws {
        let manager = GRDBManager.shared
        
        // Validate Edwin's primary assignment (Stuyvesant Cove Park)
        let edwinPrimary: [[String: Any]] = try await manager.query("""
            SELECT building_id, worker_name FROM worker_assignments 
            WHERE worker_id = 2 AND is_primary = 1 AND is_active = 1
        """)
        
        if let primary = edwinPrimary.first {
            let buildingId = primary["building_id"] as? String ?? "Unknown"
            logInfo("✅ Edwin's primary building: \(buildingId)")
        } else {
            logInfo("⚠️ Edwin has no primary building assignment")
        }
        
        // Validate Kevin's primary assignment (Rubin Museum)
        let kevinPrimary: [[String: Any]] = try await manager.query("""
            SELECT building_id, worker_name FROM worker_assignments 
            WHERE worker_id = 4 AND is_primary = 1 AND is_active = 1
        """)
        
        if let primary = kevinPrimary.first {
            let buildingId = primary["building_id"] as? String ?? "Unknown"
            logInfo("✅ Kevin's primary building: \(buildingId)")
        } else {
            logInfo("⚠️ Kevin has no primary building assignment")
        }
        
        // Validate total assignments
        let totalAssignments: [[String: Any]] = try await manager.query("""
            SELECT COUNT(*) as total FROM worker_assignments WHERE is_active = 1
        """)
        
        if let total = totalAssignments.first?["total"] as? Int64 {
            logInfo("✅ Total active assignments: \(total)")
        }
    }
}

// MARK: - ISO8601 DateFormatter Extension

extension ISO8601DateFormatter {
    static let shared: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
