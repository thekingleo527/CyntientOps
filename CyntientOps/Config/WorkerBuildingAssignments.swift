//
//  WorkerBuildingAssignments.swift
//  CyntientOps (formerly CyntientOps)
//
//  Extracted from CoverageInfoCard.swift - Production Worker-Building Assignments
//  🔄 UPDATED: Fixed worker names to match canonical data
//  📊 SOURCE: OperationalDataManager production data
//

import Foundation

public struct WorkerBuildingAssignments {
    
    // MARK: - Primary Worker Assignment Mapping
    
    /// Get the primary worker assigned to a specific building
    /// This data is extracted from CoverageInfoCard and updated to match canonical worker names
    public static func getPrimaryWorker(for buildingId: String) -> String? {
        switch buildingId {
        // Kevin Dutan - Rubin Museum specialist + JM Realty buildings
        case "14": return "Kevin Dutan"        // Rubin Museum (142-148 West 17th)
        case "9": return "Kevin Dutan"         // 117 West 17th (JM Realty)
        case "10": return "Kevin Dutan"        // 131 Perry (JM Realty)
        case "11": return "Kevin Dutan"        // 123 1st Ave (JM Realty)
        
        // Edwin Lema - Stuyvesant Cove specialist
        case "16": return "Edwin Lema"         // Stuyvesant Cove Park (Solar One)
        
        // Mercedes Inamagua - Glass cleaning specialist
        case "5": return "Mercedes Inamagua"  // 138 West 17th
        case "13": return "Mercedes Inamagua" // 136 West 17th (Weber Farhat)
        
        // Luis Lopez - Elizabeth Street PRIMARY + coverage
        case "8": return "Luis Lopez"          // 41 Elizabeth (PRIMARY - Bathrooms, Lobby, Elevator, Mail)
        case "4": return "Luis Lopez"          // 104 Franklin - Sidewalk Hose
        case "18": return "Luis Lopez"         // 36 Walker - Sidewalk Sweep
        
        // Kevin Dutan - Perry Streets + Rubin Museum
        case "6": return "Kevin Dutan"         // 68 Perry (Sidewalk, Building Clean, Stairwell, Roof)
        
        // Angel Guiracocha - Evening DSNY specialist  
        case "7": return "Angel Guiracocha"   // 112 West 18th - Night shift
        
        // Shawn Magloire - HVAC/Advanced maintenance
        case "3": return "Shawn Magloire"     // 135-139 West 17th
        case "15": return "Shawn Magloire"    // 133 East 15th (Corbel Property)
        case "21": return "Shawn Magloire"    // 148 Chambers (JM Realty - NEW)
        
        // Greg Hutson - 12 West 18th primary worker
        case "1": return "Greg Hutson"        // 12 West 18th
        default: return nil
        }
    }
    
    // MARK: - Reverse Lookup: Buildings by Worker
    
    /// Get all buildings assigned to a specific worker
    public static func getAssignedBuildings(for workerName: String) -> [String] {
        switch workerName {
        case "Kevin Dutan":
            return ["14", "9", "10", "11"]  // Rubin + JM Realty buildings
            
        case "Edwin Lema":
            return ["16"]  // Stuyvesant Cove only
            
        case "Mercedes Inamagua":
            return ["5", "13"]  // Glass cleaning buildings
            
        case "Luis Lopez":
            return ["6", "4"]  // Perry St + Franklin
            
        case "Angel Guiracocha":
            return ["7", "8", "18"]  // Evening shift buildings
            
        case "Shawn Magloire":
            return ["3", "15", "21"]  // HVAC/Advanced buildings
            
        case "Greg Hutson":
            return ["1"]  // 12 West 18th
            
        default:
            return []
        }
    }
    
    // MARK: - Worker Specializations
    
    public enum WorkerSpecialization {
        case rubinMuseumSpecialist      // Kevin
        case stuyvesantCoveSpecialist   // Edwin
        case glassCleaningSpecialist    // Mercedes
        case elizabethStreetSpecialist  // Luis - CORRECTED
        case eveningDSNYSpecialist      // Angel
        case hvacAdvancedMaintenance    // Shawn
        case west18thSpecialist         // Greg (12 West 18th)
    }
    
    /// Get the specialization for a worker
    public static func getSpecialization(for workerName: String) -> WorkerSpecialization? {
        switch workerName {
        case "Kevin Dutan": return .rubinMuseumSpecialist
        case "Edwin Lema": return .stuyvesantCoveSpecialist
        case "Mercedes Inamagua": return .glassCleaningSpecialist
        case "Luis Lopez": return .elizabethStreetSpecialist
        case "Angel Guiracocha": return .eveningDSNYSpecialist
        case "Shawn Magloire": return .hvacAdvancedMaintenance
        case "Greg Hutson": return .west18thSpecialist
        default: return nil
        }
    }
    
