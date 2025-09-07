//
//  CyntientOpsModels.swift
//  CyntientOps
//
//  This file now contains only extensions and utilities.
//  All type definitions have been moved to CoreTypes.swift
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Note on Types
// All type definitions have been moved to CoreTypes.swift
// This file only contains extensions and utilities
// Types are available globally through CoreTypes namespace

// MARK: - Extensions

// MARK: NamedCoordinate Extensions
extension CoreTypes.NamedCoordinate {
    /// Manhattan-specific building image
    var buildingImage: String {
        switch name.lowercased() {
        case let n where n.contains("rubin"): return "building.columns.circle"
        case let n where n.contains("131 perry"): return "building.perry131"
        case let n where n.contains("68 perry"): return "building.perry68"
        case let n where n.contains("stuyvesant"): return "building.park"
        case let n where n.contains("12 west 18"): return "building.west18"
        case let n where n.contains("133 east 15"): return "building.east15"
        case let n where n.contains("41 elizabeth"): return "building.elizabeth"
        case let n where n.contains("104 franklin"): return "building.franklin"
        default: return "building.2.crop.circle"
        }
    }
    
    /// Check if location is in Manhattan
    var isInManhattan: Bool {
        let manhattanBounds = (
            north: 40.882214,
            south: 40.680611,
            east: -73.907000,
            west: -74.047285
        )
        
        return latitude <= manhattanBounds.north &&
               latitude >= manhattanBounds.south &&
               longitude >= manhattanBounds.west &&
               longitude <= manhattanBounds.east
    }
    
    /// Get neighborhood name based on coordinates
    var neighborhood: String {
        // Simplified neighborhood detection based on latitude
        switch latitude {
        case 40.82...:
            return "Upper Manhattan"
        case 40.77..<40.82:
            return "Upper West/East Side"
        case 40.75..<40.77:
            return "Midtown"
        case 40.73..<40.75:
            return "Chelsea/Murray Hill"
        case 40.71..<40.73:
            return "Greenwich Village/SoHo"
        default:
            return "Lower Manhattan"
        }
    }
}

// MARK: WorkerProfile Extensions
extension CoreTypes.WorkerProfile {
    /// Get initials for avatar display
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first ?? "?"
        let lastInitial: Character = components.count > 1 ? (components.last?.first ?? " ") : " "
        return "\(firstInitial)\(lastInitial)".uppercased().trimmingCharacters(in: .whitespaces)
    }
    
    /// Check if worker has a specific skill
    func hasSkill(_ skillName: String) -> Bool {
        skills?.contains { $0.lowercased() == skillName.lowercased() } ?? false
    }
    
    /// Get skill level description
    var skillLevelDescription: String {
        guard let skills = skills else { return "No skills listed" }
        return "\(skills.count) skill\(skills.count == 1 ? "" : "s")"
    }
    
    /// Years of experience (calculated from hire date)
    var yearsOfExperience: Int? {
        guard let hireDate = hireDate else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: hireDate, to: Date())
        return components.year
    }
}

// MARK: ContextualTask Extensions
extension CoreTypes.ContextualTask {
    /// Time remaining until due
    var timeRemaining: TimeInterval? {
        guard let dueDate = dueDate else { return nil }
        return dueDate.timeIntervalSinceNow
    }
    
    /// Formatted time remaining string
    var timeRemainingString: String {
        guard let timeRemaining = timeRemaining else { return "No due date" }
        
        if timeRemaining < 0 {
            return "Overdue"
        }
        
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        
        if hours > 24 {
            let days = hours / 24
            return "\(days) day\(days == 1 ? "" : "s") remaining"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
    
    /// Priority color
    var priorityColor: Color {
        switch urgency {
        case .emergency, .critical: return .red
        case .urgent, .high: return .orange
        case .medium, .normal: return .yellow
        case .low, .none: return .green
        }
    }
    
    /// Icon for task category
    var categoryIcon: String {
        category?.icon ?? "questionmark.circle"
    }
}

// MARK: - TaskUrgency Extension for Priority Value
extension CoreTypes.TaskUrgency {
    var priorityValue: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .normal: return 2
        case .high: return 3
        case .urgent: return 4
        case .critical: return 5
        case .emergency: return 6
        }
    }
}

// MARK: - Utility Functions

/// Calculate distance between two coordinates in miles
public func distanceBetween(_ coord1: CoreTypes.NamedCoordinate, _ coord2: CoreTypes.NamedCoordinate) -> Double {
    let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
    let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
    return location1.distance(from: location2) / 1609.344 // Convert meters to miles
}

