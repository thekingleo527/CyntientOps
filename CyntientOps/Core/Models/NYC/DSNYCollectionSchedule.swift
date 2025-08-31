//
//  DSNYCollectionSchedule.swift
//  CyntientOps
//
//  Centralized DSNY collection schedule management
//  Prevents workers from forgetting bin placement/retrieval schedules
//  Ensures consistent bin management across all buildings
//

import Foundation

// MARK: - DSNY Collection Schedule System

public struct DSNYCollectionSchedule {
    
    // MARK: - DSNY Regulations (as of Nov 2024)
    
    /// DSNY requires buildings with ≤9 units to use bins (not bags)  
    /// Buildings with 10+ units can use black bags, Empire containers, or bins
    /// Empire containers are suggested for 31+ units but not mandatory
    public static let individualBinMaxUnits = 9
    public static let empireContainerMinUnits = 31
    
    // MARK: - Collection Day Configuration
    
    /// Buildings that require bin management with their collection schedules  
    /// Only includes buildings with ≤9 units that require individual bins per DSNY regulations
    /// Unit counts validated against user-provided ground truth data
    public static let buildingCollectionSchedules: [String: BuildingDSNYSchedule] = {
        var schedules: [String: BuildingDSNYSchedule] = [:]
        
        // Only include buildings that require bin management based on unit count
        let buildingsNeedingBins = BuildingUnitValidator.getBuildingsRequiringBinManagement()
        
        for buildingId in buildingsNeedingBins {
            switch buildingId {
            case CanonicalIDs.Buildings.springStreet178:
                schedules[buildingId] = BuildingDSNYSchedule(
                    buildingId: buildingId,
                    buildingName: "178 Spring Street",
                    unitCount: 4, // 4 residential + 1 commercial
                    collectionDays: [CollectionDay.monday, CollectionDay.wednesday, CollectionDay.saturday],
                    binSetOutTime: DSNYTime(hour: 18, minute: 0),
                    binRetrievalTime: DSNYTime(hour: 10, minute: 30),
                    binLocation: "curbside",
                    specialInstructions: "Glass door area - coordinate with entrance cleaning",
                    wasteStreams: [
                        WasteStreamGuidance(wasteType: WasteType.trash, collectionDays: [CollectionDay.monday, CollectionDay.wednesday, CollectionDay.saturday], containerType: ContainerType.blackBin, specialInstructions: "Black bins required for 4 residential units"),
                        WasteStreamGuidance(wasteType: WasteType.recycling, collectionDays: [CollectionDay.wednesday, CollectionDay.saturday], containerType: ContainerType.greenBin, specialInstructions: "Green bins - no glass, paper/cardboard/plastic/metal only"),
                        WasteStreamGuidance(wasteType: WasteType.compost, collectionDays: [CollectionDay.monday, CollectionDay.wednesday], containerType: ContainerType.brownBin, specialInstructions: "Brown bins - food scraps and organic waste")
                    ]
                )
                
            case CanonicalIDs.Buildings.perry68:
                schedules[buildingId] = BuildingDSNYSchedule(
                    buildingId: buildingId,
                    buildingName: "68 Perry Street",
                    unitCount: 6, // 6 residential units
                    collectionDays: [CollectionDay.tuesday, CollectionDay.friday],
                    binSetOutTime: DSNYTime(hour: 19, minute: 0),
                    binRetrievalTime: DSNYTime(hour: 8, minute: 30),
                    binLocation: "curbside",
                    specialInstructions: "Coordinate with Kevin's Perry Street morning sequence",
                    wasteStreams: [
                        WasteStreamGuidance(wasteType: WasteType.trash, collectionDays: [CollectionDay.tuesday, CollectionDay.friday], containerType: ContainerType.blackBin, specialInstructions: "Black bins required for 6 residential units"),
                        WasteStreamGuidance(wasteType: WasteType.recycling, collectionDays: [CollectionDay.friday], containerType: ContainerType.greenBin, specialInstructions: "Green bins - West Village area has separate glass collection"),
                        WasteStreamGuidance(wasteType: WasteType.compost, collectionDays: [CollectionDay.tuesday], containerType: ContainerType.brownBin, specialInstructions: "Brown bins - organics collection")
                    ]
                )

            case CanonicalIDs.Buildings.perry131:
                schedules[buildingId] = BuildingDSNYSchedule(
                    buildingId: buildingId,
                    buildingName: "131 Perry Street",
                    unitCount: 3, // 3 residential units
                    collectionDays: [CollectionDay.tuesday, CollectionDay.friday], // Align with Perry corridor
                    binSetOutTime: DSNYTime(hour: 19, minute: 0),
                    binRetrievalTime: DSNYTime(hour: 8, minute: 30),
                    binLocation: "curbside",
                    specialInstructions: "Align with 68 Perry Street bin cadence",
                    wasteStreams: [
                        WasteStreamGuidance(wasteType: WasteType.trash, collectionDays: [.tuesday, .friday], containerType: ContainerType.blackBin, specialInstructions: "Black bins required for ≤9 residential units"),
                        WasteStreamGuidance(wasteType: WasteType.recycling, collectionDays: [.friday], containerType: ContainerType.greenBin, specialInstructions: "Green bins - standard recycling"),
                        WasteStreamGuidance(wasteType: WasteType.compost, collectionDays: [.tuesday], containerType: ContainerType.brownBin, specialInstructions: "Brown bins - organics collection")
                    ]
                )
                
            case CanonicalIDs.Buildings.firstAvenue123:
                schedules[buildingId] = BuildingDSNYSchedule(
                    buildingId: buildingId,
                    buildingName: "123 1st Avenue",
                    unitCount: 3, // 3 residential + 1 commercial
                    collectionDays: [CollectionDay.monday, CollectionDay.wednesday, CollectionDay.friday],
                    binSetOutTime: DSNYTime(hour: 18, minute: 30),
                    binRetrievalTime: DSNYTime(hour: 13, minute: 30),
                    binLocation: "curbside",
                    specialInstructions: "Part of Kevin's M W F afternoon rotation",
                    wasteStreams: [
                        WasteStreamGuidance(wasteType: WasteType.trash, collectionDays: [.monday, .wednesday, .friday], containerType: ContainerType.blackBin, specialInstructions: "Black bins required for 3 residential units"),
                        WasteStreamGuidance(wasteType: WasteType.recycling, collectionDays: [CollectionDay.wednesday, CollectionDay.friday], containerType: ContainerType.greenBin, specialInstructions: "Green bins - East Village district collection"),
                        WasteStreamGuidance(wasteType: WasteType.compost, collectionDays: [CollectionDay.monday, CollectionDay.friday], containerType: ContainerType.brownBin, specialInstructions: "Brown bins - organics collection")
                    ]
                )
                
            case CanonicalIDs.Buildings.westSeventeenth136:
                schedules[buildingId] = BuildingDSNYSchedule(
                    buildingId: buildingId,
                    buildingName: "136 West 17th Street", 
                    unitCount: 7, // Floors 2,3,4,5,6,7/8 penthouse,9/10 penthouse (ground commercial)
                    collectionDays: [CollectionDay.tuesday, CollectionDay.thursday, CollectionDay.saturday],
                    binSetOutTime: DSNYTime(hour: 19, minute: 0),
                    binRetrievalTime: DSNYTime(hour: 11, minute: 0),
                    binLocation: "curbside",
                    specialInstructions: "Edwin covers Saturday retrieval for Kevin's buildings",
                    wasteStreams: [
                        WasteStreamGuidance(wasteType: WasteType.trash, collectionDays: [.tuesday, .thursday, .saturday], containerType: ContainerType.blackBin, specialInstructions: "Black bins required for 7 residential units"),
                        WasteStreamGuidance(wasteType: WasteType.recycling, collectionDays: [CollectionDay.thursday, CollectionDay.saturday], containerType: ContainerType.greenBin, specialInstructions: "Green bins - Chelsea/Flatiron district"),
                        WasteStreamGuidance(wasteType: WasteType.compost, collectionDays: [CollectionDay.tuesday, CollectionDay.thursday], containerType: ContainerType.brownBin, specialInstructions: "Brown bins - organics collection")
                    ]
                )

            case CanonicalIDs.Buildings.westSeventeenth117:
                schedules[buildingId] = BuildingDSNYSchedule(
                    buildingId: buildingId,
                    buildingName: "117 West 17th Street",
                    unitCount: 8, // Residential floors
                    collectionDays: [CollectionDay.tuesday, CollectionDay.thursday, CollectionDay.saturday], // Align with W 17th corridor
                    binSetOutTime: DSNYTime(hour: 19, minute: 0),
                    binRetrievalTime: DSNYTime(hour: 10, minute: 45),
                    binLocation: "curbside",
                    specialInstructions: "Match neighboring West 17th cadence",
                    wasteStreams: [
                        WasteStreamGuidance(wasteType: WasteType.trash, collectionDays: [.tuesday, .thursday, .saturday], containerType: ContainerType.blackBin, specialInstructions: "Black bins for residential"),
                        WasteStreamGuidance(wasteType: WasteType.recycling, collectionDays: [.thursday, .saturday], containerType: ContainerType.greenBin, specialInstructions: "Green bins - standard recycling"),
                        WasteStreamGuidance(wasteType: WasteType.compost, collectionDays: [.tuesday, .thursday], containerType: ContainerType.brownBin, specialInstructions: "Brown bins - organics collection")
                    ]
                )
                
            case CanonicalIDs.Buildings.westSeventeenth138:
                schedules[buildingId] = BuildingDSNYSchedule(
                    buildingId: buildingId,
                    buildingName: "138 West 17th Street",
                    unitCount: 8, // Floors 3-10 residential (2nd floor + ground = museum/offices)
                    collectionDays: [CollectionDay.tuesday, CollectionDay.thursday, CollectionDay.saturday],
                    binSetOutTime: DSNYTime(hour: 19, minute: 0),
                    binRetrievalTime: DSNYTime(hour: 11, minute: 15),
                    binLocation: "curbside",
                    specialInstructions: "Edwin covers Saturday retrieval for Kevin's buildings",
                    wasteStreams: [
                        WasteStreamGuidance(wasteType: WasteType.trash, collectionDays: [.tuesday, .thursday, .saturday], containerType: ContainerType.blackBin, specialInstructions: "Black bins required for 8 residential units"),
                        WasteStreamGuidance(wasteType: WasteType.recycling, collectionDays: [CollectionDay.thursday, CollectionDay.saturday], containerType: ContainerType.greenBin, specialInstructions: "Green bins - same as 136 W 17th"),
                        WasteStreamGuidance(wasteType: WasteType.compost, collectionDays: [CollectionDay.tuesday, CollectionDay.thursday], containerType: ContainerType.brownBin, specialInstructions: "Brown bins - organics collection")
                    ]
                )

            case CanonicalIDs.Buildings.westEighteenth112:
                schedules[buildingId] = BuildingDSNYSchedule(
                    buildingId: buildingId,
                    buildingName: "112 West 18th Street",
                    unitCount: 6,
                    collectionDays: [CollectionDay.tuesday, CollectionDay.thursday, CollectionDay.saturday], // Align with nearby blocks
                    binSetOutTime: DSNYTime(hour: 19, minute: 0),
                    binRetrievalTime: DSNYTime(hour: 9, minute: 30),
                    binLocation: "curbside",
                    specialInstructions: "Coordinate with hallway/lobby clean",
                    wasteStreams: [
                        WasteStreamGuidance(wasteType: WasteType.trash, collectionDays: [.tuesday, .thursday, .saturday], containerType: ContainerType.blackBin, specialInstructions: "Black bins for ≤9 residential units"),
                        WasteStreamGuidance(wasteType: WasteType.recycling, collectionDays: [.thursday, .saturday], containerType: ContainerType.greenBin, specialInstructions: "Green bins - standard recycling"),
                        WasteStreamGuidance(wasteType: WasteType.compost, collectionDays: [.tuesday, .thursday], containerType: ContainerType.brownBin, specialInstructions: "Brown bins - organics collection")
                    ]
                )
                
            case CanonicalIDs.Buildings.chambers148:
                schedules[buildingId] = BuildingDSNYSchedule(
                    buildingId: buildingId,
                    buildingName: "148 Chambers Street",
                    unitCount: 7,
                    collectionDays: [CollectionDay.monday, CollectionDay.wednesday, CollectionDay.saturday],
                    binSetOutTime: DSNYTime(hour: 18, minute: 0),
                    binRetrievalTime: DSNYTime(hour: 12, minute: 0),
                    binLocation: "curbside",
                    specialInstructions: "Part of Edwin's structured morning sequence",
                    wasteStreams: [
                        WasteStreamGuidance(wasteType: WasteType.trash, collectionDays: [.monday, .wednesday, .saturday], containerType: ContainerType.blackBin, specialInstructions: "Black bins required for 7 residential units"),
                        WasteStreamGuidance(wasteType: WasteType.recycling, collectionDays: [CollectionDay.wednesday, CollectionDay.saturday], containerType: ContainerType.greenBin, specialInstructions: "Green bins - TriBeCa/Financial district"),
                        WasteStreamGuidance(wasteType: WasteType.compost, collectionDays: [CollectionDay.monday, CollectionDay.wednesday], containerType: ContainerType.brownBin, specialInstructions: "Brown bins - organics collection")
                    ]
                )
                
            default:
                // Log unknown building that needs bins but no schedule defined
                print("⚠️ DSNY: Building \(buildingId) requires bins but no collection schedule defined")
            }
        }
        
        return schedules
    }()

