//
//  EdwinLemaRoutes.swift
//  CyntientOps
//
//  Edwin Lema's operational routes and specialized tasks
//  Focuses on repairs, maintenance, and Stuyvesant Cove Park
//

import Foundation

// MARK: - Edwin Lema Route Definitions

public struct EdwinLemaRoutes {
    
    // MARK: - Weekly Route Patterns
    
    /// Edwin's complete weekly schedule
    public static func getWeeklyRoutes() -> [WorkerRoute] {
        return [
            mondayRoute(),
            tuesdayRoute(),
            wednesdayRoute(),
            thursdayRoute(),
            fridayRoute(),
            saturdayRoute()
            // Edwin is off Sundays
        ]
    }
    
    // MARK: - Daily Routes
    
    /// Monday Route (Park Day + Building Sequence)
    public static func mondayRoute() -> WorkerRoute {
        let routeId = "edwin_monday_route"
        let startTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()
        
        return WorkerRoute(
            id: routeId,
            workerId: CanonicalIDs.Workers.edwinLema,
            routeName: "Edwin Monday - Park + Building Circuit",
            dayOfWeek: 2, // Monday
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [
                // Morning structured sequence: Park → Spring → Franklin → Chambers
                stuyvesantCoveParkSequence(day: "Monday", time: 7, 0),
                springSt178Sequence(day: "Monday", time: 10, 30, isBinDay: true),
                franklin104Sequence(day: "Monday", time: 11, 30),
                chambers148Sequence(day: "Monday", time: 12, 0, isBinDay: true),
                // Afternoon: walkthroughs, repairs, projects, vendor access as needed
                afternoonRepairsSequence(day: "Monday", time: 13, 30),
                vendorAccessAvailability(day: "Monday", time: 15, 0)
            ],
            routeType: .morningCleaning
        )
    }
    
    /// Tuesday Route (Building Circuit without Park)
    public static func tuesdayRoute() -> WorkerRoute {
        let routeId = "edwin_tuesday_route"
        let startTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()
        
        return WorkerRoute(
            id: routeId,
            workerId: CanonicalIDs.Workers.edwinLema,
            routeName: "Edwin Tuesday - Building Circuit (No Park)",
            dayOfWeek: 3, // Tuesday
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: {
                var seq: [RouteSequence] = []
                // Start directly with building sequence (no park)
                seq.append(springSt178Sequence(day: "Tuesday", time: 8, 0, isBinDay: true))
                // After Spring, go to Franklin and Walker
                seq.append(franklin104Sequence(day: "Tuesday", time: 9, 0))
                seq.append(walker36Sequence(day: "Tuesday", time: 9, 30))
                // Chambers if bin retrieval day
                let day = CollectionDay.tuesday
                if DSNYCollectionSchedule.hasCollection(buildingId: CanonicalIDs.Buildings.chambers148, on: day) {
                    seq.append(chambers148Sequence(day: "Tuesday", time: 10, 30, isBinDay: true))
                }
                // 123 1st Ave on bin retrieval day
                if DSNYCollectionSchedule.hasCollection(buildingId: CanonicalIDs.Buildings.firstAvenue123, on: day) {
                    seq.append(firstAve123BinRetrievalSequence(day: "Tuesday", time: 11, 15))
                }
                // Continue with general ops
                seq.append(buildingWalkthroughsSequence(day: "Tuesday", time: 12, 0))
                seq.append(vendorAccessSequence(day: "Tuesday", time: 13, 0))
                seq.append(afternoonRepairsSequence(day: "Tuesday", time: 14, 0))
                seq.append(boilerBlowdownSequence(day: "Tuesday", time: 15, 0))
                return seq
            }(),
            routeType: .afternoonMaintenance
        )
    }
    
    /// Wednesday Route (Park Day + Building Sequence)  
    public static func wednesdayRoute() -> WorkerRoute {
        let routeId = "edwin_wednesday_route"
        let startTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()
        
        return WorkerRoute(
            id: routeId,
            workerId: CanonicalIDs.Workers.edwinLema,
            routeName: "Edwin Wednesday - Park + Building Circuit",
            dayOfWeek: 4, // Wednesday
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [
                // Morning structured sequence: Park → Spring → Franklin → Chambers
                stuyvesantCoveParkSequence(day: "Wednesday", time: 7, 0),
                springSt178Sequence(day: "Wednesday", time: 10, 30, isBinDay: true),
                franklin104Sequence(day: "Wednesday", time: 11, 30),
                chambers148Sequence(day: "Wednesday", time: 12, 0, isBinDay: true),
                // Afternoon: walkthroughs, repairs, projects, vendor access as needed
                afternoonRepairsSequence(day: "Wednesday", time: 13, 30),
                vendorAccessAvailability(day: "Wednesday", time: 15, 0)
            ],
            routeType: .morningCleaning
        )
    }
    
