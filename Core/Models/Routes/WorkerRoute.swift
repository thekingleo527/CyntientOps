//
//  WorkerRoute.swift
//  CyntientOps
//
//  Route-based operational architecture for real-world worker workflows
//  Represents actual building sequences and operational patterns
//

import Foundation
import CoreLocation

// MARK: - Worker Route Architecture

/// Represents a worker's complete operational route for a day/shift
public struct WorkerRoute: Codable, Identifiable {
    public let id: String
    public let workerId: String
    public let routeName: String
    public let dayOfWeek: Int // 1=Sunday, 7=Saturday
    public let startTime: Date
    public let estimatedEndTime: Date
    public let sequences: [RouteSequence]
    public let routeType: RouteType
    
    public enum RouteType: String, Codable, CaseIterable {
        case morningCleaning = "Morning Cleaning"
        case afternoonMaintenance = "Afternoon Maintenance" 
        case eveningOperations = "Evening Operations"
        case specialProject = "Special Project"
        case coverage = "Coverage Route"
    }
    
    public init(id: String, workerId: String, routeName: String, dayOfWeek: Int,
                startTime: Date, estimatedEndTime: Date, sequences: [RouteSequence],
                routeType: RouteType) {
        self.id = id
        self.workerId = workerId
        self.routeName = routeName
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.estimatedEndTime = estimatedEndTime
        self.sequences = sequences
        self.routeType = routeType
    }
}

/// Represents a sequence of operations at a building or location
public struct RouteSequence: Codable, Identifiable {
    public let id: String
    public let buildingId: String
    public let buildingName: String
    public let arrivalTime: Date
    public let estimatedDuration: TimeInterval // in seconds
    public let operations: [OperationTask]
    public let sequenceType: SequenceType
    public let isFlexible: Bool // Can be reordered due to weather/conditions
    public let dependencies: [String] // IDs of sequences that must complete first
    
    public enum SequenceType: String, Codable, CaseIterable {
        case buildingCheck = "Building Check"
        case outdoorCleaning = "Outdoor Cleaning"
        case indoorCleaning = "Indoor Cleaning"
        case maintenance = "Maintenance"
        case sanitation = "Sanitation"
        case operations = "Operations"
        case inspection = "Inspection"
    }
    
    public init(id: String, buildingId: String, buildingName: String,
                arrivalTime: Date, estimatedDuration: TimeInterval,
                operations: [OperationTask], sequenceType: SequenceType,
                isFlexible: Bool = true, dependencies: [String] = []) {
        self.id = id
        self.buildingId = buildingId
        self.buildingName = buildingName
        self.arrivalTime = arrivalTime
        self.estimatedDuration = estimatedDuration
        self.operations = operations
        self.sequenceType = sequenceType
        self.isFlexible = isFlexible
        self.dependencies = dependencies
    }
}

/// Represents a specific operational task within a sequence
public struct OperationTask: Codable, Identifiable {
    public let id: String
    public let name: String
    public let category: TaskCategory
    public let location: TaskLocation
    public let estimatedDuration: TimeInterval
    public let isWeatherSensitive: Bool
    public let requiredEquipment: [String]
    public let skillLevel: SkillLevel
    public let requiresPhoto: Bool
    public let instructions: String?
    
    public enum TaskCategory: String, Codable, CaseIterable {
        case sweeping = "Sweeping"
        case hosing = "Hosing"
        case vacuuming = "Vacuuming"
        case mopping = "Mopping"
        case trashCollection = "Trash Collection"
        case binManagement = "Bin Management"
        case posterRemoval = "Poster Removal"
        case treepitCleaning = "Treepit Cleaning"
        case stairwellCleaning = "Stairwell Cleaning"
        case laundryRoom = "Laundry Room"
        case buildingInspection = "Building Inspection"
        case dsnySetout = "DSNY Setout"
        case maintenance = "Maintenance"
    }
    
    public enum TaskLocation: String, Codable, CaseIterable {
        case sidewalk = "Sidewalk"
        case entrance = "Entrance"
        case hallway = "Hallway"
        case stairwell = "Stairwell"
        case basement = "Basement"
        case trashArea = "Trash Area"
        case laundryRoom = "Laundry Room"
        case exterior = "Exterior"
        case courtyard = "Courtyard"
        case treepit = "Treepit"
        case curbside = "Curbside"
    }
    