    // MARK: - Bin Management Lists

    /// Returns all buildings that are managed via individual bins with their schedules
    public static func getBinManagementBuildings() -> [BuildingDSNYSchedule] {
        return Array(buildingCollectionSchedules.values)
            .sorted { $0.buildingName < $1.buildingName }
    }

    /// Plan of set-out (evening before) and retrieval (collection day) for each bin-managed building
    public static func getBinManagementPlan() -> [BinManagementPlan] {
        return buildingCollectionSchedules.values.map { schedule in
            let retrievalDays = schedule.collectionDays
            let setOutDays = retrievalDays.map { $0.previousDay() }
            return BinManagementPlan(
                buildingId: schedule.buildingId,
                buildingName: schedule.buildingName,
                setOutDays: setOutDays,
                retrievalDays: retrievalDays,
                binSetOutTime: schedule.binSetOutTime,
                binRetrievalTime: schedule.binRetrievalTime
            )
        }.sorted { $0.buildingName < $1.buildingName }
    }
    
    // MARK: - Schedule Query Methods
    
    /// Check if a building has collection on a specific day
    public static func hasCollection(buildingId: String, on day: CollectionDay) -> Bool {
        guard let schedule = buildingCollectionSchedules[buildingId] else { return false }
        return schedule.collectionDays.contains(day)
    }
    
