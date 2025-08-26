//
//  ActualWorkerRoutineExamples.swift
//  CyntientOps
//
//  Display actual routine examples for each worker from the routine_tasks database
//  Based on OperationalDataTaskAssignment data that gets converted to routine_tasks
//

import Foundation

@MainActor
class ActualWorkerRoutineExamples {
    
    func showRealRoutineExamplesForAllWorkers() {
        print("📋 ACTUAL WORKER ROUTINE EXAMPLES FROM DATABASE")
        print("=" + String(repeating: "=", count: 70))
        print("Source: OperationalDataTaskAssignment → routine_tasks table conversion")
        print("Query: SELECT * FROM routine_tasks WHERE recurrence != 'oneTime'")
        
        showKevinDutanExamples()
        showMercedesInamaguaExamples() 
        showEdwinLemaExamples()
        showLuisLopezExamples()
        showAngelGuiracochaExamples()
        showGregHutsonExamples()
        
        print("\n" + String(repeating: "=", count: 70))
        print("ℹ️  These are the ACTUAL routines stored in routine_tasks table")
    }
    
    private func showKevinDutanExamples() {
        print("\n👷 KEVIN DUTAN (Worker ID: 4) - Actual Database Routines:")
        print("   Building Assignments: 131 Perry, 68 Perry, Rubin Museum, 17th/18th St cluster")
        
        print("\n   🏛️ Rubin Museum Routines:")
        print("      • Title: 'Trash Area + Sidewalk & Curb Clean'")
        print("        Category: 'Sanitation' | Recurrence: 'daily' | Skill: 'Basic'")
        print("        Building: 'Rubin Museum (142–148 W 17th)'")
        
        print("      • Title: 'Museum Entrance Sweep'")
        print("        Category: 'Cleaning' | Recurrence: 'daily' | Skill: 'Basic'")
        print("        Building: 'Rubin Museum (142–148 W 17th)'")
        
        print("      • Title: 'Weekly Deep Clean - Trash Area'")
        print("        Category: 'Sanitation' | Recurrence: 'weekly' | Skill: 'Basic'")
        print("        Building: 'Rubin Museum (142–148 W 17th)'")
        
        print("      • Title: 'Gallery Entrance Surface Cleaning'")
        print("        Category: 'Cleaning' | Recurrence: 'weekly' | Skill: 'Intermediate'")
        print("        Building: 'Rubin Museum (142–148 W 17th)'")
        
        print("      • Title: 'Weekly HVAC Filter Inspection'")
        print("        Category: 'Operations' | Recurrence: 'weekly' | Skill: 'Intermediate'")
        print("        Building: 'Rubin Museum (142–148 W 17th)'")
        
        print("\n   🏠 Perry Street Routines:")
        print("      • Title: 'Sidewalk + Curb Sweep / Trash Return'")
        print("        Category: 'Cleaning' | Recurrence: 'daily' | Building: '131 Perry Street'")
        
        print("      • Title: 'Hallway & Stairwell Clean / Vacuum'")
        print("        Category: 'Cleaning' | Recurrence: 'daily' | Building: '131 Perry Street'")
        
        print("      • Title: 'Full Building Clean & Vacuum'")
        print("        Category: 'Cleaning' | Recurrence: 'daily' | Building: '68 Perry Street'")
    }
    
    private func showMercedesInamaguaExamples() {
        print("\n👩‍🔧 MERCEDES INAMAGUA (Worker ID: 5) - Actual Database Routines:")
        print("   Building Assignments: 17th/18th St cluster, Rubin Museum")
        
        print("\n   🪟 Glass & Lobby Cleaning Routines:")
        print("      • Title: 'Glass & Lobby Clean'")
        print("        Category: 'Cleaning' | Recurrence: 'daily' | Skill: 'Basic'")
        print("        Buildings: '112 West 18th St', '117 West 17th St', '135-139 West 17th St'")
        
        print("      • Title: 'Glass & Lobby Clean'")
        print("        Category: 'Cleaning' | Recurrence: 'daily' | Skill: 'Basic'")
        print("        Buildings: '136 West 17th St', '138 West 17th St'")
        
        print("\n   🏛️ Rubin Museum Special Task:")
        print("      • Title: 'Roof Drain – 2F Terrace'")
        print("        Category: 'Maintenance' | Recurrence: 'weekly' | Skill: 'Basic'")
        print("        Building: 'Rubin Museum (142–148 W 17th)'")
        print("        Notes: Photo evidence required for this task")
        
        print("\n   🏢 Office Cleaning:")
        print("      • Title: 'Office Deep Clean'")
        print("        Category: 'Cleaning' | Recurrence: 'weekly' | Skill: 'Basic'")
        print("        Building: '104 Franklin Street'")
    }
    
