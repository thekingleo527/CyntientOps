// UPDATED: Using centralized TypeRegistry for all types
//
//  WorkerConstants 2.swift
//  CyntientOps
//
//  Created by Shawn Magloire on 6/8/25.
//

// CyntientOps/Constants/WorkerConstants.swift
// Central lookup table with ACTUAL worker schedules from the system
// Using numeric IDs 1-7, 8-10 as Strings

import Foundation
// CyntientOps Types Import
// (This comment helps identify our import)

struct WorkerConstants {
    
    // MARK: - Worker IDs (as Strings)
    static let gregHutson = "1"
    static let edwinLema = "2"
    static let kevinDutan = "4"
    static let mercedesInamagua = "5"
    static let luisLopez = "6"
    static let angelGuirachocha = "7"
    static let shawnWorker = "8"
    static let shawnClient = "9"
    static let shawnAdmin = "10"
    
    // MARK: - Worker Names
    static let workerNames: [String: String] = [
        "1": "Greg Hutson",
        "2": "Edwin Lema",
        "4": "Kevin Dutan",
        "5": "Mercedes Inamagua",
        "6": "Luis Lopez",
        "7": "Angel Guirachocha",
        "8": "Shawn Magloire",
        "9": "Shawn Magloire",
        "10": "Shawn Magloire"
    ]
    
    // MARK: - Worker Emails
    static let workerEmails: [String: String] = [
        "1": "g.hutson1989@gmail.com",
        "2": "edwinlema911@gmail.com",
        "4": "dutankevin1@gmail.com",
        "5": "jneola@gmail.com",
        "6": "luislopez030@yahoo.com",
        "7": "lio.angel71@gmail.com",
        "8": "shawn@francomanagementgroup.com",
        "9": "francosphere@francomanagementgroup.com",
        "10": "shawn@fme-llc.com"
    ]
    
    // MARK: - Worker Roles
    static let workerRoles: [String: String] = [
        "1": "worker",
        "2": "worker",
        "4": "worker",
        "5": "worker",
        "6": "worker",
        "7": "worker",
        "8": "worker",
        "9": "client",
        "10": "admin"
    ]
    
    // MARK: - Worker Skills
    static let workerSkills: [String: [String]] = [
        "1": ["cleaning", "sanitation", "operations", "maintenance"],
        "2": ["painting", "carpentry", "general_maintenance", "landscaping"],
        "4": ["plumbing", "electrical", "hvac", "general_maintenance", "garbage_collection"],
        "5": ["cleaning", "general_maintenance"],
        "6": ["maintenance", "repair", "painting"],
        "7": ["sanitation", "waste_management", "recycling", "evening_garbage"],
        "8": ["management", "inspection"],
        "9": ["client_access"],
        "10": ["all_access", "management", "supervision"]
    ]
    
    // MARK: - Building Assignments
    static let workerBuildingAssignments: [String: [String]] = [
        "1": ["12-west-18th"], // Greg - ONLY 12 West 18th
        "2": ["12-west-18th", "29-31-east-20th", "36-walker", "41-elizabeth", "68-perry"],
        "4": ["117-west-17th", "123-1st-ave", "131-perry", "133-east-15th", 
              "135-west-17th", "136-west-17th", "138-west-17th", 
              "rubin-museum", "stuyvesant-cove"],
        "5": ["117-west-17th", "135-west-17th"],
        "6": ["104-franklin", "112-west-18th"],
        "7": ["12-west-18th"] // Angel - evening garbage at 12 West 18th
    ]
    
    // MARK: - Worker Schedules (CORRECTED WITH REAL DATA)
    static let workerSchedules: [String: [(start: Int, end: Int, days: [Int])]] = [
        "1": [(start: 9, end: 15, days: [1,2,3,4,5])],     // Greg: 9am-3pm Mon-Fri (35 hrs)
        
        "2": [(start: 6, end: 15, days: [1,2,3,4,5])],     // Edwin: 6am-3pm Mon-Fri
        
        "4": [(start: 7, end: 15, days: [1,2,3,4,5])],     // Kevin: 7am-3pm Mon-Fri (plus garbage)
        
        "5": [
            (start: 6, end: 11, days: [1,2,3,4,5]),         // Mercedes: 6:30am-11am mornings
            (start: 13, end: 17, days: [1,2,3,4,5])         // Mercedes: afternoons (split shift)
        ],
        
        "6": [(start: 7, end: 16, days: [1,2,3,4,5])],     // Luis: 7am-4pm Mon-Fri
        
        "7": [(start: 18, end: 22, days: [1,2,3,4,5])]     // Angel: 6pm-10pm Mon-Fri (evening garbage)
    ]
    