    // MARK: - Building Client Mapping (from README data)
    
    /// Get the client that owns a specific building
    public static func getClient(for buildingId: String) -> String? {
        switch buildingId {
        // JM Realty (9 buildings)
        case "3", "5", "6", "7", "9", "10", "11", "14", "21":
            return "JM Realty"
            
        // Weber Farhat (1 building)
        case "13":
            return "Weber Farhat"
            
        // Solar One (1 building)
        case "16":
            return "Solar One"
            
        // Grand Elizabeth LLC (1 building)
        case "8":
            return "Grand Elizabeth LLC"
            
        // Citadel Realty (2 buildings)
        case "4", "18":
            return "Citadel Realty"
            
        // Corbel Property (1 building)
        case "15":
            return "Corbel Property"
            
        default:
            return nil
        }
    }
    
    // MARK: - Coverage Access Logic
    
    /// Determine if a worker has coverage access to a building (not their primary assignment)
    public static func hasCoverageAccess(worker: String, buildingId: String) -> Bool {
        let assignedBuildings = getAssignedBuildings(for: worker)
        return !assignedBuildings.contains(buildingId)
    }
    
    /// Get coverage type for worker-building combination
    public enum AccessType {
        case primary        // Worker's regular assignment
        case coverage       // Coverage/support access
        case emergency      // Emergency situation access
        case training       // Cross-training access
    }
    
    public static func getAccessType(worker: String, buildingId: String, isEmergency: Bool = false, isTraining: Bool = false) -> AccessType {
        if isEmergency {
            return .emergency
        }
        
        if isTraining {
            return .training
        }
        
        let assignedBuildings = getAssignedBuildings(for: worker)
        return assignedBuildings.contains(buildingId) ? .primary : .coverage
    }
    
    // MARK: - Validation
    
    /// Validate that all building-worker assignments are consistent
    public static func validateAssignments() -> [String] {
        var errors: [String] = []
        
        // Check that Kevin has Rubin Museum (critical requirement)
        let kevinBuildings = getAssignedBuildings(for: "Kevin Dutan")
        if !kevinBuildings.contains("14") {
            errors.append("CRITICAL: Kevin Dutan must have Rubin Museum (14) assignment")
        }
        
        // Check that all active buildings have assignments
        let activeBuildings = ["3", "4", "5", "6", "7", "8", "9", "10", "11", "13", "14", "15", "16", "18", "21"]
        for buildingId in activeBuildings {
            if getPrimaryWorker(for: buildingId) == nil {
                errors.append("No primary worker assigned to building \(buildingId)")
            }
        }
        
        // Check that no worker is over-assigned
        let allWorkers = ["Kevin Dutan", "Edwin Lema", "Mercedes Inamagua", "Luis Lopez", "Angel Guiracocha", "Shawn Magloire"]
        for worker in allWorkers {
            let buildings = getAssignedBuildings(for: worker)
            if buildings.count > 6 {  // Reasonable limit
                errors.append("Worker \(worker) has too many assignments: \(buildings.count) buildings")
            }
        }
        
        return errors
    }
}

// MARK: - Extensions for Integration

extension WorkerBuildingAssignments {
    
    /// Get building name from ID (for display purposes)
    public static func getBuildingName(for buildingId: String) -> String? {
        switch buildingId {
        case "3": return "135-139 West 17th Street"
        case "4": return "104 Franklin Street"
        case "5": return "138 West 17th Street"
        case "6": return "68 Perry Street"
        case "7": return "112 West 18th Street"
        case "8": return "41 Elizabeth Street"
        case "9": return "117 West 17th Street"
        case "10": return "131 Perry Street"
        case "11": return "123 1st Avenue"
        case "13": return "136 West 17th Street"
        case "14": return "Rubin Museum (142-148 West 17th)"
        case "15": return "133 East 15th Street"
        case "16": return "Stuyvesant Cove Park"
        case "18": return "36 Walker Street"
        case "21": return "148 Chambers Street"
        default: return nil
        }
    }
    
    /// Check if building is active (building 2 was deactivated)
    public static func isBuildingActive(_ buildingId: String) -> Bool {
        return buildingId != "2"  // Building 2 (29-31 East 20th) was discontinued
    }
}