    /// Thursday Route (Building Circuit without Park)
    public static func thursdayRoute() -> WorkerRoute {
        let routeId = "edwin_thursday_route"
        let startTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()
        
        return WorkerRoute(
            id: routeId,
            workerId: CanonicalIDs.Workers.edwinLema,
            routeName: "Edwin Thursday - Building Circuit (No Park)",
            dayOfWeek: 5, // Thursday
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [
                // Start directly with building sequence (no park)
                springSt178Sequence(day: "Thursday", time: 8, 0, isBinDay: true), // Thursday bin day
                franklin104Sequence(day: "Thursday", time: 9, 0),
                chambers148Sequence(day: "Thursday", time: 9, 30, isBinDay: true), // Thursday bin day
                // Extended time for walkthroughs, projects, and repairs
                buildingWalkthroughsSequence(day: "Thursday", time: 10, 30),
                specializedMaintenanceSequence(day: "Thursday", time: 12, 0),
                afternoonRepairsSequence(day: "Thursday", time: 13, 30),
                capitalProjectWorkSequence(day: "Thursday", time: 15, 0)
            ],
            routeType: .afternoonMaintenance
        )
    }
    
    /// Friday Route (Park Day + Building Sequence)
    public static func fridayRoute() -> WorkerRoute {
        let routeId = "edwin_friday_route"
        let startTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()
        
        return WorkerRoute(
            id: routeId,
            workerId: CanonicalIDs.Workers.edwinLema,
            routeName: "Edwin Friday - Park + Building Circuit",
            dayOfWeek: 6, // Friday
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [
                // Morning structured sequence: Park → Spring → Franklin → Chambers
                stuyvesantCoveParkSequence(day: "Friday", time: 7, 0),
                springSt178Sequence(day: "Friday", time: 10, 30, isBinDay: false), // No bins on Friday
                franklin104Sequence(day: "Friday", time: 11, 30),
                chambers148Sequence(day: "Friday", time: 12, 0, isBinDay: false), // No bins on Friday
                // Afternoon: weekly tasks, repairs, projects
                weeklyMaintenanceTasksSequence(day: "Friday", time: 13, 30),
                vendorAccessAvailability(day: "Friday", time: 14, 30)
            ],
            routeType: .morningCleaning
        )
    }
    
    /// Saturday Route (Park + Building Sequence + Kevin's Coverage)
    public static func saturdayRoute() -> WorkerRoute {
        let routeId = "edwin_saturday_route"
        let startTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()
        
        return WorkerRoute(
            id: routeId,
            workerId: CanonicalIDs.Workers.edwinLema,
            routeName: "Edwin Saturday - Park + Building Circuit + Coverage",
            dayOfWeek: 7, // Saturday
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [
                // Morning structured sequence: Park → Spring → Franklin → Chambers (with Saturday tasks)
                stuyvesantCoveParkSequence(day: "Saturday", time: 7, 0),
                springSt178Sequence(day: "Saturday", time: 10, 0, isBinDay: true), // Saturday bin day
                franklin104Sequence(day: "Saturday", time: 10, 45),
                chambers148Sequence(day: "Saturday", time: 11, 0, isBinDay: true), // Saturday bin day  
                // Kevin's 17th/18th street coverage 
                saturdayBuildingCoverageSequence(day: "Saturday", time: 11, 45)
            ],
            routeType: .morningCleaning
        )
    }
    
    // MARK: - Sequence Builders
    