    public enum SkillLevel: String, Codable, CaseIterable {
        case basic = "Basic"
        case intermediate = "Intermediate" 
        case advanced = "Advanced"
        case specialist = "Specialist"
    }
    
    public init(id: String, name: String, category: TaskCategory, location: TaskLocation,
                estimatedDuration: TimeInterval, isWeatherSensitive: Bool = false,
                requiredEquipment: [String] = [], skillLevel: SkillLevel = .basic,
                requiresPhoto: Bool = false, instructions: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.location = location
        self.estimatedDuration = estimatedDuration
        self.isWeatherSensitive = isWeatherSensitive
        self.requiredEquipment = requiredEquipment
        self.skillLevel = skillLevel
        self.requiresPhoto = requiresPhoto
        self.instructions = instructions
    }
}

// MARK: - Building Operational Profiles

/// Represents building-specific operational requirements and constraints
public struct BuildingOperationalProfile: Codable, Identifiable {
    public let id: String
    public let buildingId: String
    public let buildingName: String
    public let operationalComplexity: OperationalComplexity
    public let floorConfiguration: FloorConfiguration
    public let specialRequirements: [SpecialRequirement]
    public let accessConstraints: [AccessConstraint]
    public let weatherSensitiveAreas: [WeatherSensitiveArea]
    
    public enum OperationalComplexity: String, Codable, CaseIterable {
        case simple = "Simple" // Single entrance, standard cleaning
        case moderate = "Moderate" // Multiple entrances, some special areas
        case complex = "Complex" // Multiple buildings, specialized areas
        case institutional = "Institutional" // Museum, special protocols
    }
    
    public struct FloorConfiguration: Codable {
        public let totalFloors: Int
        public let basementLevels: Int
        public let hallwayFloors: [Int] // Floors requiring hallway cleaning
        public let stairwellFloors: [Int] // Floors requiring stairwell cleaning
        public let specialFloors: [Int: String] // Floor number to special requirement
        
        public init(totalFloors: Int, basementLevels: Int = 0, 
                    hallwayFloors: [Int] = [], stairwellFloors: [Int] = [],
                    specialFloors: [Int: String] = [:]) {
            self.totalFloors = totalFloors
            self.basementLevels = basementLevels
            self.hallwayFloors = hallwayFloors
            self.stairwellFloors = stairwellFloors
            self.specialFloors = specialFloors
        }
    }
    
    public enum SpecialRequirement: String, Codable, CaseIterable {
        case laundryRoom = "Laundry Room"
        case multipleTrashAreas = "Multiple Trash Areas"
        case sharedSidewalk = "Shared Sidewalk"
        case separateBuildingSides = "Separate Building Sides"
        case museumProtocols = "Museum Protocols"
        case commercialTenants = "Commercial Tenants"
        case limitedAccess = "Limited Access"
    }
    
    public enum AccessConstraint: String, Codable, CaseIterable {
        case keyRequired = "Key Required"
        case timeRestricted = "Time Restricted"
        case tenantCoordination = "Tenant Coordination"
        case securityProtocol = "Security Protocol"
        case noiseRestriction = "Noise Restriction"
    }
    
    public enum WeatherSensitiveArea: String, Codable, CaseIterable {
        case sidewalk = "Sidewalk"
        case courtyard = "Courtyard"
        case entrance = "Entrance"
        case exteriorStairs = "Exterior Stairs"
        case treepitArea = "Treepit Area"
        case curbside = "Curbside"
    }
    
    public init(id: String, buildingId: String, buildingName: String,
                operationalComplexity: OperationalComplexity,
                floorConfiguration: FloorConfiguration,
                specialRequirements: [SpecialRequirement] = [],
                accessConstraints: [AccessConstraint] = [],
                weatherSensitiveAreas: [WeatherSensitiveArea] = []) {
        self.id = id
        self.buildingId = buildingId
        self.buildingName = buildingName
        self.operationalComplexity = operationalComplexity
        self.floorConfiguration = floorConfiguration
        self.specialRequirements = specialRequirements
        self.accessConstraints = accessConstraints
        self.weatherSensitiveAreas = weatherSensitiveAreas
    }
}