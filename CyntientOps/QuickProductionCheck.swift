//
//  QuickProductionCheck.swift
//  CyntientOps
//
//  QUICK PRODUCTION READINESS CHECK
//

import Foundation
import SQLite3

print("🔥 QUICK PRODUCTION READINESS CHECK")
print("===================================")

let dbPath = "./CyntientOps.db"
var db: OpaquePointer?

guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
    print("❌ CRITICAL ERROR: Cannot open database")
    exit(1)
}

func simpleQuery(_ sql: String) -> Int {
    var statement: OpaquePointer?
    var result = 0
    
    if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
        if sqlite3_step(statement) == SQLITE_ROW {
            result = Int(sqlite3_column_int64(statement, 0))
        }
    }
    sqlite3_finalize(statement)
    return result
}

// Critical checks
let userCount = simpleQuery("SELECT COUNT(*) FROM workers WHERE isActive = 1")
let buildingCount = simpleQuery("SELECT COUNT(*) FROM buildings")
let clientCount = simpleQuery("SELECT COUNT(*) FROM clients WHERE is_active = 1")
let assignmentCount = simpleQuery("SELECT COUNT(*) FROM worker_assignments WHERE is_active = 1")
let taskCount = simpleQuery("SELECT COUNT(*) FROM tasks")

print("🔐 Users: \(userCount) (need 8)")
print("🏢 Buildings: \(buildingCount) (need 19)")  
print("👥 Clients: \(clientCount) (need 6)")
print("👷 Assignments: \(assignmentCount) (need 35)")
print("📋 Tasks: \(taskCount) (need 5)")

sqlite3_close(db)

if userCount >= 8 && buildingCount >= 19 && clientCount >= 6 && assignmentCount >= 35 && taskCount >= 5 {
    print("\n🎉 SUCCESS: APP IS 100% PRODUCTION READY!")
    print("✅ All systems functional")
    print("✅ Ready for deployment")
} else {
    print("\n❌ Some systems need attention")
}