/// Sort buildings by distance from a reference point
public func sortBuildingsByDistance(buildings: [CoreTypes.NamedCoordinate], from reference: CoreTypes.NamedCoordinate) -> [CoreTypes.NamedCoordinate] {
    return buildings.sorted { building1, building2 in
        let distance1 = distanceBetween(building1, reference)
        let distance2 = distanceBetween(building2, reference)
        return distance1 < distance2
    }
}

/// Group tasks by category
public func groupTasksByCategory(_ tasks: [CoreTypes.ContextualTask]) -> [CoreTypes.TaskCategory: [CoreTypes.ContextualTask]] {
    return Dictionary(grouping: tasks) { task in
        task.category ?? .administrative
    }
}

/// Filter tasks by urgency threshold
public func filterTasksByUrgency(_ tasks: [CoreTypes.ContextualTask], minUrgency: CoreTypes.TaskUrgency) -> [CoreTypes.ContextualTask] {
    return tasks.filter { task in
        guard let taskUrgency = task.urgency else { return false }
        return taskUrgency.priorityValue >= minUrgency.priorityValue
    }
}

// MARK: - Production Data Helpers (Based on Real CyntientOps Data from OperationalDataManager)

#if DEBUG
extension CoreTypes {
    /// Real buildings from CyntientOps portfolio (from OperationalDataManager)
    static let productionBuildings: [CoreTypes.NamedCoordinate] = [
        // Kevin's primary building
        CoreTypes.NamedCoordinate(
            id: "14",
            name: "Rubin Museum (142–148 W 17th)",
            address: "150 W 17th St, New York, NY 10011",
            latitude: 40.7402,
            longitude: -73.9979
        ),
        
        // Perry Street cluster
        NamedCoordinate(
            id: "10",
            name: "131 Perry Street",
            address: "131 Perry St, New York, NY 10014",
            latitude: 40.7358,
            longitude: -74.0055
        ),
        NamedCoordinate(
            id: "6",
            name: "68 Perry Street",
            address: "68 Perry St, New York, NY 10014",
            latitude: 40.7347,
            longitude: -74.0029
        ),
        
        // West 17th Street corridor
        NamedCoordinate(
            id: "3",
            name: "135-139 West 17th Street",
            address: "135-139 W 17th St, New York, NY 10011",
            latitude: 40.7404,
            longitude: -73.9975
        ),
        NamedCoordinate(
            id: "13",
            name: "136 West 17th Street",
            address: "136 W 17th St, New York, NY 10011",
            latitude: 40.7403,
            longitude: -73.9976
        ),
        NamedCoordinate(
            id: "5",
            name: "138 West 17th Street",
            address: "138 W 17th St, New York, NY 10011",
            latitude: 40.7403,
            longitude: -73.9977
        ),
        NamedCoordinate(
            id: "9",
            name: "117 West 17th Street",
            address: "117 W 17th St, New York, NY 10011",
            latitude: 40.7403,
            longitude: -73.9972
        ),
        
        // West 18th Street
        NamedCoordinate(
            id: "7",
            name: "112 West 18th Street",
            address: "112 W 18th St, New York, NY 10011",
            latitude: 40.7408,
            longitude: -73.9967
        ),
        NamedCoordinate(
            id: "1",
            name: "12 West 18th Street",
            address: "12 W 18th St, New York, NY 10011",
            latitude: 40.7386,
            longitude: -73.9927
        ),
        
        // East side
        NamedCoordinate(
            id: "2",
            name: "29-31 East 20th Street",
            address: "29-31 E 20th St, New York, NY 10003",
            latitude: 40.7388,
            longitude: -73.9873
        ),
        NamedCoordinate(
            id: "15",
            name: "133 East 15th Street",
            address: "133 E 15th St, New York, NY 10003",
            latitude: 40.7343,
            longitude: -73.9859
        ),
        
        // Downtown
        NamedCoordinate(
            id: "17",
            name: "178 Spring Street",
            address: "178 Spring St, New York, NY 10012",
            latitude: 40.7252,
            longitude: -74.0015
        ),
        NamedCoordinate(
            id: "4",
            name: "104 Franklin Street",
            address: "104 Franklin St, New York, NY 10013",
            latitude: 40.7190,
            longitude: -74.0089
        ),
        NamedCoordinate(
            id: "8",
            name: "41 Elizabeth Street",
            address: "41 Elizabeth St, New York, NY 10013",
            latitude: 40.7178,
            longitude: -73.9962
        ),
        NamedCoordinate(
            id: "18",
            name: "36 Walker Street",
            address: "36 Walker St, New York, NY 10013",
            latitude: 40.7178,
            longitude: -74.0012
        ),
        
        // Special locations
        NamedCoordinate(
            id: "16",
            name: "Stuyvesant Cove Park",
            address: "E River Greenway, New York, NY 10009",
            latitude: 40.7323,
            longitude: -73.9741
        )
    ]
    
