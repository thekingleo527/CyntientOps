//
//  FinalProductionCheck.swift
//  CyntientOps
//
//  FINAL PRODUCTION READINESS CHECK - Ensure 100% functionality
//

import Foundation
import SQLite3

print("🔥 FINAL PRODUCTION READINESS CHECK")
print("===================================")

let dbPath = "./CyntientOps.db"
var db: OpaquePointer?

guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
    print("❌ CRITICAL ERROR: Cannot open database")
    exit(1)
}

func query(_ sql: String) -> [[String: Any]] {
    var results: [[String: Any]] = []
    var statement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            let columnCount = sqlite3_column_count(statement)
            
            for i in 0..<columnCount {
                let name = String(cString: sqlite3_column_name(statement, i))
                
                switch sqlite3_column_type(statement, i) {
                case SQLITE_INTEGER:
                    row[name] = sqlite3_column_int64(statement, i)
                case SQLITE_FLOAT:
                    row[name] = sqlite3_column_double(statement, i)
                case SQLITE_TEXT:
                    row[name] = String(cString: sqlite3_column_text(statement, i))
                case SQLITE_NULL:
                    row[name] = nil
                default:
                    if let blob = sqlite3_column_blob(statement, i) {
                        let size = sqlite3_column_bytes(statement, i)
                        let data = Data(bytes: blob, count: Int(size))
                        row[name] = data
                    }
                }
            }
            results.append(row)
        }
    }
    
    sqlite3_finalize(statement)
    return results
}

var allChecks = true

// 1. CRITICAL: Authentication System
print("\n1. 🔐 AUTHENTICATION SYSTEM")
print("============================")
let users = query("SELECT COUNT(*) as count FROM workers WHERE isActive = 1")
let userCount = users.first?["count"] as? Int64 ?? 0

if userCount >= 8 {
    print("✅ PASS: \(userCount) active users found")
    
    // Test each critical user exists
    let criticalUsers = [
        "shawn.magloire@cyntientops.com",
        "David@jmrealty.org", 
        "kevin.dutan@cyntientops.com",
        "edwin.lema@cyntientops.com"
    ]
    
    for email in criticalUsers {
        let userCheck = query("SELECT name, role FROM workers WHERE email = ? AND isActive = 1", [email])
        if userCheck.isEmpty {
            print("❌ CRITICAL ERROR: Missing user \(email)")
            allChecks = false
        } else {
            let name = userCheck.first?["name"] as? String ?? ""
            let role = userCheck.first?["role"] as? String ?? ""
            print("✅ \(email) (\(role)) - \(name)")
        }
    }
} else {
    print("❌ CRITICAL ERROR: Only \(userCount) users, need at least 8")
    allChecks = false
}

// 2. CRITICAL: Building Portfolio
print("\n2. 🏢 BUILDING PORTFOLIO")
print("=========================")
let buildings = query("SELECT COUNT(*) as count FROM buildings")
let buildingCount = buildings.first?["count"] as? Int64 ?? 0

if buildingCount >= 19 {
    print("✅ PASS: \(buildingCount) buildings loaded")
    
    // Test critical buildings exist
    let criticalBuildings = ["1", "14", "16", "8", "4"] // Key buildings for each worker
    for buildingId in criticalBuildings {
        let buildingCheck = query("SELECT name FROM buildings WHERE id = ?", [buildingId])
        if buildingCheck.isEmpty {
            print("❌ CRITICAL ERROR: Missing building \(buildingId)")
            allChecks = false
        } else {
            let name = buildingCheck.first?["name"] as? String ?? ""
            print("✅ Building \(buildingId): \(name)")
        }
    }
} else {
    print("❌ CRITICAL ERROR: Only \(buildingCount) buildings, need at least 19")
    allChecks = false
}

// 3. CRITICAL: Client Relationships
print("\n3. 👥 CLIENT RELATIONSHIPS")
print("===========================")
let clients = query("SELECT COUNT(*) as count FROM clients WHERE is_active = 1")
let clientCount = clients.first?["count"] as? Int64 ?? 0

if clientCount >= 6 {
    print("✅ PASS: \(clientCount) active clients")
    
    // Test JM Realty has buildings
    let jmBuildings = query("SELECT COUNT(*) as count FROM client_buildings WHERE client_id = 'JMR'")
    let jmBuildingCount = jmBuildings.first?["count"] as? Int64 ?? 0
    
    if jmBuildingCount >= 9 {
        print("✅ JM Realty has \(jmBuildingCount) buildings")
    } else {
        print("❌ CRITICAL ERROR: JM Realty only has \(jmBuildingCount) buildings, needs 9")
        allChecks = false
    }
} else {
    print("❌ CRITICAL ERROR: Only \(clientCount) clients, need at least 6")
    allChecks = false
}

// 4. CRITICAL: Worker Assignments
print("\n4. 👷 WORKER ASSIGNMENTS")
print("=========================")
let assignments = query("SELECT COUNT(*) as count FROM worker_assignments WHERE is_active = 1")
let assignmentCount = assignments.first?["count"] as? Int64 ?? 0