    // MARK: - Task Counts
    static let workerTaskCounts: [String: (daily: Int, weekly: Int, monthly: Int, onDemand: Int)] = [
        "1": (daily: 6, weekly: 2, monthly: 0, onDemand: 2),     // Greg: 10 total
        "2": (daily: 0, weekly: 4, monthly: 1, onDemand: 0),     // Edwin: 5 total
        "4": (daily: 4, weekly: 4, monthly: 4, onDemand: 0),     // Kevin: 12 total + garbage
        "5": (daily: 2, weekly: 0, monthly: 0, onDemand: 0),     // Mercedes: 2 total
        "6": (daily: 2, weekly: 0, monthly: 0, onDemand: 0),     // Luis: 2 total
        "7": (daily: 3, weekly: 1, monthly: 0, onDemand: 0)      // Angel: 4 total (evening)
    ]
    
    // MARK: - Weekly Hours
    static let workerWeeklyHours: [String: Int] = [
        "1": 35,  // Greg: reduced hours (9-3)
        "2": 45,  // Edwin: 6am-3pm
        "4": 40,  // Kevin: 7am-3pm
        "5": 40,  // Mercedes: split shift (6:30-11 + afternoons)
        "6": 45,  // Luis: 7am-4pm
        "7": 20   // Angel: part-time evening (6pm-10pm)
    ]
    
    // MARK: - Helper Functions
    
    /// Get worker name by ID
    static func getWorkerName(id: String) -> String {
        return workerNames[id] ?? "Unknown Worker"
    }
    
    /// Get worker email by ID
    static func getWorkerEmail(id: String) -> String {
        return workerEmails[id] ?? ""
    }
    
    /// Check if worker is available at given hour
    static func isWorkerAvailable(id: String, at hour: Int) -> Bool {
        guard let schedules = workerSchedules[id] else { return false }
        
        // Check all schedule blocks (for split shifts like Mercedes)
        for schedule in schedules {
            if hour >= schedule.start && hour < schedule.end {
                return true
            }
        }
        return false
    }
    
    /// Check if worker is assigned to building
    static func isWorkerAssignedToBuilding(workerId: String, buildingId: String) -> Bool {
        let assignments = workerBuildingAssignments[workerId] ?? []
        return assignments.contains(buildingId)
    }
    
    /// Get all worker IDs
    static var allWorkerIds: [String] {
        return ["1", "2", "4", "5", "6", "7", "8", "9", "10"]
    }
    
    /// Get active worker IDs (excluding Shawn's multiple roles)
    static var activeWorkerIds: [String] {
        return ["1", "2", "4", "5", "6", "7"]
    }
    
    /// Format schedule for display
    static func formatSchedule(for workerId: String) -> String {
        guard let schedules = workerSchedules[workerId] else { return "No schedule" }
        
        var scheduleStrings: [String] = []
        
        for schedule in schedules {
            let startHour = schedule.start
            let endHour = schedule.end
            
            // Handle 24-hour to 12-hour conversion
            let startTime: String
            let endTime: String
            
            if startHour == 6 && workerId == "5" {
                startTime = "6:30am" // Mercedes starts at 6:30
            } else if startHour < 12 {
                startTime = "\(startHour)am"
            } else if startHour == 12 {
                startTime = "12pm"
            } else {
                startTime = "\(startHour - 12)pm"
            }
            
            if endHour < 12 {
                endTime = "\(endHour)am"
            } else if endHour == 12 {
                endTime = "12pm"
            } else {
                endTime = "\(endHour - 12)pm"
            }
            
            scheduleStrings.append("\(startTime)-\(endTime)")
        }
        
        return scheduleStrings.joined(separator: " & ")
    }
    
    /// Get worker type/shift description
    static func getWorkerShiftType(id: String) -> String {
        switch id {
        case "1": return "Day Shift (Reduced Hours)"
        case "2": return "Early Morning Shift"
        case "4": return "Day Shift + Garbage"
        case "5": return "Split Shift"
        case "6": return "Day Shift"
        case "7": return "Evening Garbage"
        default: return "Standard"
        }
    }
}