    /// Stuyvesant Cove Park operations (M W F Sat mornings)
    private static func stuyvesantCoveParkSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "edwin_stuyvesant_park_\(day.lowercased())",
            buildingId: CanonicalIDs.Buildings.stuyvesantCove,
            buildingName: "Stuyvesant Cove Park",
            arrivalTime: arrivalTime,
            estimatedDuration: 210 * 60, // 3.5 hours
            operations: [
                OperationTask(
                    id: "park_pathways_cleaning_\(day.lowercased())",
                    name: "Park Pathways & Walkways Cleaning",
                    category: .sweeping,
                    location: .exterior,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic,
                    instructions: "\(day): Clean all park pathways, remove debris and litter"
                ),
                OperationTask(
                    id: "park_landscaping_maintenance_\(day.lowercased())",
                    name: "Park Landscaping Maintenance",
                    category: .treepitCleaning,
                    location: .exterior,
                    estimatedDuration: 90 * 60,
                    isWeatherSensitive: true,
                    requiredEquipment: ["Hand tools", "Pruning shears", "Leaf blower"],
                    skillLevel: .intermediate,
                    instructions: "Tree pit cleaning, shrub maintenance, leaf removal"
                ),
                OperationTask(
                    id: "park_trash_collection_\(day.lowercased())",
                    name: "Park Trash Collection & Bin Management",
                    category: .trashCollection,
                    location: .exterior,
                    estimatedDuration: 45 * 60,
                    isWeatherSensitive: false,
                    instructions: "Empty all park trash receptacles, replace liners"
                ),
                OperationTask(
                    id: "park_facility_inspection_\(day.lowercased())",
                    name: "Park Facility Inspection",
                    category: .buildingInspection,
                    location: .exterior,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: false,
                    instructions: "Inspect benches, lighting, safety equipment"
                )
            ],
            sequenceType: .outdoorCleaning,
            isFlexible: true // Can adjust based on weather
        )
    }
    
    /// Building walkthroughs and vendor access
    private static func buildingWalkthroughsSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "edwin_building_walkthroughs_\(day.lowercased())",
            buildingId: "multiple_buildings",
            buildingName: "Building Walkthroughs",
            arrivalTime: arrivalTime,
            estimatedDuration: 120 * 60, // 2 hours
            operations: [
                OperationTask(
                    id: "building_condition_assessment_\(day.lowercased())",
                    name: "Building Condition Assessment",
                    category: .buildingInspection,
                    location: .hallway,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .intermediate,
                    instructions: "\(day): Comprehensive walkthrough of assigned buildings"
                ),
                OperationTask(
                    id: "maintenance_issue_identification_\(day.lowercased())",
                    name: "Maintenance Issue Identification",
                    category: .buildingInspection,
                    location: .exterior,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .intermediate,
                    requiresPhoto: true,
                    instructions: "Document maintenance needs and safety issues"
                )
            ],
            sequenceType: .inspection,
            isFlexible: true
        )
    }
    
    /// Vendor access coordination
    private static func vendorAccessSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "edwin_vendor_access_\(day.lowercased())",
            buildingId: "various",
            buildingName: "Vendor Access Coordination",
            arrivalTime: arrivalTime,
            estimatedDuration: 120 * 60,
            operations: [
                OperationTask(
                    id: "vendor_coordination_\(day.lowercased())",
                    name: "Vendor Access Coordination",
                    category: .buildingInspection,
                    location: .entrance,
                    estimatedDuration: 120 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .intermediate,
                    instructions: "\(day): Coordinate and supervise vendor access to buildings"
                )
            ],
            sequenceType: .operations,
            isFlexible: false // Scheduled vendor appointments
        )
    }
    
    /// Afternoon repairs (after lunch hours)
    private static func afternoonRepairsSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "edwin_afternoon_repairs_\(day.lowercased())",
            buildingId: "as_needed",
            buildingName: "Repair Work",
            arrivalTime: arrivalTime,
            estimatedDuration: 120 * 60, // 2 hours
            operations: [
                OperationTask(
                    id: "priority_repairs_\(day.lowercased())",
                    name: "Priority Repair Work",
                    category: .maintenance,
                    location: .exterior,
                    estimatedDuration: 90 * 60,
                    isWeatherSensitive: true,
                    requiredEquipment: ["Tool kit", "Repair materials"],
                    skillLevel: .advanced,
                    instructions: "\(day): Address urgent repair items from walkthrough reports"
                ),
                OperationTask(
                    id: "preventive_maintenance_\(day.lowercased())",
                    name: "Preventive Maintenance Tasks",
                    category: .maintenance,
                    location: .basement,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .intermediate,
                    instructions: "Routine preventive maintenance tasks"
                )
            ],
            sequenceType: .maintenance,
            isFlexible: true
        )
    }
    
    /// Weekly roof drain inspections
    private static func weeklyRoofDrainInspection(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "edwin_roof_drain_inspection_\(day.lowercased())",
            buildingId: "multiple_buildings",
            buildingName: "Roof Drain Inspection",
            arrivalTime: arrivalTime,
            estimatedDuration: 60 * 60,
            operations: [
                OperationTask(
                    id: "roof_drain_check_\(day.lowercased())",
                    name: "Roof Drain Inspection & Clearing",
                    category: .maintenance,
                    location: .exterior,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false, // Actually needs to be done regardless of weather
                    requiredEquipment: ["Ladder", "Safety equipment", "Drain snake"],
                    skillLevel: .intermediate,
                    instructions: "\(day): Check all roof drains for blockages, clear as needed"
                )
            ],
            sequenceType: .maintenance,
            isFlexible: false // Critical for building safety
        )
    }
    
    /// Weekly boiler blowdowns
    private static func boilerBlowdownSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "edwin_boiler_blowdown_\(day.lowercased())",
            buildingId: "buildings_with_boilers",
            buildingName: "Boiler Maintenance",
            arrivalTime: arrivalTime,
            estimatedDuration: 90 * 60,
            operations: [
                OperationTask(
                    id: "boiler_blowdown_\(day.lowercased())",
                    name: "Weekly Boiler Blowdown",
                    category: .maintenance,
                    location: .basement,
                    estimatedDuration: 90 * 60,
                    isWeatherSensitive: false,
                    requiredEquipment: ["Safety equipment", "Boiler tools"],
                    skillLevel: .advanced,
                    instructions: "\(day): Perform weekly boiler blowdowns on all buildings with boiler systems"
                )
            ],
            sequenceType: .maintenance,
            isFlexible: false // Critical maintenance schedule
        )
    }
    
    /// Kevin coverage while he's on vacation
    private static func kevinCoverageSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "edwin_kevin_coverage_\(day.lowercased())",
            buildingId: "17th_street_complex",
            buildingName: "Kevin Coverage - 17th Street",
            arrivalTime: arrivalTime,
            estimatedDuration: 90 * 60,
            operations: [
                OperationTask(
                    id: "coverage_morning_routine_\(day.lowercased())",
                    name: "Morning Routine Coverage",
                    category: .sweeping,
                    location: .sidewalk,
                    estimatedDuration: 45 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic,
                    instructions: "\(day): Cover Kevin's morning sidewalk and entrance cleaning"
                ),
                OperationTask(
                    id: "coverage_trash_areas_\(day.lowercased())",
                    name: "Trash Area Coverage",
                    category: .trashCollection,
                    location: .trashArea,
                    estimatedDuration: 45 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "Cover Kevin's trash area responsibilities"
                )
            ],
            sequenceType: .indoorCleaning,
            isFlexible: true
        )
    }
    
    /// Specialized maintenance tasks
    private static func specializedMaintenanceSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "edwin_specialized_maintenance_\(day.lowercased())",
            buildingId: "various",
            buildingName: "Specialized Maintenance",
            arrivalTime: arrivalTime,
            estimatedDuration: 180 * 60, // 3 hours
            operations: [
                OperationTask(
                    id: "water_filter_change_112_117_\(day.lowercased())",
                    name: "Water Filter Changes - 112 & 117 W 17th",
                    category: .maintenance,
                    location: .basement,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    requiredEquipment: ["New filters", "Tools"],
                    skillLevel: .intermediate,
                    instructions: "\(day): Monthly water filter replacement for buildings 112 and 117"
                ),
                OperationTask(
                    id: "hvac_system_check_\(day.lowercased())",
                    name: "HVAC System Inspection",
                    category: .maintenance,
                    location: .basement,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .advanced,
                    instructions: "Check HVAC systems, filters, and operation"
                ),
                OperationTask(
                    id: "plumbing_inspection_\(day.lowercased())",
                    name: "Plumbing System Inspection",
                    category: .maintenance,
                    location: .basement,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .advanced,
                    instructions: "Inspect plumbing systems for leaks and issues"
                )
            ],
            sequenceType: .maintenance,
            isFlexible: false // Scheduled maintenance
        )
    }
    
    /// Capital project work
    private static func capitalProjectWorkSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "edwin_capital_projects_\(day.lowercased())",
            buildingId: "project_locations",
            buildingName: "Capital Improvement Projects",
            arrivalTime: arrivalTime,
            estimatedDuration: 90 * 60,
            operations: [
                OperationTask(
                    id: "basement_painting_148chambers_\(day.lowercased())",
                    name: "Basement Painting Project - 148 Chambers",
                    category: .maintenance,
                    location: .basement,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    requiredEquipment: ["Paint", "Brushes", "Drop cloths", "Ventilation"],
                    skillLevel: .intermediate,
                    instructions: "\(day): Continue basement painting at 148 Chambers Street"
                ),
                OperationTask(
                    id: "stairwell_painting_178spring_\(day.lowercased())",
                    name: "Stairwell Painting Project - 178 Spring",
                    category: .maintenance,
                    location: .stairwell,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: false,
                    requiredEquipment: ["Paint", "Brushes", "Drop cloths"],
                    skillLevel: .intermediate,
                    instructions: "Continue stairwell painting at 178 Spring Street"
                )
            ],
            sequenceType: .maintenance,
            isFlexible: false // Project deadlines
        )
    }
    
    /// Weekly maintenance tasks compilation
    private static func weeklyMaintenanceTasksSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "edwin_weekly_tasks_\(day.lowercased())",
            buildingId: "various",
            buildingName: "Weekly Maintenance Tasks",
            arrivalTime: arrivalTime,
            estimatedDuration: 120 * 60,
            operations: [
                OperationTask(
                    id: "weekly_system_checks_\(day.lowercased())",
                    name: "Weekly System Checks",
                    category: .maintenance,
                    location: .basement,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .intermediate,
                    instructions: "\(day): Systematic check of all building systems"
                ),
                OperationTask(
                    id: "safety_equipment_inspection_\(day.lowercased())",
                    name: "Safety Equipment Inspection",
                    category: .buildingInspection,
                    location: .hallway,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "Check fire extinguishers, emergency lighting, exits"
                )
            ],
            sequenceType: .maintenance,
            isFlexible: true
        )
    }
    
    /// Saturday building coverage (Kevin's weekend work)
    private static func saturdayBuildingCoverageSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "edwin_saturday_building_coverage_\(day.lowercased())",
            buildingId: "17th_18th_street_buildings",
            buildingName: "Saturday Building Coverage (Kevin's Route)",
            arrivalTime: arrivalTime,
            estimatedDuration: 240 * 60, // 4 hours
            operations: [
                OperationTask(
                    id: "saturday_bins_retrieval_\(day.lowercased())",
                    name: "Trash Bins Retrieval - Bring Inside",
                    category: .binManagement,
                    location: .curbside,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "\(day): Bring back inside all trash bins that Angel put out Friday evening for collection"
                ),
                OperationTask(
                    id: "saturday_sidewalk_routine_17th_\(day.lowercased())",
                    name: "Sidewalk Cleaning - 17th Street Buildings",
                    category: .hosing,
                    location: .sidewalk,
                    estimatedDuration: 90 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic,
                    instructions: "\(day): Saturday sidewalk routine for 112, 117, 135-139, 136, 138, 142-148 W 17th"
                ),
                OperationTask(
                    id: "saturday_sidewalk_routine_12w18_\(day.lowercased())",
                    name: "Sidewalk Cleaning - 12 W 18th Street", 
                    category: .hosing,
                    location: .sidewalk,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic,
                    instructions: "Saturday sidewalk cleaning for 12 West 18th Street"
                ),
                OperationTask(
                    id: "saturday_trash_areas_coverage_\(day.lowercased())",
                    name: "Trash Area Cleaning - Weekend Coverage",
                    category: .trashCollection,
                    location: .trashArea,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "Saturday trash area cleaning for 17th & 18th street buildings"
                )
            ],
            sequenceType: .outdoorCleaning,
            isFlexible: true // Can adjust order based on weather
        )
    }
    
    // MARK: - New Structured Building Sequence Methods
    
    /// 178 Spring Street sequence (hose sidewalk, clean glass door, clean trash room, weekly stairwell)
    private static func springSt178Sequence(day: String, time hour: Int, _ minute: Int, isBinDay: Bool) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        let collectionDay = CollectionDay(rawValue: day) ?? .monday
        
        var operations: [OperationTask] = [
            OperationTask(
                id: "spring178_sidewalk_hose_\(day.lowercased())",
                name: "Sidewalk Hosing - 178 Spring Street",
                category: .hosing,
                location: .sidewalk,
                estimatedDuration: 15 * 60,
                isWeatherSensitive: true,
                skillLevel: .basic,
                instructions: "\(day): Hose and clean sidewalk in front of 178 Spring Street"
            ),
            OperationTask(
                id: "spring178_glass_door_\(day.lowercased())",
                name: "Glass Door Cleaning - 178 Spring Street",
                category: .maintenance,
                location: .entrance,
                estimatedDuration: 10 * 60,
                isWeatherSensitive: false,
                skillLevel: .basic,
                instructions: "Clean glass entrance door, remove fingerprints and spots"
            ),
            OperationTask(
                id: "spring178_trash_room_\(day.lowercased())",
                name: "Trash Room Area Cleaning - 178 Spring Street",
                category: .trashCollection,
                location: .trashArea,
                estimatedDuration: 15 * 60,
                isWeatherSensitive: false,
                skillLevel: .basic,
                instructions: "Clean trash room area, sweep, mop if needed"
            )
        ]
        
        // Use DSNY schedule system to determine bin management
        let needsBinRetrieval = DSNYCollectionSchedule.needsBinRetrieval(
            buildingId: CanonicalIDs.Buildings.springStreet178, 
            on: collectionDay
        )
        
        if needsBinRetrieval {
            let dsnyTasks = DSNYCollectionSchedule.getBinRetrievalTasks(
                for: CanonicalIDs.Workers.edwinLema, 
                on: collectionDay
            )
            operations.append(contentsOf: dsnyTasks)
        }
        
        // Add weekly stairwell cleaning (once per week)
        if day == "Wednesday" {
            operations.append(
                OperationTask(
                    id: "spring178_stairwell_weekly_\(day.lowercased())",
                    name: "Weekly Stairwell Vacuum & Mop - 178 Spring Street",
                    category: .stairwellCleaning,
                    location: .stairwell,
                    estimatedDuration: 20 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "Weekly stairwell vacuum and mop - all floors"
                )
            )
        }
        
        return RouteSequence(
            id: "edwin_spring178_\(day.lowercased())",
            buildingId: CanonicalIDs.Buildings.springStreet178,
            buildingName: "178 Spring Street",
            arrivalTime: arrivalTime,
            estimatedDuration: TimeInterval(operations.reduce(0) { $0 + Int($1.estimatedDuration) }),
            operations: operations,
            sequenceType: .maintenance,
            isFlexible: false,
            dependencies: ["edwin_stuyvesant_park_\(day.lowercased())"]
        )
    }
    
    /// 104 Franklin Street sequence (sidewalk hose)
    private static func franklin104Sequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "edwin_franklin104_\(day.lowercased())",
            buildingId: CanonicalIDs.Buildings.franklin104,
            buildingName: "104 Franklin Street",
            arrivalTime: arrivalTime,
            estimatedDuration: 15 * 60, // 15 minutes
            operations: [
                OperationTask(
                    id: "franklin104_sidewalk_hose_\(day.lowercased())",
                    name: "Sidewalk Hosing - 104 Franklin Street",
                    category: .hosing,
                    location: .sidewalk,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic,
                    instructions: "\(day): Hose and clean sidewalk in front of 104 Franklin Street"
                )
            ],
            sequenceType: .outdoorCleaning,
            isFlexible: false,
            dependencies: ["edwin_spring178_\(day.lowercased())"]
        )
    }
    
    /// 148 Chambers Street sequence (sidewalk hose, bins, elevator steel, glass, trash area)
    private static func chambers148Sequence(day: String, time hour: Int, _ minute: Int, isBinDay: Bool) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        let collectionDay = CollectionDay(rawValue: day) ?? .monday
        
        var operations: [OperationTask] = [
            OperationTask(
                id: "chambers148_sidewalk_hose_\(day.lowercased())",
                name: "Sidewalk Hosing - 148 Chambers Street",
                category: .hosing,
                location: .sidewalk,
                estimatedDuration: 15 * 60,
                isWeatherSensitive: true,
                skillLevel: .basic,
                instructions: "\(day): Hose and clean sidewalk in front of 148 Chambers Street"
            ),
                OperationTask(
                    id: "chambers148_elevator_steel_\(day.lowercased())",
                    name: "Elevator Stainless Steel Cleaning - 148 Chambers",
                    category: .maintenance,
                    location: .hallway,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .intermediate,
                    instructions: "Clean and polish elevator stainless steel surfaces"
                ),
            OperationTask(
                id: "chambers148_glass_cleaning_\(day.lowercased())",
                name: "Glass Cleaning - 148 Chambers Street",
                category: .maintenance,
                location: .entrance,
                estimatedDuration: 10 * 60,
                isWeatherSensitive: false,
                skillLevel: .basic,
                instructions: "Clean glass surfaces - entrance doors and windows"
            ),
            OperationTask(
                id: "chambers148_trash_area_\(day.lowercased())",
                name: "Trash Area Cleaning - 148 Chambers Street",
                category: .trashCollection,
                location: .trashArea,
                estimatedDuration: 15 * 60,
                isWeatherSensitive: false,
                skillLevel: .basic,
                instructions: "Clean trash area, sweep, organize bins"
            )
        ]
        
        // Use DSNY schedule system to determine bin management
        let needsBinRetrieval = DSNYCollectionSchedule.needsBinRetrieval(
            buildingId: CanonicalIDs.Buildings.chambers148, 
            on: collectionDay
        )
        
        if needsBinRetrieval {
            let dsnyTasks = DSNYCollectionSchedule.getBinRetrievalTasks(
                for: CanonicalIDs.Workers.edwinLema, 
                on: collectionDay
            )
            operations.append(contentsOf: dsnyTasks)
        }
        
        return RouteSequence(
            id: "edwin_chambers148_\(day.lowercased())",
            buildingId: CanonicalIDs.Buildings.chambers148,
            buildingName: "148 Chambers Street",
            arrivalTime: arrivalTime,
            estimatedDuration: TimeInterval(operations.reduce(0) { $0 + Int($1.estimatedDuration) }),
            operations: operations,
            sequenceType: .maintenance,
            isFlexible: false,
            dependencies: ["edwin_franklin104_\(day.lowercased())"]
        )
    }
    
    /// Vendor Access Availability (flexible coordination)
    private static func vendorAccessAvailability(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "edwin_vendor_access_\(day.lowercased())",
            buildingId: "various",
            buildingName: "Vendor Access Coordination",
            arrivalTime: arrivalTime,
            estimatedDuration: 60 * 60, // 1 hour availability window
            operations: [
                OperationTask(
                    id: "vendor_access_availability_\(day.lowercased())",
                    name: "Vendor Access Coordination",
                    category: .buildingInspection,
                    location: .exterior,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "\(day): Available for vendor access coordination (sprinkler, ConEd, exterminator, etc.) - coordinate with other workers for closest available person"
                )
            ],
            sequenceType: .inspection,
            isFlexible: true // Very flexible - can be moved based on vendor needs
        )
    }
    
    /// 36 Walker Street sequence (sidewalk hose)
    private static func walker36Sequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "edwin_walker36_\(day.lowercased())",
            buildingId: CanonicalIDs.Buildings.walker36,
            buildingName: "36 Walker Street",
            arrivalTime: arrivalTime,
            estimatedDuration: 15 * 60, // 15 minutes
            operations: [
                OperationTask(
                    id: "walker36_sidewalk_hose_\(day.lowercased())",
                    name: "Sidewalk Hosing - 36 Walker Street",
                    category: .hosing,
                    location: .sidewalk,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic,
                    instructions: "\(day): Hose and clean sidewalk in front of 36 Walker Street"
                )
            ],
            sequenceType: .outdoorCleaning,
            isFlexible: false,
            dependencies: ["edwin_franklin104_\(day.lowercased())"]
        )
    }
    
    /// 123 1st Avenue bin retrieval sequence (bin collection only)
    private static func firstAve123BinRetrievalSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "edwin_firstave123_bin_\(day.lowercased())",
            buildingId: CanonicalIDs.Buildings.firstAvenue123,
            buildingName: "123 1st Avenue - Bin Retrieval",
            arrivalTime: arrivalTime,
            estimatedDuration: 10 * 60, // 10 minutes for bin retrieval only
            operations: [
                OperationTask(
                    id: "firstave123_bin_retrieval_\(day.lowercased())",
                    name: "Bin Collection - 123 1st Avenue",
                    category: .trashCollection,
                    location: .sidewalk,
                    estimatedDuration: 10 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "\(day): Collect and return bins for 123 1st Avenue on collection day"
                )
            ],
            sequenceType: .sanitation,
            isFlexible: false
        )
    }
}