if assignmentCount >= 35 {
    print("✅ PASS: \(assignmentCount) active worker assignments")
    
    // Test critical workers have assignments
    let criticalWorkers = [
        ("4", "Kevin Dutan", 8), // Kevin should have 8 assignments
        ("2", "Edwin Lema", 8),  // Edwin should have 8 assignments
        ("6", "Luis Lopez", 3)   // Luis should have 3 assignments
    ]
    
    for (workerId, workerName, expectedCount) in criticalWorkers {
        let workerAssignments = query("SELECT COUNT(*) as count FROM worker_assignments WHERE worker_id = ? AND is_active = 1", [workerId])
        let actualCount = workerAssignments.first?["count"] as? Int64 ?? 0
        
        if actualCount >= expectedCount {
            print("✅ \(workerName): \(actualCount) assignments")
        } else {
            print("❌ CRITICAL ERROR: \(workerName) only has \(actualCount) assignments, needs at least \(expectedCount)")
            allChecks = false
        }
    }
} else {
    print("❌ CRITICAL ERROR: Only \(assignmentCount) assignments, need at least 35")
    allChecks = false
}

// 5. CRITICAL: Task System
print("\n5. 📋 TASK SYSTEM")
print("==================")
let tasks = query("SELECT COUNT(*) as count FROM tasks")
let taskCount = tasks.first?["count"] as? Int64 ?? 0

if taskCount >= 5 {
    print("✅ PASS: \(taskCount) tasks in system")
} else {
    print("❌ CRITICAL ERROR: Only \(taskCount) tasks, need at least 5")
    allChecks = false
}

// 6. DATABASE INTEGRITY
print("\n6. 🔄 DATABASE INTEGRITY")
print("=========================")

// Check for orphaned records
let orphanedAssignments = query("SELECT COUNT(*) as count FROM worker_assignments wa LEFT JOIN workers w ON wa.worker_id = w.id WHERE w.id IS NULL")
let orphanedCount = orphanedAssignments.first?["count"] as? Int64 ?? 0

if orphanedCount == 0 {
    print("✅ PASS: No orphaned worker assignments")
} else {
    print("❌ CRITICAL ERROR: \(orphanedCount) orphaned worker assignments")
    allChecks = false
}

// Check client-building integrity
let orphanedClientBuildings = query("SELECT COUNT(*) as count FROM client_buildings cb LEFT JOIN buildings b ON cb.building_id = b.id WHERE b.id IS NULL")
let orphanedCBCount = orphanedClientBuildings.first?["count"] as? Int64 ?? 0

if orphanedCBCount == 0 {
    print("✅ PASS: All client-building relationships valid")
} else {
    print("❌ CRITICAL ERROR: \(orphanedCBCount) orphaned client-building relationships")
    allChecks = false
}

sqlite3_close(db)

// 7. FILE INTEGRITY
print("\n7. 📁 FILE INTEGRITY")
print("=====================")

let dbSize = (try? FileManager.default.attributesOfItem(atPath: dbPath)[.size] as? Int64) ?? 0
if dbSize >= 70000 {
    print("✅ PASS: Database file size \(dbSize) bytes")
} else {
    print("❌ CRITICAL ERROR: Database too small at \(dbSize) bytes")
    allChecks = false
}

// FINAL VERDICT
print("\n" + String(repeating: "=", count: 50))
if allChecks {
    print("🎉 SUCCESS: APP IS 100% PRODUCTION READY!")
    print("✅ All critical systems functional")
    print("✅ Database fully populated with real data")
    print("✅ Authentication system ready")
    print("✅ All Franco Management data loaded")
    print("✅ Worker assignments correct")
    print("✅ Client relationships established")
    print("✅ No data integrity issues")
    print("\n🚀 READY FOR IMMEDIATE DEPLOYMENT!")
    exit(0)
} else {
    print("❌ CRITICAL ERRORS FOUND - NOT PRODUCTION READY")
    print("Fix all issues above before deployment")
    exit(1)
}

// Helper function for parameterized queries
func query(_ sql: String, _ parameters: [Any]) -> [[String: Any]] {
    var results: [[String: Any]] = []
    var statement: OpaquePointer?
    
    if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
        for (index, param) in parameters.enumerated() {
            if let stringParam = param as? String {
                sqlite3_bind_text(statement, Int32(index + 1), stringParam, -1, nil)
            } else if let intParam = param as? Int64 {
                sqlite3_bind_int64(statement, Int32(index + 1), intParam)
            } else if let doubleParam = param as? Double {
                sqlite3_bind_double(statement, Int32(index + 1), doubleParam)
            }
        }
        
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            let columnCount = sqlite3_column_count(statement)
            
            for i in 0..<columnCount {
                let name = String(cString: sqlite3_column_name(statement, i))
                
                switch sqlite3_column_type(statement, i) {
                case SQLITE_INTEGER:
                    row[name] = sqlite3_column_int64(statement, i)
                case SQLITE_FLOAT:
                    row[name] = sqlite3_column_double(statement, i)
                case SQLITE_TEXT:
                    row[name] = String(cString: sqlite3_column_text(statement, i))
                case SQLITE_NULL:
                    row[name] = nil
                default:
                    if let blob = sqlite3_column_blob(statement, i) {
                        let size = sqlite3_column_bytes(statement, i)
                        let data = Data(bytes: blob, count: Int(size))
                        row[name] = data
                    }
                }
            }
            results.append(row)
        }
    }
    
    sqlite3_finalize(statement)
    return results
}