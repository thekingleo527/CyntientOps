//
//  CanonicalIDs.swift
//  CyntientOps
//
//  🛡️ CANONICAL ID SYSTEM - SINGLE SOURCE OF TRUTH
//  Created: 2024-01-31
//  Purpose: Prevent ID mismatches across the entire system
//

import Foundation

public struct CanonicalIDs {
    // MARK: - Worker IDs (Never change these!)
    public struct Workers {
        public static let gregHutson = "1"
        public static let edwinLema = "2"
        // Note: ID "3" was Jose Santos - removed from company
        public static let kevinDutan = "4"        // ⚡ Expanded duties + Rubin Museum
        public static let mercedesInamagua = "5"
        public static let luisLopez = "6"
        public static let angelGuirachocha = "7"
        public static let shawnMagloire = "8"
        
        // ID to Name mapping for validation
        public static let nameMap: [String: String] = [
            "1": "Greg Hutson",
            "2": "Edwin Lema",
            "4": "Kevin Dutan",
            "5": "Mercedes Inamagua",
            "6": "Luis Lopez",
            "7": "Angel Guirachocha",
            "8": "Shawn Magloire"
        ]
        
        public static func getName(for id: String) -> String? {
            return nameMap[id]
        }
        
        public static func isValidWorkerId(_ id: String) -> Bool {
            return nameMap[id] != nil
        }
    }
    
    // MARK: - Building IDs (Consistent with database)
    public struct Buildings {
        public static let westEighteenth12 = "1"
        public static let eastTwentieth29_31 = "2"
        public static let westSeventeenth135_139 = "3"
        public static let franklin104 = "4"
        public static let westSeventeenth138 = "5"
        public static let perry68 = "6"
        public static let westEighteenth112 = "7"
        public static let elizabeth41 = "8"
        public static let westSeventeenth117 = "9"
        public static let perry131 = "10"
        public static let firstAvenue123 = "11"
        // Note: ID "12" not in use
        public static let westSeventeenth136 = "13"
        public static let rubinMuseum = "14"      // 🏛️ Kevin's primary location
        public static let eastFifteenth133 = "15"
        public static let stuyvesantCove = "16"
        public static let springStreet178 = "17"
        public static let walker36 = "18"
        public static let seventhAvenue115 = "19"
        public static let francoSphereHQ = "20"
        
        // ID to Name mapping
        public static let nameMap: [String: String] = [
            "1": "12 West 18th Street",
            "2": "29-31 East 20th Street",
            "3": "135-139 West 17th Street",
            "4": "104 Franklin Street",
            "5": "138 West 17th Street",
            "6": "68 Perry Street",
            "7": "112 West 18th Street",
            "8": "41 Elizabeth Street",
            "9": "117 West 17th Street",
            "10": "131 Perry Street",
            "11": "123 1st Avenue",
            "13": "136 West 17th Street",
            "14": "Rubin Museum (142–148 W 17th)",
            "15": "133 East 15th Street",
            "16": "Stuyvesant Cove Park",
            "17": "178 Spring Street",
            "18": "36 Walker Street",
            "19": "115 7th Avenue",
            "20": "CyntientOps HQ"
        ]
        
        // Name to ID mapping (for lookups)
        public static let idMap: [String: String] = {
            var map: [String: String] = [:]
            for (id, name) in nameMap {
                map[name] = id
                // Add variations for Rubin Museum
                if id == "14" {
                    map["Rubin Museum"] = id
                    map["Rubin Museum (142-148 W 17th)"] = id
                    map["Rubin Museum (142–148 W 17th)"] = id
                }
            }
            return map
        }()
        
        public static func getName(for id: String) -> String? {
            return nameMap[id]
        }
        
        public static func getId(for name: String) -> String? {
            // Try exact match first
            if let id = idMap[name] {
                return id
            }
            
            // Try partial match for Rubin Museum
            if name.lowercased().contains("rubin") {
                return rubinMuseum
            }
            
            // Try to find by partial match
            for (buildingName, id) in idMap {
                if buildingName.lowercased().contains(name.lowercased()) ||
                   name.lowercased().contains(buildingName.lowercased()) {
                    return id
                }
            }
            
            return nil
        }
        
        public static func isValidBuildingId(_ id: String) -> Bool {
            return nameMap[id] != nil
        }
    }
    
    // MARK: - Task Categories (for consistency)
    public struct TaskCategories {
        public static let cleaning = "Cleaning"
        public static let maintenance = "Maintenance"
        public static let sanitation = "Sanitation"
        public static let inspection = "Inspection"
        public static let operations = "Operations"
        public static let repair = "Repair"
        
        public static let all = [cleaning, maintenance, sanitation, inspection, operations, repair]
    }
    
    // MARK: - Skill Levels
    public struct SkillLevels {
        public static let basic = "Basic"
        public static let intermediate = "Intermediate"
        public static let advanced = "Advanced"
        
        public static let all = [basic, intermediate, advanced]
    }
    
    // MARK: - Recurrence Types
    public struct RecurrenceTypes {
        public static let daily = "Daily"
        public static let weekly = "Weekly"
        public static let biWeekly = "Bi-Weekly"
        public static let monthly = "Monthly"
        public static let biMonthly = "Bi-Monthly"
        public static let quarterly = "Quarterly"
        public static let semiannual = "Semiannual"
        public static let annual = "Annual"
        public static let onDemand = "On-Demand"
        
        public static let all = [daily, weekly, biWeekly, monthly, biMonthly, quarterly, semiannual, annual, onDemand]
    }
}

// MARK: - Validation Extensions

extension CanonicalIDs {
    /// Validate a task assignment has proper IDs
    public static func validateTaskAssignment(workerId: String?, buildingId: String?) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        
        if let workerId = workerId {
            if !Workers.isValidWorkerId(workerId) {
                errors.append("Invalid worker ID: '\(workerId)'")
            }
        } else {
            errors.append("Missing worker ID")
        }
        
        if let buildingId = buildingId {
            if !Buildings.isValidBuildingId(buildingId) {
                errors.append("Invalid building ID: '\(buildingId)'")
            }
        } else {
            errors.append("Missing building ID")
        }
        
        return (errors.isEmpty, errors)
    }
    
    /// Get display name for a worker/building pair
    public static func getDisplayName(workerId: String?, buildingId: String?) -> String {
        let workerName = workerId.flatMap { Workers.getName(for: $0) } ?? "Unknown Worker"
        let buildingName = buildingId.flatMap { Buildings.getName(for: $0) } ?? "Unknown Building"
        return "\(workerName) at \(buildingName)"
    }
}
