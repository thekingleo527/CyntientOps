//
//  WorkerRoutineSeeder.swift  
//  CyntientOps v7.0
//
//  Creates EXACT worker routines and schedules for specific workers/locations/clients
//  🎯 REAL DATA: No mock data - actual worker assignments and building schedules
//

import Foundation

struct WorkerRoutineSeeder {
    
    // MARK: - Real Building Data
    private static let buildings: [String: String] = [
        "14": "Rubin Museum (142-148 West 17th Street)",
        "16": "133 East 15th Street", 
        "5": "68 Perry Street",
        "6": "131 Perry Street", 
        "7": "36 Walker Street",
        "20": "112 West 18th Street"
    ]
    
    // MARK: - Exact Worker Building Assignments
    private static let workerAssignments: [String: [String]] = [
        // Kevin Dutan - Rubin Museum specialist
        "4": ["14"], // Rubin Museum only
        
        // Greg Hutson - West Village properties
        "1": ["5", "6"], // 68 Perry Street, 131 Perry Street
        
        // Edwin Lema - Mixed portfolio
        "2": ["16", "7"], // 133 East 15th Street, 36 Walker Street
        
        // Mercedes Inamagua - Evening shift
        "5": ["20"], // 112 West 18th Street
        
        // Luis Lopez - Coverage worker
        "6": ["16", "20"], // 133 East 15th Street, 112 West 18th Street
        
        // Angel Guiracocha - Night/DSNY shift
        "7": ["7", "5"] // 36 Walker Street, 68 Perry Street
    ]
    
    // MARK: - Real Routine Templates by Building Type
    private static func getRoutinesForBuilding(_ buildingId: String, workerId: String) -> [WorkerRoutine] {
        let buildingName = buildings[buildingId] ?? "Unknown Building"
        var routines: [WorkerRoutine] = []
        
        switch buildingId {
        case "14": // Rubin Museum - Kevin Dutan's specialized routines
            routines = [
                WorkerRoutine(
                    id: "\(workerId)_\(buildingId)_museum_opening",
                    workerId: workerId,
                    buildingId: buildingId,
                    buildingName: buildingName,
                    name: "Museum Opening Security Check",
                    description: "Pre-opening security sweep and systems check",
                    rrule: "FREQ=DAILY;BYHOUR=8;BYMINUTE=0", // 8:00 AM daily
                    category: "security",
                    estimatedDuration: 45,
                    isWeatherDependent: false,
                    priority: 3
                ),
                WorkerRoutine(
                    id: "\(workerId)_\(buildingId)_hvac_check",
                    workerId: workerId,
                    buildingId: buildingId,
                    buildingName: buildingName,
                    name: "HVAC Gallery Climate Control",
                    description: "Monitor and adjust gallery climate systems",
                    rrule: "FREQ=DAILY;BYHOUR=10,14,16;BYMINUTE=0", // 10 AM, 2 PM, 4 PM
                    category: "hvac",
                    estimatedDuration: 30,
                    isWeatherDependent: false,
                    priority: 2
                ),
                WorkerRoutine(
                    id: "\(workerId)_\(buildingId)_visitor_area_clean",
                    workerId: workerId,
                    buildingId: buildingId,
                    buildingName: buildingName,
                    name: "Visitor Area Sanitation",
                    description: "Clean and sanitize public areas and restrooms",
                    rrule: "FREQ=DAILY;BYHOUR=12,15,17;BYMINUTE=30", // 12:30, 3:30, 5:30 PM
                    category: "sanitation",
                    estimatedDuration: 60,
                    isWeatherDependent: false,
                    priority: 1
                )
            ]
            
        case "5", "6": // Perry Street buildings - Residential
            routines = [
                WorkerRoutine(
                    id: "\(workerId)_\(buildingId)_morning_inspect",
                    workerId: workerId,
                    buildingId: buildingId,
                    buildingName: buildingName,
                    name: "Morning Building Inspection",
                    description: "Daily building safety and maintenance check",
                    rrule: "FREQ=DAILY;BYHOUR=9;BYMINUTE=0", // 9:00 AM daily
                    category: "inspection",
                    estimatedDuration: 30,
                    isWeatherDependent: false,
                    priority: 2
                ),
                WorkerRoutine(
                    id: "\(workerId)_\(buildingId)_trash_collect",
                    workerId: workerId,
                    buildingId: buildingId,
                    buildingName: buildingName,
                    name: "Trash Collection & Disposal",
                    description: "Collect and dispose of building waste",
                    rrule: "FREQ=WEEKLY;BYDAY=MO,WE,FR;BYHOUR=7;BYMINUTE=0", // Mon/Wed/Fri 7 AM
                    category: "sanitation",
                    estimatedDuration: 45,
                    isWeatherDependent: true,
                    priority: 1
                )
            ]
            
        case "16": // 133 East 15th Street - Mixed commercial/residential
            routines = [
                WorkerRoutine(
                    id: "\(workerId)_\(buildingId)_lobby_maintain",
                    workerId: workerId,
                    buildingId: buildingId,
                    buildingName: buildingName,
                    name: "Lobby Maintenance",
                    description: "Clean and maintain lobby and entrance areas",
                    rrule: "FREQ=DAILY;BYHOUR=8,13,17;BYMINUTE=0", // 8 AM, 1 PM, 5 PM
                    category: "maintenance",
                    estimatedDuration: 25,
                    isWeatherDependent: false,
                    priority: 2
                ),
                WorkerRoutine(
                    id: "\(workerId)_\(buildingId)_elevator_inspect",
                    workerId: workerId,
                    buildingId: buildingId,
                    buildingName: buildingName,
                    name: "Elevator Safety Check",
                    description: "Daily elevator operation and safety inspection",
                    rrule: "FREQ=DAILY;BYHOUR=11;BYMINUTE=0", // 11:00 AM daily
                    category: "safety",
                    estimatedDuration: 20,
                    isWeatherDependent: false,
                    priority: 3
                )
            ]
            
        default:
            // Generic building routines
            routines = [
                WorkerRoutine(
                    id: "\(workerId)_\(buildingId)_general_inspect",
                    workerId: workerId,
                    buildingId: buildingId,
                    buildingName: buildingName,
                    name: "General Building Inspection",
                    description: "Standard building inspection and maintenance",
                    rrule: "FREQ=DAILY;BYHOUR=9;BYMINUTE=0", // 9:00 AM daily
                    category: "inspection",
                    estimatedDuration: 30,
                    isWeatherDependent: false,
                    priority: 2
                )
            ]
        }
        
        return routines
    }
    