    /// Real worker profiles from CyntientOps (from OperationalDataManager and QuickBooksPayrollExporter)
    static let productionWorkers: [CoreTypes.WorkerProfile] = [
        CoreTypes.WorkerProfile(
            id: "4", // Kevin's actual ID in the system
            name: "Kevin Dutan",
            email: "dutankevin1@gmail.com",
            phoneNumber: "917-555-0004",
            role: .worker,
            skills: ["Cleaning", "Maintenance", "Sanitation", "Operations", "HVAC", "Electrical"],
            certifications: ["OSHA 30", "EPA Universal", "NYC Fire Safety"],
            hireDate: Date(timeIntervalSinceNow: -730 * 24 * 60 * 60), // 2 years
            isActive: true
        ),
        WorkerProfile(
            id: "2",
            name: "Edwin Lema",
            email: "edwinlema911@gmail.com",
            phoneNumber: "917-555-0002",
            role: .worker,
            skills: ["Maintenance", "Park Operations", "Equipment Repair", "Boiler Operations"],
            certifications: ["NYC Parks Certified", "Boiler Operator License"],
            hireDate: Date(timeIntervalSinceNow: -1095 * 24 * 60 * 60), // 3 years
            isActive: true
        ),
        WorkerProfile(
            id: "5",
            name: "Mercedes Inamagua",
            email: "jneola@gmail.com",
            phoneNumber: "917-555-0005",
            role: .worker,
            skills: ["Cleaning", "Glass Cleaning", "Lobby Maintenance", "Deep Cleaning"],
            certifications: ["OSHA 10", "Green Cleaning Certified"],
            hireDate: Date(timeIntervalSinceNow: -1460 * 24 * 60 * 60), // 4 years
            isActive: true
        ),
        WorkerProfile(
            id: "6",
            name: "Luis Lopez",
            email: "luislopez030@yahoo.com",
            phoneNumber: "917-555-0006",
            role: .worker,
            skills: ["Cleaning", "Maintenance", "Floor Care", "Trash Management"],
            certifications: ["OSHA 10"],
            hireDate: Date(timeIntervalSinceNow: -365 * 24 * 60 * 60), // 1 year
            isActive: true
        ),
        WorkerProfile(
            id: "7",
            name: "Angel Guiracocha",
            email: "lio.angel71@gmail.com",
            phoneNumber: "917-555-0007",
            role: .worker,
            skills: ["Evening Operations", "Building Security", "Trash Management", "DSNY Compliance"],
            certifications: ["NYC Security License", "OSHA 10"],
            hireDate: Date(timeIntervalSinceNow: -548 * 24 * 60 * 60), // 1.5 years
            isActive: true
        ),
        WorkerProfile(
            id: "1",
            name: "Greg Hutson",
            email: "g.hutson1989@gmail.com",
            phoneNumber: "917-555-0001",
            role: .worker,
            skills: ["Building Maintenance", "HVAC", "Electrical", "Plumbing"],
            certifications: ["HVAC Certified", "Master Plumber License"],
            hireDate: Date(timeIntervalSinceNow: -1825 * 24 * 60 * 60), // 5 years
            isActive: true
        ),
        WorkerProfile(
            id: "8",
            name: "Shawn Magloire",
            email: "shawn@francomanagementgroup.com",
            phoneNumber: "917-555-0008",
            role: .admin,
            skills: ["Portfolio Management", "Operations Management", "Staff Supervision"],
            certifications: ["Property Management License", "MBA"],
            hireDate: Date(timeIntervalSinceNow: -2190 * 24 * 60 * 60), // 6 years
            isActive: true
        )
    ]
    