    /// Get buildings that need bins set out today (evening before collection)
    public static func getBuildingsForBinSetOut(on day: CollectionDay) -> [BuildingDSNYSchedule] {
        let tomorrow = day.nextDay()
        return buildingCollectionSchedules.values.filter { schedule in
            schedule.collectionDays.contains(tomorrow)
        }
    }
    
    /// Get buildings that need bins retrieved today (morning after collection)
    public static func getBuildingsForBinRetrieval(on day: CollectionDay) -> [BuildingDSNYSchedule] {
        return buildingCollectionSchedules.values.filter { schedule in
            schedule.collectionDays.contains(day)
        }
    }
    
    /// Get bin retrieval tasks for a specific worker on a specific day
    public static func getBinRetrievalTasks(for workerId: String, on day: CollectionDay) -> [OperationTask] {
        let buildingsToRetrieve = getBuildingsForBinRetrieval(on: day)
        var tasks: [OperationTask] = []
        
        for schedule in buildingsToRetrieve {
            // Determine if this worker handles this building
            if shouldWorkerHandleBuilding(workerId: workerId, buildingId: schedule.buildingId, on: day) {
                let task = OperationTask(
                    id: "bin_retrieval_\(schedule.buildingId)_\(day.rawValue.lowercased())",
                    name: "Bin Retrieval - \(schedule.buildingName)",
                    category: .binManagement,
                    location: .curbside,
                    estimatedDuration: 10 * 60, // 10 minutes
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "Bring trash bins back inside after DSNY collection. \(schedule.specialInstructions)"
                )
                tasks.append(task)
            }
        }
        
        return tasks
    }
    