    // MARK: - Generate All Worker Routines
    static func generateAllWorkerRoutines() -> [WorkerRoutine] {
        var allRoutines: [WorkerRoutine] = []
        
        for (workerId, buildingIds) in workerAssignments {
            for buildingId in buildingIds {
                let routines = getRoutinesForBuilding(buildingId, workerId: workerId)
                allRoutines.append(contentsOf: routines)
            }
        }
        
        print("📋 Generated \(allRoutines.count) exact worker routines for \(workerAssignments.count) workers")
        return allRoutines
    }
    
    // MARK: - Create SQL Insert Statements
    static func generateInsertSQL() -> [String] {
        let routines = generateAllWorkerRoutines()
        var sqlStatements: [String] = []
        
        // First create the table if it doesn't exist
        sqlStatements.append("""
            CREATE TABLE IF NOT EXISTS worker_routines (
                id TEXT PRIMARY KEY,
                worker_id TEXT NOT NULL,
                building_id TEXT NOT NULL, 
                building_name TEXT NOT NULL,
                name TEXT NOT NULL,
                description TEXT,
                rrule TEXT NOT NULL,
                category TEXT NOT NULL,
                estimated_duration INTEGER NOT NULL,
                is_weather_dependent INTEGER NOT NULL,
                priority INTEGER NOT NULL,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT DEFAULT CURRENT_TIMESTAMP
            );
        """)
        
        // Insert each routine
        for routine in routines {
            let sql = """
                INSERT OR REPLACE INTO worker_routines 
                (id, worker_id, building_id, building_name, name, description, rrule, category, estimated_duration, is_weather_dependent, priority, created_at, updated_at)
                VALUES 
                ('\(routine.id)', '\(routine.workerId)', '\(routine.buildingId)', '\(routine.buildingName)', '\(routine.name)', '\(routine.description)', '\(routine.rrule)', '\(routine.category)', \(routine.estimatedDuration), \(routine.isWeatherDependent ? 1 : 0), \(routine.priority), datetime('now'), datetime('now'));
            """
            sqlStatements.append(sql)
        }
        
        return sqlStatements
    }
}

// MARK: - WorkerRoutine Data Structure
struct WorkerRoutine {
    let id: String
    let workerId: String
    let buildingId: String
    let buildingName: String
    let name: String
    let description: String
    let rrule: String // RFC 5545 recurrence rule
    let category: String
    let estimatedDuration: Int // minutes
    let isWeatherDependent: Bool
    let priority: Int // 1=high, 2=medium, 3=low
}

// MARK: - Main Execution

print("🏗️ STARTING EXACT WORKER ROUTINE SEEDER")
print("=" + String(repeating: "=", count: 50))

// Generate the routines
let routines = WorkerRoutineSeeder.generateAllWorkerRoutines()

print("\n📊 ROUTINE BREAKDOWN:")
for routine in routines {
    print("✅ \(routine.workerId) → \(routine.buildingName): \(routine.name)")
}

print("\n💾 SQL STATEMENTS:")
let sqlStatements = WorkerRoutineSeeder.generateInsertSQL()
for sql in sqlStatements {
    print(sql)
    print("") // Empty line for readability
}

print("🎯 EXACT WORKER ROUTINE SEEDER COMPLETE")
print("Copy the SQL statements above to populate your database")
print("=" + String(repeating: "=", count: 50))