//
//  KevinDutanCompleteSchedule.swift
//  CyntientOps
//
//  Kevin Dutan's complete weekly and monthly operational schedule
//  Based on real operational patterns with stairwell rotation
//

import Foundation

// MARK: - Kevin Dutan Complete Schedule

public struct KevinDutanCompleteSchedule {
    
    // MARK: - Weekly Route Patterns
    
    /// Kevin's complete weekly schedule
    public static func getWeeklyRoutes() -> [WorkerRoute] {
        return [
            mondayRoute(),
            tuesdayRoute(), // Already defined in KevinDutanRoutes
            wednesdayRoute(),
            thursdayRoute(),
            fridayRoute()
            // Kevin is off Saturdays & Sundays
        ]
    }
    
    // MARK: - Daily Routes
    
    /// Monday Route
    public static func mondayRoute() -> WorkerRoute {
        let routeId = "kevin_monday_route"
        let startTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()
        
        return WorkerRoute(
            id: routeId,
            workerId: CanonicalIDs.Workers.kevinDutan,
            routeName: "Kevin Monday Route",
            dayOfWeek: 2, // Monday
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [
                perryStreet131Sequence(day: "Monday", time: 7, 0),
                perryStreet68Sequence(day: "Monday", time: 8, 0),
                seventeenthStreetMorningSequence(day: "Monday", time: 9, 15),
                // Monday afternoon: 123 1st Ave & 178 Spring (M W F pattern)
                firstAvenueAndSpringSequence(day: "Monday", time: 13, 0),
                // Weekly stairwell rotation (determined by week of year)
                stairwellRotationSequence(day: "Monday", time: 15, 0)
            ],
            routeType: .morningCleaning
        )
    }
    
    /// Tuesday Route (Reference from KevinDutanRoutes)
    public static func tuesdayRoute() -> WorkerRoute {
        return KevinDutanRoutes.tuesdayRoute()
    }
    
    /// Wednesday Route
    public static func wednesdayRoute() -> WorkerRoute {
        let routeId = "kevin_wednesday_route"
        let startTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()
        
        return WorkerRoute(
            id: routeId,
            workerId: CanonicalIDs.Workers.kevinDutan,
            routeName: "Kevin Wednesday Route",
            dayOfWeek: 4, // Wednesday
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [
                perryStreet131Sequence(day: "Wednesday", time: 7, 0),
                perryStreet68Sequence(day: "Wednesday", time: 8, 0),
                seventeenthStreetMorningSequence(day: "Wednesday", time: 9, 15),
                // Wednesday afternoon: 123 1st Ave & 178 Spring (M W F pattern) + Angel covers evening garbage
                firstAvenueAndSpringSequence(day: "Wednesday", time: 13, 0)
                // No evening garbage - Angel handles Wednesday evenings
            ],
            routeType: .morningCleaning
        )
    }
    
    /// Thursday Route
    public static func thursdayRoute() -> WorkerRoute {
        let routeId = "kevin_thursday_route"
        let startTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()
        
        return WorkerRoute(
            id: routeId,
            workerId: CanonicalIDs.Workers.kevinDutan,
            routeName: "Kevin Thursday Route",
            dayOfWeek: 5, // Thursday
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [
                perryStreet131Sequence(day: "Thursday", time: 7, 0),
                perryStreet68Sequence(day: "Thursday", time: 8, 0),
                seventeenthStreetMorningSequence(day: "Thursday", time: 9, 15),
                seventhAvenueSequence(day: "Thursday", time: 12, 0),
                // Thursday afternoon: Alternative buildings or projects
                alternativeBuildingsSequence(day: "Thursday", time: 14, 0)
            ],
            routeType: .morningCleaning
        )
    }
    
    /// Friday Route
    public static func fridayRoute() -> WorkerRoute {
        let routeId = "kevin_friday_route"
        let startTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let endTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date()) ?? Date()
        