    /// Generate bin set-out reminders for evening operations
    public static func getBinSetOutReminders(for day: CollectionDay) -> [DSNYReminder] {
        let buildingsToSetOut = getBuildingsForBinSetOut(on: day)
        return buildingsToSetOut.map { schedule in
            DSNYReminder(
                buildingId: schedule.buildingId,
                buildingName: schedule.buildingName,
                action: .setOut,
                scheduledTime: schedule.binSetOutTime,
                collectionDay: day.nextDay(),
                instructions: "Set out bins at \(schedule.binLocation). \(schedule.specialInstructions)"
            )
        }
    }
    
    /// Determine which worker should handle a building's bin management
    private static func shouldWorkerHandleBuilding(workerId: String, buildingId: String, on day: CollectionDay) -> Bool {
        switch buildingId {
        case CanonicalIDs.Buildings.springStreet178, 
             CanonicalIDs.Buildings.chambers148:
            // Edwin handles these during his morning sequence
            return workerId == CanonicalIDs.Workers.edwinLema
            
        case CanonicalIDs.Buildings.perry68:
            // Kevin handles Perry Street
            return workerId == CanonicalIDs.Workers.kevinDutan
            
        case CanonicalIDs.Buildings.perry131:
            // Align with Perry corridor – Kevin
            return workerId == CanonicalIDs.Workers.kevinDutan

        case CanonicalIDs.Buildings.firstAvenue123:
            // Kevin handles 1st Ave during his M W F afternoon rotation
            return workerId == CanonicalIDs.Workers.kevinDutan && 
                   [CollectionDay.monday, CollectionDay.wednesday, CollectionDay.friday].contains(day)
            
        case CanonicalIDs.Buildings.westSeventeenth136,
             CanonicalIDs.Buildings.westSeventeenth138:
            // Kevin handles these on weekdays, Edwin covers Saturday
            if day == CollectionDay.saturday {
                return workerId == CanonicalIDs.Workers.edwinLema
            } else {
                return workerId == CanonicalIDs.Workers.kevinDutan
            }

        case CanonicalIDs.Buildings.westSeventeenth117:
            // Same pattern as adjacent West 17th buildings
            if day == CollectionDay.saturday {
                return workerId == CanonicalIDs.Workers.edwinLema
            } else {
                return workerId == CanonicalIDs.Workers.kevinDutan
            }

        case CanonicalIDs.Buildings.westEighteenth112:
            // Default Kevin assignment for this corridor
            return workerId == CanonicalIDs.Workers.kevinDutan
            
        default:
            return false
        }
    }
}