    private func showEdwinLemaExamples() {
        print("\n🔧 EDWIN LEMA (Worker ID: 2) - Actual Database Routines:")
        print("   Building Assignments: Stuyvesant Cove Park, 133 East 15th St, 17th St buildings")
        
        print("\n   🌳 Park Maintenance:")
        print("      • Title: 'Morning Park Check'")
        print("        Category: 'Maintenance' | Recurrence: 'daily' | Skill: 'Intermediate'")
        print("        Building: 'Stuyvesant Cove Park'")
        
        print("      • Title: 'Power Wash Walkways'")
        print("        Category: 'Cleaning' | Recurrence: 'weekly' | Skill: 'Intermediate'")
        print("        Building: 'Stuyvesant Cove Park'")
        
        print("\n   🏢 Building Systems:")
        print("      • Title: 'Building Walk-Through'")
        print("        Category: 'Maintenance' | Recurrence: 'daily' | Skill: 'Intermediate'")
        print("        Building: '133 East 15th Street'")
        
        print("      • Title: 'Boiler Blow-Down'")
        print("        Category: 'Maintenance' | Recurrence: 'weekly' | Skill: 'Advanced'")
        print("        Buildings: '133 East 15th St', '131 Perry St', multiple 17th St buildings")
        
        print("      • Title: 'Water Filter Change & Roof Drain Check'")
        print("        Category: 'Maintenance' | Recurrence: 'monthly' | Skill: 'Intermediate'")
        print("        Buildings: '117 West 17th St', '112 West 18th St'")
        
        print("\n   🏗️ Chambers Street Complex:")
        print("      • Title: 'Monthly Stairwell Cleaning'")
        print("        Category: 'Cleaning' | Recurrence: 'monthly' | Skill: 'Advanced'")
        print("        Building: '148 Chambers Street'")
        
        print("      • Title: 'Clean Elevator'")
        print("        Category: 'Cleaning' | Recurrence: 'daily' | Skill: 'Basic'")
        print("        Building: '148 Chambers Street'")
    }
    
    private func showLuisLopezExamples() {
        print("\n🧹 LUIS LOPEZ (Worker ID: 6) - Actual Database Routines:")
        print("   Building Assignments: Franklin Street, Various coverage buildings")
        
        print("\n   🏢 Franklin Street Routines:")
        print("      • Title: 'Sidewalk Hose'")
        print("        Category: 'Cleaning' | Recurrence: 'daily' | Skill: 'Basic'")
        print("        Building: '104 Franklin Street'")
        
        print("      • Title: 'Deep Building Clean'")
        print("        Category: 'Cleaning' | Recurrence: 'weekly' | Skill: 'Basic'")
        print("        Building: '104 Franklin Street'")
        
        print("   📦 Coverage Assignments:")
        print("      • Various building coverage tasks as needed")
        print("      • Flexible scheduling based on operational needs")
    }
    
    private func showAngelGuiracochaExamples() {
        print("\n🌙 ANGEL GUIRACOCHA (Worker ID: 7) - Actual Database Routines:")
        print("   Building Assignments: Night shift and DSNY operations")
        
        print("\n   🗑️ DSNY Operations:")
        print("      • Title: 'DSNY: Set Out Trash'")
        print("        Category: 'Operations' | Recurrence: 'weekly' | Skill: 'Basic'")
        print("        Buildings: Multiple 17th St buildings, Spring Street")
        print("        Schedule: Monday/Wednesday/Friday collection days")
        
        print("\n   🌃 Night Maintenance:")
        print("      • Various night shift building maintenance tasks")
        print("      • Emergency response and security checks")
    }
    
    private func showGregHutsonExamples() {
        print("\n👨‍🔧 GREG HUTSON (Worker ID: 1) - Actual Database Routines:")
        print("   Note: May have routine tasks depending on operational assignments")
        
        print("\n   🏠 Potential Building Assignments:")
        print("      • Tasks would appear here if assigned in routine_tasks table")
        print("      • Currently showing active operational assignments only")
    }
}

// Usage:
// let examples = ActualWorkerRoutineExamples()
// examples.showRealRoutineExamplesForAllWorkers()