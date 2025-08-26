//
//  ShowActualWorkerRoutines.swift
//  CyntientOps
//
//  Script to display actual routine examples for each worker from database
//

import Foundation

@MainActor
class ActualWorkerRoutineDisplayer {
    
    func showActualRoutinesForAllWorkers() async {
        print("📋 ACTUAL WORKER ROUTINE EXAMPLES FROM DATABASE")
        print("=" + String(repeating: "=", count: 70))
        
        // This would require access to the actual database
        // For now, let's show what the query structure looks like
        await showQueryStructure()
        await showExpectedDatabaseContent()
        
        print("\n" + String(repeating: "=", count: 70))
        print("ℹ️  Note: Actual results depend on what's in the routine_tasks table")
    }
    
    private func showQueryStructure() async {
        print("\n🔍 DATABASE QUERY STRUCTURE:")
        print("""
        SELECT 
            rt.id,
            rt.title,
            rt.description,
            rt.category,
            rt.estimatedDuration,
            rt.recurrence,
            rt.buildingId,
            b.name as building_name,
            w.name as worker_name
        FROM routine_tasks rt
        JOIN buildings b ON rt.buildingId = b.id
        JOIN workers w ON rt.workerId = w.id  
        WHERE rt.recurrence != 'oneTime'
        ORDER BY w.name, rt.category, rt.title
        """)
    }
    
    private func showExpectedDatabaseContent() async {
        print("\n👷 EXPECTED ROUTINE EXAMPLES (if they exist in database):")
        
        print("\n   🎯 Kevin Dutan (Worker ID: 4):")
        print("      Query: WHERE rt.workerId = '4' AND rt.recurrence != 'oneTime'")
        print("      Expected results (if any routine_tasks exist for Kevin):")
        print("      - Title: [From routine_tasks.title field]")
        print("      - Description: [From routine_tasks.description field]")
        print("      - Building: [From joined buildings.name]")
        print("      - Category: [From routine_tasks.category]")
        print("      - Duration: [From routine_tasks.estimatedDuration] minutes")
        print("      - Recurrence: [From routine_tasks.recurrence]")
        
        print("\n   🏠 Greg Hutson (Worker ID: 1):")
        print("      Query: WHERE rt.workerId = '1' AND rt.recurrence != 'oneTime'")
        print("      Expected results: [Database-dependent]")
        
        print("\n   🏢 Edwin Lema (Worker ID: 2):")
        print("      Query: WHERE rt.workerId = '2' AND rt.recurrence != 'oneTime'")
        print("      Expected results: [Database-dependent]")
        
        print("\n   🌅 Mercedes Inamagua (Worker ID: 5):")
        print("      Query: WHERE rt.workerId = '5' AND rt.recurrence != 'oneTime'")
        print("      Expected results: [Database-dependent]")
        
        print("\n   🔧 Luis Lopez (Worker ID: 6):")
        print("      Query: WHERE rt.workerId = '6' AND rt.recurrence != 'oneTime'")
        print("      Expected results: [Database-dependent]")
        
        print("\n   🌙 Angel Guiracocha (Worker ID: 7):")
        print("      Query: WHERE rt.workerId = '7' AND rt.recurrence != 'oneTime'")
        print("      Expected results: [Database-dependent]")
    }
}

// To see actual routine examples, run this query directly on the database:
// SELECT rt.*, b.name as building_name, w.name as worker_name 
// FROM routine_tasks rt 
// JOIN buildings b ON rt.buildingId = b.id 
// JOIN workers w ON rt.workerId = w.id 
// WHERE rt.recurrence != 'oneTime' 
// ORDER BY w.name, rt.title;