// MARK: - Supporting Types

public struct BuildingDSNYSchedule {
    public let buildingId: String
    public let buildingName: String
    public let unitCount: Int
    public let collectionDays: [CollectionDay]
    public let binSetOutTime: DSNYTime
    public let binRetrievalTime: DSNYTime
    public let binLocation: String
    public let specialInstructions: String
    public let wasteStreams: [WasteStreamGuidance]
    
    public var dsnyCompliance: DSNYCompliance {
        if unitCount <= 9 {
            return .individualBinsRequired
        } else if unitCount <= 30 {
            return .choiceBetweenBinsAndEmpire
        } else {
            return .empireContainersRequired
        }
    }
}

public struct DSNYTime {
    public let hour: Int
    public let minute: Int
    
    public var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

public enum CollectionDay: String, CaseIterable {
    case monday = "Monday"
    case tuesday = "Tuesday" 
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"
    case sunday = "Sunday"
    
    public static func from(weekday: Int) -> CollectionDay {
        // Calendar weekday: 1 = Sunday, 2 = Monday, etc.
        switch weekday {
        case 1: return CollectionDay.sunday
        case 2: return CollectionDay.monday
        case 3: return CollectionDay.tuesday
        case 4: return CollectionDay.wednesday
        case 5: return CollectionDay.thursday
        case 6: return CollectionDay.friday
        case 7: return CollectionDay.saturday
        default: return CollectionDay.monday
        }
    }
    