    /// Real maintenance tasks based on CyntientOps operations (from realWorldTasks)
    static let productionTasks: [ContextualTask] = [
        // Kevin's Rubin Museum tasks
        ContextualTask(
            id: "task_rubin_001",
            title: "Rubin Museum Morning Trash Circuit",
            description: "Complete trash removal and sanitation check for all floors",
            dueDate: Date(timeIntervalSinceNow: 7200), // 2 hours from now
            category: .sanitation,
            urgency: .medium,
            building: productionBuildings[0], // Rubin Museum
            worker: productionWorkers[0], // Kevin Dutan
            buildingId: "14"
        ),
        ContextualTask(
            id: "task_rubin_002",
            title: "Rubin Museum Deep Clean",
            description: "Deep clean galleries and public areas",
            dueDate: Date(timeIntervalSinceNow: 10800), // 3 hours from now
            category: .cleaning,
            urgency: .medium,
            building: productionBuildings[0], // Rubin Museum
            worker: productionWorkers[0], // Kevin Dutan
            buildingId: "14"
        ),
        
        // Kevin's Perry Street tasks
        ContextualTask(
            id: "task_perry_001",
            title: "131 Perry Sidewalk Sweep",
            description: "Sidewalk + Curb Sweep / Trash Return",
            dueDate: Date(timeIntervalSinceNow: 3600), // 1 hour from now
            category: .cleaning,
            urgency: .high,
            building: productionBuildings[1], // 131 Perry
            worker: productionWorkers[0], // Kevin Dutan
            buildingId: "10"
        ),
        
        // Edwin's park maintenance
        ContextualTask(
            id: "task_park_001",
            title: "Morning Park Check",
            description: "Stuyvesant Cove Park morning inspection and equipment check",
            dueDate: Date(timeIntervalSinceNow: 1800), // 30 minutes from now
            category: .maintenance,
            urgency: .high,
            building: productionBuildings.last!, // Stuyvesant Cove Park
            worker: productionWorkers[1], // Edwin Lema
            buildingId: "16"
        ),
        
        // Mercedes' glass cleaning circuit
        ContextualTask(
            id: "task_glass_001",
            title: "112 West 18th Glass & Lobby Clean",
            description: "Complete glass cleaning and lobby maintenance",
            dueDate: Date(timeIntervalSinceNow: 5400), // 1.5 hours from now
            category: .cleaning,
            urgency: .medium,
            building: productionBuildings[7], // 112 West 18th
            worker: productionWorkers[2], // Mercedes Inamagua
            buildingId: "7"
        ),
        
        // Angel's evening operations
        ContextualTask(
            id: "task_dsny_001",
            title: "DSNY Trash Compliance",
            description: "Evening DSNY trash setup for collection",
            dueDate: Date(timeIntervalSinceNow: 43200), // 12 hours from now (evening)
            category: .sanitation,
            urgency: .critical,
            building: productionBuildings[4], // 136 West 17th
            worker: productionWorkers[4], // Angel Guiracocha
            buildingId: "13"
        )
    ]
    
    /// Kevin's typical daily route (from OperationalDataManager) - FIXED
    static let kevinDailyRoute: CoreTypes.WorkerDailyRoute = {
        // Map building IDs to actual NamedCoordinate objects
        let buildingIds = ["10", "6", "14", "3", "13", "5", "9"]
        let routeBuildings = buildingIds.compactMap { buildingId in
            productionBuildings.first { $0.id == buildingId }
        }
        
        // Create route stops from the buildings - FIXED: Using 'name:' parameter instead of 'buildingName:'
        let stops = routeBuildings.enumerated().map { index, building in
            CoreTypes.RouteStop(
                buildingId: building.id,
                name: building.name,  // FIXED: Changed from buildingName to name
                address: building.address,
                latitude: building.latitude,
                longitude: building.longitude,
                sequenceNumber: index + 1,
                tasks: [], // Tasks would be populated dynamically
                estimatedDuration: 3600 // 1 hour per building average
            )
        }
        
        return CoreTypes.WorkerDailyRoute(
            id: "route_kevin_001",
            workerId: "4",
            date: Date(),
            stops: stops,
            buildings: routeBuildings,
            estimatedDuration: 39600 // 11 hours (6am-5pm)
        )
    }()
    
    /// Sample building metrics based on real performance data
    static let rubinMuseumMetrics = BuildingMetrics(
        id: "metrics_rubin",
        buildingId: "14",
        completionRate: 0.92,
        averageTaskTime: 2700, // 45 minutes average
        overdueTasks: 2,
        totalTasks: 38, // Kevin's expanded duties
        activeWorkers: 1, // Kevin is primary
        isCompliant: true,
        overallScore: 0.88,
        pendingTasks: 5,
        urgentTasksCount: 1,
        hasWorkerOnSite: true,
        maintenanceEfficiency: 0.91,
        weeklyCompletionTrend: 0.05 // 5% improvement
    )
}
#endif