        return WorkerRoute(
            id: routeId,
            workerId: CanonicalIDs.Workers.kevinDutan,
            routeName: "Kevin Friday Route",
            dayOfWeek: 6, // Friday
            startTime: startTime,
            estimatedEndTime: endTime,
            sequences: [
                perryStreet131Sequence(day: "Friday", time: 7, 0),
                perryStreet68Sequence(day: "Friday", time: 8, 0),
                seventeenthStreetMorningSequence(day: "Friday", time: 9, 15),
                // Friday afternoon: 123 1st Ave & 178 Spring (M W F pattern)
                firstAvenueAndSpringSequence(day: "Friday", time: 13, 0),
                // Weekly maintenance tasks (water filters monthly, etc.)
                weeklyMaintenanceSequence(day: "Friday", time: 15, 0)
            ],
            routeType: .morningCleaning
        )
    }
    
    
    // MARK: - Sequence Builders
    
    /// Reusable Perry Street 131 sequence with day/time parameters
    private static func perryStreet131Sequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_perry131_\(day.lowercased())",
            buildingId: CanonicalIDs.Buildings.perry131,
            buildingName: "131 Perry Street",
            arrivalTime: arrivalTime,
            estimatedDuration: 30 * 60,
            operations: [
                OperationTask(
                    id: "perry131_building_check_\(day.lowercased())",
                    name: "Building Check & Assessment",
                    category: .buildingInspection,
                    location: .entrance,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic,
                    instructions: "\(day) building check - entrance, lobby, immediate issues"
                ),
                OperationTask(
                    id: "perry131_entrance_cleaning_\(day.lowercased())",
                    name: "Entrance Area Cleaning",
                    category: .sweeping,
                    location: .entrance,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic
                )
            ],
            sequenceType: .buildingCheck,
            isFlexible: true
        )
    }
    
    /// Reusable Perry Street 68 sequence
    private static func perryStreet68Sequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_perry68_\(day.lowercased())",
            buildingId: CanonicalIDs.Buildings.perry68,
            buildingName: "68 Perry Street",
            arrivalTime: arrivalTime,
            estimatedDuration: 45 * 60,
            operations: [
                OperationTask(
                    id: "perry68_maintenance_check_\(day.lowercased())",
                    name: "\(day) Perry Street Maintenance",
                    category: .maintenance,
                    location: .exterior,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .intermediate
                ),
                OperationTask(
                    id: "perry68_trash_area_\(day.lowercased())",
                    name: "Trash Area Maintenance",
                    category: .trashCollection,
                    location: .trashArea,
                    estimatedDuration: 15 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .basic
                )
            ],
            sequenceType: .maintenance,
            isFlexible: true,
            dependencies: ["kevin_perry131_\(day.lowercased())"]
        )
    }
    
    /// 17th Street morning sequence (consistent across weekdays)
    private static func seventeenthStreetMorningSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_17th_complex_\(day.lowercased())",
            buildingId: "17th_street_complex",
            buildingName: "17th Street Building Complex",
            arrivalTime: arrivalTime,
            estimatedDuration: 165 * 60, // 2 hours 45 minutes
            operations: [
                // Same operations as Tuesday but with day-specific IDs
                OperationTask(
                    id: "sidewalk_hosing_112_117_\(day.lowercased())",
                    name: "Sidewalk Hosing - 112 & 117 W 17th",
                    category: .hosing,
                    location: .sidewalk,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: true,
                    requiredEquipment: ["Hose", "Squeegee"],
                    skillLevel: .basic,
                    instructions: "\(day): Hose sidewalks, squeegee clean, ensure proper drainage"
                ),
                OperationTask(
                    id: "vacuum_hallways_112_\(day.lowercased())",
                    name: "Vacuum Hallways Floors 2-6 - 112 W 17th",
                    category: .vacuuming,
                    location: .hallway,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: false,
                    requiredEquipment: ["Vacuum"],
                    instructions: "Floors 2, 3, 4, 5, 6 hallways and stairwell landings"
                ),
                OperationTask(
                    id: "trash_areas_multiple_\(day.lowercased())",
                    name: "Trash Area Cleaning - All 17th St Buildings",
                    category: .trashCollection,
                    location: .trashArea,
                    estimatedDuration: 45 * 60,
                    isWeatherSensitive: false,
                    instructions: "Clean trash areas for 112, 117, 136, 138, 142-148"
                )
                // Additional operations as needed per day
            ],
            sequenceType: .indoorCleaning,
            isFlexible: true,
            dependencies: ["kevin_perry68_\(day.lowercased())"]
        )
    }
    
    /// 7th Avenue sequence (poster removal & treepit cleaning)
    private static func seventhAvenueSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_7th_avenue_\(day.lowercased())",
            buildingId: CanonicalIDs.Buildings.seventhAvenue115,
            buildingName: "115 7th Avenue",
            arrivalTime: arrivalTime,
            estimatedDuration: 90 * 60,
            operations: [
                OperationTask(
                    id: "poster_removal_7th_ave_\(day.lowercased())",
                    name: "Poster Removal - 115 7th Avenue",
                    category: .posterRemoval,
                    location: .exterior,
                    estimatedDuration: 45 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .intermediate,
                    instructions: "\(day): Remove illegal postings, clean adhesive residue"
                ),
                OperationTask(
                    id: "treepit_cleaning_7th_ave_\(day.lowercased())",
                    name: "Treepit Cleaning - 115 7th Avenue Area",
                    category: .treepitCleaning,
                    location: .treepit,
                    estimatedDuration: 45 * 60,
                    isWeatherSensitive: true,
                    requiredEquipment: ["Hand tools", "Trash bags"],
                    instructions: "\(day): Clean tree pits, remove debris, maintain landscaping"
                )
            ],
            sequenceType: .outdoorCleaning,
            isFlexible: false, // Weather dependent but cannot be skipped
            dependencies: ["kevin_17th_complex_\(day.lowercased())"]
        )
    }
    
    /// 123 1st Avenue & 178 Spring Street sequence (M W F pattern)
    private static func firstAvenueAndSpringSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_1st_spring_\(day.lowercased())",
            buildingId: "multi_location",
            buildingName: "123 1st Ave & 178 Spring St",
            arrivalTime: arrivalTime,
            estimatedDuration: 120 * 60, // 2 hours
            operations: [
                OperationTask(
                    id: "building_maintenance_1st_ave_\(day.lowercased())",
                    name: "Building Maintenance - 123 1st Avenue",
                    category: .maintenance,
                    location: .exterior,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .intermediate,
                    instructions: "\(day): Full building exterior and common area maintenance"
                ),
                OperationTask(
                    id: "building_cleaning_spring_\(day.lowercased())",
                    name: "Building Cleaning - 178 Spring Street",
                    category: .sweeping,
                    location: .exterior,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic,
                    instructions: "\(day): Exterior cleaning and entrance maintenance"
                )
            ],
            sequenceType: .maintenance,
            isFlexible: true,
            dependencies: ["kevin_7th_avenue_\(day.lowercased())"]
        )
    }
    
    /// Stairwell rotation sequence (weekly assignments)
    private static func stairwellRotationSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        // Determine which stairwells to clean this week (this would be calculated dynamically)
        let currentWeek = Calendar.current.component(.weekOfYear, from: Date())
        let assignedBuildings = getStairwellAssignmentsForWeek(currentWeek)
        
        return RouteSequence(
            id: "kevin_stairwell_rotation_\(day.lowercased())",
            buildingId: assignedBuildings.first?.buildingId ?? "unknown",
            buildingName: "Stairwell Cleaning Rotation",
            arrivalTime: arrivalTime,
            estimatedDuration: 60 * 60, // 1 hour per building
            operations: assignedBuildings.map { building in
                OperationTask(
                    id: "stairwell_cleaning_\(building.buildingId)_\(day.lowercased())",
                    name: "Stairwell Cleaning - \(building.buildingName)",
                    category: .stairwellCleaning,
                    location: .stairwell,
                    estimatedDuration: 60 * 60,
                    isWeatherSensitive: false,
                    requiredEquipment: ["Vacuum", "Mop", "Cleaning supplies"],
                    skillLevel: .basic,
                    instructions: "Clean stairwell floors \(building.floors.map { String($0) }.joined(separator: ", "))"
                )
            },
            sequenceType: .indoorCleaning,
            isFlexible: true
        )
    }
    
    /// Alternative buildings sequence for days without 123 1st/178 Spring
    private static func alternativeBuildingsSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_alternative_buildings_\(day.lowercased())",
            buildingId: "various",
            buildingName: "Alternative Building Maintenance",
            arrivalTime: arrivalTime,
            estimatedDuration: 90 * 60,
            operations: [
                OperationTask(
                    id: "alternative_maintenance_\(day.lowercased())",
                    name: "Alternative Building Tasks",
                    category: .maintenance,
                    location: .exterior,
                    estimatedDuration: 90 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .intermediate,
                    instructions: "\(day): Focus on buildings not covered in regular rotation"
                )
            ],
            sequenceType: .maintenance,
            isFlexible: true
        )
    }
    
    /// Weekly maintenance tasks (water filters, etc.)
    private static func weeklyMaintenanceSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_weekly_maintenance_\(day.lowercased())",
            buildingId: "various",
            buildingName: "Weekly Maintenance Tasks",
            arrivalTime: arrivalTime,
            estimatedDuration: 60 * 60,
            operations: [
                OperationTask(
                    id: "water_filters_monthly_\(day.lowercased())",
                    name: "Water Filter Check/Change - 112 & 117",
                    category: .maintenance,
                    location: .basement,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: false,
                    skillLevel: .intermediate,
                    instructions: "Monthly water filter maintenance for buildings 112 and 117"
                ),
                OperationTask(
                    id: "general_weekly_maintenance_\(day.lowercased())",
                    name: "General Weekly Maintenance",
                    category: .maintenance,
                    location: .exterior,
                    estimatedDuration: 30 * 60,
                    isWeatherSensitive: true,
                    skillLevel: .basic,
                    instructions: "General building maintenance tasks"
                )
            ],
            sequenceType: .maintenance,
            isFlexible: true
        )
    }
    
    
    /// Project work sequence (capital improvements)
    private static func projectWorkSequence(day: String, time hour: Int, _ minute: Int) -> RouteSequence {
        let arrivalTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        
        return RouteSequence(
            id: "kevin_project_work_\(day.lowercased())",
            buildingId: CanonicalIDs.Buildings.chambers148,
            buildingName: "Capital Improvement Projects",
            arrivalTime: arrivalTime,
            estimatedDuration: 120 * 60,
            operations: [
                OperationTask(
                    id: "capital_improvement_work_\(day.lowercased())",
                    name: "Capital Improvement Support Work",
                    category: .maintenance,
                    location: .basement,
                    estimatedDuration: 120 * 60,
                    isWeatherSensitive: false,
                    requiredEquipment: ["Hand tools", "Cleaning supplies"],
                    skillLevel: .intermediate,
                    instructions: "Support capital improvement projects - no painting (done by Shawn, Edwin, or contractors)"
                )
            ],
            sequenceType: .maintenance,
            isFlexible: false // Projects have deadlines
        )
    }
    
    // MARK: - Stairwell Assignment Logic
    
    /// Get stairwell assignments for a specific week (this would be more sophisticated in practice)
    private static func getStairwellAssignmentsForWeek(_ week: Int) -> [StairwellInfo] {
        let allBuildings = [
            StairwellInfo(buildingId: CanonicalIDs.Buildings.westEighteenth112, buildingName: "112 West 18th Street", floors: [2, 3, 4, 5, 6]),
            StairwellInfo(buildingId: CanonicalIDs.Buildings.westSeventeenth117, buildingName: "117 West 17th Street", floors: [2, 3, 4, 5, 6]),
            StairwellInfo(buildingId: CanonicalIDs.Buildings.rubinMuseum, buildingName: "Rubin Museum Complex", floors: [1, 2, 3, 4, 5, 6])
        ]
        
        // Simple rotation - in practice this would be more sophisticated
        let assignedIndex = week % allBuildings.count
        return [allBuildings[assignedIndex]]
    }
    
    private struct StairwellInfo {
        let buildingId: String
        let buildingName: String
        let floors: [Int]
    }
}