    public func nextDay() -> CollectionDay {
        switch self {
        case .sunday: return CollectionDay.monday
        case .monday: return CollectionDay.tuesday
        case .tuesday: return CollectionDay.wednesday
        case .wednesday: return CollectionDay.thursday
        case .thursday: return CollectionDay.friday
        case .friday: return CollectionDay.saturday
        case .saturday: return CollectionDay.sunday
        }
    }

    public func previousDay() -> CollectionDay {
        switch self {
        case .sunday: return CollectionDay.saturday
        case .monday: return CollectionDay.sunday
        case .tuesday: return CollectionDay.monday
        case .wednesday: return CollectionDay.tuesday
        case .thursday: return CollectionDay.wednesday
        case .friday: return CollectionDay.thursday
        case .saturday: return CollectionDay.friday
        }
    }
}

// BinLocation is now defined in CoreTypes.swift to avoid duplication

public struct DSNYReminder {
    public let buildingId: String
    public let buildingName: String
    public let action: DSNYAction
    public let scheduledTime: DSNYTime
    public let collectionDay: CollectionDay
    public let instructions: String
}

public enum DSNYAction {
    case setOut
    case retrieve
}

public enum DSNYCompliance: String, CaseIterable, Codable {
    case individualBinsRequired = "Individual bins required"
    case choiceBetweenBinsAndEmpire = "Choice: bins or Empire containers"
    case empireContainersRequired = "Empire containers required"
}

public struct WasteStreamGuidance {
    public let wasteType: WasteType
    public let collectionDays: [CollectionDay]
    public let containerType: ContainerType
    public let specialInstructions: String
    
    public init(wasteType: WasteType, collectionDays: [CollectionDay], containerType: ContainerType, specialInstructions: String = "") {
        self.wasteType = wasteType
        self.collectionDays = collectionDays
        self.containerType = containerType
        self.specialInstructions = specialInstructions
    }
}

public enum WasteType: String, CaseIterable {
    case trash = "Trash"
    case recycling = "Recycling"  
    case compost = "Compost"
    case bulky = "Bulky Items"
    case electronics = "Electronics"
}

public enum ContainerType: String {
    case blackBin = "Black Bin"
    case greenBin = "Green Bin" 
    case brownBin = "Brown Bin"
    case blackBags = "Black Bags"
    case clearBags = "Clear Bags"
    case empireContainer = "Empire Container"
}

// MARK: - Integration Helpers

extension DSNYCollectionSchedule {
    
    /// Get today's bin management tasks for route integration
    public static func getTodaysBinTasks() -> [String: [OperationTask]] {
        let today = CollectionDay.from(weekday: Calendar.current.component(.weekday, from: Date()))
        
        return [
            CanonicalIDs.Workers.kevinDutan: getBinRetrievalTasks(for: CanonicalIDs.Workers.kevinDutan, on: today),
            CanonicalIDs.Workers.edwinLema: getBinRetrievalTasks(for: CanonicalIDs.Workers.edwinLema, on: today)
        ]
    }
    
    /// Check if building needs bin retrieval during a specific route sequence
    public static func needsBinRetrieval(buildingId: String, on day: CollectionDay) -> Bool {
        return hasCollection(buildingId: buildingId, on: day)
    }
}

// MARK: - Summary Types

public struct BinManagementPlan {
    public let buildingId: String
    public let buildingName: String
    public let setOutDays: [CollectionDay]
    public let retrievalDays: [CollectionDay]
    public let binSetOutTime: DSNYTime
    public let binRetrievalTime: DSNYTime
}
